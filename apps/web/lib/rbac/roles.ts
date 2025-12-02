import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listRoles() {
  const supabase = getSupabaseServerAdminClient();
  const { data, error } = await supabase.from("roles").select("*");
  if (error) throw error;
  return data;
}
