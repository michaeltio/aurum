"use client";

import { useEffect } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import {
  useEmergencyWithdraw,
  useStakedBalance,
} from "@/hooks/contracts/useStaking";
import { useConnection } from "wagmi";

export default function EmergencyWithdraw() {
  const { address } = useConnection();
  const {
    emergencyWithdraw,
    isPending,
    isConfirming,
    isConfirmed,
    isError,
    error,
  } = useEmergencyWithdraw();

  const { data: stakedBalance } = useStakedBalance(address);

  const handleEmergencyWithdraw = () => {
    if (!stakedBalance || (stakedBalance as bigint) === 0n) {
      console.log("stakedBalance", stakedBalance);
      toast.error("No staked balance to withdraw.");
      return;
    }

    emergencyWithdraw();
    toast.loading("Waiting for wallet confirmation...");
  };

  useEffect(() => {
    if (isConfirmed) {
      toast.success("Emergency withdraw successful.");
    }
  }, [isConfirmed]);

  useEffect(() => {
    if (isError) {
      toast.error("Emergency withdraw failed.");
    }
  }, [isError, error]);

  return (
    <Card className="p-6 border border-destructive/30 bg-destructive/5">
      <div className="space-y-4">
        <div>
          <h4 className="text-lg font-semibold text-destructive mb-2">
            Emergency Withdraw
          </h4>
          <p className="text-sm text-muted-foreground">
            Withdraw all tokens without claiming rewards.
          </p>
        </div>

        <Button
          variant="destructive"
          className="w-full"
          size="lg"
          onClick={handleEmergencyWithdraw}
          disabled={isPending || isConfirming}
        >
          {isPending
            ? "Waiting for Wallet..."
            : isConfirming
              ? "Processing Transaction..."
              : "Emergency Withdraw All"}
        </Button>
      </div>
    </Card>
  );
}
