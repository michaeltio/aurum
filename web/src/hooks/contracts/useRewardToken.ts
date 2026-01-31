"use client";
import { useMemo } from "react";
import { useReadContract } from "wagmi";
import type { Abi } from "viem";

import { RewardTokenABI } from "@repo/contract";

export function useRewardToken(user?: `0x${string}`) {
  const contract = useMemo(
    () => ({
      address: process.env.NEXT_PUBLIC_REWARD_TOKEN_ADDRESS as `0x${string}`,
      abi: RewardTokenABI as Abi,
    }),
    []
  );

  return useReadContract({
    ...contract,
    functionName: "balanceOf",
    args: user ? [user] : undefined,
    query: {
      enabled: !!user,
    },
  });
}
