"use client";
import { useRewardRate, useTotalStaked } from "@/hooks/contracts/useStaking";
import { formatEther } from "viem";

export function DashboardRewardRate() {
  const { data: rewardRate, isError, isLoading } = useRewardRate();

  if (isLoading) {
    return <p className="text-4xl md:text-5xl font-bold">Loading...</p>;
  }

  if (isError || rewardRate === undefined) {
    return <p className="text-4xl md:text-5xl font-bold">Error</p>;
  }

  return <p className="text-4xl md:text-5xl font-bold">{rewardRate}</p>;
}

export function DashboardTotalStaked() {
  const { data: totalStaked, isError, isLoading } = useTotalStaked();

  if (isLoading) {
    return <p className="text-4xl md:text-5xl font-bold">Loading...</p>;
  }

  if (isError || totalStaked === undefined) {
    return <p className="text-4xl md:text-5xl font-bold">Error</p>;
  }

  return <p className="text-4xl md:text-5xl font-bold">{totalStaked}</p>;
}
