import { serve } from 'https://deno.land/std/http/server.ts';

import { supabaseAdmin } from '../_shared/supabase-admin.ts';

serve(async (req) => {
  try {
    const { email, password, full_name, tenant_id, tier_id, role_ids } =
      await req.json();

    // 1. Create the auth user
    const { data: authUser, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

    if (authError) {
      return new Response(JSON.stringify({ error: authError.message }), {
        status: 400,
      });
    }

    const user_id = authUser.user.id;

    // 2. Insert profile
    await supabaseAdmin.from('user_profile').insert({
      id: user_id,
      full_name,
      tenant_id,
      tier_id,
    });

    // 3. Insert roles
    if (Array.isArray(role_ids) && role_ids.length > 0) {
      const rows = role_ids.map((role_id) => ({
        user_id,
        role_id,
        tenant_id,
      }));
      await supabaseAdmin.from('user_roles').insert(rows);
    }

    // 4. Apply claims
    await supabaseAdmin.rpc('apply_claims_to_user', {
      p_user_id: user_id,
    });

    return new Response(JSON.stringify({ user_id }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
    });
  }
});
