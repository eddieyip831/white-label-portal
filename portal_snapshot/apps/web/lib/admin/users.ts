// SAFE ADMIN USERS — users.ts
import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listAdminUsers() {
  const admin = getSupabaseServerAdminClient();
  const { data, error } = await admin.auth.admin.listUsers({ page: 1, perPage: 50 });
  if (error) throw error;

  return (data?.users ?? []).map(u => ({
    id: u.id,
    email: u.email ?? null,
    created_at: u.created_at
  }));
}
