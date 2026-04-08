import { User } from '@prisma/client';

export function sanitizeUser(user: any) {
  return {
    id: user.user_id.toString(),
    fullName: user.full_name,
    phone: user.phone,
    email: user.email,
    role: user.role,
    isActive: user.status === 'active',
    createdAt: user.created_at,
    updatedAt: user.updated_at,
  };
}
