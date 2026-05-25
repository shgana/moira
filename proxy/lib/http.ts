export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, s-maxage=300, stale-while-revalidate=86400"
    }
  });
}

export function badRequest(message: string): Response {
  return json({ error: message }, 400);
}

export function upstreamError(message: string, status = 502): Response {
  return json({ error: message }, status);
}
