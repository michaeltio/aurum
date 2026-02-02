import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
console.log(__dirname);

const IGNITION_DIR = path.resolve(
  __dirname,
  "../contract/ignition/deployments",
);

const OUTPUT_BASE = path.resolve(__dirname, "../shared/address");

const CHAIN_MAP = {
  1: "mainnet",
  11155111: "sepolia",
  5: "goerli",
  137: "polygon",
  31337: "localhost",
};

if (!fs.existsSync(IGNITION_DIR)) {
  console.error("Ignition deployments folder not found");
  process.exit(1);
}

fs.mkdirSync(OUTPUT_BASE, { recursive: true });

for (const deployment of fs.readdirSync(IGNITION_DIR)) {
  if (!deployment.startsWith("chain-")) continue;

  const chainId = Number(deployment.replace("chain-", ""));
  if (Number.isNaN(chainId)) continue;

  const network = CHAIN_MAP[chainId] ?? `chain-${chainId}`;

  const src = path.join(IGNITION_DIR, deployment, "deployed_addresses.json");

  if (!fs.existsSync(src)) {
    console.warn(`No deployed_addresses.json for ${deployment}`);
    continue;
  }

  const raw = JSON.parse(fs.readFileSync(src, "utf8"));

  const addresses = {};

  for (const [key, value] of Object.entries(raw)) {
    const name = key.includes("#") ? key.split("#")[1] : key;

    addresses[name] = value;
  }

  const outDir = path.join(OUTPUT_BASE, network);
  fs.mkdirSync(outDir, { recursive: true });

  fs.writeFileSync(
    path.join(outDir, "addresses.json"),
    JSON.stringify(addresses, null, 2),
  );

  console.log(`Synced ${network} (chainId=${chainId})`);
}

console.log("All networks synced");
