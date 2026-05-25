import type { GooglePlace } from "./google";
import type { ProxyPlace } from "./types";
import type { YelpMatch } from "./yelp";

export function cityFromAddress(address?: string): string {
  if (!address) return "";
  const parts = address.split(",").map(part => part.trim()).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[parts.length - 2]}, ${parts[parts.length - 1]}`;
  }
  return address;
}

export function toProxyPlace(place: GooglePlace, yelpMatch: YelpMatch | null, proxyOrigin: string): ProxyPlace {
  const photoName = place.photos?.[0]?.name;
  const photoURL = photoName
    ? `${proxyOrigin}/api/photo?name=${encodeURIComponent(photoName)}&maxHeight=1200`
    : null;

  return {
    id: place.id,
    name: place.displayName?.text ?? "Unknown",
    cuisine: place.primaryTypeDisplayName?.text ?? "Restaurant",
    address: place.formattedAddress ?? "",
    city: cityFromAddress(place.formattedAddress),
    latitude: place.location?.latitude ?? null,
    longitude: place.location?.longitude ?? null,
    photoURL,
    googleRating: place.rating ?? null,
    googleReviewCount: place.userRatingCount ?? 0,
    yelpRating: yelpMatch?.rating ?? null,
    yelpReviewCount: yelpMatch?.reviewCount ?? 0
  };
}
