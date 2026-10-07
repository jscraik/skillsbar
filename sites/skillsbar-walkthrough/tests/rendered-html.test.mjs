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
  assert.match(html, /<title>Know what your skill needs next · SkillsBar<\/title>/i);
  assert.match(html, /Know what your skill needs next/);
  assert.match(html, /by jscraik/);
  assert.doesNotMatch(html, /brAInwav/);
  assert.match(html, /Security review required/);
  assert.match(html, /Identity missing/);
  assert.match(html, /stage-grid/);
  assert.match(html, /Supported demo fixture/);
  assert.match(html, /Native app · Fixture capture/);
  assert.match(html, /skillsbar-demo-render\.webp/);
  assert.match(html, /skillsbar-icon-168\.webp/);
  assert.match(html, /Selecting a gate changes what you inspect/);
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

test("server renders nine selectable stages and distinct scenario controls", async () => {
  const html = await (await render()).text();
  assert.equal((html.match(/aria-label="Gate [1-9]:/g) ?? []).length, 9);
  assert.match(html, /2 passed · 1 needs review · 6 awaiting proof/);
  assert.match(html, /Full security receipt missing or malformed/);
  assert.match(html, /tessl-logo\.png/);
  assert.match(html, /Registry evidence is separate/);
  assert.match(html, /Selection changes the view, never the evidence/);
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
