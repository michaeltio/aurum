"use client";
import { Card } from "@/components/ui/card";

import { useStakedBalance } from "@/hooks/contracts/useStaking";
import { useConnection } from "wagmi";
import { formatUnits } from "viem";

export default function StakedBalance() {
  const { address } = useConnection();
  const { data: stakedBalance, isLoading, error } = useStakedBalance(address);
  console.log("StakedBalance rendered", stakedBalance);
  if (isLoading) {
    return (
      <Card className="p-6">
        <p className="text-sm text-muted-foreground">Loading staked balance…</p>
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

  if (stakedBalance === undefined) return null;

  const stakedBalanceValue = stakedBalance as bigint | undefined;

  return (
    <Card className="p-6 border border-border bg-card">
      <p className="text-sm text-muted-foreground mb-2">Staked Balance</p>
      <p className="text-3xl font-bold text-primary">
        {formatUnits(stakedBalanceValue || 0n, 18)}
      </p>
      <p className="text-xs text-muted-foreground mt-2">Tokens</p>
    </Card>
  );
}
