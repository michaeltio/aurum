"use client";

import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useState, useEffect, useRef } from "react";
import { useStake } from "@/hooks/contracts/useStaking";
import {
  useBalanceOf,
  useAllowance,
  useApprove,
} from "@/hooks/contracts/useStakeToken";
import { useConnection } from "wagmi";
import { formatUnits, parseEther } from "viem";
import { toast } from "sonner";
import SepoliaAddress from "@shared/address/sepolia/addresses.json";

export default function StakeCard() {
  const [amount, setAmount] = useState("");
  const { address } = useConnection();

  const { data: balance } = useBalanceOf(address);
  const { data: allowance, refetch: refetchAllowance } = useAllowance(
    address,
    SepoliaAddress.Staking as `0x${string}`,
  );
  const allowanceValue = allowance as bigint | undefined;
  const rawBalance = balance as bigint | undefined;

  const pendingStakeAmount = useRef<bigint | null>(null);

  const {
    approve,
    isPending: isApprovePending,
    isConfirming: isApproveConfirming,
    isConfirmed: isApproveConfirmed,
    isError: isApproveError,
  } = useApprove();
  const {
    stake,
    isPending: isStakePending,
    isConfirming: isStakeConfirming,
    isConfirmed: isStakeConfirmed,
    isError: isStakeError,
  } = useStake();

  let amountWei: bigint | undefined;
  try {
    if (amount) amountWei = parseEther(amount);
  } catch (e) {
    amountWei = undefined;
  }

  const handleMax = () => {
    if (rawBalance) {
      setAmount(formatUnits(rawBalance, 18));
    }
  };

  const handleStake = () => {
    console.log("amount", amountWei);
    if (!amount || !amountWei) {
      toast.error("Please enter a valid amount.");
      return;
    }

    console.log("Checking allowance...");
    console.log("allowanceValue", allowanceValue);

    if (!allowanceValue || allowanceValue < amountWei) {
      toast(`Allowance too low. Approving ${amount} tokens...`);
      pendingStakeAmount.current = amountWei;
      approve(SepoliaAddress.Staking as `0x${string}`, amountWei);
      return;
    }

    console.log("Staking now...");
    stake(amountWei);
  };

  useEffect(() => {
    const autoStake = async () => {
      if (!isApproveConfirmed) return;
      if (!pendingStakeAmount.current) return;

      const { data: newAllowance } = await refetchAllowance();
      const updatedAllowance = newAllowance as bigint | undefined;

      if (updatedAllowance && updatedAllowance >= pendingStakeAmount.current) {
        toast.success("Allowance confirmed. Staking now...");
        const amountToStake = pendingStakeAmount.current;
        pendingStakeAmount.current = null;
        stake(amountToStake);
      }
    };

    autoStake();
  }, [isApproveConfirmed, refetchAllowance, stake]);

  useEffect(() => {
    if (isStakePending) toast("Stake transaction submitted...");
    if (isStakeConfirming) toast.loading("Stake confirming...");
    if (isStakeConfirmed) toast.success("Stake successful!");
    if (isStakeError) toast.error("Stake failed.");
  }, [isStakePending, isStakeConfirming, isStakeConfirmed, isStakeError]);

  let buttonText = "Stake";
  const isProcessing =
    isApprovePending ||
    isApproveConfirming ||
    isStakePending ||
    isStakeConfirming;
  if (amountWei && allowanceValue && allowanceValue < amountWei)
    buttonText = "Approve";
  if (isProcessing) buttonText = "Processing...";

  return (
    <Card className="p-6 border border-border bg-card">
      <div className="space-y-4">
        <div>
          <h4 className="text-lg font-semibold text-foreground mb-2">
            Stake Tokens
          </h4>
          <p className="text-sm text-muted-foreground">
            Lock your tokens to earn rewards
          </p>
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium text-foreground">
            Amount
          </label>
          <div className="flex gap-2">
            <Input
              type="number"
              placeholder="0.00"
              className="flex-1"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
            <Button
              type="button"
              variant="outline"
              className="px-4 bg-transparent"
              onClick={handleMax}
            >
              Max
            </Button>
          </div>
          <p className="text-xs text-muted-foreground">
            Available: {rawBalance ? formatUnits(rawBalance, 18) : "0"} Tokens
          </p>
        </div>

        <Button
          className="w-full"
          size="lg"
          onClick={handleStake}
          disabled={isProcessing || !amount || !amountWei || amountWei === 0n}
        >
          {buttonText}
        </Button>
      </div>
    </Card>
  );
}
