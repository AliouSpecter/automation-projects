<?php
/**
 * Plugin Name: AutomationAct WhatsApp Callback
 * Description: Reçoit le code OAuth Embedded Signup Meta, récupère WABA ID + Phone Number ID + Access Token et les stocke.
 * Version: 1.0
 */

defined('ABSPATH') || exit;

// ─── Constantes ───────────────────────────────────────────────────────────────
define('AA_META_APP_ID',     '2093631011414930');
define('AA_META_APP_SECRET', 'c22c1b441a7661f03b1fa2193c41805a');

// ─── Enregistrement de la route REST ──────────────────────────────────────────
add_action('rest_api_init', function () {
    register_rest_route('automationact/v1', '/whatsapp-callback', [
        'methods'             => 'POST',
        'callback'            => 'aa_whatsapp_callback',
        'permission_callback' => '__return_true',
    ]);
    register_rest_route('automationact/v1', '/whatsapp-clients', [
        'methods'             => 'GET',
        'callback'            => 'aa_whatsapp_list_clients',
        'permission_callback' => function() { return current_user_can('manage_options'); },
    ]);
});

// ─── Liste des clients connectés (admin only) ─────────────────────────────────
function aa_whatsapp_list_clients() {
    $clients = get_option('aa_wa_connected_clients', []);
    return new WP_REST_Response($clients, 200);
}

// ─── Handler principal ────────────────────────────────────────────────────────
function aa_whatsapp_callback(WP_REST_Request $request) {
    $body = $request->get_json_params();
    $code = sanitize_text_field($body['code'] ?? '');

    if (empty($code)) {
        return new WP_REST_Response(['error' => 'Code manquant'], 400);
    }

    // 1. Échanger le code contre un access token
    $token_res = wp_remote_get(add_query_arg([
        'client_id'     => AA_META_APP_ID,
        'client_secret' => AA_META_APP_SECRET,
        'code'          => $code,
    ], 'https://graph.facebook.com/v25.0/oauth/access_token'));

    if (is_wp_error($token_res)) {
        return new WP_REST_Response(['error' => 'Erreur échange token'], 500);
    }

    $token_data = json_decode(wp_remote_retrieve_body($token_res), true);
    $access_token = $token_data['access_token'] ?? '';

    if (empty($access_token)) {
        return new WP_REST_Response(['error' => 'Token non reçu', 'detail' => $token_data], 400);
    }

    // 2. Récupérer le WABA ID via debug_token
    $debug_res = wp_remote_get(add_query_arg([
        'input_token'  => $access_token,
        'access_token' => AA_META_APP_ID . '|' . AA_META_APP_SECRET,
    ], 'https://graph.facebook.com/v25.0/debug_token'));

    $debug_data = json_decode(wp_remote_retrieve_body($debug_res), true);
    $waba_id    = '';

    foreach (($debug_data['data']['granular_scopes'] ?? []) as $scope) {
        if ($scope['scope'] === 'whatsapp_business_management' && !empty($scope['target_ids'][0])) {
            $waba_id = $scope['target_ids'][0];
            break;
        }
    }

    if (empty($waba_id)) {
        return new WP_REST_Response(['error' => 'WABA ID non trouvé', 'detail' => $debug_data], 400);
    }

    // 3. Récupérer le Phone Number ID
    $phone_res  = wp_remote_get(
        'https://graph.facebook.com/v25.0/' . $waba_id . '/phone_numbers',
        ['headers' => ['Authorization' => 'Bearer ' . $access_token]]
    );
    $phone_data = json_decode(wp_remote_retrieve_body($phone_res), true);
    $phone_number_id = $phone_data['data'][0]['id'] ?? '';

    // 4. Stocker en base (wp_options)
    $client_key = 'aa_wa_client_' . $waba_id;
    $client_record = [
        'waba_id'         => $waba_id,
        'phone_number_id' => $phone_number_id,
        'access_token'    => $access_token,
        'connected_at'    => current_time('mysql'),
    ];
    update_option($client_key, $client_record, false);

    // Log dans une liste globale des clients connectés
    $clients = get_option('aa_wa_connected_clients', []);
    $clients[$waba_id] = [
        'waba_id'         => $waba_id,
        'phone_number_id' => $phone_number_id,
        'connected_at'    => current_time('mysql'),
    ];
    update_option('aa_wa_connected_clients', $clients, false);

    return new WP_REST_Response([
        'success'         => true,
        'waba_id'         => $waba_id,
        'phone_number_id' => $phone_number_id,
    ], 200);
}
