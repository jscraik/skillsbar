"use client";
import { useState, type CSSProperties } from "react";
import Image from "next/image";
import { CopyCommand } from "./interactive-evidence";

const names = ["Identity", "Validation", "Security", "Eval prep", "Local eval", "Cloud eval", "Staging", "Publication", "Runtime"];
const titles = ["Candidate identity", "Mechanical validation", "Security & guardrails", "Eval preparation", "Eval local proof", "Eval cloud proof", "Tessl staging", "Tessl publication & registry", "Runtime truth"];
const descriptions = ["Canonical package digest missing", "Validation requires an identified candidate.", "Security receipts require the current candidate digest.", "Evaluation preparation awaits candidate identity.", "Local proof must bind to the current candidate.", "Cloud proof must bind to the current candidate.", "Candidate-bound scenario identities are required before Tessl staging.", "Candidate-bound Tessl publication and score receipts are required.", "No runtime card is bound to the current package digest."];
type Status = "Passed" | "Review required" | "Held" | "Unproven";
type Scenario = "security" | "identity";
const scenarios: Record<Scenario, { label: string; active: number; statuses: Status[] }> = {
  security: { label: "Security review required", active: 2, statuses: ["Passed", "Passed", "Review required", "Held", "Unproven", "Unproven", "Unproven", "Unproven", "Unproven"] },
  identity: { label: "Identity missing", active: 0, statuses: ["Review required", "Held", "Held", "Held", "Unproven", "Unproven", "Unproven", "Unproven", "Unproven"] },
};
const symbols: Record<Status, string> = { Passed: "✓", "Review required": "⚠", Held: "Ⅱ", Unproven: "−" };

/* ANIMATION STORYBOARD
 *   0ms   selected stage content changes; grid and registry remain fixed
 * 160ms   detail opacity 0.65 → 1; Reduced Motion shows the result immediately
 */
const TIMING = { detailReveal: 160 }; // milliseconds after stage selection
const DETAIL = { initialOpacity: 0.65 }; // brief acknowledgement without movement
const detailStyle = { "--detail-duration": `${TIMING.detailReveal}ms`, "--detail-start": DETAIL.initialOpacity } as CSSProperties;

export function FocusNavigator() {
  const [scenario, setScenario] = useState<Scenario>("security");
  const [selected, setSelected] = useState(2);
  const [expanded, setExpanded] = useState(false);
  const data = scenarios[scenario];
  const select = (index: number) => { setSelected(index); setExpanded(false); };
  const canCopy = scenario === "identity" && selected === 0;
  return <div className="focus-demo">
    <div className="demo-layout">
      <div className="focus-inspector">
        <header className="inspector-header"><Image src="/skillsbar-icon-168.webp" width={46} height={46} alt="" unoptimized /><div><small>SKILLS SDK</small><b>improve-agent-native</b><p><span className="local-tag">Local</span> v0.2.0 <strong>● Needs attention</strong></p></div></header>
        <div className="scenario-picker"><span>Demo scenario</span>{(Object.keys(scenarios) as Scenario[]).map(id => <button type="button" key={id} aria-pressed={scenario === id} onClick={() => { setScenario(id); select(scenarios[id].active); }}>{scenarios[id].label}</button>)}</div>
        <p className="scenario-disclosure">Interactive fixture · Selection changes the view, never the evidence. {scenario === "security" ? "The security command is illustrative." : "The identity command can be copied for local use."}</p>
        <div className="stage-grid" aria-label="Evidence stages">{names.map((name, index) => <button type="button" key={name} data-status={data.statuses[index]} aria-pressed={selected === index} aria-label={`Gate ${index + 1}: ${name}, ${data.statuses[index]}`} onClick={() => select(index)} onKeyDown={event => {
          const offsets: Record<string, number> = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: 3, ArrowUp: -3 };
          const offset = offsets[event.key];
          if (offset === undefined) return;
          event.preventDefault();
          const next = Math.max(0, Math.min(8, index + offset));
          select(next);
          event.currentTarget.parentElement?.querySelectorAll("button")[next]?.focus();
        }}><span>{String(index + 1).padStart(2, "0")}</span><i aria-hidden="true">{symbols[data.statuses[index]]}</i><b>{name}</b></button>)}</div>
        <p className="stage-summary">{scenario === "security" ? "2 passed · 1 needs review · 6 awaiting proof" : "1 needs review · 8 awaiting proof"}</p>
        <section className="stage-detail" aria-labelledby="stage-title">
          <div className="gate-context"><span>Gate {String(selected + 1).padStart(2, "0")} / 09</span><span>{selected === data.active ? "Next required" : `Next required: Gate ${String(data.active + 1).padStart(2, "0")}`}</span></div>
          <div className="detail-reveal" key={`${scenario}-${selected}`} style={detailStyle}>
          <h3 id="stage-title">{titles[selected]}</h3>
          <div className="detail-status">{scenario === "security" && selected === 2 ? <><span className="severity">1 critical</span><span className="severity">2 high</span></> : <span>{symbols[data.statuses[selected]]} {data.statuses[selected]}</span>}</div>
          <p className="stage-explanation">{scenario === "security" ? (selected === 2 ? <>Full security receipt missing or malformed.<br />Inspect findings before continuing.</> : "Review findings · full governed security receipt is missing or malformed") : descriptions[selected]}</p>
          </div>
          <div className="stage-actions">{canCopy ? <><button type="button" aria-expanded={expanded} onClick={() => setExpanded(!expanded)}>{expanded ? "⌄ Hide command" : "› Show command"}</button><CopyCommand className="inspector-command" showCommand={expanded} /></> : <span>{scenario === "security" ? "Visual reference · no executable command" : "No command available for this stage"}</span>}</div>
        </section>
        <section className="registry-summary" aria-label="Tessl registry"><Image src="/tessl-logo.png" width={38} height={38} alt="Tessl" unoptimized /><div><h4>Tessl Registry <span className="local-tag">{scenario === "identity" ? "Baseline" : "Unavailable"}</span></h4><p>{scenario === "identity" ? "v0.2.0 · observation time unavailable" : "No cached registry evidence"}</p><p>jscraik/improve-agent-native</p></div>{scenario === "identity" && <div className="registry-score"><b>66</b><small>Registry score</small><span>1.28x lift</span></div>}</section>
        <p className="registry-boundary">Registry evidence is separate from proof for the local candidate.</p>
      </div>
      <aside className="demo-reading">
        <p className="section-number">Explore the inspector</p>
        <h3>Inspect a stage.<br />Keep the evidence in view.</h3>
        <p className="demo-introduction">See what each gate needs, without losing sight of the next required check.</p>
        <dl className="demo-guidance">
          <div><dt>Select any stage</dt><dd>Read its status and explanation. The next required gate stays marked as you explore.</dd></div>
          <div><dt>Inspect without advancing</dt><dd>Changing your selection leaves the candidate’s evidence and progress unchanged.</dd></div>
          <div><dt>Navigate with the keyboard</dt><dd>Focus a stage button, then use the arrow keys to move through the grid.</dd></div>
        </dl>
      </aside>
    </div>
  </div>;
}
