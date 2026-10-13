import { Link } from "react-router-dom";
import { CommonContainer } from "../../components";
import { Content } from "./NotFoundPage.styles";
export function NotFoundPage() {
  return (
    <CommonContainer>
      <Content>
        <p>404</p>
        <h1>This page took a different path.</h1>
        <Link to="/">Back to Just2</Link>
      </Content>
    </CommonContainer>
  );
}
