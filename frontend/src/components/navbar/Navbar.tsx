import { useEffect, useRef } from "react";
import { NavLink, useLocation } from "react-router-dom";
import { BrandLogo } from "../brand-logo/BrandLogo";
import { navigation } from "../../constants/navigation";
import * as S from "./Navbar.styles";
export function Navbar() {
  const dialog = useRef<HTMLDialogElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const location = useLocation();
  const close = () => {
    dialog.current?.close();
    document.body.style.overflow = "";
    trigger.current?.setAttribute("aria-expanded", "false");
  };
  useEffect(() => {
    close();
  }, [location.pathname]);
  useEffect(() => {
    const media = matchMedia("(min-width:851px)");
    const resize = () => {
      if (media.matches) close();
    };
    media.addEventListener("change", resize);
    return () => {
      media.removeEventListener("change", resize);
      document.body.style.overflow = "";
    };
  }, []);
  const open = () => {
    dialog.current?.showModal();
    document.body.style.overflow = "hidden";
    trigger.current?.setAttribute("aria-expanded", "true");
  };
  return (
    <>
      <S.Skip href="#main-content">Skip to content</S.Skip>
      <S.Header>
        <S.Capsule>
          <S.Brand to="/" aria-label="Just2 home">
            <BrandLogo decorative />
          </S.Brand>
          <S.Desktop aria-label="Main navigation">
            {navigation.map((n) => (
              <S.NavItem end={n.to === "/"} key={n.to} to={n.to}>
                {n.label}
              </S.NavItem>
            ))}
          </S.Desktop>
          <S.Cta to="/download">Meet the app ↗</S.Cta>
          <S.MenuButton
            ref={trigger}
            onClick={open}
            aria-label="Open menu"
            aria-controls="mobile-navigation"
            aria-expanded="false"
          >
            ☰
          </S.MenuButton>
        </S.Capsule>
      </S.Header>
      <S.Dialog
        ref={dialog}
        id="mobile-navigation"
        aria-label="Main navigation"
        onClose={close}
        onCancel={close}
      >
        <div data-top>
          <S.Brand to="/" onClick={close}>
            <BrandLogo onDark />
          </S.Brand>
          <button onClick={close} aria-label="Close menu">
            ×
          </button>
        </div>
        <nav>
          {navigation.map((n) => (
            <NavLink end={n.to === "/"} key={n.to} to={n.to} onClick={close}>
              {n.label}
            </NavLink>
          ))}
          <NavLink to="/download" onClick={close}>
            Meet the app ↗
          </NavLink>
        </nav>
        <p>A little curiosity. A real connection.</p>
      </S.Dialog>
    </>
  );
}
