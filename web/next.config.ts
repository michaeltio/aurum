import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: true,
  transpilePackages: [],
  experimental: {
    externalDir: true,
  },
};

export default nextConfig;
