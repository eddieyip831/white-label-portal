import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listAttributes() {
  const supabase = getSupabaseServerAdminClient();
  const { data, error } = await supabase.from("user_attribute_definitions").select("*");
  if (error) throw error;
  return data;
}
