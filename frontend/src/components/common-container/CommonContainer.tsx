import type { PropsWithChildren } from "react";
import { Container } from "./CommonContainer.styles";
export function CommonContainer({
  children,
  className,
}: PropsWithChildren<{ className?: string }>) {
  return <Container className={className}>{children}</Container>;
}
