import { network } from "hardhat";
import type { Abi } from "viem";

import StakingABI from "@shared/abi/Staking.abi.json";
import Addresses from "@shared/address/sepolia/addresses.json";

const NEW_REWARD_END_TIME = BigInt(
  Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
);

async function main() {
  const { viem } = await network.connect({
    network: "sepolia",
  });

  console.log("Connected to sepolia");

  const publicClient = await viem.getPublicClient();
  const [walletClient] = await viem.getWalletClients();

  console.log("Using account:", walletClient.account.address);

  const hash = await walletClient.writeContract({
    address: Addresses.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "setRewardEndTime",
    args: [NEW_REWARD_END_TIME],
  });

  console.log("Transaction hash:", hash);

  await publicClient.waitForTransactionReceipt({ hash });

  console.log("rewardEndTime updated");

  const rewardEndTime = await publicClient.readContract({
    address: Addresses.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "rewardEndTime",
  });

  console.log(
    "Current rewardEndTime:",
    (rewardEndTime as bigint).toString(),
    `(UTC: ${new Date(Number(rewardEndTime) * 1000).toISOString()})`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
