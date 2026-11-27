// create-account Edge Function kurallarının testleri.
// Node TypeScript dosyasını doğrudan çalıştırır (type stripping, Node 23.6+).
import {
  generateLoginId,
  loginIdToEmail,
  generatePassword,
  planAccount,
  planAdminEmails,
  planPasswordReset,
} from '../functions/create-account/rules.ts';

const company = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';

const superAdmin = { id: 's', role: 'super_admin', companyId: null, isActive: true };
const admin = { id: 'a', role: 'admin', companyId: company, isActive: true };
const guide = { id: 'g', role: 'guide', companyId: company, isActive: true };
const customer = { id: 'c', role: 'customer', companyId: null, isActive: true };

const base = { full_name: 'Rehber Rıza', password: 'gizli1234' };

let failures = 0;
const check = (label, actual, expected) => {
  const ok = Object.entries(expected).every(([k, v]) => actual[k] === v);
  if (ok) console.log('PASS', label);
  else { failures++; console.log('FAIL', label, '→', JSON.stringify(actual)); }
};

check('super admin firma admini açar (e-posta küçük harfe çevrilir)',
  planAccount(superAdmin, { ...base, role: 'admin', company_id: company, email: ' Ali@Firma.com ' }),
  { ok: true, role: 'admin', companyId: company, email: 'ali@firma.com', loginPrefix: null });
check('super admin şirket vermeden hesap açamaz',
  planAccount(superAdmin, { ...base, role: 'guide' }), { ok: false, code: 'company_required' });
check('super admin rehber açar → REH kimliği',
  planAccount(superAdmin, { ...base, role: 'guide', company_id: company }),
  { ok: true, loginPrefix: 'REH', email: null });
check('super admin, super admin açamaz',
  planAccount(superAdmin, { ...base, role: 'super_admin', company_id: company }),
  { ok: false, code: 'invalid_role' });

check('admin kendi şirketine rehber açar (company_id verilmese de)',
  planAccount(admin, { ...base, role: 'guide' }), { ok: true, companyId: company, loginPrefix: 'REH' });
check('admin dışarıdan müşteri açar → MUS kimliği',
  planAccount(admin, { ...base, role: 'customer', phone: ' 0555 ' }),
  { ok: true, loginPrefix: 'MUS', phone: '0555' });
check('admin başka şirkete hesap açamaz',
  planAccount(admin, { ...base, role: 'guide', company_id: other }), { ok: false, status: 403, code: 'not_allowed' });
check('admin admin açamaz',
  planAccount(admin, { ...base, role: 'admin', email: 'x@y.com' }), { ok: false, code: 'not_allowed' });
check('pasif admin hesap açamaz',
  planAccount({ ...admin, isActive: false }, { ...base, role: 'guide' }), { ok: false, code: 'not_allowed' });
check('şirketsiz admin hesap açamaz',
  planAccount({ ...admin, companyId: null }, { ...base, role: 'guide' }), { ok: false, code: 'not_allowed' });

check('rehber hesap açamaz', planAccount(guide, { ...base, role: 'customer' }), { ok: false, code: 'not_allowed' });
check('müşteri hesap açamaz', planAccount(customer, { ...base, role: 'guide' }), { ok: false, code: 'not_allowed' });

check('kısa şifre reddedilir', planAccount(admin, { ...base, role: 'guide', password: '123' }),
  { ok: false, code: 'weak_password' });
check('kısa ad reddedilir', planAccount(admin, { ...base, role: 'guide', full_name: ' A ' }),
  { ok: false, code: 'invalid_full_name' });
check('geçersiz e-posta reddedilir',
  planAccount(superAdmin, { ...base, role: 'admin', company_id: company, email: 'gecersiz' }),
  { ok: false, code: 'invalid_email' });
check('giriş kimliği alan adı admin e-postası olamaz',
  planAccount(superAdmin, { ...base, role: 'admin', company_id: company, email: 'reh-1@staff.turla.app' }),
  { ok: false, code: 'invalid_email' });

const id = generateLoginId('REH', () => 0.4821);
check('giriş kimliği biçimi', { id, ok: /^REH-\d{4}$/.test(id) }, { ok: true });
check('kimlik 4 hane sınırında', { a: generateLoginId('MUS', () => 0), b: generateLoginId('MUS', () => 0.99999) },
  { a: 'MUS-1000', b: 'MUS-9999' });
check('kimlik e-postaya çevrilir', { e: loginIdToEmail(' REH-4821 ') }, { e: 'reh-4821@staff.turla.app' });

// ─── Şifre sıfırlama ─────────────────────────────────────────────────────
const rehber = { id: 'r', role: 'guide', companyId: company, loginId: 'REH-1234' };
check('admin kendi firmasının rehberinin şifresini sıfırlar',
  planPasswordReset(admin, rehber), { ok: true, userId: 'r', loginId: 'REH-1234' });
check('super admin her firmanın MUS hesabını sıfırlar',
  planPasswordReset(superAdmin, { id: 'm', role: 'customer', companyId: other, loginId: 'MUS-5555' }), { ok: true });
check('admin başka firmanın rehberini sıfırlayamaz',
  planPasswordReset(admin, { ...rehber, companyId: other }), { ok: false, code: 'not_allowed' });
check('rehber şifre sıfırlayamaz', planPasswordReset(guide, rehber), { ok: false, code: 'not_allowed' });
check('müşteri şifre sıfırlayamaz', planPasswordReset(customer, rehber), { ok: false, code: 'not_allowed' });
check('pasif admin şifre sıfırlayamaz',
  planPasswordReset({ ...admin, isActive: false }, rehber), { ok: false, code: 'not_allowed' });
check('e-postayla kayıt olan uygulama müşterisi sıfırlanmaz',
  planPasswordReset(superAdmin, { id: 'c', role: 'customer', companyId: null, loginId: null }),
  { ok: false, code: 'not_resettable' });
check('firma admini bu yoldan sıfırlanmaz',
  planPasswordReset(superAdmin, { id: 'a', role: 'admin', companyId: company, loginId: null }),
  { ok: false, code: 'not_resettable' });
check('olmayan hesap', planPasswordReset(admin, null), { ok: false, code: 'account_not_found' });
{
  let i = 0;
  const p = generatePassword((max) => (i++ * 7) % max);
  check('geçici şifre 10 karakter, karışan harf yok',
    { ok: p.length === 10 && !/[0O1lI]/.test(p) }, { ok: true });
}

// ─── Firma yöneticisi e-postaları (Faz 6) ──────────────────────────────────
check('super admin firma yöneticisi e-postalarını görür',
  planAdminEmails(superAdmin, company), { ok: true, companyId: company });
check('firma admini göremez', planAdminEmails(admin, company), { ok: false, code: 'not_allowed' });
check('rehber göremez', planAdminEmails(guide, company), { ok: false, code: 'not_allowed' });
check('pasif super admin göremez',
  planAdminEmails({ ...superAdmin, isActive: false }, company), { ok: false, code: 'not_allowed' });
check('geçersiz firma kimliği', planAdminEmails(superAdmin, 'abc'), { ok: false, code: 'invalid_body' });

console.log(failures === 0 ? '\nTÜM KURAL TESTLERİ GEÇTİ' : `\n${failures} TEST BAŞARISIZ`);
process.exit(failures === 0 ? 0 : 1);
