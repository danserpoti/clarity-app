// Clarity PWA Service Worker
const CACHE_NAME = 'clarity-v1'
const API_CACHE_NAME = 'clarity-api-v1'

// キャッシュするリソース
const STATIC_RESOURCES = [
  '/',
  '/thoughts',
  '/thoughts/new',
  '/analytics',
  '/offline',
  '/_next/static/css/app/layout.css',
  '/_next/static/chunks/webpack.js',
  '/_next/static/chunks/main.js',
  '/_next/static/chunks/pages/_app.js'
]

// API エンドポイント
const API_ENDPOINTS = [
  '/api/analyze',
  '/api/export',
  '/api/notion-sync'
]

// インストール時の処理
self.addEventListener('install', (event) => {
  console.log('[SW] Installing Service Worker')
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[SW] Caching static resources')
        return cache.addAll(STATIC_RESOURCES)
      })
      .then(() => {
        console.log('[SW] Static resources cached')
        return self.skipWaiting()
      })
      .catch((error) => {
        console.error('[SW] Failed to cache static resources:', error)
      })
  )
})

// アクティベート時の処理
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating Service Worker')
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== CACHE_NAME && cacheName !== API_CACHE_NAME) {
              console.log('[SW] Deleting old cache:', cacheName)
              return caches.delete(cacheName)
            }
          })
        )
      })
      .then(() => {
        console.log('[SW] Claiming clients')
        return self.clients.claim()
      })
  )
})

// フェッチ時の処理
self.addEventListener('fetch', (event) => {
  const { request } = event
  const url = new URL(request.url)
  
  // Same-origin リクエストのみ処理
  if (url.origin !== location.origin) {
    return
  }
  
  // API リクエストの処理
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      handleApiRequest(request)
    )
    return
  }
  
  // 静的リソースの処理
  event.respondWith(
    handleStaticRequest(request)
  )
})

// API リクエストの処理
async function handleApiRequest(request) {
  const url = new URL(request.url)
  
  try {
    // ネットワーク優先戦略
    const networkResponse = await fetch(request)
    
    // 成功したレスポンスをキャッシュ
    if (networkResponse.ok && request.method === 'GET') {
      const cache = await caches.open(API_CACHE_NAME)
      cache.put(request, networkResponse.clone())
    }
    
    return networkResponse
  } catch (error) {
    console.log('[SW] Network failed for API request:', url.pathname)
    
    // オフライン時の処理
    if (request.method === 'GET') {
      const cachedResponse = await caches.match(request)
      if (cachedResponse) {
        return cachedResponse
      }
    }
    
    // オフライン時のフォールバック
    return handleOfflineApiRequest(request)
  }
}

// 静的リソースの処理
async function handleStaticRequest(request) {
  try {
    // キャッシュ優先戦略
    const cachedResponse = await caches.match(request)
    if (cachedResponse) {
      return cachedResponse
    }
    
    // キャッシュになければネットワークから取得
    const networkResponse = await fetch(request)
    
    // 成功したレスポンスをキャッシュ
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME)
      cache.put(request, networkResponse.clone())
    }
    
    return networkResponse
  } catch (error) {
    console.log('[SW] Network failed for static request:', request.url)
    
    // オフライン時のフォールバック
    return handleOfflineRequest(request)
  }
}

// オフライン時のAPIリクエスト処理
function handleOfflineApiRequest(request) {
  const url = new URL(request.url)
  
  // 分析APIのオフライン応答
  if (url.pathname === '/api/analyze') {
    return new Response(JSON.stringify({
      success: false,
      error: 'オフラインのため分析機能を利用できません。ネットワーク接続を確認してください。',
      offline: true
    }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    })
  }
  
  // その他のAPIのオフライン応答
  return new Response(JSON.stringify({
    success: false,
    error: 'オフラインのため機能を利用できません。',
    offline: true
  }), {
    status: 503,
    headers: { 'Content-Type': 'application/json' }
  })
}

// オフライン時の静的リソース処理
async function handleOfflineRequest(request) {
  const url = new URL(request.url)
  
  // HTMLページのリクエスト
  if (request.destination === 'document') {
    const offlineResponse = await caches.match('/offline')
    if (offlineResponse) {
      return offlineResponse
    }
    
    // オフラインページがなければメインページを返す
    const indexResponse = await caches.match('/')
    if (indexResponse) {
      return indexResponse
    }
  }
  
  // その他のリソース
  return new Response('オフラインです', {
    status: 503,
    statusText: 'Service Unavailable'
  })
}

// メッセージ処理
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting()
  }
})