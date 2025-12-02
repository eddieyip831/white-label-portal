import { createRouteHandler } from "~/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = createRouteHandler();
  const { userId, roleIds } = await req.json();

  await supabase.from("user_roles").delete().eq("user_id", userId);

  for (const roleId of roleIds) {
    await supabase.from("user_roles").insert({ user_id: userId, role_id: roleId });
  }

  return new Response("OK");
}
