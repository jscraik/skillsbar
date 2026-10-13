"use client";

import { useEffect, useRef } from "react";

/** Wire Escape-key dismissal and internal-link close onto the compact nav disclosure. */
export function CompactNavBehavior() {
  const ref = useRef<HTMLDetailsElement | null>(null);

  useEffect(() => {
    const details = document.querySelector<HTMLDetailsElement>(".compact-nav");
    if (!details) return;
    ref.current = details;

    function onKeyDown(event: KeyboardEvent) {
      if (event.key !== "Escape") return;
      if (!details.open) return;
      event.stopPropagation();
      details.open = false;
      details.querySelector("summary")?.focus();
    }

    function onLinkClick(event: MouseEvent) {
      const target = event.target as HTMLElement;
      if (!target.closest("a[href^='#']")) return;
      details.open = false;
    }

    details.addEventListener("keydown", onKeyDown);
    details.addEventListener("click", onLinkClick);
    return () => {
      details.removeEventListener("keydown", onKeyDown);
      details.removeEventListener("click", onLinkClick);
    };
  }, []);

  return null;
}
