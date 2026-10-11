import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Max,
  Min,
} from "class-validator";

export const genderIdentityOptions = [
  "man",
  "woman",
  "non_binary",
  "prefer_not_to_say",
] as const;

export const interestedInOptions = ["women", "men", "everyone"] as const;

export const datingIntentionOptions = [
  "something_serious",
  "open_to_anything",
  "casual",
  "friendship",
  "not_sure_yet",
] as const;

export const vibeTypeOptions = [
  "golden_retriever",
  "black_cat",
  "social_butterfly",
  "chill_and_balanced",
  "ambitious_energy",
  "sunshine",
  "slow_burn",
  "chaotic_good",
  "somewhere_between",
  "depends_who_im_with",
  "other",
] as const;

export const idealFridayOptions = [
  "club",
  "movie_and_food",
  "long_drive",
  "gaming",
  "rooftop",
  "house_party",
  "quiet_evening",
  "cafe_hopping",
  "cozy_night_in",
  "live_music",
  "dinner_with_friends",
  "cooking_at_home",
  "spontaneous_adventure",
  "outdoors",
  "other",
] as const;

export const interestOptions = [
  "coffee",
  "gaming",
  "music",
  "books",
  "planning",
  "fitness",
  "travel",
  "art",
  "dogs",
  "cats",
  "nightlife",
  "food",
  "photography",
  "sports",
  "hiking",
  "movies_and_tv",
  "cooking",
  "wellness",
  "fashion",
  "design",
  "volunteering",
  "podcasts",
  "nature",
  "dancing",
  "concerts",
  "technology",
  "cars",
  "beach_days",
  "board_games",
  "comedy",
  "museums",
  "gardening",
  "astrology",
  "anime",
  "culture",
  "entrepreneurship",
  "family_time",
  "spirituality",
  "other",
] as const;

export const musicGenreOptions = [
  "pop",
  "indie",
  "hip_hop",
  "r_and_b",
  "rock",
  "edm",
  "classical",
  "jazz",
  "country",
  "afrobeats",
  "latin",
  "k_pop",
  "metal",
  "folk",
  "bollywood",
  "reggae",
  "soundtracks",
  "lo_fi",
  "punjabi",
  "other",
  "a_bit_of_everything",
  "not_big_on_music",
] as const;

export const currentEraOptions = [
  "rebuilding",
  "career_mode",
  "travel_era",
  "ready_for_something_real",
  "chaos_era",
  "peaceful_era",
  "personal_growth",
  "exploring_myself",
  "healing_and_growing",
  "just_vibing",
  "new_chapter",
  "creative_era",
  "figuring_it_out",
  "other",
] as const;

export const dealbreakerOptions = [
  "honesty",
  "kindness",
  "good_communication",
  "emotional_availability",
  "respect",
  "consistency",
  "similar_values",
  "shared_humor",
  "ambition",
  "family_oriented",
  "wants_children",
  "does_not_want_children",
  "monogamy",
  "non_monogamy",
  "no_smoking",
  "no_heavy_drinking",
  "no_drugs",
  "sobriety",
  "pets",
  "religion_or_spirituality",
  "political_compatibility",
  "financial_responsibility",
  "affection",
  "quality_time",
  "independence",
  "open_minded",
  "other",
  "no_hard_dealbreakers",
] as const;

export const skippableQuestionOptions = [
  "vibe_type",
  "ideal_friday",
  "interests",
  "music",
  "current_era",
  "dealbreakers",
  "dating_intentions",
  "location_preferences",
] as const;

export class UpdateOnboardingDto {
  @IsOptional()
  @IsDateString()
  birthDate?: string;

  @IsOptional()
  @IsIn(genderIdentityOptions)
  genderIdentity?: (typeof genderIdentityOptions)[number];

  @IsOptional()
  @IsIn(interestedInOptions)
  interestedIn?: (typeof interestedInOptions)[number];

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsIn(datingIntentionOptions, { each: true })
  datingIntentions?: (typeof datingIntentionOptions)[number][];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @ArrayUnique()
  @IsIn(skippableQuestionOptions, { each: true })
  skippedQuestions?: (typeof skippableQuestionOptions)[number][];

  @IsOptional()
  @IsIn(vibeTypeOptions)
  vibeType?: (typeof vibeTypeOptions)[number] | null;

  @IsOptional()
  @IsIn(idealFridayOptions)
  idealFriday?: (typeof idealFridayOptions)[number] | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @ArrayUnique()
  @IsIn(interestOptions, { each: true })
  interests?: (typeof interestOptions)[number][];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @ArrayUnique()
  @IsIn(musicGenreOptions, { each: true })
  musicGenres?: (typeof musicGenreOptions)[number][];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @ArrayUnique()
  @IsString({ each: true })
  @MaxLength(80, { each: true })
  @IsNotEmpty({ each: true })
  favoriteArtists?: string[];

  @IsOptional()
  @IsIn(currentEraOptions)
  currentEra?: (typeof currentEraOptions)[number] | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @ArrayUnique()
  @IsIn(dealbreakerOptions, { each: true })
  dealbreakers?: (typeof dealbreakerOptions)[number][];

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  preferredDistanceKm?: number;

  @IsOptional()
  @IsBoolean()
  onlyShowPeopleNearby?: boolean;

  @IsOptional()
  @IsBoolean()
  locationPermissionGranted?: boolean;

  @IsOptional() @IsNumber() @Min(-90) @Max(90) latitude?: number;

  @IsOptional() @IsNumber() @Min(-180) @Max(180) longitude?: number;
}
