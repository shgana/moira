import { badRequest, json, upstreamError } from "../lib/http";
import { matchYelpBusiness } from "../lib/yelp";

export default async function handler(request: Request): Promise<Response> {
  if (request.method !== "POST") {
    return badRequest("Use POST for yelp-match.");
  }

  const body = (await request.json().catch(() => null)) as {
    name?: string;
    address1?: string;
    city?: string;
    latitude?: number;
    longitude?: number;
  } | null;

  if (!body?.name || !body.address1 || !body.city) {
    return badRequest("Missing required body fields.");
  }

  try {
    const match = await matchYelpBusiness({
      name: body.name,
      address1: body.address1,
      city: body.city,
      latitude: body.latitude,
      longitude: body.longitude
    });
    return json({ match });
  } catch (error) {
    return upstreamError(error instanceof Error ? error.message : "Yelp match failed.");
  }
}
