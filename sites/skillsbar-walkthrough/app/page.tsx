import Image from "next/image";
import { CandidateRail, CopyCommand, Walkthrough } from "./interactive-evidence";

export default function Home() {
  return (
    <main>
      <a className="skip-link" href="#top">Skip to content</a>
      <nav className="site-nav" aria-label="Primary navigation">
        <a className="brand" href="#top" aria-label="SkillsBar home"><Image src="/skillsbar-icon-168.webp" alt="" width={28} height={28} unoptimized /><span>SkillsBar</span><small>by brAInwav</small></a>
        <div className="nav-links"><a href="#product">Product proof</a><a href="#walkthrough">How it works</a><a className="nav-cta" href="https://github.com/jscraik/skillsbar">Repository ↗</a></div>
      </nav>

      <section className="hero" id="top" tabIndex={-1} aria-labelledby="hero-title">
        <div className="hero-copy">
          <div className="hero-product"><Image src="/skillsbar-icon-168.webp" alt="" width={42} height={42} preload unoptimized /><div><b>SkillsBar</b><small>by brAInwav</small></div></div>
          <p className="kicker">OpenAI hackathon · Built with Codex</p>
          <h1 id="hero-title">A score is not a candidate.</h1>
          <p className="hero-lede">SkillsBar shows when a published score cannot prove your local skill, and which check to run next.</p>
          <div className="hero-actions"><a className="button primary" href="#product">See the app <span aria-hidden="true">↓</span></a><a className="button secondary" href="#walkthrough">Explore the walkthrough</a></div>
          <p className="hero-disclosure">Concept mockup · Not runtime evidence</p>
        </div>
        <div className="hero-technical">
          <div className="technical-head"><span><i /> Local candidate changed</span><code>canonical digest missing</code></div>
          <CandidateRail compact />
          <div className="technical-verdict"><span><b>Candidate digest is missing</b><small>Gate 1 · required</small></span><strong>Downstream proof held</strong></div>
          <div className="technical-source"><span>current candidate</span><span>observed baseline separate</span></div>
        </div>
      </section>

      <section className="product-section" id="product" aria-labelledby="product-title">
        <div className="section-intro"><p className="section-number">01 · Supported demo fixture</p><h2 id="product-title">The missing digest sits beside the next command.</h2><p>This app-rendered fixture shows why Gate 1 is held. It keeps the published Tessl baseline separate from proof for the local candidate.</p></div>
        <div className="product-proof">
          <figure className="product-shot"><div className="capture-frame"><Image src="/skillsbar-demo-render.webp" alt="App-rendered SkillsBar demo fixture showing Candidate identity as Gate 1 of 9, a missing canonical package digest, downstream proof held, and a separate Tessl baseline marked not candidate proof." width={840} height={2360} sizes="(max-width: 800px) 88vw, 430px" unoptimized /></div><figcaption>Supported demo fixture · App-rendered snapshot · Gate 1 of 9</figcaption></figure>
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

      <section className="walkthrough-section" id="walkthrough" aria-labelledby="walkthrough-title">
        <div className="walkthrough-heading"><p className="section-number">02 · Visual explainer</p><h2 id="walkthrough-title">Move through the gates. The evidence stays put.</h2><p>Follow the same missing-digest scenario through Build, Prove, and Ship. This walkthrough explains the model; the native app is the product demo.</p></div>
        <Walkthrough />
      </section>

      <section className="atlas-section" aria-labelledby="atlas-title">
        <details className="atlas-disclosure">
          <summary><span><small>03 · Technical appendix</small><b id="atlas-title">Inspect all nine evidence gates</b></span><em><span className="atlas-open-label">Open atlas ↓</span><span className="atlas-close-label">Close atlas ↑</span></em></summary>
          <div className="atlas-heading"><p>Optional judge Q&amp;A detail: every gate names its evidence source and next action.</p><a href="/skillsbar-nine-gate-walkthrough.svg" target="_blank" rel="noopener noreferrer">Open full-size diagram ↗</a></div>
          <figure className="atlas-board"><Image src="/skillsbar-nine-gate-walkthrough.svg" alt="Expanded nine-gate SkillsBar concept board showing candidate identity, mechanical validation, security, evaluation, Tessl staging and publication, and runtime truth with evidence sources and next actions." width={2160} height={1750} unoptimized /><figcaption>Concept mockup · Not runtime evidence · Nine-gate detail board</figcaption></figure>
        </details>
      </section>

      <section className="codex-section" id="codex" aria-labelledby="codex-title">
        <div className="codex-copy"><p className="section-number">04 · Meaningful use of Codex</p><h2 id="codex-title">Codex helped keep the walkthrough honest.</h2><p>Codex helped define the nine gates and build the native fixture. The implementation keeps a camera move from looking like new evidence.</p></div>
        <div className="evidence-trace">
          <article><span>Problem</span><div><h3>Moving the view looked like progress.</h3><p>The first walkthrough could imply that the candidate advanced when only the camera moved.</p></div></article>
          <article><span>Change</span><div><h3>Evidence stays fixed across views.</h3><p>Build, Prove, and Ship show the same missing digest and held downstream gates.</p></div></article>
          <article><span>Proof boundary</span><div><h3>The fixture says what it is.</h3><p>Tests cover the fixed scenario. Build and launch receipts describe the native app run; the fixture does not claim live candidate proof.</p></div></article>
        </div>
      </section>

      <section className="closing" aria-labelledby="closing-title">
        <div className="closing-copy"><p className="kicker">The maintainer decides</p><h2 id="closing-title">Run the next check. Decide what the result proves.</h2><p>Inspect the source, the native app, and the line between demo data and local evidence.</p><a className="button primary" href="https://github.com/jscraik/skillsbar">Open the repository ↗</a></div>
        <div className="closing-qr"><div><Image src="/skillsbar-repo-qr-1024.png" alt="QR code for the SkillsBar GitHub repository" width={1024} height={1024} unoptimized /></div><a href="https://github.com/jscraik/skillsbar">github.com/jscraik/skillsbar</a></div>
      </section>

      <footer className="site-footer"><div className="brand"><Image src="/skillsbar-icon-168.webp" alt="" width={24} height={24} unoptimized /><span>SkillsBar</span><small>by brAInwav</small></div><p>Concept mockups are not runtime evidence</p><a href="#top">Back to top ↑</a></footer>
    </main>
  );
}
