import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

/**
 * PUBLIC ROUTES — middleware should skip these
 */
const PUBLIC_PATHS = [
  '/',
  '/auth/register',
  '/auth/forgot-password',
  '/auth/reset-password',
  '/update-password',
  '/privacy',
  '/legal',
];

/**
 * Supabase Auth Callback Routes — MUST BE ALLOWED
 */
const SUPABASE_AUTH_CALLBACKS = [
  '/auth/v1/verify',
  '/auth/v1/callback',
  '/auth/v1/token',
];

export function middleware(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;

  console.log('🧩 MIDDLEWARE START', pathname);

  /**
   * 0. SUPABASE RESET FLOW:
   * If request contains ?type=recovery, let it through.
   * Link example:
   * https://project.supabase.co/auth/v1/verify?type=recovery&token=xxxx
   */
  if (searchParams.get('type') === 'recovery') {
    console.log('🔐 Allowing Supabase recovery URL');
    return NextResponse.next();
  }

  /**
   * 1. Allow Supabase internal callback endpoints
   * These must NEVER be redirected, blocked, or wrapped.
   */
  if (SUPABASE_AUTH_CALLBACKS.some((prefix) => pathname.startsWith(prefix))) {
    console.log('🔓 Allowing Supabase callback:', pathname);
    return NextResponse.next();
  }

  /**
   * 2. Skip middleware entirely for public routes
   */
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    console.log('🚫 Skipping middleware for public path:', pathname);
    return NextResponse.next();
  }

  /**
   * 3. All remaining routes: require authentication
   */
  const token = request.cookies.get('sb-access-token')?.value;

  if (!token) {
    console.log('🔒 Redirect: user not logged in');
    return NextResponse.redirect(new URL('/', request.url));
  }

  return NextResponse.next();
}

/**
 * Route matcher
 */
export const config = {
  matcher: [
    /*
     * This matcher includes ALL routes except:
     *  - static files
     *  - images
     *  - assets
     *  - _next/*
     */
    '/((?!_next/static|_next/image|favicon.ico|images/).*)',
  ],
};
