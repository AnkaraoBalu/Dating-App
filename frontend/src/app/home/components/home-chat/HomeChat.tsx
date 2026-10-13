import { useRef } from "react";
import { CommonContainer } from "../../../../components";
import { ChatDemo } from "../../../../components/chat-demo";
import { ScrollMore } from "../../../../components/scroll-more";
import { Copy, Eyebrow, Heading, TextLink } from "../../../../components/ui";
import {
  smooth,
  usePinnedProgress,
  useStaticScene,
} from "../../../../hooks/usePinnedScene";
import * as S from "./HomeChat.styles";

const apply = (progress: number, el: HTMLElement) => {
  el.style.setProperty("--phone", String(smooth(progress / 0.4)));
  el.style.setProperty("--msgs", String(smooth((progress - 0.25) / 0.4)));
  el.style.setProperty("--line-1", String(smooth((progress - 0.12) / 0.25)));
  el.style.setProperty("--line-2", String(smooth((progress - 0.24) / 0.25)));
  el.style.setProperty("--copy", String(smooth((progress - 0.36) / 0.22)));
};

/** "Conversations": the chat fills in on scroll; the visitor saves a message and leaves. */
export function HomeChat() {
  const ref = useRef<HTMLElement>(null);
  const staticMode = useStaticScene();
  usePinnedProgress(ref, !staticMode, apply, "enter");

  return (
    <S.Root ref={ref} id="conversations" tabIndex={-1} $static={staticMode}>
      <S.Stage $static={staticMode}>
        <CommonContainer>
          <S.Layout>
            <S.PhoneSlot>
              <ChatDemo />
            </S.PhoneSlot>
            <S.Text>
              <Eyebrow>Conversations that feel natural</Eyebrow>
              <Heading>
                <span data-line="1">Here for the moment.</span>
                <span data-line="2">
                  <em>Keep the good bits.</em>
                </span>
              </Heading>
              <div data-copy>
                <Copy>
                  Chat at your pace. Viewed messages can disappear when the
                  recipient leaves. Save the ones you want to keep, and they
                  stay for both of you.
                </Copy>
                <S.Steps>
                  <li>
                    <b>1</b> Tap a message to save it
                  </li>
                  <li>
                    <b>2</b> Leave the chat
                  </li>
                  <li>
                    <b>3</b> See what stays
                  </li>
                </S.Steps>
                <TextLink to="/help#chat">Get to know your chat →</TextLink>
              </div>
            </S.Text>
          </S.Layout>
          <ScrollMore target="meet-just2" destination="meet Just2" />
        </CommonContainer>
      </S.Stage>
    </S.Root>
  );
}
