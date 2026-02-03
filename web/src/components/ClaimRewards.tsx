"use client";

import { useEffect } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  usePendingRewards,
  useClaimRewards,
} from "@/hooks/contracts/useStaking";
import { useConnection } from "wagmi";
import { toast } from "sonner";

export default function ClaimRewards() {
  const { address, isConnected } = useConnection();

  const {
    claimRewards,
    isPending,
    isConfirming,
    isConfirmed,
    isError,
    error: claimError,
  } = useClaimRewards();

  const {
    data: pendingRewards,
    isLoading,
    error: pendingError,
  } = usePendingRewards(address);

  const rewards = pendingRewards ?? 0n;
  const isDisabled =
    !isConnected || rewards === 0n || isPending || isConfirming;

  const handleClaim = () => {
    claimRewards();
    toast.loading("Transaction submitted...", {
      id: "claim-rewards",
    });
  };

  useEffect(() => {
    if (isConfirmed) {
      toast.success("Rewards claimed successfully", {
        id: "claim-rewards",
      });
    }
  }, [isConfirmed]);

  useEffect(() => {
    if (isError) {
      toast.error(claimError?.message ?? "Transaction failed", {
        id: "claim-rewards",
      });
    }
  }, [isError, claimError]);

  return (
    <Card className="p-6 border border-border bg-card">
      <div className="space-y-4">
        <div>
          <h4 className="text-lg font-semibold">Claim Rewards</h4>
          <p className="text-sm text-muted-foreground">
            Harvest your accumulated rewards
          </p>
        </div>

        <div className="flex items-end justify-between">
          <div>
            <p className="text-xs text-muted-foreground mb-1">
              Available to Claim
            </p>
            <p className="text-2xl font-bold text-accent">
              {isLoading ? "..." : rewards.toString()}
            </p>
            <p className="text-xs text-muted-foreground mt-1">Tokens</p>
          </div>

          <Button
            size="lg"
            disabled={isDisabled}
            onClick={handleClaim}
            className="bg-accent text-accent-foreground hover:opacity-90 disabled:opacity-50"
          >
            {isPending || isConfirming ? "Claiming..." : "Claim"}
          </Button>
        </div>

        {pendingError && (
          <p className="text-sm text-destructive">Failed to load rewards</p>
        )}
      </div>
    </Card>
  );
}
