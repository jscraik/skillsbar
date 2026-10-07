"use client";

import { useEffect, useRef, useState } from "react";

export const command = "./bin/ask sdk start Skills/agent-ops/improve-agent-native --json --robot";

/** Show the selectable identity command with clipboard feedback and a manual-copy fallback. */
export function CopyCommand({ className, label, showCommand = true }: { className: string; label?: string; showCommand?: boolean }) {
  const [copyState, setCopyState] = useState<"idle" | "copied" | "unavailable">("idle");

  const reset = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => () => { if (reset.current) clearTimeout(reset.current); }, []);

  /** Copy the command and announce success or clipboard unavailability. */
  const copy = async () => {
    if (reset.current) clearTimeout(reset.current);
    try {
      await navigator.clipboard.writeText(command);
      setCopyState("copied");
      reset.current = setTimeout(() => setCopyState("idle"), 1800);
    } catch {
      setCopyState("unavailable");
    }
  };

  return (
    <div className={className}>
      {label && <small>{label}</small>}
      {(showCommand || copyState === "unavailable") && <textarea
        aria-label="Candidate identity command"
        readOnly
        spellCheck={false}
        rows={className === "command-bar" ? 2 : 3}
        value={command}
        onFocus={(event) => event.currentTarget.select()}
      />}
      <button type="button" onClick={copy}>{copyState === "copied" ? "Copied ✓" : "Copy command"}</button>
      <span className="copy-status" role="status">{copyState === "unavailable" ? "Copy unavailable—focus the command, then press ⌘C or Ctrl+C." : copyState === "copied" ? "Command copied." : ""}</span>
    </div>
  );
}
