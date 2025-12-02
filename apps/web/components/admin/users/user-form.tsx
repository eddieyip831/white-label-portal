'use client';

import { useState } from 'react';

export type UserFormValues = {
  email?: string;
  password?: string;
  full_name?: string;
  tier_id?: string;
  role_ids: string[];
};

export interface UserFormProps {
  roles: { id: string; name: string }[];
  tiers: { id: string; name: string }[];
  initial?: UserFormValues;
  onSubmit: (values: UserFormValues) => Promise<void>;
}

export default function UserForm({
  roles,
  tiers,
  onSubmit,
  initial,
}: UserFormProps) {
  const [form, setForm] = useState<UserFormValues>(
    initial ?? {
      email: '',
      password: '',
      full_name: '',
      tier_id: '',
      role_ids: [],
    },
  );

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setForm({ ...form, [e.target.name]: e.target.value });
  }

  return (
    <form
      onSubmit={async (e) => {
        e.preventDefault();
        await onSubmit(form);
      }}
      className="space-y-4"
    >
      {/* EMAIL */}
      <input
        name="email"
        type="email"
        placeholder="Email"
        value={form.email ?? ''}
        onChange={handleChange}
        className="w-full rounded border p-2"
        required={!initial}
      />

      {/* PASSWORD (only for create) */}
      {!initial && (
        <input
          name="password"
          type="password"
          placeholder="Password"
          value={form.password ?? ''}
          onChange={handleChange}
          className="w-full rounded border p-2"
          required
        />
      )}

      {/* FULL NAME */}
      <input
        name="full_name"
        type="text"
        placeholder="Full name"
        value={form.full_name ?? ''}
        onChange={handleChange}
        className="w-full rounded border p-2"
      />

      {/* TIER SELECT */}
      <select
        value={form.tier_id ?? ''}
        name="tier_id"
        onChange={(e) => setForm({ ...form, tier_id: e.target.value })}
        className="w-full rounded border p-2"
      >
        <option value="">Select Tier</option>
        {tiers.map((t) => (
          <option key={t.id} value={t.id}>
            {t.name}
          </option>
        ))}
      </select>

      {/* ROLES */}
      <div>
        <label className="font-semibold">Roles</label>
        <div className="mt-2 space-y-2">
          {roles.map((role) => (
            <label key={role.id} className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={form.role_ids.includes(role.id)}
                onChange={(e) => {
                  if (e.target.checked) {
                    setForm({
                      ...form,
                      role_ids: [...form.role_ids, role.id],
                    });
                  } else {
                    setForm({
                      ...form,
                      role_ids: form.role_ids.filter((x) => x !== role.id),
                    });
                  }
                }}
              />
              {role.name}
            </label>
          ))}
        </div>
      </div>

      <button
        type="submit"
        className="rounded bg-blue-600 px-4 py-2 text-white"
      >
        Save
      </button>
    </form>
  );
}
