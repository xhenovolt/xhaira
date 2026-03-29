/**
 * POST /api/auth/register
 *
 * Public registration with system-state aware logic:
 *
 * FIRST USER (system not initialized):
 *   - Automatically becomes SUPER_ADMIN
 *   - Initializes base role system
 *   - Status: active (immediate access)
 *
 * SUBSEQUENT USERS (system initialized):
 *   - Public registration blocked
 *   - Returns 410 Gone / "System registration closed"
 *   - Users must be created by admin via /api/admin/users
 */

import { NextResponse } from 'next/server.js';
import { validateRegister } from '@/lib/validation.js';
import {
  createUser,
  findUserByEmail,
  hashPassword,
  getUserCount,
} from '@/lib/auth.js';
import {
  isSystemInitialized,
  shouldBeFirstUseSuperAdmin,
  initializeBaseRoles,
} from '@/lib/system-init.js';
import { logAuthEvent, extractRequestMetadata } from '@/lib/audit.js';
import { createSession, getSecureCookieOptions } from '@/lib/session.js';

/**
 * Parse user-agent string into { deviceName, browser, os }
 * Mirrors the parser in the login route.
 */
function parseUserAgent(ua = '') {
  let browser = 'Unknown';
  if (/Edg\//.test(ua))               browser = 'Edge';
  else if (/OPR\/|Opera/.test(ua))    browser = 'Opera';
  else if (/Firefox\//.test(ua))      browser = 'Firefox';
  else if (/SamsungBrowser/.test(ua)) browser = 'Samsung Browser';
  else if (/Chrome\//.test(ua))       browser = 'Chrome';
  else if (/Safari\//.test(ua))       browser = 'Safari';
  else if (/MSIE|Trident/.test(ua))   browser = 'Internet Explorer';

  let os = 'Unknown';
  if (/Windows NT 10/.test(ua))       os = 'Windows 10';
  else if (/Windows NT 11/.test(ua))  os = 'Windows 11';
  else if (/Windows NT/.test(ua))     os = 'Windows';
  else if (/Android/.test(ua)) {
    const m = ua.match(/Android ([\d.]+)/);
    os = m ? `Android ${m[1]}` : 'Android';
  } else if (/iPhone|iPad/.test(ua)) {
    const m = ua.match(/OS ([\d_]+)/);
    os = m ? `iOS ${m[1].replace(/_/g, '.')}` : 'iOS';
  } else if (/Macintosh/.test(ua))    os = 'macOS';
  else if (/Linux/.test(ua))          os = 'Linux';
  else if (/CrOS/.test(ua))           os = 'Chrome OS';

  let deviceName = 'Desktop';
  if (/Mobile|Android|iPhone/.test(ua)) deviceName = 'Mobile';
  else if (/Tablet|iPad/.test(ua))      deviceName = 'Tablet';

  return { deviceName, browser, os };
}

export async function POST(request) {
  try {
    // Check if system is initialized
    const systemInitialized = await isSystemInitialized();

    // If system is already initialized, block public registration
    if (systemInitialized) {
      await logAuthEvent({
        action: 'REGISTER_BLOCKED_SYSTEM_INITIALIZED',
        reason: 'System registration closed after initialization',
        requestMetadata: extractRequestMetadata(request),
      });

      return NextResponse.json(
        {
          error: 'System registration is closed.',
          message:
            'Xhaira registration is only available during initial setup. ' +
            'User accounts are now created exclusively by administrators. ' +
            'Contact your administrator to request access.',
        },
        { status: 410 }
      );
    }

    // System not initialized — allow registration (this becomes first user)
    const body = await request.json();

    // Validate input
    const validation = validateRegister(body);
    if (!validation.success) {
      return NextResponse.json(
        {
          error: 'Validation failed',
          fields: validation.errors,
        },
        { status: 400 }
      );
    }

    const { email, password, name } = validation.data;
    const requestMetadata = extractRequestMetadata(request);

    // Check if email already exists
    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      await logAuthEvent({
        action: 'REGISTER_DUPLICATE',
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

    // This is the first user — initialize roles and make them super admin
    try {
      await initializeBaseRoles();
    } catch (roleError) {
      console.error('Error initializing roles:', roleError);
      // Continue anyway — roles may exist or will be created later
    }

    // Create first user as SUPER_ADMIN
    const user = await createUser({
      email,
      passwordHash,
      name,
      role: 'superadmin', // First user is always super admin
      status: 'active', // Immediate access (not pending approval)
    });

    if (!user || !user.id) {
      return NextResponse.json(
        {
          error: 'Failed to create user',
          message: 'An error occurred during account creation.',
        },
        { status: 500 }
      );
    }

    await logAuthEvent({
      action: 'REGISTER_SUCCESS_FIRST_USER',
      email,
      user_id: user.id,
      role: 'superadmin',
      requestMetadata,
    });

    // Collect device metadata (same approach as login route)
    const rawUA = request.headers.get('user-agent') || '';
    const ipAddress =
      request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      request.headers.get('x-real-ip') ||
      null;
    const { deviceName, browser, os } = parseUserAgent(rawUA);
    const deviceInfo = {
      ipAddress,
      userAgent: rawUA || null,
      deviceName,
      browser,
      os,
    };

    // Create session for newly registered user
    // createSession(userId: string, deviceInfo: object) — must pass userId as string
    const sessionId = await createSession(user.id, deviceInfo);

    const response = NextResponse.json(
      {
        success: true,
        message: 'Registration successful. Welcome to Xhaira!',
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          isFirstUser: true,
        },
      },
      { status: 201 }
    );

    // Set session cookie
    const cookieOptions = getSecureCookieOptions();
    response.cookies.set('xhaira_session', sessionId, cookieOptions);

    return response;
  } catch (error) {
    console.error('Registration error:', error);
    return NextResponse.json(
      {
        error: 'Registration failed',
        message: 'An unexpected error occurred. Please try again.',
      },
      { status: 500 }
    );
  }
}
