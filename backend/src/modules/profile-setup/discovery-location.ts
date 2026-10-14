// Approximate city centers for the destinations offered by Travel mode.
// These are search origins, not a replacement for a member's saved GPS location.
const travelCities: Record<string, { latitude: number; longitude: number }> = {
  bangalore: { latitude: 12.9716, longitude: 77.5946 },
  bengaluru: { latitude: 12.9716, longitude: 77.5946 },
  mumbai: { latitude: 19.076, longitude: 72.8777 },
  delhi: { latitude: 28.6139, longitude: 77.209 },
  hyderabad: { latitude: 17.385, longitude: 78.4867 },
};

export function discoveryCityCenter(city?: string) {
  const key = city?.trim().toLowerCase() ?? "";
  return Object.prototype.hasOwnProperty.call(travelCities, key)
    ? travelCities[key]
    : undefined;
}
