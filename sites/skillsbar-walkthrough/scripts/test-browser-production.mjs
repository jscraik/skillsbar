import { spawn } from "node:child_process";
import { closeSync, openSync } from "node:fs";
import { mkdir, readFile } from "node:fs/promises";
import path from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { fileURLToPath } from "node:url";

const siteRoot = fileURLToPath(new URL("../", import.meta.url));
const output = path.resolve(process.env.BROWSER_ARTIFACT_DIR ?? path.join(siteRoot, "outputs/browser"));
const baseURL = "http://127.0.0.1:3008/";
await mkdir(output, { recursive: true });
const serverLog = path.join(output, "server.log");
const log = openSync(serverLog, "w");
const children = [];
let interrupted = false;

function start(args, stdio) {
  const child = spawn("npm", args, { cwd: siteRoot, detached: true, stdio, env: { ...process.env, BROWSER_ARTIFACT_DIR: output } });
  const run = { child, error: null, finished: false };
  run.done = new Promise(resolve => {
    child.once("error", error => { run.error = error; run.finished = true; resolve(null); });
    child.once("exit", code => { run.finished = true; resolve(code); });
  });
  children.push(run);
  return run;
}

function signalGroup(run, signal) {
  if (!run.child.pid) return;
  try { process.kill(-run.child.pid, signal); }
  catch (error) { if (error.code !== "ESRCH") throw error; }
}

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    interrupted = true;
    for (const run of children) signalGroup(run, "SIGTERM");
  });
}

try {
  // Refuse to test an unrelated server already using the fixed smoke-test port.
  let occupied = false;
  try { occupied = Boolean(await fetch(baseURL, { signal: AbortSignal.timeout(1000) })); } catch {}
  if (occupied) throw new Error("Port 3008 already serves HTTP; stop that server before this isolated test.");
  const server = start(["run", "start", "--", "--port", "3008"], ["ignore", log, log]);
  const deadline = Date.now() + 60_000;
  let ready = false;
  while (!ready && Date.now() < deadline) {
    if (server.finished || interrupted) throw server.error ?? new Error("Production server exited before readiness.");
    try { ready = (await fetch(baseURL, { signal: AbortSignal.timeout(2000) })).ok; } catch {}
    if (!ready) await delay(250);
  }
  if (!ready) throw new Error("Production server did not become ready within 60 seconds.");
  const tests = start(["run", "test:browser", "--", baseURL], "inherit");
  const code = await Promise.race([
    tests.done,
    delay(180_000, undefined, { ref: false }).then(() => { throw new Error("Browser smoke exceeded 180 seconds."); }),
  ]);
  if (tests.error) throw tests.error;
  if (code !== 0 || interrupted) throw new Error(`Browser smoke failed (exit ${code}).`);
} catch (error) {
  console.error(error);
  console.error((await readFile(serverLog, "utf8")).slice(-12_000));
  process.exitCode = 1;
} finally {
  for (const run of children) signalGroup(run, "SIGTERM");
  await Promise.race([Promise.all(children.map(run => run.done)), delay(5000, undefined, { ref: false })]);
  for (const run of children) signalGroup(run, "SIGKILL");
  closeSync(log);
}
