"use client";
import { useMemo } from "react";
import { useReadContract } from "wagmi";
import { type Abi, formatUnits } from "viem";

import RewardTokenABI from "@shared/abi/RewardToken.abi.json";
import SepoliaAddress from "@shared/address/sepolia/addresses.json";

export function useRewardToken(user?: `0x${string}`) {
  const contract = useMemo(
    () => ({
      address: SepoliaAddress.RewardToken as `0x${string}`,
      abi: RewardTokenABI as Abi,
    }),
    [],
  );

  return useReadContract({
    ...contract,
    functionName: "balanceOf",
    args: user ? [user] : undefined,
    query: {
      enabled: !!user,
      select: (data) => {
        const value = formatUnits((data as bigint) ?? 0n, 18);
        const [int, dec = ""] = value.split(".");
        return dec ? `${int}.${dec.slice(0, 4)}` : int;
      },
    },
  });
}
