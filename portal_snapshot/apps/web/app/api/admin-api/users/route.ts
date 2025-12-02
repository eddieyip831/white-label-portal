import { createServerClientWrapper } from "~/lib/supabase/server";

export async function GET() {
  const supabase = createServerClientWrapper();
  const { data } = await supabase.from("users").select("*");
  return Response.json(data);
}
