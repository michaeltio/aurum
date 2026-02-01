"use client";

import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import type { Abi } from "viem";

import StakingABI from "@shared/abi/Staking.abi.json";

export function useRewardEndTime() {
  return useReadContract({
    address: process.env.NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "rewardEndTime",
  });
}

export function useStakedBalance(user?: `0x${string}`) {
  return useReadContract({
    address: process.env.NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "getStakedBalance",
    args: user ? [user] : undefined,
    query: {
      enabled: !!user,
    },
  });
}

export function usePendingRewards(user?: `0x${string}`) {
  return useReadContract({
    address: process.env.NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "getPendingRewards",
    args: user ? [user] : undefined,
    query: {
      enabled: !!user,
    },
  });
}

export function useTotalStaked() {
  return useReadContract({
    address: process.env.NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "totalStaked",
  });
}

export function useRewardRate() {
  return useReadContract({
    address: process.env.NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "rewardRate",
  });
}

export function useStake() {
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

  const stake = (amount: bigint) => {
    writeContract({
      address: process.env
        .NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
      abi: StakingABI as Abi,
      functionName: "stake",
      args: [amount],
    });
  };

  return {
    stake,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    isFailed,
    isError,
    error,
  };
}

export function useWithdraw() {
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

  const withdraw = (amount: bigint) => {
    writeContract({
      address: process.env
        .NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
      abi: StakingABI as Abi,
      functionName: "withdraw",
      args: [amount],
    });
  };

  return {
    withdraw,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    isFailed,
    isError,
    error,
  };
}

export function useEmergencyWithdraw() {
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

  const emergencyWithdraw = () => {
    writeContract({
      address: process.env
        .NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
      abi: StakingABI as Abi,
      functionName: "emergencyWithdraw",
    });
  };

  return {
    emergencyWithdraw,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    isFailed,
    isError,
    error,
  };
}

export function useClaimRewards() {
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

  const claimRewards = () => {
    writeContract({
      address: process.env
        .NEXT_PUBLIC_STAKING_CONTRACT_ADDRESS as `0x${string}`,
      abi: StakingABI as Abi,
      functionName: "claimRewards",
    });
  };

  return {
    claimRewards,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    isFailed,
    isError,
    error,
  };
}
