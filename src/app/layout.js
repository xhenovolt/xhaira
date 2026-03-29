import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';
import { NavigationWrapper } from '@/components/layout/NavigationWrapper';
import LayoutClient from './layout-client';
import { ThemeProvider } from '@/components/providers/ThemeProvider';
import { PermissionProvider } from '@/components/providers/PermissionProvider';
import { ToastProvider } from '@/components/ui/Toast';
import { ErrorBoundary } from '@/components/providers/ErrorBoundary';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
  preload: false,
  fallback: ['system-ui', 'arial'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
  preload: false,
  fallback: ['monospace'],
});

export const metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL || process.env.API_URL || 'http://localhost:3000'),
  title: 'Xhaira — Founder Operating System',
  description: 'Institutional intelligence platform by Xhenvolt. Systems, deals, payments, invoices, and organizational intelligence.',
  keywords: ['xhaira', 'founder os', 'business intelligence', 'xhenvolt'],
  authors: [{ name: 'Xhenvolt' }],
  creator: 'Xhenvolt',
  manifest: '/manifest.json',
  icons: {
    icon: [
      { url: '/icons/icon-32x32.png', sizes: '32x32', type: 'image/png' },
      { url: '/icons/icon-192x192.png', sizes: '192x192', type: 'image/png' },
    ],
    apple: '/apple-touch-icon.png',
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Xhaira',
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    title: 'Xhaira — Founder Operating System',
    description: 'Institutional intelligence platform by Xhenvolt',
    images: [{ url: '/icons/icon-512x512.png', width: 512, height: 512 }],
  },
};

export const viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#1a1a1a' },
  ],
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <meta charSet="utf-8" />
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content="Xhaira" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
        <link rel="apple-touch-startup-image" href="/icons/icon-512x512.png" />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-background text-foreground transition-colors duration-300`}
      >
        <ErrorBoundary>
          <ThemeProvider>
            <PermissionProvider>
              <ToastProvider>
                {/* Navigation Wrapper - Only shows on /app routes */}
                <NavigationWrapper />

                {/* Layout wrapper with state management for mobile drawer */}
                <div className="flex min-h-screen flex-col">
                  <LayoutClient>
                    {children}
                  </LayoutClient>
                </div>
              </ToastProvider>
            </PermissionProvider>
          </ThemeProvider>
        </ErrorBoundary>
      </body>
    </html>
  );
}
