import { createHmac, timingSafeEqual } from "node:crypto";

export const DEMO_USER_PREFIX = "demo_matchify_";
const DEMO_ISSUER = "matchify-development-demo";
const TOKEN_LIFETIME_SECONDS = 60 * 60;

function encode(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString("base64url");
}

function signature(input: string, secret: string): Buffer {
  return createHmac("sha256", secret).update(input).digest();
}

export function createDemoSessionToken(
  subject: string,
  secret: string,
): string {
  const now = Math.floor(Date.now() / 1000);
  const header = encode({ alg: "HS256", typ: "JWT" });
  const payload = encode({
    iss: DEMO_ISSUER,
    sub: subject,
    iat: now,
    exp: now + TOKEN_LIFETIME_SECONDS,
  });
  const input = `${header}.${payload}`;
  return `${input}.${signature(input, secret).toString("base64url")}`;
}

export function verifyDemoSessionToken(
  token: string,
  secret: string,
): string | null {
  try {
    const [headerPart, payloadPart, signaturePart, extra] = token.split(".");
    if (!headerPart || !payloadPart || !signaturePart || extra) return null;
    const input = `${headerPart}.${payloadPart}`;
    const suppliedSignature = Buffer.from(signaturePart, "base64url");
    const expectedSignature = signature(input, secret);
    if (
      suppliedSignature.length !== expectedSignature.length ||
      !timingSafeEqual(suppliedSignature, expectedSignature)
    ) {
      return null;
    }
    const header = JSON.parse(
      Buffer.from(headerPart, "base64url").toString("utf8"),
    ) as { alg?: string; typ?: string };
    const payload = JSON.parse(
      Buffer.from(payloadPart, "base64url").toString("utf8"),
    ) as { iss?: string; sub?: string; exp?: number };
    if (
      header.alg !== "HS256" ||
      payload.iss !== DEMO_ISSUER ||
      !payload.sub?.startsWith(DEMO_USER_PREFIX) ||
      typeof payload.exp !== "number" ||
      payload.exp <= Math.floor(Date.now() / 1000)
    ) {
      return null;
    }
    return payload.sub;
  } catch {
    return null;
  }
}

export const demoSessionLifetimeSeconds = TOKEN_LIFETIME_SECONDS;
