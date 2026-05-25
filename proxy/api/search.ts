import { searchGooglePlaces } from "../lib/google";
import { badRequest, json, upstreamError } from "../lib/http";
import { toProxyPlace } from "../lib/transform";

export default async function handler(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const query = url.searchParams.get("q")?.trim() ?? "";
  if (!query) {
    return badRequest("Missing q query parameter.");
  }

  try {
    const places = await searchGooglePlaces(query);
    const results = places.map(place => toProxyPlace(place, null, url.origin));
    return json({ results });
  } catch (error) {
    return upstreamError(error instanceof Error ? error.message : "Google search failed.");
  }
}
