import assert from "node:assert/strict";
import { mkdir, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const baseURL = process.argv[2] ?? "http://localhost:3008/";
const artifactDir = path.resolve(process.env.BROWSER_ARTIFACT_DIR ?? fileURLToPath(new URL("../outputs/browser", import.meta.url)));
await mkdir(artifactDir, { recursive: true });
await rm(path.join(artifactDir, "failure.png"), { force: true });
const browser = await chromium.launch({ headless: true, channel: "chrome" });
let activePage;
try {
  for (const width of [375, 654, 837, 900, 1024, 1440]) {
    const context = await browser.newContext({ viewport: { width, height: 900 }, reducedMotion: "reduce", permissions: ["clipboard-read", "clipboard-write"] });
    const page = await context.newPage();
    activePage = page;
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));
    await page.goto(baseURL, { waitUntil: "networkidle" });
    if (width === 1440) await page.screenshot({ path: path.join(artifactDir, "skillsbar-site-hero.png") });
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

    /** Return selected stage indices and focused stage index (-1 if no stage button is active element). */
    async function stageState() {
      return page.evaluate(() => {
        const buttons = [...document.querySelectorAll(".stage-grid button")];
        const selected = buttons.reduce((acc, btn, i) => { if (btn.getAttribute("aria-pressed") === "true") acc.push(i); return acc; }, []);
        const focused = buttons.indexOf(document.activeElement);
        return { selected, focused };
      });
    }

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

    // Home/End assertions for both scenarios
    const scenarioDefaults = { "Security review required": 2, "Identity missing": 0 };
    for (const [scenarioLabel, defaultIndex] of Object.entries(scenarioDefaults)) {
      await page.getByRole("button", { name: scenarioLabel, exact: true }).click();
      const statuses = await page.locator(".stage-grid button").evaluateAll(buttons => buttons.map(button => button.dataset.status));
      const nextRequired = await page.locator(".gate-context").textContent();
      const registryText = await page.locator(".registry-summary").textContent();

      // Focus an interior stage (Gate 5, index 4)
      await page.locator(".stage-grid button").nth(4).focus();

      // Press Home: expect stage 1 (index 0) selected and focused
      await page.keyboard.press("Home");
      await page.waitForFunction(() => {
        const buttons = [...document.querySelectorAll(".stage-grid button")];
        return buttons[0].getAttribute("aria-pressed") === "true" && document.activeElement === buttons[0];
      }, { timeout: 2000 });
      const afterHome = await stageState();
      assert.deepEqual(afterHome.selected, [0], `${scenarioLabel}: Home should select stage 1`);
      assert.equal(afterHome.focused, 0, `${scenarioLabel}: Home should focus stage 1`);
      assert.deepEqual(await page.locator(".stage-grid button").evaluateAll(buttons => buttons.map(button => button.dataset.status)), statuses, `${scenarioLabel}: Home must not change statuses`);
      assert.equal(await page.locator(".gate-context").textContent(), nextRequired, `${scenarioLabel}: Home must not change next-required`);
      assert.equal(await page.locator(".registry-summary").textContent(), registryText, `${scenarioLabel}: Home must not change registry evidence`);

      // Press End: expect stage 9 (index 8) selected and focused
      await page.keyboard.press("End");
      await page.waitForFunction(() => {
        const buttons = [...document.querySelectorAll(".stage-grid button")];
        return buttons[8].getAttribute("aria-pressed") === "true" && document.activeElement === buttons[8];
      }, { timeout: 2000 });
      const afterEnd = await stageState();
      assert.deepEqual(afterEnd.selected, [8], `${scenarioLabel}: End should select stage 9`);
      assert.equal(afterEnd.focused, 8, `${scenarioLabel}: End should focus stage 9`);
      assert.deepEqual(await page.locator(".stage-grid button").evaluateAll(buttons => buttons.map(button => button.dataset.status)), statuses, `${scenarioLabel}: End must not change statuses`);
      assert.equal(await page.locator(".gate-context").textContent(), nextRequired, `${scenarioLabel}: End must not change next-required`);
      assert.equal(await page.locator(".registry-summary").textContent(), registryText, `${scenarioLabel}: End must not change registry evidence`);

      // Reset via scenario button and assert default selection
      await page.getByRole("button", { name: scenarioLabel, exact: true }).click();
      assert.equal(await page.locator(".stage-grid button").nth(defaultIndex).getAttribute("aria-pressed"), "true", `${scenarioLabel}: reset should select default stage ${defaultIndex + 1}`);
    }

    await page.getByRole("button", { name: "Identity missing", exact: true }).click();
    assert.equal(await page.locator(".stage-grid button").nth(0).getAttribute("aria-pressed"), "true");
    assert.match(await page.locator(".registry-summary").textContent(), /66/);
    assert.match(await page.locator(".registry-summary").textContent(), /1.28x lift/);
    await page.locator(".stage-grid button").nth(0).press("ArrowRight");
    assert.equal(await page.locator(".stage-grid button").nth(1).getAttribute("aria-pressed"), "true");
    await page.locator(".stage-grid button").nth(1).press("ArrowLeft");
    // Assert ArrowLeft result: Identity Gate 2 -> Gate 1
    assert.equal(await page.locator(".stage-grid button").nth(0).getAttribute("aria-pressed"), "true", "ArrowLeft from Gate 2 should select Gate 1");
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
    // Textarea Home/End must not change stage selection
    const selectedBeforeTextareaNav = await page.locator(".stage-grid button").evaluateAll(buttons => buttons.findIndex(b => b.getAttribute("aria-pressed") === "true"));
    await page.locator(".inspector-command textarea").press("Home");
    assert.equal(await page.locator(".stage-grid button").evaluateAll(buttons => buttons.findIndex(b => b.getAttribute("aria-pressed") === "true")), selectedBeforeTextareaNav, "textarea Home must not change stage selection");
    await page.locator(".inspector-command textarea").press("End");
    assert.equal(await page.locator(".stage-grid button").evaluateAll(buttons => buttons.findIndex(b => b.getAttribute("aria-pressed") === "true")), selectedBeforeTextareaNav, "textarea End must not change stage selection");
    await page.getByRole("button", { name: "Security review required", exact: true }).click();
    assert.equal(await page.locator(".stage-grid button").nth(2).getAttribute("aria-pressed"), "true");
    if (width === 375 || width === 1440) {
      await page.locator(".focus-demo").scrollIntoViewIfNeeded();
      await page.locator(".focus-demo").evaluate(element => window.scrollTo({ top: element.getBoundingClientRect().top + scrollY - 110, behavior: "instant" }));
      await page.screenshot({ path: path.join(artifactDir, `skillsbar-site-${width}.png`) });
    }
    if (width === 654) await page.locator(".demo-reading").screenshot({ path: path.join(artifactDir, "skillsbar-demo-reading.png") });
    console.log(`pass: ${width}px layout, assets, nine stages, evidence stability, scenario reset, keyboard and clipboard`);
    await context.close();
  }
  const motionContext = await browser.newContext({ viewport: { width: 1440, height: 900 }, reducedMotion: "no-preference" });
  const motionPage = await motionContext.newPage();
  activePage = motionPage;
  await motionPage.goto(baseURL, { waitUntil: "networkidle" });
  await motionPage.locator(".stage-grid button").nth(0).click();
  assert.equal(await motionPage.locator(".detail-reveal").evaluate(element => getComputedStyle(element).animationDuration), "0.16s");
  await motionContext.close();
  console.log("pass: stage transition enabled when motion is allowed");
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 375, height: 900 } });
  const page = await context.newPage();
  activePage = page;
  await page.goto(baseURL, { waitUntil: "load" });
  assert.equal(await page.locator(".hero h1").isVisible(), true);
  assert.equal(await page.locator(".hero-technical img").isVisible(), true);
  console.log("pass: no-JavaScript hero");
  await context.close();
} catch (error) {
  if (activePage && !activePage.isClosed()) {
    await activePage.screenshot({ path: path.join(artifactDir, "failure.png"), fullPage: true })
      .catch(screenshotError => console.error("Failure screenshot unavailable:", screenshotError.message));
  }
  throw error;
} finally { await browser.close(); }
