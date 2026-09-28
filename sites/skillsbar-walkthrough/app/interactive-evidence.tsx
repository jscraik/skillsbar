"use client";

import { useEffect, useState, type CSSProperties } from "react";

type GateStatus = "required" | "held";
type Camera = "overview" | "build" | "prove" | "ship";

export const command = "./bin/ask sdk start Skills/agent-ops/improve-agent-native --json --robot";

const gates = [
  "Candidate identity", "Mechanical validation", "Security & guardrails",
  "Eval preparation", "Eval local proof", "Eval cloud proof",
  "Tessl staging", "Publication & registry", "Runtime truth",
] as const;

const chapters = [
  { id: "build", number: "01", name: "Build", range: "Gates 1–2", gateIndexes: [0, 1] },
  { id: "prove", number: "02", name: "Prove", range: "Gates 3–6", gateIndexes: [2, 3, 4, 5] },
  { id: "ship", number: "03", name: "Ship", range: "Gates 7–9", gateIndexes: [6, 7, 8] },
] as const;

// Camera movement never changes the candidate or its proof status.
const scenarioStatuses: readonly GateStatus[] = [
  "required", "held", "held", "held", "held", "held", "held", "held", "held",
];

const beats = [
  { number: "01", label: "Problem", camera: "overview" as Camera, eyebrow: "One candidate · one evidence chain", headline: "Healthy score. Wrong candidate.", body: "The published baseline remains visible, but SkillsBar requires one canonical package digest before any downstream receipt can count." },
  { number: "02", label: "Build", camera: "build" as Camera, eyebrow: "Gate 1 · required", headline: "Identity comes first.", body: "Without the canonical package digest, mechanical validation and every later receipt remain downstream." },
  { number: "03", label: "Prove", camera: "prove" as Camera, eyebrow: "Gates 3–6 · held", headline: "Prove cannot borrow an identity.", body: "Security and evaluation stay held because there is no candidate digest to bind their receipts to." },
  { number: "04", label: "Ship & decide", camera: "ship" as Camera, eyebrow: "Gates 7–9 · held", headline: "Missing identity holds shipping.", body: "Staging, publication, and runtime truth stay held. SkillsBar gives the maintainer the identity command without implying approval." },
] as const;

const cameraPositions: Record<Exclude<Camera, "overview">, string> = {
  build: "0%", prove: "-33.333%", ship: "-66.666%",
};

/** Return the display label for a gate in the fixed candidate scenario. */
const statusLabel = (status: GateStatus) => status === "required" ? "Required" : "Held";

/** Render the fixed evidence gates, focusing the camera or hiding details in compact mode. */
export function CandidateRail({ camera = "overview", compact = false }: { camera?: Camera; compact?: boolean }) {
  const railStyle: CSSProperties & { "--camera-x": string } = {
    "--camera-x": camera === "overview" ? "0%" : cameraPositions[camera],
  };

  return (
    <div className={`rail-viewport ${compact ? "rail-compact" : ""}`} data-camera={camera} aria-label="Local candidate moves through Build, Prove, and Ship and stops at the required candidate identity receipt">
      <div className="rail-world" style={railStyle}>
        <div className="candidate-track" aria-hidden="true">
          <span className="candidate-origin">candidate <b>digest missing</b></span>
          <i className="candidate-progress" />
          <b className="candidate-stop"><span>required</span></b>
          <span className="candidate-decision">human decision</span>
        </div>
        <div className="rail-chapters">
          {chapters.map((chapter) => (
            <section className={`rail-chapter ${camera === chapter.id ? "active" : ""}`} key={chapter.id} aria-label={`${chapter.name}, ${chapter.range}`}>
              <header><span>{chapter.number}</span><div><b>{chapter.name}</b><small>{chapter.range}</small></div></header>
              {!compact && (
                <ol>
                  {chapter.gateIndexes.map((gateIndex) => {
                    const status = scenarioStatuses[gateIndex];
                    return <li className={status} key={gates[gateIndex]}><span>{gateIndex + 1}</span><b>{gates[gateIndex]}</b><small>{statusLabel(status)}</small></li>;
                  })}
                </ol>
              )}
            </section>
          ))}
        </div>
      </div>
    </div>
  );
}

