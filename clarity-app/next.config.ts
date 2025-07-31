import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // パフォーマンス最適化
  compress: true,
  poweredByHeader: false,
  
  // 静的ファイル最適化
  images: {
    formats: ['image/webp', 'image/avif'],
  },
  
  // Service Worker用の設定
  async headers() {
    return [
      {
        source: '/sw.js',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, must-revalidate',
          },
          {
            key: 'Service-Worker-Allowed',
            value: '/',
          },
        ],
      },
    ];
  },
};

export default nextConfig;
