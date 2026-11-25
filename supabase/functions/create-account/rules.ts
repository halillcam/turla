// create-account Edge Function'ının iş kuralları.
//
// Dışa bağımlılığı yoktur; Deno'da (Edge Function) ve Node'da (testler)
// aynen çalışır. Ağ/veritabanı işleri index.ts içindedir.

export type Role = 'super_admin' | 'admin' | 'guide' | 'customer';

/** İsteği yapan kullanıcı (profiles tablosundan). */
export interface Caller {
  id: string;
  role: Role;
  companyId: string | null;
  isActive: boolean;
}

/** Panelden gelen istek gövdesi (doğrulanmamış). */
export interface CreateAccountBody {
  role?: unknown;
  company_id?: unknown;
  full_name?: unknown;
  email?: unknown;
  password?: unknown;
  phone?: unknown;
}

export interface AccountPlan {
  ok: true;
  role: Exclude<Role, 'super_admin'>;
  companyId: string;
  fullName: string;
  password: string;
  phone: string | null;
  /** Firma admini e-posta ile girer. */
  email: string | null;
  /** Rehber ve dışarıdan müşteri giriş kimliğiyle girer (ör. REH-1234). */
  loginPrefix: string | null;
}

export interface PlanError {
  ok: false;
  status: number;
  code: string;
}

/** Giriş kimliği e-postasının alan adı (packages/core LoginId ile aynı). */
export const LOGIN_ID_EMAIL_DOMAIN = 'staff.turla.app';

export const LOGIN_ID_PREFIXES = { guide: 'REH', customer: 'MUS' } as const;

export const MIN_PASSWORD_LENGTH = 8;
const MIN_NAME_LENGTH = 3;
const MAX_NAME_LENGTH = 120;
const MAX_PHONE_LENGTH = 20;

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const fail = (status: number, code: string): PlanError => ({ ok: false, status, code });
const text = (value: unknown): string => (typeof value === 'string' ? value.trim() : '');

/**
 * Kim hangi hesabı açabilir?
 * - super_admin: admin, rehber, müşteri (her şirket için; company_id zorunlu)
 * - admin: sadece kendi şirketine rehber ve müşteri
 * - diğerleri: hiçbiri
 */
export function planAccount(caller: Caller, body: CreateAccountBody): AccountPlan | PlanError {
  if (!caller.isActive) return fail(403, 'not_allowed');

  const role = text(body.role);
  if (role !== 'admin' && role !== 'guide' && role !== 'customer') {
    return fail(400, 'invalid_role');
  }

  let companyId: string;
  if (caller.role === 'super_admin') {
    companyId = text(body.company_id);
    if (!UUID_RE.test(companyId)) return fail(400, 'company_required');
  } else if (caller.role === 'admin' && caller.companyId) {
    if (role === 'admin') return fail(403, 'not_allowed');
    // Admin başka şirkete hesap açamaz; gönderilen değer yok sayılmaz, reddedilir.
    const requested = text(body.company_id);
    if (requested && requested !== caller.companyId) return fail(403, 'not_allowed');
    companyId = caller.companyId;
  } else {
    return fail(403, 'not_allowed');
  }

  const fullName = text(body.full_name);
  if (fullName.length < MIN_NAME_LENGTH || fullName.length > MAX_NAME_LENGTH) {
    return fail(400, 'invalid_full_name');
  }

  const password = typeof body.password === 'string' ? body.password : '';
  if (password.length < MIN_PASSWORD_LENGTH) return fail(400, 'weak_password');

  const phone = text(body.phone);
  if (phone.length > MAX_PHONE_LENGTH) return fail(400, 'invalid_phone');

  let email: string | null = null;
  let loginPrefix: string | null = null;
  if (role === 'admin') {
    email = text(body.email).toLowerCase();
    if (!EMAIL_RE.test(email)) return fail(400, 'invalid_email');
    if (email.endsWith(`@${LOGIN_ID_EMAIL_DOMAIN}`)) return fail(400, 'invalid_email');
  } else {
    loginPrefix = LOGIN_ID_PREFIXES[role];
  }

  return {
    ok: true,
    role,
    companyId,
    fullName,
    password,
    phone: phone || null,
    email,
    loginPrefix,
  };
}

/** Örn. REH-4821. Çakışırsa çağıran yeni bir kimlik dener. */
export function generateLoginId(prefix: string, random: () => number = Math.random): string {
  const digits = 1000 + Math.floor(random() * 9000);
  return `${prefix}-${digits}`;
}

/** packages/core LoginId.toEmail ile aynı dönüşüm. */
export function loginIdToEmail(loginId: string): string {
  return `${loginId.trim().toLowerCase()}@${LOGIN_ID_EMAIL_DOMAIN}`;
}

// ─── Şifre sıfırlama (Faz 4) ────────────────────────────────────────────────

/** Şifresi sıfırlanacak hesap (profiles tablosundan). */
export interface ResetTarget {
  id: string;
  role: Role;
  companyId: string | null;
  loginId: string | null;
}

export interface ResetPlan {
  ok: true;
  userId: string;
  loginId: string;
}

/**
 * Kim kimin şifresini sıfırlayabilir?
 * - Sadece giriş kimliğiyle giren panel hesapları (REH-, MUS-). E-postayla kayıt olan
 *   uygulama müşterisi ve firma admini kapsam dışı (onların şifresi kendilerinde).
 * - super_admin: her firmanın bu hesapları; admin: sadece kendi firmasınınkiler.
 * - Kendi şifresini bu yoldan sıfırlayamaz (zaten giriş kimliği hesabı değil).
 */
export function planPasswordReset(caller: Caller, target: ResetTarget | null): ResetPlan | PlanError {
  if (!caller.isActive) return fail(403, 'not_allowed');
  if (caller.role !== 'super_admin' && caller.role !== 'admin') return fail(403, 'not_allowed');
  if (!target) return fail(404, 'account_not_found');
  if ((target.role !== 'guide' && target.role !== 'customer') || !target.loginId || !target.companyId) {
    return fail(400, 'not_resettable');
  }
  if (caller.role === 'admin' && caller.companyId !== target.companyId) return fail(403, 'not_allowed');
  return { ok: true, userId: target.id, loginId: target.loginId };
}

/** Karışması kolay harfler (0/O, 1/l/I) çıkarılmış alfabe; rehbere sesli okunabilir. */
const PASSWORD_ALPHABET = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const GENERATED_PASSWORD_LENGTH = 10;

/** Geçici şifre. `randomInt(n)` 0..n-1 arası güvenli rastgele sayı döndürmeli. */
export function generatePassword(randomInt: (max: number) => number): string {
  let password = '';
  for (let i = 0; i < GENERATED_PASSWORD_LENGTH; i++) {
    password += PASSWORD_ALPHABET[randomInt(PASSWORD_ALPHABET.length)];
  }
  return password;
}
