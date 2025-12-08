'use client';

import { useState } from 'react';

import { Badge } from '@kit/ui/badge';
import { Button } from '@kit/ui/button';
import { Checkbox } from '@kit/ui/checkbox';
import { Label } from '@kit/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@kit/ui/select';

type Role = {
  id: string;
  name: string;
};

type Tier = {
  id: string;
  name: string | null;
};

export default function SuperAdminUserForm({
  userId,
  availableRoles,
  availableTiers,
  initialRoleIds,
  initialTierId,
}: {
  userId: string;
  availableRoles: Role[];
  availableTiers: Tier[];
  initialRoleIds: string[];
  initialTierId: string | null;
}) {
  const [selectedRoles, setSelectedRoles] = useState<Set<string>>(
    new Set(initialRoleIds),
  );
  const [selectedTier, setSelectedTier] = useState(initialTierId ?? '');
  const [status, setStatus] = useState<'idle' | 'saving' | 'success' | 'error'>(
    'idle',
  );
  const [message, setMessage] = useState<string | null>(null);

  function toggleRole(roleId: string, checked: boolean) {
    setSelectedRoles((prev) => {
      const next = new Set(prev);
      if (checked) {
        next.add(roleId);
      } else {
        next.delete(roleId);
      }
      return next;
    });
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus('saving');
    setMessage(null);

    try {
      const response = await fetch(
        '/api/admin-api/super-admin/update-user',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            user_id: userId,
            roles: Array.from(selectedRoles),
            tier_id: selectedTier || null,
          }),
        },
      );

      if (!response.ok) {
        throw new Error('Failed to update user');
      }

      setStatus('success');
      setMessage('User updated successfully.');
    } catch (error) {
      console.error(error);
      setStatus('error');
      setMessage('Failed to update user.');
    }
  }

  return (
    <form className="space-y-6" onSubmit={handleSubmit}>
      <div>
        <Label className="mb-2 block text-sm font-semibold text-gray-700">
          Roles
        </Label>
        {availableRoles.length === 0 ? (
          <p className="text-sm text-gray-500">No roles defined.</p>
        ) : (
          <div className="grid gap-3 md:grid-cols-2">
            {availableRoles.map((role) => {
              const checked = selectedRoles.has(role.id);
              return (
                <label
                  key={role.id}
                  className="flex items-center gap-3 rounded border border-gray-200 bg-white px-3 py-2 text-sm"
                >
                  <Checkbox
                    checked={checked}
                    onCheckedChange={(next) =>
                      toggleRole(role.id, Boolean(next))
                    }
                  />
                  <span className="flex-1">{role.name}</span>
                </label>
              );
            })}
          </div>
        )}
      </div>

      <div>
        <Label className="mb-2 block text-sm font-semibold text-gray-700">
          Tier
        </Label>
        <Select value={selectedTier} onValueChange={setSelectedTier}>
          <SelectTrigger className="w-full md:w-80">
            <SelectValue placeholder="Select a tier" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Unassigned</SelectItem>
            {availableTiers.map((tier) => (
              <SelectItem key={tier.id} value={tier.id}>
                {tier.name ?? tier.id}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div className="text-sm text-gray-500">
          Changes take effect immediately and refresh the user claims.
        </div>
        <div className="flex items-center gap-2">
          <Button type="submit" disabled={status === 'saving'}>
            {status === 'saving' ? 'Saving…' : 'Save changes'}
          </Button>
          {status === 'success' && <Badge variant="secondary">Saved</Badge>}
        </div>
      </div>

      {message && (
        <p
          className={[
            'text-sm',
            status === 'error' ? 'text-red-600' : 'text-green-600',
          ].join(' ')}
        >
          {message}
        </p>
      )}
    </form>
  );
}
