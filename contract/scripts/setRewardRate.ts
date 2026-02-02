import { network } from "hardhat";
import type { Abi } from "viem";

import StakingABI from "@shared/abi/Staking.abi.json";
import Addresses from "@shared/address/sepolia/addresses.json";

const NEW_REWARD_RATE = 1000000000000000n;

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
    functionName: "setRewardRate",
    args: [NEW_REWARD_RATE],
  });

  console.log("Transaction hash:", hash);

  await publicClient.waitForTransactionReceipt({ hash });

  console.log("rewardRate updated");

  const rewardRate = await publicClient.readContract({
    address: Addresses.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "rewardRate",
  });

  console.log("Current rewardRate:", (rewardRate as bigint).toString());
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
