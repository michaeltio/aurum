"use client";

import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import type { Abi } from "viem";

import StakeTokenABI from "@shared/abi/StakeToken.abi.json";

export function useBalanceOf(user?: `0x${string}`) {
  return useReadContract({
    address: process.env.NEXT_PUBLIC_STAKE_TOKEN_ADDRESS as `0x${string}`,
    abi: StakeTokenABI as Abi,
    functionName: "balanceOf",
    args: user ? [user] : undefined,
    query: {
      enabled: !!user,
    },
  });
}

export function useAllowance(user?: `0x${string}`, spender?: `0x${string}`) {
  return useReadContract({
    address: process.env.NEXT_PUBLIC_STAKE_TOKEN_ADDRESS as `0x${string}`,
    abi: StakeTokenABI as Abi,
    functionName: "allowance",
    args: user && spender ? [user, spender] : undefined,
    query: {
      enabled: !!user && !!spender,
    },
  });
}

export function useApprove() {
  const stakeTokenAddress = process.env
    .NEXT_PUBLIC_STAKE_TOKEN_ADDRESS as `0x${string}`;

  const {
    writeContract,
    data: hash,
    isPending,
    isError,
    error,
  } = useWriteContract();

  const {
    isLoading: isConfirming,
    isSuccess: isConfirmed,
    isError: isFailed,
  } = useWaitForTransactionReceipt({
    hash,
  });

  const approve = (spender: `0x${string}`, amount: bigint) => {
    writeContract({
      address: stakeTokenAddress,
      abi: StakeTokenABI as Abi,
      functionName: "approve",
      args: [spender, amount],
    });
  };

  return {
    approve,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    isFailed,
    isError,
    error,
  };
}
