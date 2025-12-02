import { cookies } from 'next/headers';

export async function getClaims() {
  const cookieStore = await cookies();
  const token = cookieStore.get('sb-access-token')?.value;

  if (!token) return null;

  try {
    const payload = JSON.parse(
      Buffer.from(token.split('.')[1], 'base64').toString(),
    );
    return payload?.app_metadata?.claims ?? null;
  } catch {
    return null;
  }
}
