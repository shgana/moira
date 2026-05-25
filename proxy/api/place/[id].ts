import { fetchGooglePlace } from "../../lib/google";
import { badRequest, json, upstreamError } from "../../lib/http";
import { cityFromAddress, toProxyPlace } from "../../lib/transform";
import { matchYelpBusiness } from "../../lib/yelp";

export default async function handler(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const placeID = url.pathname.split("/").pop()?.trim() ?? "";
  if (!placeID) {
    return badRequest("Missing place id.");
  }

  try {
    const googlePlace = await fetchGooglePlace(placeID);
    let yelpMatch = null;

    try {
      yelpMatch = await matchYelpBusiness({
        name: googlePlace.displayName?.text ?? "",
        address1: googlePlace.formattedAddress ?? "",
        city: cityFromAddress(googlePlace.formattedAddress),
        latitude: googlePlace.location?.latitude,
        longitude: googlePlace.location?.longitude
      });
    } catch {
      yelpMatch = null;
    }

    return json(toProxyPlace(googlePlace, yelpMatch, url.origin));
  } catch (error) {
    return upstreamError(error instanceof Error ? error.message : "Place lookup failed.");
  }
}
