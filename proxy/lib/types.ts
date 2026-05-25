export type ProxyPlace = {
  id: string;
  name: string;
  cuisine: string;
  address: string;
  city: string;
  latitude: number | null;
  longitude: number | null;
  photoURL: string | null;
  googleRating: number | null;
  googleReviewCount: number;
  yelpRating: number | null;
  yelpReviewCount: number;
};
