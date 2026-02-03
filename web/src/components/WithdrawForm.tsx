"use client";

import { useEffect, useState } from "react";

import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useConnection } from "wagmi";
import { toast } from "sonner";
import { parseEther } from "viem";

import { useWithdraw, useStakedBalance } from "@/hooks/contracts/useStaking";

export default function WithdrawForm() {
  const [amount, setAmount] = useState("");
  const { address } = useConnection();

  const {
    withdraw,
    isPending: isWithdrawPending,
    isConfirming: isWithdrawConfirming,
    isConfirmed: isWithdrawConfirmed,
    isError: isWithdrawError,
  } = useWithdraw();

  const { data: stakedBalance } = useStakedBalance(address);

  const isProcessing = isWithdrawPending || isWithdrawConfirming;

  const handleWithdraw = () => {
    if (!stakedBalance) {
      toast.error("Staked balance not loaded");
      return;
    }

    if (!amount || Number(amount) <= 0) {
      toast.error("Invalid withdraw amount");
      return;
    }

    if (Number(amount) > Number(stakedBalance)) {
      console.log("stakedBalance", stakedBalance);
      console.log("withdrawAmount", amount);
      toast.error("Cannot withdraw more than staked balance");
      return;
    }

    try {
      withdraw(amount ? parseEther(amount) : 0n);
    } catch (err) {
      toast.error("Withdraw failed");
    }
  };

  const handleMax = () => {
    if (!stakedBalance || typeof stakedBalance !== "bigint") return;
    setAmount(stakedBalance);
  };

  useEffect(() => {
    if (isWithdrawConfirmed) {
      toast.success("Withdraw successful");
      setAmount("");
    }
  }, [isWithdrawConfirmed]);

  useEffect(() => {
    if (isWithdrawError) {
      toast.error("Transaction failed");
    }
  }, [isWithdrawError]);

  return (
    <Card className="p-6 border border-border bg-card">
      <div className="space-y-4">
        <div>
          <h4 className="text-lg font-semibold text-foreground mb-2">
            Withdraw Tokens
          </h4>
          <p className="text-sm text-muted-foreground">
            Withdraw your staked tokens
          </p>
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium text-foreground">
            Amount
          </label>

          <div className="flex gap-2">
            <Input
              type="number"
              min="0"
              className="flex-1"
              value={amount}
              disabled={isProcessing}
              onChange={(e) => setAmount(e.target.value)}
            />
            <Button
              type="button"
              variant="outline"
              className="px-4 bg-transparent"
              disabled={!stakedBalance || isProcessing}
              onClick={handleMax}
            >
              Max
            </Button>
          </div>

          <p className="text-xs text-muted-foreground">
            Staked: {stakedBalance ? stakedBalance.toString() : "0"} Tokens
          </p>
        </div>

        <Button
          className="w-full"
          size="lg"
          variant="secondary"
          disabled={isProcessing || !amount}
          onClick={handleWithdraw}
        >
          {isWithdrawPending
            ? "Waiting for wallet..."
            : isWithdrawConfirming
              ? "Confirming..."
              : "Withdraw"}
        </Button>
      </div>
    </Card>
  );
}
