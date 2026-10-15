import { z } from "zod";

const environmentSchema = z
  .object({
    NODE_ENV: z
      .enum(["development", "test", "production"])
      .default("development"),
    HOST: z.string().default("0.0.0.0"),
    PORT: z.coerce.number().int().positive().default(3000),
    DB_URL: z.string().url(),
    CLERK_SECRET_KEY: z.string().min(1),
    DEMO_AUTH_ENABLED: z.enum(["true", "false"]).default("false"),
    DEMO_AUTH_SECRET: z.string().min(32).optional(),
    // Closed testing only: lets demo sign-in run on a production server.
    DEMO_AUTH_ALLOW_IN_PRODUCTION: z.enum(["true", "false"]).default("false"),
    CLOUDINARY_CLOUD_NAME: z.string().min(1),
    CLOUDINARY_API_KEY: z.string().min(1),
    CLOUDINARY_API_SECRET: z.string().min(1),
    // Firebase service account key file (JSON) for push notifications. Optional:
    // without it the API runs normally and simply sends no pushes.
    FIREBASE_SERVICE_ACCOUNT_PATH: z.string().min(1).optional(),
    // Optional for deployments that have not enabled Vibe voice yet. Set all
    // three together; the voice-token endpoint reports unavailable otherwise.
    LIVEKIT_URL: z.string().min(1).optional(),
    LIVEKIT_API_KEY: z.string().min(1).optional(),
    LIVEKIT_API_SECRET: z.string().min(1).optional(),
  })
  .superRefine((environment, context) => {
    const liveKitValues = [
      environment.LIVEKIT_URL,
      environment.LIVEKIT_API_KEY,
      environment.LIVEKIT_API_SECRET,
    ];
    const configuredCount = liveKitValues.filter(Boolean).length;
    if (configuredCount !== 0 && configuredCount !== liveKitValues.length) {
      context.addIssue({
        code: "custom",
        message:
          "Set LIVEKIT_URL, LIVEKIT_API_KEY, and LIVEKIT_API_SECRET together.",
        path: ["LIVEKIT_URL"],
      });
    }
  });

export function validateEnvironment(environment: Record<string, unknown>) {
  const result = environmentSchema.safeParse(environment);
  if (!result.success) {
    throw new Error(
      `Invalid environment configuration: ${result.error.message}`,
    );
  }
  return result.data;
}
