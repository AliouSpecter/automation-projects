#!/usr/bin/env python3
"""
Check WordPress drafts tagged pending-linkedin, post to LinkedIn, publish post
Designed to run as a scheduled task on the n8n server or locally
"""

import os
import sys
import re
import base64
import requests
from requests.auth import HTTPBasicAuth
from typing import Optional, List, Dict, Any
import json
from datetime import datetime

# Load environment
dotenv_path = os.path.join(os.path.dirname(__file__), '../.env')
if os.path.exists(dotenv_path):
    with open(dotenv_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, val = line.split('=', 1)
                os.environ[key.strip()] = val.strip()

WP_URL = os.getenv('WP_URL')
WP_USER = os.getenv('WP_USER')
WP_PASS = os.getenv('WP_APP_PASSWORD')
LI_TOKEN = os.getenv('LINKEDIN_ACCESS_TOKEN')
LI_PID = os.getenv('LINKEDIN_PERSON_ID')

def log(msg: str):
    ts = datetime.now().isoformat()
    print(f"[{ts}] {msg}")

def get_wp_drafts() -> List[Dict[str, Any]]:
    """Get WordPress draft posts with pending-linkedin tag"""
    url = f"{WP_URL}/wp-json/wp/v2/posts"
    params = {'status': 'draft', 'tags': '32', 'per_page': 10}

    try:
        r = requests.get(url, params=params, auth=HTTPBasicAuth(WP_USER, WP_PASS), timeout=10)
        r.raise_for_status()
        posts = r.json()
        if isinstance(posts, list):
            return posts
        return []
    except Exception as e:
        log(f"Error fetching WP drafts: {e}")
        return []

def get_featured_image(media_id: int) -> Optional[bytes]:
    """Download featured image from WordPress"""
    if not media_id:
        return None

    url = f"{WP_URL}/wp-json/wp/v2/media/{media_id}"
    try:
        r = requests.get(url, auth=HTTPBasicAuth(WP_USER, WP_PASS), timeout=10)
        r.raise_for_status()
        media = r.json()

        if media.get('source_url'):
            img_r = requests.get(media['source_url'], timeout=10)
            img_r.raise_for_status()
            return img_r.content
    except Exception as e:
        log(f"Error getting image {media_id}: {e}")
    return None

def init_linkedin_image() -> Optional[Dict[str, str]]:
    """Initialize LinkedIn image upload"""
    url = "https://api.linkedin.com/rest/images?action=initializeUpload"
    headers = {
        "Authorization": f"Bearer {LI_TOKEN}",
        "LinkedIn-Version": "202306",
        "X-Restli-Protocol-Version": "2.0.0"
    }
    data = {"initializeUploadRequest": {"owner": f"urn:li:person:{LI_PID}"}}

    try:
        r = requests.post(url, json=data, headers=headers, timeout=15)
        r.raise_for_status()
        resp = r.json()
        return {
            'uploadUrl': resp['value']['uploadUrl'],
            'imageUrn': resp['value']['image']
        }
    except Exception as e:
        log(f"Error initializing LinkedIn image: {e}")
        return None

def upload_image_to_linkedin(upload_url: str, image_data: bytes) -> bool:
    """Upload image to LinkedIn"""
    headers = {"Authorization": f"Bearer {LI_TOKEN}"}

    try:
        r = requests.put(upload_url, data=image_data, headers=headers, timeout=30)
        r.raise_for_status()
        return True
    except Exception as e:
        log(f"Error uploading image to LinkedIn: {e}")
        return False

def post_to_linkedin(text: str, image_urn: Optional[str] = None) -> Optional[str]:
    """Post to LinkedIn with optional image"""
    url = "https://api.linkedin.com/rest/posts"
    headers = {
        "Authorization": f"Bearer {LI_TOKEN}",
        "LinkedIn-Version": "202306",
        "X-Restli-Protocol-Version": "2.0.0"
    }

    payload = {
        "author": f"urn:li:person:{LI_PID}",
        "commentary": text,
        "visibility": "PUBLIC",
        "distribution": {
            "feedDistribution": "MAIN_FEED",
            "targetEntities": [],
            "thirdPartyDistributionChannels": []
        },
        "lifecycleState": "PUBLISHED",
        "isReshareDisabledByAuthor": False
    }

    if image_urn:
        payload["content"] = {"media": {"id": image_urn}}

    try:
        r = requests.post(url, json=payload, headers=headers, timeout=15)
        r.raise_for_status()
        resp = r.json()
        return resp.get('id')
    except Exception as e:
        log(f"Error posting to LinkedIn: {e}")
        return None

def publish_wp_post(post_id: int) -> bool:
    """Publish WordPress post"""
    url = f"{WP_URL}/wp-json/wp/v2/posts/{post_id}"
    data = {"status": "publish"}

    try:
        r = requests.post(url, json=data, auth=HTTPBasicAuth(WP_USER, WP_PASS), timeout=10)
        r.raise_for_status()
        return True
    except Exception as e:
        log(f"Error publishing WP post {post_id}: {e}")
        return False

def main():
    log("Checking WordPress drafts...")
    drafts = get_wp_drafts()

    if not drafts:
        log("No drafts to process")
        return

    log(f"Found {len(drafts)} draft(s)")

    for post in drafts:
        post_id = post['id']
        text = post.get('content', {}).get('rendered', '')
        media_id = post.get('featured_media')

        log(f"Processing post {post_id}...")

        # Remove HTML tags from text
        text_clean = re.sub(r'<[^>]+>', '', text).strip()
        if not text_clean:
            log(f"  Skipping: empty content")
            continue

        linkedin_post_id = None

        # If image exists, upload and include
        if media_id:
            log(f"  Downloading image {media_id}...")
            img_data = get_featured_image(media_id)

            if img_data:
                log(f"  Initializing LinkedIn image...")
                img_init = init_linkedin_image()

                if img_init:
                    log(f"  Uploading image to LinkedIn...")
                    if upload_image_to_linkedin(img_init['uploadUrl'], img_data):
                        log(f"  Posting to LinkedIn with image...")
                        linkedin_post_id = post_to_linkedin(text_clean, img_init['imageUrn'])

        # If no image or image upload failed, post text only
        if not linkedin_post_id:
            log(f"  Posting text-only to LinkedIn...")
            linkedin_post_id = post_to_linkedin(text_clean)

        if linkedin_post_id:
            log(f"  ✓ Posted to LinkedIn: {linkedin_post_id}")

            # Publish WP post
            log(f"  Publishing WP post...")
            if publish_wp_post(post_id):
                log(f"  ✓ Post {post_id} published")
            else:
                log(f"  ✗ Failed to publish WP post (but LinkedIn post succeeded)")
        else:
            log(f"  ✗ Failed to post to LinkedIn")

if __name__ == '__main__':
    main()
