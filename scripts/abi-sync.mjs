import fs from "fs";
import path from "path";

const DEST = "shared/abi";

fs.mkdirSync(DEST, { recursive: true });

for (const sol of fs.readdirSync(OUT_DIR)) {
  if (!sol.endsWith(".sol")) continue;

  const name = sol.replace(".sol", "");
  const artifactPath = path.join(OUT_DIR, sol, `${name}.json`);

  if (!fs.existsSync(artifactPath)) continue;

  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  fs.writeFileSync(
    path.join(DEST, `${name}.abi.json`),
    JSON.stringify(artifact.abi, null, 2),
  );

  console.log(`${name} Synced`);
}
