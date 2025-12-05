'use server';

import { revalidatePath } from 'next/cache';

import { createServerClientWrapper } from '~/lib/supabase/server';

export async function updateProfile(formData: FormData) {
  const supabase = createServerClientWrapper();

  // Get the authenticated user
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    return { error: 'Not authenticated' };
  }

  const firstName = formData.get('firstName') as string;
  const lastName = formData.get('lastName') as string;

  // Note: The database has first_name/last_name columns but the generated types
  // may be out of date. Using type assertion to work around this.
  const { error } = await supabase
    .from('user_profile')
    .update({
      first_name: firstName,
      last_name: lastName,
    } as Record<string, string>)
    .eq('id', user.id);

  if (error) {
    console.error('[updateProfile] Error updating profile:', error);
    return { error: error.message };
  }

  revalidatePath('/settings/profile');
  return { success: true };
}
