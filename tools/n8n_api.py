"""
n8n API Tool
Usage:
  python tools/n8n_api.py workflows                        # list all workflows
  python tools/n8n_api.py executions <workflow_id>         # last 5 executions
  python tools/n8n_api.py execution <execution_id>         # full execution detail
  python tools/n8n_api.py errors <workflow_id>             # last failed execution detail
"""
import sys
import json
import os
import urllib.request
import urllib.error
from dotenv import load_dotenv

load_dotenv()

BASE_URL = os.getenv("N8N_BASE_URL", "").rstrip("/")
API_KEY  = os.getenv("N8N_API_KEY", "")

def api(path, params=None):
    url = f"{BASE_URL}/api/v1{path}"
    if params:
        query = "&".join(f"{k}={v}" for k, v in params.items())
        url += f"?{query}"
    req = urllib.request.Request(url, headers={"X-N8N-API-KEY": API_KEY})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode()}")
        sys.exit(1)

def cmd_workflows():
    data = api("/workflows", {"limit": "50"})
    rows = data.get("data", [])
    print(f"{'ID':<36} {'ACTIVE':<8} NAME")
    print("-" * 80)
    for w in rows:
        active = "✅" if w.get("active") else "❌"
        print(f"{w['id']:<36} {active:<8} {w['name']}")

def cmd_executions(wf_id):
    data = api("/executions", {"workflowId": wf_id, "limit": "5", "includeData": "false"})
    rows = data.get("data", [])
    if not rows:
        print("Aucune exécution trouvée.")
        return
    print(f"{'ID':<12} {'STATUS':<12} {'STARTED':<25} DURATION")
    print("-" * 70)
    for e in rows:
        started = e.get("startedAt", "")[:19]
        status  = e.get("status", "?")
        eid     = str(e.get("id", ""))
        dur_ms  = ""
        if e.get("startedAt") and e.get("stoppedAt"):
            from datetime import datetime
            s = datetime.fromisoformat(e["startedAt"].replace("Z", "+00:00"))
            t = datetime.fromisoformat(e["stoppedAt"].replace("Z", "+00:00"))
            dur_ms = f"{int((t-s).total_seconds()*1000)}ms"
        mark = "❌" if status == "error" else ("✅" if status == "success" else "🔄")
        print(f"{eid:<12} {mark} {status:<10} {started:<25} {dur_ms}")

def cmd_execution(exec_id):
    data = api(f"/executions/{exec_id}", {"includeData": "true"})
    status = data.get("status", "?")
    print(f"\n=== Execution {exec_id} — {status.upper()} ===\n")
    run_data = data.get("data", {})
    result_data = run_data.get("resultData", {})
    run_data_exec = result_data.get("runData", {})
    error = result_data.get("error")
    if error:
        print(f"🔴 ERREUR GLOBALE: {error.get('message','')}\n")
    for node_name, node_runs in run_data_exec.items():
        for run in node_runs:
            err = run.get("error")
            if err:
                print(f"🔴 NODE EN ERREUR: [{node_name}]")
                print(f"   Message : {err.get('message','')}")
                print(f"   Type    : {err.get('name','')}")
                desc = err.get("description", "")
                if desc:
                    print(f"   Détail  : {desc}")
                print()
            else:
                out = run.get("data", {}).get("main", [[]])[0]
                count = len(out) if out else 0
                print(f"✅ [{node_name}] — {count} item(s)")

def cmd_errors(wf_id):
    data = api("/executions", {"workflowId": wf_id, "status": "error", "limit": "1", "includeData": "false"})
    rows = data.get("data", [])
    if not rows:
        print("Aucune exécution en erreur trouvée.")
        return
    exec_id = rows[0]["id"]
    print(f"Dernière exécution en erreur : {exec_id}")
    cmd_execution(exec_id)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd == "workflows":
        cmd_workflows()
    elif cmd == "executions" and len(sys.argv) >= 3:
        cmd_executions(sys.argv[2])
    elif cmd == "execution" and len(sys.argv) >= 3:
        cmd_execution(sys.argv[2])
    elif cmd == "errors" and len(sys.argv) >= 3:
        cmd_errors(sys.argv[2])
    else:
        print(__doc__)
