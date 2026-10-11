/** API shape persisted by the profile setup feature. */
export interface ProfilePromptDraft {
  question: string;
  answer: string;
}

export interface ProfileBasicsDraft {
  location?: string;
  education?: string;
  fieldOfStudy?: string;
  jobTitle?: string;
  company?: string;
  heightCm?: number;
  zodiac?: string;
  languages?: string[];
}

export interface ProfileSetupDraft {
  photoIds: string[];
  prompts: ProfilePromptDraft[];
  bio?: string;
  basics: ProfileBasicsDraft;
  spotifyConnected: boolean;
  verificationStatus: "not_started" | "pending" | "verified";
}

export interface ProfilePhotoResponse {
  id: string;
  secureUrl: string;
  width: number;
  height: number;
  position: number;
}
