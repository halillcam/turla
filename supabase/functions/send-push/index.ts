// send-push: bildirim kutusuna düşen satırları Android cihazlara push olarak yollar (FCM HTTP v1).
//
// Çağıran: notifications tablosundaki notifications_push tetikleyicisi (pg_net), tek
// INSERT için tek istek: POST { notification_ids: [...] }.
//
// Gövdeye güvenilmez (verify_jwt kapalı, herkes çağırabilir): fonksiyon sadece
// kimlikleri verilen, henüz gönderilmemiş ve son 10 dakikada oluşmuş bildirimleri
// service role ile kendisi okur ve push_sent_at yazarak "sahiplenir". Böylece sahte
// bir çağrı içerik uyduramaz, aynı bildirim iki kez gönderilmez.
//
// FCM_SERVICE_ACCOUNT (Firebase service account JSON'u) sadece Supabase secret'ıdır;
// yoksa fonksiyon hiçbir şey yapmaz (uygulama içi bildirim kutusu yine çalışır).
// Geçersiz (UNREGISTERED) token'lar tablodan silinir.

import { createClient } from 'npm:@supabase/supabase-js@2.49.4';

import {
  PUSH_MAX_AGE_MINUTES,
  type ServiceAccount,
  base64UrlEncode,
  buildFcmMessage,
  isDeadToken,
  oauthClaims,
  parseNotificationIds,
  parseServiceAccount,
  pemToDer,
} from './rules.ts';

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

let cachedToken: { value: string; expiresAt: number } | null = null;

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;

  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64UrlEncode(JSON.stringify(oauthClaims(sa, now)));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  const assertion = `${header}.${claims}.${base64UrlEncode(signature)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`oauth_failed_${res.status}`);
  const body = await res.json() as { access_token: string; expires_in: number };
  cachedToken = { value: body.access_token, expiresAt: now + body.expires_in };
  return body.access_token;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, { code: 'method_not_allowed' });

  const ids = parseNotificationIds(await req.json().catch(() => null));
  if (ids.length === 0) return json(200, { sent: 0 });

  const sa = parseServiceAccount(Deno.env.get('FCM_SERVICE_ACCOUNT'));
  if (!sa) return json(200, { sent: 0, skipped: 'no_credentials' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) return json(500, { code: 'server_misconfigured' });
  const db = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const since = new Date(Date.now() - PUSH_MAX_AGE_MINUTES * 60_000).toISOString();
  const { data: claimed, error: claimError } = await db
    .from('notifications')
    .update({ push_sent_at: new Date().toISOString() })
    .in('id', ids)
    .is('push_sent_at', null)
    .gt('created_at', since)
    .select('id, user_id, title, body, departure_id');
  if (claimError) return json(500, { code: 'claim_failed' });
  if (!claimed || claimed.length === 0) return json(200, { sent: 0 });

  const userIds = [...new Set(claimed.map((n) => n.user_id as string))];
  const { data: tokens, error: tokenError } = await db
    .from('device_tokens')
    .select('token, user_id')
    .in('user_id', userIds)
    .eq('platform', 'android');
  if (tokenError) return json(500, { code: 'tokens_failed' });
  if (!tokens || tokens.length === 0) return json(200, { sent: 0 });

  let bearer: string;
  try {
    bearer = await accessToken(sa);
  } catch (_) {
    return json(502, { code: 'oauth_failed' });
  }

  const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.projectId}/messages:send`;
  const dead: string[] = [];
  let sent = 0;
  await Promise.all(claimed.flatMap((n) =>
    tokens.filter((t) => t.user_id === n.user_id).map(async (t) => {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(buildFcmMessage(t.token as string, {
          id: n.id as string,
          title: n.title as string,
          body: n.body as string,
          departureId: (n.departure_id as string | null) ?? null,
        })),
      });
      if (res.ok) {
        sent++;
      } else if (isDeadToken(res.status, await res.json().catch(() => null))) {
        dead.push(t.token as string);
      }
    })
  ));

  if (dead.length > 0) await db.from('device_tokens').delete().in('token', [...new Set(dead)]);
  return json(200, { sent, removed_tokens: dead.length });
});
