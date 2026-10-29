import readline from "node:readline";
import { galjp } from "galjp";

const input = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });

for await (const line of input) {
  if (!line) continue;
  try {
    const request = JSON.parse(line);
    const options = request.options ?? {};
    const result = galjp(request.input ?? "", {
      layers: options.layers,
      splitPolicy: options.splitPolicy,
      variant: options.variant,
      styleStandalone: options.styleStandalone,
      maxDepth: options.maxDepth,
      seed: options.seed || undefined,
      preserve: options.preserveUrlsAndEmoji ? undefined : false,
      dictionary: options.dictionary ?? {},
    });
    process.stdout.write(JSON.stringify({ result }) + "\n");
  } catch (error) {
    process.stdout.write(JSON.stringify({ error: String(error) }) + "\n");
  }
}
