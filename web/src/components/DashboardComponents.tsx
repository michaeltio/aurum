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

  return (
    <p className="text-4xl md:text-5xl font-bold">
      {Number(formatEther(rewardRate as bigint)).toFixed(2)}
    </p>
  );
}

export function DashboardTotalStaked() {
  const { data: totalStaked, isError, isLoading } = useTotalStaked();

  if (isLoading) {
    return <p className="text-4xl md:text-5xl font-bold">Loading...</p>;
  }

  if (isError || totalStaked === undefined) {
    return <p className="text-4xl md:text-5xl font-bold">Error</p>;
  }

  return (
    <p className="text-4xl md:text-5xl font-bold">
      {Number(formatEther(totalStaked as bigint)).toFixed(2)}
    </p>
  );
}
