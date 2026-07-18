"use client";

import Image from "next/image";
import { useEffect, useState, type CSSProperties } from "react";

type GateStatus = "current" | "required" | "held";
type Camera = "overview" | "build" | "prove" | "ship";

const gates = [
  "Candidate identity",
  "Mechanical validation",
  "Security & guardrails",
  "Eval preparation",
  "Eval local proof",
  "Eval cloud proof",
  "Tessl staging",
  "Publication & registry",
  "Runtime truth",
] as const;

const chapters = [
  { id: "build", number: "01", name: "Build", range: "Gates 1–2", gateIndexes: [0, 1] },
  { id: "prove", number: "02", name: "Prove", range: "Gates 3–6", gateIndexes: [2, 3, 4, 5] },
  { id: "ship", number: "03", name: "Ship", range: "Gates 7–9", gateIndexes: [6, 7, 8] },
] as const;

// The proof scenario never changes when the camera moves.
const scenarioStatuses: readonly GateStatus[] = [
  "required", "held", "held", "held", "held", "held", "held", "held", "held",
];

const beats = [
  {
    number: "01",
    label: "Problem",
    camera: "overview" as Camera,
    eyebrow: "One candidate · one evidence chain",
    headline: "A healthy registry score can still belong to the wrong candidate.",
    body: "The published baseline remains visible, but SkillsBar requires one canonical package digest before any downstream receipt can count.",
  },
  {
    number: "02",
    label: "Build",
    camera: "build" as Camera,
    eyebrow: "Gate 1 · required",
    headline: "The candidate line stops before Build can complete.",
    body: "Without the canonical package digest, mechanical validation and every later receipt remain downstream.",
  },
  {
    number: "03",
    label: "Prove",
    camera: "prove" as Camera,
    eyebrow: "Gates 3–6 · held",
    headline: "Prove cannot borrow an identity.",
    body: "Security and evaluation stay held because there is no candidate digest to bind their receipts to.",
  },
  {
    number: "04",
    label: "Ship & decide",
    camera: "ship" as Camera,
    eyebrow: "Gates 7–9 · held",
    headline: "A registry score cannot override missing candidate identity.",
    body: "Staging, publication, and runtime truth stay held while SkillsBar gives the maintainer the identity command—not a false green light.",
  },
] as const;

const cameraPositions: Record<Exclude<Camera, "overview">, string> = {
  build: "0%",
  prove: "-33.333%",
  ship: "-66.666%",
};

/* ─────────────────────────────────────────────────────────────
 * PROOF WALKTHROUGH STORYBOARD
 *
 *   beat 1  problem: whole Build → Prove → Ship world is visible
 *   beat 2  build: camera moves into gates 1–2
 *   beat 3  prove: camera continues right; held proof is centered
 *   beat 4  ship: downstream gates and the human decision stay explicit
 *
 * Camera uses transform only. State emphasis uses opacity/color only.
 * Reduced motion replaces travel with an immediate state change.
 * ───────────────────────────────────────────────────────────── */

const statusLabel = (status: GateStatus) => status === "current" ? "Current" : status === "required" ? "Required" : "Held";

