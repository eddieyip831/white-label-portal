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

function isPublicPath(pathname: string) {
  // Root is public only for the exact root path
  if (pathname === '/') return true;

  // For other paths, don't let '/' match everything
  return PUBLIC_PATHS
    .filter((path) => path !== '/')
    .some((path) => {
      // Exact match (/auth/register) or nested (/legal/terms)
      return pathname === path || pathname.startsWith(`${path}/`);
    });
}

export function middleware(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;

  console.log('🧩 MIDDLEWARE START', pathname);

  /**
   * 0. SUPABASE RESET FLOW — allow password recovery links
   */
  if (searchParams.get('type') === 'recovery') {
    console.log('🔐 Allowing Supabase recovery URL');
    return NextResponse.next();
  }

  /**
   * 1. Allow Supabase internal callback endpoints
   */
  if (SUPABASE_AUTH_CALLBACKS.some((prefix) => pathname.startsWith(prefix))) {
    console.log('🔓 Allowing Supabase callback:', pathname);
    return NextResponse.next();
  }

  /**
   * 2. Skip middleware entirely for public routes
   */
  if (isPublicPath(pathname)) {
    console.log('🚫 Skipping middleware for public path:', pathname);
    return NextResponse.next();
  }

  /**
   * 3. TEMP: allow all non-public routes through
   * We are not enforcing auth here yet; (app)/layout will handle it.
   */
  console.log('➡ Allowing non-public path without auth check (temp):', pathname);
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
