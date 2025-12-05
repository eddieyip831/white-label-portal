'use client';

import { useState } from 'react';

import { updateProfile } from './actions';

interface ProfileFormProps {
  email: string;
  roles: string[];
  tier: string;
  firstName: string;
  lastName: string;
}

export default function ProfileForm({
  email,
  roles,
  tier,
  firstName: initialFirstName,
  lastName: initialLastName,
}: ProfileFormProps) {
  const [firstName, setFirstName] = useState(initialFirstName);
  const [lastName, setLastName] = useState(initialLastName);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSaving(true);
    setMessage(null);

    const formData = new FormData();
    formData.append('firstName', firstName);
    formData.append('lastName', lastName);

    const result = await updateProfile(formData);

    setSaving(false);

    if (result.error) {
      setMessage({ type: 'error', text: result.error });
    } else {
      setMessage({ type: 'success', text: 'Profile updated successfully.' });
    }
  }

  return (
    <div className="space-y-8">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="flex items-center gap-4">
          <label htmlFor="firstName" className="w-32 text-sm font-medium">
            First Name
          </label>
          <input
            id="firstName"
            type="text"
            className="flex-1 rounded border px-3 py-2"
            placeholder="First Name"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
          />
        </div>

        <div className="flex items-center gap-4">
          <label htmlFor="lastName" className="w-32 text-sm font-medium">
            Last Name
          </label>
          <input
            id="lastName"
            type="text"
            className="flex-1 rounded border px-3 py-2"
            placeholder="Last Name"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
          />
        </div>

        <button
          type="submit"
          disabled={saving}
          className="rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
        >
          {saving ? 'Saving...' : 'Save'}
        </button>

        {message && (
          <p
            className={`mt-2 text-sm ${
              message.type === 'error' ? 'text-red-600' : 'text-green-600'
            }`}
          >
            {message.text}
          </p>
        )}
      </form>

      <div className="space-y-3 border-t pt-6">
        <h2 className="text-lg font-semibold">Account Details</h2>

        <div>
          <p className="text-sm font-medium">Email</p>
          <p className="text-gray-600">{email}</p>
        </div>

        <div>
          <p className="text-sm font-medium">Roles</p>
          <p className="text-gray-600">{roles.length > 0 ? roles.join(', ') : 'None'}</p>
        </div>

        <div>
          <p className="text-sm font-medium">Tier</p>
          <p className="text-gray-600 capitalize">{tier}</p>
        </div>
      </div>
    </div>
  );
}
