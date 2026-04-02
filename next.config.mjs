/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Disable static prerendering of the global-error route — it crashes when
    // the root layout uses React context providers (Turbopack / Next.js 16 known issue).
    prerenderEarlyExit: false,
  },
};

export default nextConfig;
