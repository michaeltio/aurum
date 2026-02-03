"use client";

import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";

import SepoliaAddress from "@shared/address/sepolia/addresses.json";
import { type Abi, formatUnits } from "viem";

import StakingABI from "@shared/abi/Staking.abi.json";

export function useRewardEndTime() {
  return useReadContract({
    address: SepoliaAddress.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "rewardEndTime",
  });
}

export function useStakedBalance(user?: `0x${string}`) {
  return useReadContract({
    address: SepoliaAddress.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "getStakedBalance",
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

export function usePendingRewards(user?: `0x${string}`) {
  return useReadContract({
    address: SepoliaAddress.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "getPendingRewards",
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

export function useTotalStaked() {
  return useReadContract({
    address: SepoliaAddress.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "totalStaked",
    query: {
      select: (data) => {
        const value = formatUnits((data as bigint) ?? 0n, 18);
        const [int, dec = ""] = value.split(".");
        return dec ? `${int}.${dec.slice(0, 4)}` : int;
      },
    },
  });
}

export function useRewardRate() {
  return useReadContract({
    address: SepoliaAddress.Staking as `0x${string}`,
    abi: StakingABI as Abi,
    functionName: "rewardRate",
    query: {
      select: (data) => {
        const value = formatUnits((data as bigint) ?? 0n, 18);
        const [int, dec = ""] = value.split(".");
        return dec ? `${int}.${dec.slice(0, 4)}` : int;
      },
    },
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
      address: SepoliaAddress.Staking as `0x${string}`,
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
      address: SepoliaAddress.Staking as `0x${string}`,
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
      address: SepoliaAddress.Staking as `0x${string}`,
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
      address: SepoliaAddress.Staking as `0x${string}`,
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
