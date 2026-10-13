import type { CSSProperties } from "react";

type Props = {
  onDark?: boolean;
  decorative?: boolean;
  className?: string;
  style?: CSSProperties;
};

/** Same approved artwork used in the mobile app; intrinsic ratio avoids jumps. */
export function BrandLogo({ onDark = false, decorative = false, className, style }: Props) {
  return (
    <img
      src={`/images/branding/just2-wordmark${onDark ? "-light" : ""}.png`}
      alt={decorative ? "" : "Just2"}
      width={1200}
      height={600}
      className={className}
      draggable={false}
      style={{ display: "block", width: "100%", height: "auto", objectFit: "contain", ...style }}
    />
  );
}
