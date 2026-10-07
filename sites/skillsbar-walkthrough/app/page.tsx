import Image from "next/image";
import { CopyCommand } from "./interactive-evidence";
import { FocusNavigator } from "./focus-navigator";

/** Render the landing page with native-demo evidence, the interactive scenario, and source links. */
export default function Home() {
  return (
    <main>
      <a className="skip-link" href="#top">Skip to content</a>
      <nav className="site-nav" aria-label="Primary navigation">
        <a className="brand" href="#top" aria-label="SkillsBar home"><Image src="/skillsbar-icon-168.webp" alt="" width={28} height={28} unoptimized /><span>SkillsBar</span><small>by jscraik</small></a>
        <div className="nav-links"><a href="#product">Product proof</a><a href="#walkthrough">How it works</a><a className="nav-cta" href="https://github.com/jscraik/skillsbar">Repository ↗</a></div>
        <details className="compact-nav"><summary>Explore</summary><div><a href="#walkthrough">Interactive demo</a><a href="#product">Native app detail</a><a href="https://github.com/jscraik/skillsbar">Repository ↗</a></div></details>
      </nav>

      <section className="hero" id="top" tabIndex={-1} aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="kicker">macOS menu-bar app</p>
          <h1 id="hero-title">Know what your skill needs next.</h1>
          <p className="hero-lede">Inspect nine evidence gates, see what needs attention, and copy the next command—all from your macOS menu bar.</p>
          <div className="hero-actions"><a className="button primary" href="#walkthrough">Explore the demo <span aria-hidden="true">↓</span></a><a className="button secondary" href="#product">See the native app</a></div>
        </div>
        <div className="hero-technical"><Image src="/skillsbar-demo-render.webp" alt="Current SkillsBar app fixture with nine evidence stages, selected gate details, and a separate Tessl registry summary." width={460} height={586} preload unoptimized /><p className="concept-label">Native app · Fixture capture</p></div>
      </section>

      <section className="walkthrough-section" id="walkthrough" aria-labelledby="walkthrough-title">
        <div className="walkthrough-heading"><p className="section-number">01 · Interactive demo</p><h2 id="walkthrough-title">Move through the gates. The evidence stays put.</h2><p>Explore two labelled scenarios in the same nine-stage layout as the app. Selecting a gate changes what you inspect; it never creates new evidence.</p></div>
        <FocusNavigator />
      </section>

      <section className="product-section" id="product" aria-labelledby="product-title">
        <div className="section-intro"><p className="section-number">02 · Supported demo fixture</p><h2 id="product-title">The missing digest sits beside the next command.</h2><p>This app-rendered fixture shows why Gate 1 is held. It keeps the published Tessl baseline separate from proof for the local candidate.</p></div>
        <div className="product-proof">
          <figure className="product-shot"><div className="native-detail-crop"><Image src="/skillsbar-demo-render.webp" alt="Native detail: missing candidate digest, Copy command action, and Tessl registry baseline." width={460} height={586} sizes="(max-width: 800px) 88vw, 430px" unoptimized /></div><figcaption>Gate 1 · A closer look at the native app</figcaption><ol className="capture-annotations"><li><b>01 · Missing evidence</b><span>The digest identifies the candidate being checked.</span></li><li><b>02 · Next action</b><span>Copy the command beside the explanation.</span></li><li><b>03 · Registry context</b><span>The Tessl baseline stays visible with its own score.</span></li></ol></figure>
          <div className="proof-reading">
            <p className="proof-digest"><span>candidate digest</span><code>MISSING</code></p>
            <ol>
              <li className="required"><span>01</span><div><b>Identity is required</b><p>The canonical package digest is missing.</p></div></li>
              <li className="held"><span>02–06</span><div><b>Validation and proof stay held</b><p>No receipt can bind to an unidentified candidate.</p></div></li>
              <li className="held"><span>07–09</span><div><b>Shipping stays held</b><p>The Tessl baseline is context, not local approval.</p></div></li>
            </ol>
            <CopyCommand className="proof-command" label="Next proving action" />
          </div>
        </div>
      </section>

      <section className="atlas-section" aria-labelledby="atlas-title">
        <details className="atlas-disclosure">
          <summary><span><small>03 · Technical appendix</small><b id="atlas-title">Inspect all nine evidence gates</b></span><em><span className="atlas-open-label">Open atlas ↓</span><span className="atlas-close-label">Close atlas ↑</span></em></summary>
          <div className="atlas-heading"><p>Every gate names its evidence source and next action. This concept diagram and the fixture captures illustrate the model; they do not establish live candidate proof.</p><a href="/skillsbar-nine-gate-walkthrough.svg" target="_blank" rel="noopener noreferrer">Open full-size diagram ↗</a></div>
          <figure className="atlas-board"><Image src="/skillsbar-nine-gate-walkthrough.svg" alt="Expanded nine-gate SkillsBar concept board showing candidate identity, mechanical validation, security, evaluation, Tessl staging and publication, and runtime truth with evidence sources and next actions." width={2160} height={1750} unoptimized /><figcaption>Concept mockup · Not runtime evidence · Nine-gate detail board</figcaption></figure>
        </details>
      </section>

      <section className="codex-section" id="codex" aria-labelledby="codex-title">
        <div className="codex-copy"><p className="section-number">04 · Meaningful use of Codex</p><h2 id="codex-title">Built and refined with Codex.</h2><p>Codex helped build the native app, refine its stage layout, and make the demo distinguish inspection from evidence.</p></div>
        <div className="evidence-trace">
          <article><span>Problem</span><div><h3>Inspection can look like progress.</h3><p>A selected gate tells you what you are inspecting. It does not mean that gate has passed.</p></div></article>
          <article><span>Change</span><div><h3>Evidence stays fixed across selections.</h3><p>All nine stages retain their evidence status while the detail panel follows your selection.</p></div></article>
          <article><span>Proof boundary</span><div><h3>The fixture says what it is.</h3><p>Tests cover the fixed scenario. Build and launch receipts describe the native app run; the fixture does not claim live candidate proof.</p></div></article>
        </div>
      </section>

      <section className="closing" aria-labelledby="closing-title">
        <div className="closing-copy"><p className="kicker">The maintainer decides</p><h2 id="closing-title">Run the next check. Decide what the result proves.</h2><p>Inspect the source, the native app, and the line between demo data and local evidence.</p><a className="button primary" href="https://github.com/jscraik/skillsbar">Open the repository ↗</a></div>
        <div className="closing-qr"><div><Image src="/skillsbar-repo-qr-1024.png" alt="QR code for the SkillsBar GitHub repository" width={1024} height={1024} unoptimized /></div><a href="https://github.com/jscraik/skillsbar">github.com/jscraik/skillsbar</a></div>
      </section>

      <footer className="site-footer"><div className="brand"><Image src="/skillsbar-icon-168.webp" alt="" width={24} height={24} unoptimized /><span>SkillsBar</span><small>by jscraik</small></div><p>Evidence at a glance. The next check in reach.</p><a href="#top">Back to top ↑</a></footer>
    </main>
  );
}
