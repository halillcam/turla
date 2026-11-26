// send-push Edge Function'ının iş kuralları.
//
// Dışa bağımlılığı yoktur; Deno'da (Edge Function) ve Node'da (testler)
// aynen çalışır. Ağ/veritabanı işleri index.ts içindedir.

/** Bir çağrıda en fazla bu kadar bildirim işlenir (bir tarihin kontenjanı bunun altında). */
export const MAX_NOTIFICATIONS_PER_CALL = 500;

/** Bu süreden eski bildirim push olarak gönderilmez (geç kalmış push kafa karıştırır). */
export const PUSH_MAX_AGE_MINUTES = 10;

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Tetikleyiciden gelen gövdedeki bildirim kimlikleri. Gövdeye güvenilmez:
 * sadece geçerli uuid'ler alınır, tekrarlar atılır, üst sınır uygulanır.
 * Asıl içerik veritabanından okunur.
 */
export function parseNotificationIds(body: unknown): string[] {
  if (typeof body !== 'object' || body === null) return [];
  const raw = (body as { notification_ids?: unknown }).notification_ids;
  if (!Array.isArray(raw)) return [];
  const ids = new Set<string>();
  for (const value of raw) {
    if (typeof value === 'string' && UUID_RE.test(value)) ids.add(value.toLowerCase());
    if (ids.size >= MAX_NOTIFICATIONS_PER_CALL) break;
  }
  return [...ids];
}

export interface ServiceAccount {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

/** FCM_SERVICE_ACCOUNT secret'ındaki JSON. Eksik alan varsa null (push yapılmaz). */
export function parseServiceAccount(raw: string | undefined | null): ServiceAccount | null {
  if (!raw) return null;
  try {
    const json = JSON.parse(raw) as Record<string, unknown>;
    const projectId = json.project_id;
    const clientEmail = json.client_email;
    const privateKey = json.private_key;
    if (typeof projectId !== 'string' || typeof clientEmail !== 'string' || typeof privateKey !== 'string') {
      return null;
    }
    if (!privateKey.includes('BEGIN PRIVATE KEY')) return null;
    return { projectId, clientEmail, privateKey };
  } catch {
    return null;
  }
}

/** Google OAuth için JWT gövdesi (1 saat geçerli). */
export function oauthClaims(sa: ServiceAccount, nowSeconds: number) {
  return {
    iss: sa.clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  };
}

export interface PushNotification {
  id: string;
  title: string;
  body: string;
  departureId: string | null;
}

/** FCM HTTP v1 mesajı. data alanı uygulamada dokununca açılacak ekranı belirler. */
export function buildFcmMessage(token: string, n: PushNotification) {
  const data: Record<string, string> = { type: 'announcement', notification_id: n.id };
  if (n.departureId) data.departure_id = n.departureId;
  return {
    message: {
      token,
      notification: { title: truncate(n.title, 120), body: truncate(n.body, 400) },
      data,
      // Uygulamada ayrı kanal yok: FCM'in varsayılan Android kanalı kullanılır.
      android: { priority: 'HIGH' },
    },
  };
}

/** Token artık geçersizse (uygulama silinmiş vb.) true: token tablodan silinir. */
export function isDeadToken(status: number, responseBody: unknown): boolean {
  if (status === 404) return true;
  const details = (responseBody as { error?: { details?: unknown } })?.error?.details;
  if (!Array.isArray(details)) return false;
  return details.some((d) => (d as { errorCode?: string })?.errorCode === 'UNREGISTERED');
}

export function truncate(text: string, max: number): string {
  return text.length <= max ? text : `${text.slice(0, max - 1)}…`;
}

/** PEM özel anahtarını WebCrypto'nun beklediği ham bayt dizisine çevirir. */
export function pemToDer(pem: string): Uint8Array {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\\n/g, '')
    .replace(/\s+/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

export function base64UrlEncode(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