function CandidateRail({ camera = "overview", compact = false }: { camera?: Camera; compact?: boolean }) {
  const railStyle = {
    "--camera-x": camera === "overview" ? "0%" : cameraPositions[camera],
  } as CSSProperties;

  return (
    <div className={`rail-viewport ${compact ? "rail-compact" : ""}`} data-camera={camera} aria-label="Candidate 9c21 moves through Build, Prove, and Ship and stops at the required security receipt">
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

export default function Home() {
  const [activeBeat, setActiveBeat] = useState(0);
  const [copyState, setCopyState] = useState<"idle" | "copied" | "unavailable">("idle");
  const beat = beats[activeBeat];
  const command = "./bin/ask sdk start …/improve-agent-native --json --robot";

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((entry) => entry.isIntersecting && entry.target.classList.add("revealed")),
      { threshold: 0.14 },
    );
    document.querySelectorAll<HTMLElement>("[data-reveal]").forEach((element) => observer.observe(element));
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (target?.closest("button, a, input, textarea, select")) return;
      if (event.key === "ArrowRight" || event.key === " ") {
        event.preventDefault();
        setActiveBeat((current) => Math.min(beats.length - 1, current + 1));
      }
      if (event.key === "ArrowLeft") setActiveBeat((current) => Math.max(0, current - 1));
      if (event.key.toLowerCase() === "r") setActiveBeat(0);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  const selectBeat = (index: number) => {
    setActiveBeat(index);
    setCopyState("idle");
  };

  const copyCommand = async () => {
    try {
      await navigator.clipboard.writeText(command);
      setCopyState("copied");
    } catch {
      setCopyState("unavailable");
    }
  };

  return (
    <main>
      <nav className="site-nav" aria-label="Primary navigation">
        <a className="brand" href="#top" aria-label="SkillsBar home"><Image src="/skillsbar-icon.png" alt="" width={28} height={28} unoptimized /><span>SkillsBar</span><small>by brAInwav</small></a>
        <div className="nav-links"><a href="#product">Product proof</a><a href="#walkthrough">90-second walkthrough</a><a className="nav-cta" href="https://github.com/jscraik/skillsbar">Repository ↗</a></div>
      </nav>

      <section className="hero" id="top" aria-labelledby="hero-title">
        <div className="hero-copy" data-reveal>
          <div className="hero-product"><Image src="/skillsbar-icon.png" alt="" width={42} height={42} unoptimized /><div><b>SkillsBar</b><small>by brAInwav</small></div></div>
          <p className="kicker">OpenAI hackathon · Built with Codex</p>
          <h1 id="hero-title">When evidence goes stale.</h1>
          <p className="hero-lede">A changed Skill can still look healthy when its registry score belongs to yesterday’s candidate. SkillsBar stops the hand-me-down.</p>
          <div className="hero-actions"><a className="button primary" href="#walkthrough">Run the proof <span aria-hidden="true">↓</span></a><a className="button secondary" href="#product">See the app</a></div>
          <p className="hero-disclosure">CONCEPT MOCKUP · NOT RUNTIME EVIDENCE</p>
        </div>
        <div className="hero-technical" data-reveal>
          <div className="technical-head"><span><i /> Local candidate changed</span><code>canonical digest missing</code></div>
          <CandidateRail compact />
          <div className="technical-verdict"><span><b>Candidate digest is missing</b><small>Gate 1 · required</small></span><strong>Downstream proof held</strong></div>
          <div className="technical-source"><span>current candidate</span><span>observed baseline separate</span></div>
        </div>
      </section>

      <section className="product-section" id="product" aria-labelledby="product-title">
        <div className="section-intro" data-reveal><p className="section-number">01 · Supported demo fixture</p><h2 id="product-title">The held gate and the next action share one decision surface.</h2><p>The native macOS app discloses its deterministic state while keeping local candidate proof, the Tessl baseline, and the proving command visibly separate.</p></div>
        <div className="product-proof" data-reveal>
          <figure className="product-shot"><div className="capture-frame"><Image src="/skillsbar-candidate-identity-gate.png" alt="The native SkillsBar demo fixture showing Candidate identity as Gate 1 of 9, a missing canonical package digest, downstream proof held, and a separate Tessl baseline marked not candidate proof." width={816} height={1116} sizes="(max-width: 800px) 88vw, 560px" unoptimized /></div><figcaption>SUPPORTED DEMO FIXTURE · NATIVE APP CAPTURE · GATE 1 OF 9</figcaption></figure>
          <div className="proof-reading">
            <p className="proof-digest"><span>candidate digest</span><code>MISSING</code></p>
            <ol>
              <li className="required"><span>01</span><div><b>Identity is required</b><p>The canonical package digest is missing.</p></div></li>
              <li className="held"><span>02–06</span><div><b>Validation and proof stay held</b><p>No receipt can bind to an unidentified candidate.</p></div></li>
              <li className="held"><span>07–09</span><div><b>Shipping stays held</b><p>The Tessl baseline is context, not local approval.</p></div></li>
            </ol>
            <div className="proof-command"><small>Next proving action</small><code>{command}</code></div>
          </div>
        </div>
      </section>

      <section className="walkthrough-section" id="walkthrough" aria-labelledby="walkthrough-title">
        <div className="walkthrough-heading" data-reveal><p className="section-number">02 · 90-second walkthrough</p><h2 id="walkthrough-title">One world. One candidate. Four views.</h2><p>The evidence stays fixed while the camera moves from Build to Prove to Ship.</p></div>
        <div className="walkthrough-shell" data-reveal>
          <div className="beat-copy" id="active-proof-beat" aria-live="polite"><p>{beat.number} · {beat.eyebrow}</p><h3>{beat.headline}</h3><span>{beat.body}</span></div>
          <div className="technical-stage">
            <header><div><small>SKILLS SDK · LOCAL · v0.2.0</small><strong>jscraik/improve-agent-native</strong></div><span>candidate digest missing</span></header>
            <CandidateRail camera={beat.camera} />
            <div className="command-bar"><code>{command}</code><button type="button" onClick={copyCommand}>{copyState === "copied" ? "Copied" : copyState === "unavailable" ? "Unavailable" : "Copy command"}</button></div>
            <div className="baseline-bar"><i /> Tessl registry · observed external baseline · not current local proof</div>
          </div>
          <div className="beat-controls">
            <div className="beat-tabs" role="tablist" aria-label="Walkthrough beats">{beats.map((item, index) => <button key={item.label} type="button" role="tab" aria-controls="active-proof-beat" aria-selected={index === activeBeat} className={index === activeBeat ? "active" : ""} onClick={() => selectBeat(index)}><span>{item.number}</span><b>{item.label}</b></button>)}</div>
            <div className="step-buttons"><button type="button" disabled={activeBeat === 0} onClick={() => selectBeat(activeBeat - 1)}>← Previous</button><span>{activeBeat + 1} / {beats.length}</span><button type="button" disabled={activeBeat === beats.length - 1} onClick={() => selectBeat(activeBeat + 1)}>Next →</button></div>
          </div>
          <p className="concept-label">CONCEPT MOCKUP · DETERMINISTIC SCENARIO · NOT RUNTIME EVIDENCE</p>
        </div>
      </section>

      <section className="atlas-section" aria-labelledby="atlas-title">
        <details className="atlas-disclosure">
          <summary><span><small>03 · Technical appendix</small><b id="atlas-title">Inspect all nine evidence gates</b></span><em>Open atlas ↓</em></summary>
          <div className="atlas-heading"><p>Optional judge Q&amp;A detail: every gate names its evidence source and next action.</p></div>
          <figure className="atlas-board"><Image src="/skillsbar-nine-gate-walkthrough.svg" alt="Expanded nine-gate SkillsBar concept board showing candidate identity, mechanical validation, security, evaluation, Tessl staging and publication, and runtime truth with evidence sources and next actions." width={2160} height={1750} unoptimized /><figcaption>CONCEPT MOCKUP · NOT RUNTIME EVIDENCE · NINE-GATE DETAIL BOARD</figcaption></figure>
        </details>
      </section>

      <section className="codex-section" id="codex" aria-labelledby="codex-title">
        <div className="codex-copy" data-reveal><p className="section-number">04 · Meaningful use of Codex</p><h2 id="codex-title">Codex turned the proof boundary into an executable contract.</h2><p>Codex helped model the nine gates, separate deterministic evidence from presentation state, implement the native fixture, and preserve those boundaries with tests and launch receipts.</p></div>
        <div className="evidence-trace" data-reveal>
          <article><span>Challenge found</span><h3>Camera state changed evidence.</h3><p>The walkthrough could imply that moving the view advanced the candidate.</p></article>
          <article><span>Codex intervention</span><h3>One deterministic contract.</h3><p>The evidence state remains fixed while only the camera and disclosure change.</p></article>
          <article><span>Behavior proof</span><h3>82 tests. Signed app. Launch receipt.</h3><p>The fixture cannot claim live evidence, and the native app records exactly how it launched.</p></article>
        </div>
      </section>

      <section className="closing" aria-labelledby="closing-title">
        <div className="closing-copy" data-reveal><p className="kicker">The maintainer decides</p><h2 id="closing-title">The next command is clear. The release decision remains human.</h2><p>Inspect the source, the native implementation, and the explicit real-versus-demo boundary.</p><a className="button primary" href="https://github.com/jscraik/skillsbar">Open the repository ↗</a></div>
        <div className="closing-qr" data-reveal><div><Image src="/skillsbar-repo-qr-1024.png" alt="QR code for the SkillsBar GitHub repository" width={1024} height={1024} unoptimized /></div><a href="https://github.com/jscraik/skillsbar">github.com/jscraik/skillsbar</a></div>
      </section>

      <footer className="site-footer"><div className="brand"><Image src="/skillsbar-icon.png" alt="" width={24} height={24} unoptimized /><span>SkillsBar</span><small>by brAInwav</small></div><p>CONCEPT MOCKUPS ARE NOT RUNTIME EVIDENCE</p><a href="#top">Back to top ↑</a></footer>
    </main>
  );
}
