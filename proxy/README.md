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

- `GOOGLE_PLACES_API_KEY`
- `YELP_API_KEY`

## Local

```bash
cd /Users/shyam/Documents/Moira/proxy
npm install
npm run check
vercel dev
```

Point the iOS app at the proxy by setting the generated Info.plist key `MOIRA_PROXY_BASE_URL` in [project.yml](/Users/shyam/Documents/Moira/project.yml), for example:

```yaml
INFOPLIST_KEY_MOIRA_PROXY_BASE_URL: "http://127.0.0.1:3000"
```

## Product guardrails

- No review-text NLP
- No fake AI summaries
- No invented counts or hidden ranking factors
- Only aggregate Google/Yelp values and manually entered Beli score
