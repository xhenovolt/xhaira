/**
 * POST /api/admin/users/create
 * 
 * Admin-only endpoint for creating new users
 * Only accessible by SUPER_ADMIN and ADMIN roles
 * 
 * Request body:
 * {
 *   email: string (required)
 *   password: string (required, min 8 chars)
 *   name: string (required)
 *   role: string (default: 'staff', can be 'admin' or 'staff')
 * }
 * 
 * Response:
 * - 201: User created successfully
 * - 400: Validation failed
 * - 403: Unauthorized (not admin)
 * - 409: Email already exists
 * - 500: Server error
 */

import { NextResponse } from 'next/server';
import { requirePermission } from '@/lib/permissions.js';
import { validateRegister } from '@/lib/validation.js';
import {
  createUser,
  findUserByEmail,
  hashPassword,
} from '@/lib/auth.js';
import { logAuthEvent, extractRequestMetadata } from '@/lib/audit.js';

export async function POST(request) {
  try {
    // Verify admin permission
    const perm = await requirePermission(request, 'users.manage');
    if (perm instanceof NextResponse) return perm;

    const { auth } = perm;
    const body = await request.json();

    // Validate input
    const validation = validateRegister(body);
    if (!validation.success) {
      await logAuthEvent({
        action: 'USER_CREATE_VALIDATION_FAILED',
        created_by: auth.userId,
        reason: 'Validation failed',
        requestMetadata: extractRequestMetadata(request),
      });

      return NextResponse.json(
        {
          error: 'Validation failed',
          fields: validation.errors,
        },
        { status: 400 }
      );
    }

    const { email, password, name } = validation.data;
    const role = body.role || 'staff'; // Default to staff
    
    // Only allow admins to create other admins
    if (role === 'admin' && auth.role !== 'superadmin') {
      await logAuthEvent({
        action: 'USER_CREATE_ADMIN_BLOCKED',
        created_by: auth.userId,
        email,
        reason: 'Only superadmin can create admin users',
        requestMetadata: extractRequestMetadata(request),
      });

      return NextResponse.json(
        {
          error: 'Permission denied',
          message: 'Only system administrators can create admin users',
        },
        { status: 403 }
      );
    }

    const requestMetadata = extractRequestMetadata(request);

    // Check if email already exists
    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      await logAuthEvent({
        action: 'USER_CREATE_DUPLICATE',
        created_by: auth.userId,
        email,
        reason: 'Email already exists',
        requestMetadata,
      });

      return NextResponse.json(
        { error: 'Email already registered' },
        { status: 409 }
      );
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Create user with specified role
    const user = await createUser({
      email,
      passwordHash,
      name,
      role: role === 'admin' ? 'admin' : 'staff',
      status: 'active', // Admin-created users are immediately active
    });

    if (!user || !user.id) {
      await logAuthEvent({
        action: 'USER_CREATE_FAILED',
        created_by: auth.userId,
        email,
        reason: 'Database error',
        requestMetadata,
      });

      return NextResponse.json(
        {
          error: 'Failed to create user',
          message: 'An error occurred during user creation.',
        },
        { status: 500 }
      );
    }

    await logAuthEvent({
      action: 'USER_CREATE_SUCCESS',
      created_by: auth.userId,
      user_id: user.id,
      email: user.email,
      role: user.role,
      requestMetadata,
    });

    return NextResponse.json(
      {
        success: true,
        message: `User ${user.email} created successfully`,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          status: user.status,
        },
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('User creation error:', error);

    return NextResponse.json(
      {
        error: 'User creation failed',
        message: 'An unexpected error occurred. Please try again.',
      },
      { status: 500 }
    );
  }
}
