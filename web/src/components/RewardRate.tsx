"use client";

import { Card } from "@/components/ui/card";
import { useRewardRate } from "@/hooks/contracts/useStaking";
import { formatUnits } from "viem";

export default function RewardRate() {
  const { data: rewardRate, isLoading, error } = useRewardRate();

  if (isLoading) {
    return (
      <Card className="p-6">
        <p className="text-sm text-muted-foreground">Loading reward rate…</p>
      </Card>
    );
  }
  if (error) {
    return (
      <Card className="p-6">
        <p className="text-sm text-red-500">Error: {error.message}</p>
      </Card>
    );
  }

  if (rewardRate === undefined) return null;
  const rewardRateValue = rewardRate as bigint | undefined;

  return (
    <Card className="p-6 border border-border bg-card">
      <p className="text-sm text-muted-foreground mb-2">Reward Rate</p>
      <p className="text-3xl font-bold text-foreground">
        {formatUnits(rewardRateValue || 0n, 18)}
      </p>
      <p className="text-xs text-muted-foreground mt-2">per second</p>
    </Card>
  );
}
