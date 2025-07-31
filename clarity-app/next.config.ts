import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // GitHub Pages用の設定
  output: 'export',
  trailingSlash: true,
  skipTrailingSlashRedirect: true,
  distDir: 'out',
  
  // GitHub Pagesのベースパス設定（リポジトリ名に合わせる）
  basePath: process.env.NODE_ENV === 'production' ? '/clarity-app' : '',
  assetPrefix: process.env.NODE_ENV === 'production' ? '/clarity-app/' : '',
  
  // パフォーマンス最適化
  compress: true,
  poweredByHeader: false,
  
  // 静的ファイル最適化
  images: {
    formats: ['image/webp', 'image/avif'],
    unoptimized: true, // GitHub Pages用
  },
  
  // GitHub Pages用にESLintを一時的に無効化
  eslint: {
    ignoreDuringBuilds: true,
  },
  
  // 静的エクスポート用にAPIルートを除外
  async generateStaticParams() {
    return [];
  },
  
  // Service Worker用の設定（静的エクスポートでは無効）
  // GitHub Pagesでは Service Worker は別途処理が必要
};

export default nextConfig;
