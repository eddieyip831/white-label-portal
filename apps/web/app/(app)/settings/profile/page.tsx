import { createServerClientWrapper } from '~/lib/supabase/server';

import ProfileForm from './profile-form';

export default async function ProfilePage() {
  const supabase = createServerClientWrapper();

  // Authenticated user
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <div className="p-8">Not authenticated.</div>;
  }

  // Load user_profile
  // Note: The database has first_name/last_name columns but the generated types
  // may be out of date. Using type assertion to work around this.
  const { data: profile } = await supabase
    .from('user_profile')
    .select('*')
    .eq('id', user.id)
    .single();

  const profileData = profile as { first_name?: string; last_name?: string } | null;

  // Claims structure (from build_claims)
  const roles = (user.app_metadata?.roles ?? []) as string[];
  const tier = (user.app_metadata?.tier ?? 'free') as string;

  return (
    <div className="max-w-xl space-y-6 p-8">
      <h1 className="text-2xl font-semibold">Profile</h1>

      <ProfileForm
        email={user.email ?? ''}
        roles={roles}
        tier={tier}
        firstName={profileData?.first_name ?? ''}
        lastName={profileData?.last_name ?? ''}
      />
    </div>
  );
}
