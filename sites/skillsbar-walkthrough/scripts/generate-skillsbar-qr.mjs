import { mkdir } from "node:fs/promises";
import { resolve } from "node:path";
import QRCode from "qrcode";

const repositoryURL = "https://github.com/jscraik/skillsbar";
const outputDirectory = resolve(process.argv[2] ?? "public");

await mkdir(outputDirectory, { recursive: true });

for (const size of [1024, 512]) {
  const filename = `skillsbar-repo-qr-${size}.png`;
  const outputPath = resolve(outputDirectory, filename);
  await QRCode.toFile(outputPath, repositoryURL, {
    errorCorrectionLevel: "H",
    margin: 4,
    width: size,
    color: { dark: "#000000ff", light: "#ffffffff" },
  });
  console.log(`GENERATED ${filename} ${repositoryURL}`);
}
