import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { PNG } from "pngjs";

const root = new URL("../", import.meta.url);

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("server-renders the SkillsBar evidence landing page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>A score is not a candidate · SkillsBar<\/title>/i);
  assert.match(html, /A score is not a candidate/);
  assert.match(html, /Build/);
  assert.match(html, /Prove/);
  assert.match(html, /Ship/);
  assert.match(html, /Candidate digest is missing/);
  assert.match(html, /Supported demo fixture/);
  assert.match(html, /App-rendered snapshot/);
  assert.match(html, /skillsbar-demo-render\.webp/);
  assert.match(html, /skillsbar-icon-168\.webp/);
  assert.match(html, /This walkthrough explains the model; the native app is the product demo\./);
  assert.doesNotMatch(html, /Run the proof/);
  assert.match(html, /Inspect all nine evidence gates/);
  assert.match(html, /Concept mockup/);
  assert.match(html, /Not runtime evidence/);
  assert.match(html, /Open full-size diagram/);
  assert.match(html, /Close atlas/);
  assert.doesNotMatch(html, /data-reveal/);
  assert.match(html, /Meaningful use of Codex/);
  assert.match(html, /The fixture says what it is\./);
  assert.doesNotMatch(html, /LIVE PRODUCT CAPTURE/);
  assert.doesNotMatch(html, /Safe to release|Production ready|Live runtime proof/i);
});

test("keeps four views and nine gates in one fixed evidence scenario", async () => {
  const page = await readFile(new URL("app/page.tsx", root), "utf8");
  const interactive = await readFile(new URL("app/interactive-evidence.tsx", root), "utf8");
  const beatNumbers = [...interactive.matchAll(/number: "0[1-4]"/g)];
  const gateNames = [
    "Candidate identity",
    "Mechanical validation",
    "Security & guardrails",
    "Eval preparation",
    "Eval local proof",
    "Eval cloud proof",
    "Tessl staging",
    "Publication & registry",
    "Runtime truth",
  ];

  assert.equal(beatNumbers.length, 7, "four beats plus three chapter numbers should be declared");
  for (const gateName of gateNames) assert.match(interactive, new RegExp(gateName.replace("&", "&")));
  assert.doesNotMatch(page, /"use client"/);
  assert.match(interactive, /const scenarioStatuses/);
  assert.match(interactive, /const cameraPositions/);
  assert.match(interactive, /camera: "overview" as Camera/);
  assert.match(interactive, /event\.key === "ArrowRight" \|\| event\.key === " "/);
  assert.match(interactive, /event\.key === "ArrowLeft"/);
  assert.match(interactive, /event\.key\.toLowerCase\(\) === "r"/);
  assert.match(interactive, /aria-live="polite"/);
});

test("ships an opaque, non-empty repository QR code", async () => {
  const data = await readFile(new URL("public/skillsbar-repo-qr-1024.png", root));
  const png = PNG.sync.read(data);
  let blackPixels = 0;
  let whitePixels = 0;

  for (let index = 0; index < png.data.length; index += 4) {
    const [red, green, blue, alpha] = png.data.subarray(index, index + 4);
    assert.equal(alpha, 255, "QR pixels must be opaque");
    if (red < 16 && green < 16 && blue < 16) blackPixels += 1;
    if (red > 239 && green > 239 && blue > 239) whitePixels += 1;
  }

  assert.ok(blackPixels > 100_000, "QR must contain substantial dark modules");
  assert.ok(whitePixels > 100_000, "QR must contain a white quiet zone and light modules");
});
