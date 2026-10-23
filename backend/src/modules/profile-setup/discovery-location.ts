// Approximate city centers for the destinations offered by Travel mode.
// These are search origins, not a replacement for a member's saved GPS location.
// Every city on the app's travel screen must appear here
// (test/discovery-location.test.cjs checks this).
const travelCities: Record<string, { latitude: number; longitude: number }> = {
  bangalore: { latitude: 12.9716, longitude: 77.5946 },
  mumbai: { latitude: 19.076, longitude: 72.8777 },
  delhi: { latitude: 28.6139, longitude: 77.209 },
  hyderabad: { latitude: 17.385, longitude: 78.4867 },
  chennai: { latitude: 13.0827, longitude: 80.2707 },
  kolkata: { latitude: 22.5726, longitude: 88.3639 },
  pune: { latitude: 18.5204, longitude: 73.8567 },
  ahmedabad: { latitude: 23.0225, longitude: 72.5714 },
  gurugram: { latitude: 28.4595, longitude: 77.0266 },
  noida: { latitude: 28.5355, longitude: 77.391 },
  jaipur: { latitude: 26.9124, longitude: 75.7873 },
  goa: { latitude: 15.4909, longitude: 73.8278 },
  chandigarh: { latitude: 30.7333, longitude: 76.7794 },
  kochi: { latitude: 9.9312, longitude: 76.2673 },
  lucknow: { latitude: 26.8467, longitude: 80.9462 },
  indore: { latitude: 22.7196, longitude: 75.8577 },
  visakhapatnam: { latitude: 17.6868, longitude: 83.2185 },
  vijayawada: { latitude: 16.5062, longitude: 80.648 },
  warangal: { latitude: 17.9689, longitude: 79.5941 },
  coimbatore: { latitude: 11.0168, longitude: 76.9558 },
  mysuru: { latitude: 12.2958, longitude: 76.6394 },
  thiruvananthapuram: { latitude: 8.5241, longitude: 76.9366 },
  puducherry: { latitude: 11.9416, longitude: 79.8083 },
  bhubaneswar: { latitude: 20.2961, longitude: 85.8245 },
  nagpur: { latitude: 21.1458, longitude: 79.0882 },
  surat: { latitude: 21.1702, longitude: 72.8311 },
  udaipur: { latitude: 24.5854, longitude: 73.7125 },
  varanasi: { latitude: 25.3176, longitude: 82.9739 },
  rishikesh: { latitude: 30.0869, longitude: 78.2676 },
  shimla: { latitude: 31.1048, longitude: 77.1734 },
  manali: { latitude: 32.2432, longitude: 77.1892 },
};

// Other spellings members may have saved or typed.
const aliases: Record<string, string> = {
  bengaluru: "bangalore",
  "new delhi": "delhi",
  gurgaon: "gurugram",
  vizag: "visakhapatnam",
  mysore: "mysuru",
  trivandrum: "thiruvananthapuram",
  pondicherry: "puducherry",
  cochin: "kochi",
  calcutta: "kolkata",
  bombay: "mumbai",
  madras: "chennai",
};

export function discoveryCityCenter(city?: string) {
  const raw = city?.trim().toLowerCase() ?? "";
  const key = Object.prototype.hasOwnProperty.call(aliases, raw)
    ? aliases[raw]
    : raw;
  return Object.prototype.hasOwnProperty.call(travelCities, key)
    ? travelCities[key]
    : undefined;
}
