import { fetchGooglePhoto } from "../lib/google";
import { badRequest, upstreamError } from "../lib/http";

export default async function handler(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const photoName = url.searchParams.get("name")?.trim() ?? "";
  const maxHeight = Number(url.searchParams.get("maxHeight") ?? "1200");

  if (!photoName) {
    return badRequest("Missing name query parameter.");
  }

  const safeMaxHeight = Number.isFinite(maxHeight) ? Math.min(Math.max(Math.round(maxHeight), 200), 1600) : 1200;

  try {
    const upstream = await fetchGooglePhoto(photoName, safeMaxHeight);
    return new Response(upstream.body, {
      status: upstream.status,
      headers: {
        "Content-Type": upstream.headers.get("content-type") ?? "image/jpeg",
        "Cache-Control": "public, s-maxage=86400, stale-while-revalidate=604800"
      }
    });
  } catch (error) {
    return upstreamError(error instanceof Error ? error.message : "Photo fetch failed.");
  }
}