/** Show the selectable identity command with clipboard feedback and a manual-copy fallback. */
export function CopyCommand({ className, label }: { className: string; label?: string }) {
  const [copyState, setCopyState] = useState<"idle" | "copied" | "unavailable">("idle");

  useEffect(() => {
    if (copyState !== "copied") return;
    const timeout = window.setTimeout(() => setCopyState("idle"), 1800);
    return () => window.clearTimeout(timeout);
  }, [copyState]);

  /** Copy the command and announce success or clipboard unavailability. */
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(command);
      setCopyState("copied");
    } catch {
      setCopyState("unavailable");
    }
  };

  return (
    <div className={className}>
      {label && <small>{label}</small>}
      <textarea
        aria-label="Candidate identity command"
        readOnly
        spellCheck={false}
        rows={className === "command-bar" ? 2 : 3}
        value={command}
        onFocus={(event) => event.currentTarget.select()}
      />
      <button type="button" onClick={copy}>{copyState === "copied" ? "Copied ✓" : "Copy command"}</button>
      <span className="copy-status" role="status">{copyState === "unavailable" ? "Copy unavailable—focus the command, then press ⌘C or Ctrl+C." : copyState === "copied" ? "Command copied." : ""}</span>
    </div>
  );
}

/** Navigate four views of one evidence scenario using buttons or scoped keyboard shortcuts. */
export function Walkthrough() {
  const [activeBeat, setActiveBeat] = useState(0);
  const [inputMode, setInputMode] = useState<"pointer" | "keyboard">("pointer");
  const beat = beats[activeBeat];

  useEffect(() => {
    /** Handle unmodified walkthrough shortcuts while preserving nested controls and command selection. */
    const onKeyDown = (event: KeyboardEvent) => {
      if (!(event.target instanceof HTMLElement)) return;
      const target = event.target;
      if (!target.closest(".walkthrough-shell") || event.altKey || event.ctrlKey || event.metaKey) return;
      if (target.closest("button, a, input, textarea, select, code, [contenteditable], summary")) return;
      if (event.key === "ArrowRight" || event.key === " ") {
        event.preventDefault();
        setInputMode("keyboard");
        setActiveBeat((current) => Math.min(beats.length - 1, current + 1));
      }
      if (event.key === "ArrowLeft") {
        event.preventDefault();
        setInputMode("keyboard");
        setActiveBeat((current) => Math.max(0, current - 1));
      }
      if (event.key.toLowerCase() === "r") {
        setInputMode("keyboard");
        setActiveBeat(0);
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  return (
    <div className="walkthrough-shell" data-input={inputMode} tabIndex={0} role="region" aria-label="Evidence walkthrough" aria-describedby="walkthrough-help">
      <p className="walkthrough-help" id="walkthrough-help">Focus this walkthrough to use arrow keys or Space. Press R to return to the overview.</p>
      <div className="beat-copy" id="active-proof-beat" aria-live="polite"><p>{beat.number} · {beat.eyebrow}</p><h3>{beat.headline}</h3><span>{beat.body}</span></div>
      <div className="technical-stage">
        <header><div><small>SKILLS SDK · LOCAL · v0.2.0</small><strong>jscraik/improve-agent-native</strong></div><span>candidate digest missing</span></header>
        <CandidateRail camera={beat.camera} />
        <CopyCommand key={activeBeat} className="command-bar" />
        <div className="baseline-bar"><i /> Tessl registry · observed external baseline · not current local proof</div>
      </div>
      <div className="beat-controls">
        <div className="beat-tabs" aria-label="Walkthrough beats">{beats.map((item, index) => <button key={item.label} type="button" aria-pressed={index === activeBeat} className={index === activeBeat ? "active" : ""} onClick={(event) => { setInputMode(event.detail === 0 ? "keyboard" : "pointer"); setActiveBeat(index); }}><span>{item.number}</span><b>{item.label}</b></button>)}</div>
        <div className="step-buttons"><button type="button" disabled={activeBeat === 0} onClick={(event) => { setInputMode(event.detail === 0 ? "keyboard" : "pointer"); setActiveBeat(activeBeat - 1); }}>← Previous</button><span>{activeBeat + 1} / {beats.length}</span><button type="button" disabled={activeBeat === beats.length - 1} onClick={(event) => { setInputMode(event.detail === 0 ? "keyboard" : "pointer"); setActiveBeat(activeBeat + 1); }}>Next →</button></div>
      </div>
      <p className="concept-label">Concept mockup · Deterministic scenario · Not runtime evidence</p>
    </div>
  );
}
