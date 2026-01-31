"use client";

import { Card } from "@/components/ui/card";
import { useTotalStaked } from "@/hooks/contracts/useStaking";
import { formatUnits } from "viem";

export default function TotalStaked() {
  const { data: totalStaked, isLoading, error } = useTotalStaked();

  if (isLoading) {
    return (
      <Card className="p-6">
        <p className="text-sm text-muted-foreground">Loading total staked…</p>
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
  if (totalStaked === undefined) return null;

  const totalStakedValue = totalStaked as bigint | undefined;

  return (
    <Card className="p-6 border border-border bg-card">
      <p className="text-sm text-muted-foreground mb-2">Total Staked</p>
      <p className="text-3xl font-bold text-foreground">
        {formatUnits(totalStakedValue || 0n, 18)}
      </p>
      <p className="text-xs text-muted-foreground mt-2">In Pool</p>
    </Card>
  );
}
