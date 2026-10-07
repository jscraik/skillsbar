import assert from "node:assert/strict";
import { chromium } from "playwright-core";

const baseURL = process.argv[2] ?? "http://localhost:3008/";
const browser = await chromium.launch({ headless: true, channel: "chrome" });
try {
  for (const width of [375, 654, 837, 900, 1024, 1440]) {
    const context = await browser.newContext({ viewport: { width, height: 900 }, reducedMotion: "reduce", permissions: ["clipboard-read", "clipboard-write"] });
    const page = await context.newPage();
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));
    await page.goto(baseURL, { waitUntil: "networkidle" });
    if (width === 1440) await page.screenshot({ path: "/private/tmp/skillsbar-site-hero.png" });
    await page.locator(".atlas-disclosure summary").click();
    for (const image of await page.locator("img").all()) {
      await image.scrollIntoViewIfNeeded();
      await image.evaluate(element => element.decode().catch(() => {}));
    }
    const layout = await page.evaluate(() => ({
      overflow: document.documentElement.scrollWidth > innerWidth,
      broken: [...document.images].filter(image => !image.complete || !image.naturalWidth).map(image => image.src),
      small: [...document.querySelectorAll("button")].filter(button => { const box = button.getBoundingClientRect(); return box.width < 44 || box.height < 44; }).map(button => button.textContent),
    }));
    assert.equal(layout.overflow, false, `${width}px overflow`);
    assert.deepEqual(layout.broken, []);
    assert.deepEqual(layout.small, []);
    assert.deepEqual(errors, []);
    assert.equal(await page.locator(".compact-nav").isVisible(), width <= 900);
    if (width <= 900) {
      await page.locator(".compact-nav summary").click();
      assert.equal(await page.locator(".compact-nav").getByRole("link", { name: "Interactive demo" }).isVisible(), true);
      await page.locator(".compact-nav summary").click();
    }
    assert.equal(await page.locator(".scenario-picker").evaluate(element => Boolean(element.closest(".focus-inspector"))), true);
    assert.equal(await page.locator(".detail-reveal").evaluate(element => getComputedStyle(element).animationName), "none");
    const crop = await page.locator(".native-detail-crop").boundingBox();
    assert.ok(crop && crop.height < crop.width, "native proof is a landscape detail crop");
    await page.locator(".atlas-disclosure summary").click();
    for (const scenario of ["Security review required", "Identity missing"]) {
      await page.getByRole("button", { name: scenario, exact: true }).click();
      const statuses = await page.locator(".stage-grid button").evaluateAll(buttons => buttons.map(button => button.dataset.status));
      const positions = [];
      for (let index = 0; index < 9; index += 1) {
        await page.locator(".stage-grid button").nth(index).click();
        assert.equal(await page.locator(".stage-grid button").nth(index).getAttribute("aria-pressed"), "true");
        assert.deepEqual(await page.locator(".stage-grid button").evaluateAll(buttons => buttons.map(button => button.dataset.status)), statuses);
        positions.push(await page.locator(".registry-summary").evaluate(element => element.getBoundingClientRect().top + scrollY));
        assert.equal(await page.locator(".registry-summary img").isVisible(), true);
      }
      if (width >= 1024) assert.ok(Math.max(...positions) - Math.min(...positions) <= 1, `${scenario} shifts registry: ${positions}`);
    }
    await page.getByRole("button", { name: "Identity missing", exact: true }).click();
    assert.equal(await page.locator(".stage-grid button").nth(0).getAttribute("aria-pressed"), "true");
    assert.match(await page.locator(".registry-summary").textContent(), /66/);
    assert.match(await page.locator(".registry-summary").textContent(), /1.28x lift/);
    await page.locator(".stage-grid button").nth(0).press("ArrowRight");
    assert.equal(await page.locator(".stage-grid button").nth(1).getAttribute("aria-pressed"), "true");
    await page.locator(".stage-grid button").nth(1).press("ArrowLeft");
    await page.locator(".inspector-command button").click();
    await page.locator(".inspector-command .copy-status").filter({ hasText: "Command copied." }).waitFor();
    assert.equal(await page.locator(".inspector-command .copy-status").textContent(), "Command copied.");
    await page.evaluate(() => { navigator.clipboard.writeText = async () => { throw new Error("Test clipboard denial"); }; });
    await page.locator(".inspector-command button").click();
    await page.locator(".inspector-command .copy-status").filter({ hasText: "Copy unavailable" }).waitFor();
    assert.match(await page.locator(".inspector-command .copy-status").textContent(), /Copy unavailable/);
    await page.locator(".inspector-command textarea").focus();
    assert.equal(await page.locator(".inspector-command textarea").evaluate(field => field.selectionStart === 0 && field.selectionEnd === field.value.length), true);
    await page.locator(".inspector-command textarea").press("ArrowRight");
    assert.equal(await page.locator(".stage-grid button").nth(0).getAttribute("aria-pressed"), "true");
    await page.getByRole("button", { name: "Security review required", exact: true }).click();
    assert.equal(await page.locator(".stage-grid button").nth(2).getAttribute("aria-pressed"), "true");
    if (width === 375 || width === 1440) {
      await page.locator(".focus-demo").scrollIntoViewIfNeeded();
      await page.locator(".focus-demo").evaluate(element => window.scrollTo({ top: element.getBoundingClientRect().top + scrollY - 110, behavior: "instant" }));
      await page.screenshot({ path: `/private/tmp/skillsbar-site-${width}.png` });
    }
    if (width === 654) await page.locator(".demo-reading").screenshot({ path: "/private/tmp/skillsbar-demo-reading.png" });
    console.log(`pass: ${width}px layout, assets, nine stages, evidence stability, scenario reset, keyboard and clipboard`);
    await context.close();
  }
  const motionContext = await browser.newContext({ viewport: { width: 1440, height: 900 }, reducedMotion: "no-preference" });
  const motionPage = await motionContext.newPage();
  await motionPage.goto(baseURL, { waitUntil: "networkidle" });
  await motionPage.locator(".stage-grid button").nth(0).click();
  assert.equal(await motionPage.locator(".detail-reveal").evaluate(element => getComputedStyle(element).animationDuration), "0.16s");
  await motionContext.close();
  console.log("pass: stage transition enabled when motion is allowed");
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 375, height: 900 } });
  const page = await context.newPage();
  await page.goto(baseURL, { waitUntil: "load" });
  assert.equal(await page.locator(".hero h1").isVisible(), true);
  assert.equal(await page.locator(".hero-technical img").isVisible(), true);
  console.log("pass: no-JavaScript hero");
  await context.close();
} finally { await browser.close(); }
