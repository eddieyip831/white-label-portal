import { requireRole } from '~/lib/auth/guards';

export default async function AdminPage() {
  await requireRole('admin');

  return (
    <div>
      <h1>Admin Area</h1>
    </div>
  );
}
