const GOOGLE_BASE = "https://places.googleapis.com/v1";
const GOOGLE_PHOTO_BASE = "https://places.googleapis.com/v1";
const FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.addressComponents",
  "places.location",
  "places.rating",
  "places.userRatingCount",
  "places.priceLevel",
  "places.primaryTypeDisplayName",
  "places.photos"
].join(",");

const DETAILS_FIELD_MASK = [
  "id",
  "displayName",
  "formattedAddress",
  "addressComponents",
  "location",
  "rating",
  "userRatingCount",
  "priceLevel",
  "primaryTypeDisplayName",
  "photos"
].join(",");

function getGoogleAPIKey(): string {
  const value = process.env.GOOGLE_PLACES_API_KEY;
  if (!value) {
    throw new Error("Missing GOOGLE_PLACES_API_KEY");
  }
  return value;
}

export type GoogleAddressComponent = {
  longText?: string;
  shortText?: string;
  types?: string[];
};

export type GooglePlace = {
  id: string;
  displayName?: { text?: string };
  formattedAddress?: string;
  addressComponents?: GoogleAddressComponent[];
  location?: { latitude?: number; longitude?: number };
  rating?: number;
  userRatingCount?: number;
  // Google Places API (New) returns PRICE_LEVEL_INEXPENSIVE / MODERATE / EXPENSIVE / VERY_EXPENSIVE.
  priceLevel?: string;
  primaryTypeDisplayName?: { text?: string };
  photos?: Array<{ name?: string }>;
};

export async function searchGooglePlaces(query: string): Promise<GooglePlace[]> {
  const response = await fetch(`${GOOGLE_BASE}/places:searchText`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": getGoogleAPIKey(),
      "X-Goog-FieldMask": FIELD_MASK
    },
    body: JSON.stringify({
      textQuery: query,
      pageSize: 8,
      languageCode: "en"
    })
  });

  if (!response.ok) {
    throw new Error(`Google search failed with ${response.status}`);
  }

  const data = (await response.json()) as { places?: GooglePlace[] };
  return data.places ?? [];
}

export async function fetchGooglePlace(placeID: string): Promise<GooglePlace> {
  const response = await fetch(`${GOOGLE_BASE}/places/${placeID}`, {
    headers: {
      "X-Goog-Api-Key": getGoogleAPIKey(),
      "X-Goog-FieldMask": DETAILS_FIELD_MASK
    }
  });

  if (!response.ok) {
    throw new Error(`Google place details failed with ${response.status}`);
  }

  return (await response.json()) as GooglePlace;
}

export async function fetchGooglePhoto(photoName: string, maxHeightPx = 1200): Promise<Response> {
  const encoded = encodeURIComponent(photoName);
  const response = await fetch(`${GOOGLE_PHOTO_BASE}/${encoded}/media?maxHeightPx=${maxHeightPx}&key=${getGoogleAPIKey()}`, {
    redirect: "follow"
  });

  if (!response.ok) {
    throw new Error(`Google photo fetch failed with ${response.status}`);
  }

  return response;
}
