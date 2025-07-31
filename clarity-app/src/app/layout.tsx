import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/ThemeProvider";
import { Toaster } from "@/components/ui/toaster";
import { Navigation } from "@/components/Navigation";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

// PWA Manifest（Data URL形式でCORS問題を回避）
const manifestDataUrl = `data:application/json;base64,${Buffer.from(JSON.stringify({
  name: "Clarity 思考記録",
  short_name: "Clarity",
  description: "AI分析機能付き思考記録PWAアプリ",
  start_url: "/",
  display: "standalone",
  background_color: "#ffffff",
  theme_color: "#3b82f6",
  orientation: "portrait",
  icons: [
    {
      src: "/icon-192.png",
      sizes: "192x192",
      type: "image/png",
      purpose: "any maskable"
    },
    {
      src: "/icon-512.png", 
      sizes: "512x512",
      type: "image/png",
      purpose: "any maskable"
    }
  ]
})).toString('base64')}`

export const metadata: Metadata = {
  title: {
    default: "Clarity 思考記録",
    template: "%s | Clarity"
  },
  description: "AI分析機能付き思考記録PWAアプリ。思考と感情を記録し、AIによる分析で新たな洞察を得ましょう。",
  keywords: ["思考記録", "AI分析", "PWA", "感情分析", "セルフケア", "メンタルヘルス"],
  authors: [{ name: "Clarity Team" }],
  creator: "Clarity",
  publisher: "Clarity",
  manifest: manifestDataUrl,
  viewport: "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no",
  themeColor: "#3b82f6",
  colorScheme: "light dark",
  robots: "index, follow",
  openGraph: {
    type: "website",
    locale: "ja_JP",
    url: "/",
    siteName: "Clarity",
    title: "Clarity 思考記録",
    description: "AI分析機能付き思考記録PWAアプリ",
    images: [
      {
        url: "/icon-512.png",
        width: 512,
        height: 512,
        alt: "Clarity アプリアイコン"
      }
    ]
  },
  twitter: {
    card: "summary",
    title: "Clarity 思考記録",
    description: "AI分析機能付き思考記録PWAアプリ",
    images: ["/icon-512.png"]
  },
  other: {
    "mobile-web-app-capable": "yes",
    "apple-mobile-web-app-capable": "yes",
    "apple-mobile-web-app-status-bar-style": "default",
    "apple-mobile-web-app-title": "Clarity",
    "format-detection": "telephone=no"
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              if ('serviceWorker' in navigator) {
                window.addEventListener('load', () => {
                  navigator.serviceWorker.register('/sw.js')
                    .then((registration) => {
                      console.log('[SW] Service Worker registered:', registration);
                    })
                    .catch((error) => {
                      console.error('[SW] Service Worker registration failed:', error);
                    });
                });
              }
            `,
          }}
        />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800 min-h-screen`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
          storageKey="clarity-theme"
        >
          <Navigation />
          <main className="relative">
            {children}
          </main>
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
