import type { GoogleAddressComponent, GooglePlace } from "./google";
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

const NEIGHBORHOOD_TYPES = ["neighborhood", "sublocality_level_1", "sublocality"];

export function neighborhoodFromComponents(components?: GoogleAddressComponent[]): string | null {
  if (!components || components.length === 0) return null;
  for (const type of NEIGHBORHOOD_TYPES) {
    const match = components.find(component => component.types?.includes(type));
    if (match?.longText) return match.longText;
  }
  return null;
}

const PRICE_LEVEL_MAP: Record<string, number> = {
  PRICE_LEVEL_FREE: 0,
  PRICE_LEVEL_INEXPENSIVE: 1,
  PRICE_LEVEL_MODERATE: 2,
  PRICE_LEVEL_EXPENSIVE: 3,
  PRICE_LEVEL_VERY_EXPENSIVE: 4
};

export function normalizePriceLevel(value?: string | number | null): number | null {
  if (value == null) return null;
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : null;
  }
  return PRICE_LEVEL_MAP[value] ?? null;
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
    neighborhood: neighborhoodFromComponents(place.addressComponents),
    latitude: place.location?.latitude ?? null,
    longitude: place.location?.longitude ?? null,
    priceLevel: normalizePriceLevel(place.priceLevel),
    photoURL,
    googleRating: place.rating ?? null,
    googleReviewCount: place.userRatingCount ?? 0,
    yelpRating: yelpMatch?.rating ?? null,
    yelpReviewCount: yelpMatch?.reviewCount ?? 0
  };
}
