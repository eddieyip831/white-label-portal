import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listPermissions() {
  const supabase = getSupabaseServerAdminClient();
  const { data, error } = await supabase.from("permissions").select("*");
  if (error) throw error;
  return data;
}
