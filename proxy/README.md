# Moira Proxy

Tiny Vercel proxy for Moira v1. It keeps Google Places and Yelp API keys off-device and returns only aggregate data the app is allowed to display.

## Endpoints

- `GET /api/search?q=...`
  Returns Google Places search results with Google aggregate ratings only.
- `GET /api/place/:id`
  Returns one Google place plus a best-effort Yelp business match.
- `GET /api/photo?name=...`
  Streams a Google Places photo through the proxy so API keys stay off-device.
- `POST /api/yelp-match`
  Utility endpoint for direct Yelp matching if the app needs it later.

## Environment

- `GOOGLE_PLACES_API_KEY` — Google Places API (New) key with the Places API enabled in your project.
- `YELP_API_KEY` — Yelp Fusion API key.

## Local development

```bash
cd proxy
npm install
npm run check
vercel dev          # serves on http://localhost:3000
```

## Pointing the iOS app at the proxy

The app reads the proxy URL from device storage at runtime — **no rebuild required**.

1. Open Moira → **Profile** tab.
2. Paste the proxy URL into **Proxy URL** and tap **Save**.
3. Search should start working immediately.

iOS App Transport Security blocks plain `http://` URLs by default, so use one of:
- **Deployed HTTPS URL** (preferred) — `vercel deploy` produces a `*.vercel.app` URL. Set the env vars in the Vercel project settings.
- **HTTPS tunnel for local dev** — `ngrok http 3000` will give you a public HTTPS URL that forwards to `vercel dev`.

## Product guardrails

- No review-text NLP
- No fake AI summaries
- No invented counts or hidden ranking factors
- Only aggregate Google/Yelp values and manually entered Beli score
