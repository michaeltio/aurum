import { network } from "hardhat";
import type { Abi } from "viem";

import StakingTokenABI from "@shared/abi/StakeToken.abi.json";
import Addresses from "@shared/address/sepolia/addresses.json";

const TO_ADDRESS = "0x3160C6cfCE8907E9eeD512396b91659a184C97D5";

const TRANSFER_AMOUNT = BigInt("100000000000000000000");

async function main() {
  const { viem } = await network.connect({
    network: "sepolia",
  });

  console.log("Connected to sepolia");

  const publicClient = await viem.getPublicClient();
  const [walletClient] = await viem.getWalletClients();

  console.log("Using account:", walletClient.account.address);

  console.log("Transferring token...");

  const hash = await walletClient.writeContract({
    address: Addresses.StakeToken as `0x${string}`,
    abi: StakingTokenABI as Abi,
    functionName: "transfer",
    args: [TO_ADDRESS, TRANSFER_AMOUNT],
  });

  console.log("Transfer tx hash:", hash);

  await publicClient.waitForTransactionReceipt({
    hash,
  });

  console.log("Token transferred successfully");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
