function getYelpAPIKey(): string {
  const value = process.env.YELP_API_KEY;
  if (!value) {
    throw new Error("Missing YELP_API_KEY");
  }
  return value;
}

export type YelpMatch = {
  rating: number | null;
  reviewCount: number;
};

export async function matchYelpBusiness(args: {
  name: string;
  address1: string;
  city: string;
  latitude?: number;
  longitude?: number;
}): Promise<YelpMatch | null> {
  const params = new URLSearchParams({
    name: args.name,
    address1: args.address1,
    city: args.city,
    country: "US"
  });

  const response = await fetch(`https://api.yelp.com/v3/businesses/matches?${params}`, {
    headers: {
      Authorization: `Bearer ${getYelpAPIKey()}`
    }
  });

  if (!response.ok) {
    throw new Error(`Yelp match failed with ${response.status}`);
  }

  const data = (await response.json()) as {
    businesses?: Array<{ rating?: number; review_count?: number }>;
  };
  const business = data.businesses?.[0];
  if (!business) return null;

  return {
    rating: business.rating ?? null,
    reviewCount: business.review_count ?? 0
  };
}
