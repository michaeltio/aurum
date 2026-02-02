import { network } from "hardhat";
import type { Abi } from "viem";

import StakingABI from "@shared/abi/Staking.abi.json";
import RewardToken from "@shared/abi/RewardToken.abi.json";
import Addresses from "@shared/address/sepolia/addresses.json";

const FUND_AMOUNT = BigInt("1000000000000000000000");

async function main() {
  const { viem } = await network.connect({
    network: "sepolia",
  });

  console.log("Connected to sepolia");

  const publicClient = await viem.getPublicClient();
  const [walletClient] = await viem.getWalletClients();

  const account = walletClient.account.address;
  console.log("Using account:", account);

  console.log("Approving reward token...");

  const approveHash = await walletClient.writeContract({
    address: Addresses.RewardToken as `0x${string}`,
    abi: RewardToken as Abi,
    functionName: "approve",
    args: [Addresses.Staking, FUND_AMOUNT],
  });

  console.log("Approve tx hash:", approveHash);

  await publicClient.waitForTransactionReceipt({
    hash: approveHash,
  });

  console.log("Approve success");

  console.log("Funding rewards...");

  const fundHash = await walletClient.writeContract({
    address: Addresses.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "fundRewards",
    args: [FUND_AMOUNT],
  });

  console.log("Fund tx hash:", fundHash);

  await publicClient.waitForTransactionReceipt({
    hash: fundHash,
  });

  console.log("Rewards funded successfully");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
