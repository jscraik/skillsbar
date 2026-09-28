import assert from "node:assert/strict";
import { chromium } from "playwright-core";

const baseURL = process.argv[2] ?? "http://localhost:3000/";
const browser = await chromium.launch({ headless: true, channel: "chrome" });

try {
  for (const width of [375, 390, 768, 1440]) {
    const context = await browser.newContext({
      viewport: { width, height: 900 },
      reducedMotion: "reduce",
      permissions: ["clipboard-read", "clipboard-write"],
    });
    const page = await context.newPage();
    const pageErrors = [];
    page.on("pageerror", (error) => pageErrors.push(error.message));
    await page.goto(baseURL, { waitUntil: "networkidle" });

    const layout = await page.evaluate(() => ({
      overflow: document.documentElement.scrollWidth > innerWidth,
      brokenImages: [...document.images]
        .filter((image) => image.complete && image.naturalWidth === 0)
        .map((image) => image.src),
      smallButtons: [...document.querySelectorAll("button")]
        .filter((button) => {
          const box = button.getBoundingClientRect();
          return box.width < 44 || box.height < 44;
        })
        .map((button) => button.textContent?.trim()),
      cameraDuration: getComputedStyle(document.querySelector(".rail-world")).transitionDuration,
    }));
    assert.equal(layout.overflow, false, `${width}px page overflows horizontally`);
    assert.deepEqual(layout.brokenImages, [], `${width}px page has broken images`);
    assert.deepEqual(layout.smallButtons, [], `${width}px page has undersized buttons`);
    assert.deepEqual(pageErrors, [], `${width}px page has JavaScript errors`);
    assert.equal(layout.cameraDuration, "0s", `${width}px reduced-motion camera still animates`);

    if (width === 390) {
      await page.keyboard.press("Tab");
      assert.equal(await page.locator(".skip-link").evaluate((link) => link === document.activeElement), true);
      await page.keyboard.press("Enter");
      assert.match(page.url(), /#top$/);

      await page.locator(".atlas-disclosure summary").click();
      assert.equal(await page.locator(".atlas-disclosure").evaluate((details) => details.open), true);
      await page.locator(".atlas-disclosure summary").click();

      await page.locator(".proof-command button").click();
      await page.locator(".proof-command .copy-status:not(:empty)").waitFor();
      assert.equal(await page.locator(".proof-command .copy-status").textContent(), "Command copied.");

      const tabs = page.locator(".beat-tabs button");
      await page.locator(".walkthrough-shell").focus();
      await page.keyboard.press("ArrowRight");
      assert.equal(await tabs.nth(1).getAttribute("aria-pressed"), "true");

      await page.locator(".command-bar code").focus();
      for (const key of ["ArrowRight", "Space", "r"]) {
        await page.keyboard.press(key);
        assert.equal(await tabs.nth(1).getAttribute("aria-pressed"), "true", `command focus changed beat on ${key}`);
      }
      await page.locator(".walkthrough-shell").focus();
      await page.keyboard.press("ArrowRight");
      assert.equal(await tabs.nth(2).getAttribute("aria-pressed"), "true");
    }

    console.log(`pass: ${width}px layout, assets, errors, motion${width === 390 ? ", focus, copy, controls" : ""}`);
    await context.close();
  }

  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 900 } });
  const page = await context.newPage();
  await page.goto(baseURL, { waitUntil: "load" });
  assert.equal(await page.locator(".hero h1").isVisible(), true, "hero is hidden without JavaScript");
  console.log("pass: no-JavaScript hero");
  await context.close();
} finally {
  await browser.close();
}
