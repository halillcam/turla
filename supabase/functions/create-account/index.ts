// create-account: web panelinden hesap açar (firma admini, rehber, dışarıdan müşteri).
//
// Service role ile çalışır; istemci bu anahtarı hiçbir zaman görmez. Rol,
// şirket ve giriş kimliği app_metadata'ya yazılır; profil handle_new_user
// tetikleyicisiyle oluşur. Hesaplar doğrulanmış açılır, e-posta gönderilmez.
//
// İstek:  POST { role, company_id?, full_name, email?, password, phone? }
// Yanıt:  201 { user_id, email, login_id }   |   4xx/5xx { code }
//
// Şifre sıfırlama (Faz 4): POST { action: 'reset_password', user_id }
// Yanıt:  200 { user_id, login_id, password }  (yeni geçici şifre bir kez gösterilir)
//
// verify_jwt kapalıdır; oturum token'ı burada auth.getUser ile doğrulanır.

import { createClient } from 'npm:@supabase/supabase-js@2.49.4';

import {
  type Caller,
  type Role,
  generateLoginId,
  generatePassword,
  loginIdToEmail,
  planAccount,
  planPasswordReset,
} from './rules.ts';

const MAX_LOGIN_ID_ATTEMPTS = 8;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json(405, { code: 'method_not_allowed' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) return json(500, { code: 'server_misconfigured' });

  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '').trim();
  if (!token) return json(401, { code: 'unauthorized' });

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) return json(401, { code: 'unauthorized' });

  const { data: profile, error: profileError } = await admin
    .from('profiles')
    .select('id, role, company_id, is_active')
    .eq('id', userData.user.id)
    .maybeSingle();
  if (profileError) {
    console.error('create-account: profile read failed', profileError.code, profileError.message);
    return json(500, { code: 'server_error' });
  }
  if (!profile) return json(403, { code: 'not_allowed' });

  const caller: Caller = {
    id: profile.id,
    role: profile.role as Role,
    companyId: profile.company_id,
    isActive: profile.is_active,
  };

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json(400, { code: 'invalid_body' });
  }

  if (body?.action === 'reset_password') return resetPassword(admin, caller, body.user_id);

  const plan = planAccount(caller, body ?? {});
  if (!plan.ok) return json(plan.status, { code: plan.code });

  const { data: company, error: companyError } = await admin
    .from('companies')
    .select('id, is_active')
    .eq('id', plan.companyId)
    .maybeSingle();
  if (companyError) {
    console.error('create-account: company read failed', companyError.code, companyError.message);
    return json(500, { code: 'server_error' });
  }
  if (!company) return json(404, { code: 'company_not_found' });
  if (!company.is_active && caller.role !== 'super_admin') {
    return json(403, { code: 'company_inactive' });
  }

  for (let attempt = 0; attempt < MAX_LOGIN_ID_ATTEMPTS; attempt++) {
    const loginId = plan.loginPrefix ? generateLoginId(plan.loginPrefix) : null;
    const email = plan.email ?? loginIdToEmail(loginId!);

    const { data: created, error } = await admin.auth.admin.createUser({
      email,
      password: plan.password,
      email_confirm: true,
      app_metadata: {
        role: plan.role,
        company_id: plan.companyId,
        ...(loginId ? { login_id: loginId } : {}),
      },
      user_metadata: { full_name: plan.fullName },
    });

    if (!error && created.user) {
      if (plan.phone) {
        const { error: phoneError } = await admin
          .from('profiles')
          .update({ phone: plan.phone })
          .eq('id', created.user.id);
        // Hesap açıldı; telefon yazılamazsa işlem başarısız sayılmaz, sadece loglanır.
        if (phoneError) console.error('create-account: phone update failed', phoneError.message);
      }
      return json(201, { user_id: created.user.id, email, login_id: loginId });
    }

    if (error?.code === 'email_exists' || error?.code === 'user_already_exists') {
      // E-posta ile açılan hesapta tekrar denemenin anlamı yok; giriş
      // kimliğinde başka bir numara denenir.
      if (!loginId) return json(409, { code: 'email_exists' });
      continue;
    }
    if (error?.code === 'weak_password') return json(400, { code: 'weak_password' });

    console.error('create-account: createUser failed', error?.code, error?.message);
    return json(500, { code: 'create_failed' });
  }

  return json(409, { code: 'login_id_unavailable' });
});

/** Güvenli rastgele tam sayı: 0..max-1 (modulo sapması olmadan). */
function secureRandomInt(max: number): number {
  const limit = Math.floor(0x100000000 / max) * max;
  const buffer = new Uint32Array(1);
  do {
    crypto.getRandomValues(buffer);
  } while (buffer[0] >= limit);
  return buffer[0] % max;
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function resetPassword(
  admin: ReturnType<typeof createClient>,
  caller: Caller,
  userId: unknown,
): Promise<Response> {
  if (typeof userId !== 'string' || !UUID_RE.test(userId)) return json(400, { code: 'invalid_body' });

  const { data: target, error } = await admin
    .from('profiles')
    .select('id, role, company_id, login_id')
    .eq('id', userId)
    .maybeSingle();
  if (error) {
    console.error('reset_password: profile read failed', error.code, error.message);
    return json(500, { code: 'server_error' });
  }

  const plan = planPasswordReset(
    caller,
    target
      ? {
          id: target.id,
          role: target.role as Role,
          companyId: target.company_id,
          loginId: target.login_id,
        }
      : null,
  );
  if (!plan.ok) return json(plan.status, { code: plan.code });

  // Pasif firmanın admini işlem yapamaz (can_manage_company ile aynı kural).
  if (caller.role !== 'super_admin') {
    const { data: company } = await admin
      .from('companies')
      .select('is_active')
      .eq('id', target!.company_id)
      .maybeSingle();
    if (!company?.is_active) return json(403, { code: 'company_inactive' });
  }

  const password = generatePassword(secureRandomInt);
  const { error: updateError } = await admin.auth.admin.updateUserById(plan.userId, { password });
  if (updateError) {
    console.error('reset_password: update failed', updateError.code, updateError.message);
    return json(500, { code: 'reset_failed' });
  }
  return json(200, { user_id: plan.userId, login_id: plan.loginId, password });
}
