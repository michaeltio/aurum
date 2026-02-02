"use client";

import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { useRewardEndTime } from "@/hooks/contracts/useStaking";

export default function StakingStatus() {
  const { data: rewardEndTime, isLoading, isError, error } = useRewardEndTime();

  if (isLoading) {
    return (
      <Card className="p-6">
        <p className="text-sm text-muted-foreground">Loading staking status…</p>
      </Card>
    );
  }

  if (isError) {
    return (
      <Card className="p-6">
        <p className="text-sm text-red-500">Error: {error?.message}</p>
      </Card>
    );
  }

  if (!rewardEndTime)
    return (
      <Card className="p-6">
        <p className="text-sm text-muted-foreground">
          Staking status not available
        </p>
      </Card>
    );

  const endTimeMs = Number(rewardEndTime) * 1000;
  const endDate = new Date(endTimeMs);
  const isEnded = Date.now() > endTimeMs;

  const formattedDateTime = endDate.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });

  return (
    <Card className="p-6 border border-border bg-card">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-muted-foreground mb-2">Staking Status</p>

          <Badge variant={isEnded ? "destructive" : "default"}>
            {isEnded ? "Ended" : "Active"}
          </Badge>
        </div>

        <div className="text-right">
          <p className="text-xs text-muted-foreground mb-1">
            {isEnded ? "Ended at" : "Ends at"}
          </p>
          <p className="font-mono text-sm text-foreground">
            {formattedDateTime}
          </p>
        </div>
      </div>
    </Card>
  );
}
