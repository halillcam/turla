// send-push Edge Function kurallarının testleri (Node, TypeScript doğrudan).
import {
  MAX_NOTIFICATIONS_PER_CALL,
  base64UrlEncode,
  buildFcmMessage,
  isDeadToken,
  oauthClaims,
  parseNotificationIds,
  parseServiceAccount,
  pemToDer,
  truncate,
} from '../functions/send-push/rules.ts';

let failures = 0;
const ok = (label, cond, detail = '') => {
  if (cond) console.log('PASS', label);
  else { failures++; console.log('FAIL', label, detail); }
};

const id1 = '11111111-1111-4111-8111-111111111111';
const id2 = '22222222-2222-4222-8222-222222222222';

ok('geçerli kimlikler alınır, tekrar atılır', JSON.stringify(parseNotificationIds({ notification_ids: [id1, id2, id1] })) === JSON.stringify([id1, id2]));
ok('uuid olmayan değerler atılır', parseNotificationIds({ notification_ids: ['x', 5, null, id1, "'; drop"] }).length === 1);
ok('bozuk gövde boş liste', parseNotificationIds(null).length === 0 && parseNotificationIds({}).length === 0
  && parseNotificationIds({ notification_ids: 'abc' }).length === 0);
const many = Array.from({ length: 700 }, (_, i) => `00000000-0000-4000-8000-${String(i).padStart(12, '0')}`);
ok('üst sınır uygulanır', parseNotificationIds({ notification_ids: many }).length === MAX_NOTIFICATIONS_PER_CALL);

ok('service account yoksa null', parseServiceAccount(undefined) === null && parseServiceAccount('') === null);
ok('bozuk JSON null', parseServiceAccount('{bozuk') === null);
ok('eksik alan null', parseServiceAccount(JSON.stringify({ project_id: 'p', client_email: 'e' })) === null);
ok('özel anahtar değilse null', parseServiceAccount(JSON.stringify({ project_id: 'p', client_email: 'e', private_key: 'abc' })) === null);

const { privateKey } = await crypto.subtle.generateKey(
  { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
  true, ['sign', 'verify'],
);
const der = new Uint8Array(await crypto.subtle.exportKey('pkcs8', privateKey));
const b64 = Buffer.from(der).toString('base64').match(/.{1,64}/g).join('\n');
const pem = `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`;
const sa = parseServiceAccount(JSON.stringify({ project_id: 'turla-test', client_email: 'push@turla-test.iam.gserviceaccount.com', private_key: pem }));
ok('geçerli service account okunur', sa?.projectId === 'turla-test');
ok('PEM ham bayta çevrilir ve WebCrypto ile içe alınır', await crypto.subtle.importKey('pkcs8', pemToDer(pem),
  { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']).then(() => true, () => false));
ok('JSON içindeki kaçışlı \\n satır sonları da çözülür', pemToDer(pem.replace(/\n/g, '\\n')).length === der.length);

const claims = oauthClaims(sa, 1000);
ok('OAuth gövdesi FCM kapsamı ve 1 saat', claims.scope.endsWith('firebase.messaging') && claims.exp === 4600 && claims.iss === sa.clientEmail);
ok('base64url dolgu ve +/ içermez', !/[=+/]/.test(base64UrlEncode(new Uint8Array([251, 255, 254, 1]))));

const msg = buildFcmMessage('tok', { id: id1, title: 'Göksun Turu', body: 'Mola 10 dk', departureId: id2 });
ok('FCM mesajı: token, başlık, data, yüksek öncelik', msg.message.token === 'tok'
  && msg.message.notification.title === 'Göksun Turu'
  && msg.message.data.departure_id === id2 && msg.message.data.type === 'announcement'
  && msg.message.android.priority === 'HIGH');
ok('tarihsiz bildirimde departure_id yok', !('departure_id' in buildFcmMessage('t', { id: id1, title: 'a', body: 'b', departureId: null }).message.data));
ok('uzun gövde kısaltılır', buildFcmMessage('t', { id: id1, title: 'a', body: 'x'.repeat(1000), departureId: null }).message.notification.body.length === 400);
ok('truncate kısa metni değiştirmez', truncate('abc', 10) === 'abc');

ok('404 ölü token', isDeadToken(404, null));
ok('UNREGISTERED ölü token', isDeadToken(400, { error: { details: [{ errorCode: 'UNREGISTERED' }] } }));
ok('kota/sunucu hatası token silmez', !isDeadToken(429, { error: { details: [{ errorCode: 'QUOTA_EXCEEDED' }] } }) && !isDeadToken(500, null));

console.log(failures === 0 ? '\nSEND-PUSH KURALLARI GEÇTİ' : `\n${failures} TEST BAŞARISIZ`);
process.exit(failures === 0 ? 0 : 1);
