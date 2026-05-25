/**
 * Lightweight local dev server that mimics Vercel's Edge Function runtime.
 * Run with: node --env-file=.env dev-server.mjs
 */
import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

const PORT = 3000;

// Dynamically import the TS handlers using tsx
async function loadHandler(tsPath) {
  const mod = await import(tsPath);
  return mod.default;
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = url.pathname;

  console.log(`${req.method} ${pathname}`);

  // Read body for POST requests
  let body = "";
  if (req.method === "POST") {
    body = await new Promise((resolve) => {
      let data = "";
      req.on("data", (chunk) => (data += chunk));
      req.on("end", () => resolve(data));
    });
  }

  // Build a Web API Request object
  const headers = new Headers();
  for (const [key, value] of Object.entries(req.headers)) {
    if (value) headers.set(key, Array.isArray(value) ? value.join(", ") : value);
  }

  const requestInit = {
    method: req.method,
    headers,
  };
  if (req.method === "POST" && body) {
    requestInit.body = body;
  }

  const webRequest = new Request(`http://localhost:${PORT}${req.url}`, requestInit);

  try {
    let handler;

    if (pathname === "/api/search") {
      handler = await loadHandler("./api/search.ts");
    } else if (pathname === "/api/photo") {
      handler = await loadHandler("./api/photo.ts");
    } else if (pathname === "/api/yelp-match") {
      handler = await loadHandler("./api/yelp-match.ts");
    } else if (pathname.startsWith("/api/place/")) {
      handler = await loadHandler("./api/place/[id].ts");
    } else {
      res.writeHead(404, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Not found" }));
      return;
    }

    const webResponse = await handler(webRequest);

    // Convert Web API Response back to Node response
    const responseHeaders = {};
    webResponse.headers.forEach((value, key) => {
      responseHeaders[key] = value;
    });

    res.writeHead(webResponse.status, responseHeaders);

    if (webResponse.body) {
      const reader = webResponse.body.getReader();
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        res.write(value);
      }
    }
    res.end();
  } catch (error) {
    console.error("Handler error:", error);
    res.writeHead(500, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: error.message }));
  }
});

server.listen(PORT, () => {
  console.log(`✅ Moira proxy dev server running at http://localhost:${PORT}`);
  console.log(`   Google API key: ${process.env.GOOGLE_PLACES_API_KEY ? "configured ✓" : "MISSING ✗"}`);
  console.log(`   Yelp API key:   ${process.env.YELP_API_KEY ? "configured ✓" : "not set (optional)"}`);
});
