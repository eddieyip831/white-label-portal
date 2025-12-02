import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listModules() {
  const supabase = getSupabaseServerAdminClient();
  const { data, error } = await supabase.from("modules").select("*");
  if (error) throw error;
  return data;
}
