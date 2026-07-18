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
  assert.match(html, /<title>When evidence goes stale · SkillsBar<\/title>/i);
  assert.match(html, /When evidence goes stale/);
  assert.match(html, /Build/);
  assert.match(html, /Prove/);
  assert.match(html, /Ship/);
  assert.match(html, /Candidate digest is missing/);
  assert.match(html, /SUPPORTED DEMO FIXTURE/);
  assert.match(html, /NATIVE APP CAPTURE/);
  assert.match(html, /Inspect all nine evidence gates/);
  assert.match(html, /CONCEPT MOCKUP/);
  assert.match(html, /NOT RUNTIME EVIDENCE/);
  assert.match(html, /Meaningful use of Codex/);
  assert.match(html, /82 tests\. Signed app\. Launch receipt\./);
  assert.doesNotMatch(html, /LIVE PRODUCT CAPTURE/);
  assert.doesNotMatch(html, /Safe to release|Production ready|Live runtime proof/i);
});

test("keeps four views and nine gates in one fixed evidence scenario", async () => {
  const page = await readFile(new URL("app/page.tsx", root), "utf8");
  const beatNumbers = [...page.matchAll(/number: "0[1-4]"/g)];
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
  for (const gateName of gateNames) assert.match(page, new RegExp(gateName.replace("&", "&")));
  assert.match(page, /const scenarioStatuses/);
  assert.match(page, /const cameraPositions/);
  assert.match(page, /camera: "overview" as Camera/);
  assert.match(page, /event\.key === "ArrowRight" \|\| event\.key === " "/);
  assert.match(page, /event\.key === "ArrowLeft"/);
  assert.match(page, /event\.key\.toLowerCase\(\) === "r"/);
  assert.match(page, /aria-live="polite"/);
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
