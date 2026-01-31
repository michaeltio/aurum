"use client";

import { Card } from "@/components/ui/card";
import { usePendingRewards } from "@/hooks/contracts/useStaking";
import { useConnection } from "wagmi";
import { formatUnits } from "viem";

export default function PendingRewards() {
  const { address } = useConnection();
  const { data: pendingRewards, isLoading, error } = usePendingRewards(address);
  if (isLoading) {
    return (
      <Card className="p-6">
        <p className="text-sm text-muted-foreground">
          Loading pending rewards…
        </p>
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
  if (pendingRewards === undefined) return null;

  const pendingRewardsValue = pendingRewards as bigint | undefined;

  return (
    <Card className="p-6 border border-border bg-card">
      <p className="text-sm text-muted-foreground mb-2">Pending Rewards</p>
      <p className="text-3xl font-bold text-accent">
        {" "}
        {formatUnits(pendingRewardsValue || 0n, 18)}
      </p>
      <p className="text-xs text-muted-foreground mt-2">Tokens</p>
    </Card>
  );
}
