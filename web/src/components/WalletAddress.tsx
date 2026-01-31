"use client";
import { Card } from "@/components/ui/card";
import { useConnection } from "wagmi";

export default function WalletAddress() {
  const { address } = useConnection();

  return (
    <Card className="p-6 border border-border bg-card">
      <p className="text-sm text-muted-foreground mb-2">Wallet Address</p>
      <p className="font-mono text-sm text-foreground break-all">
        {address || "Not connected"}
      </p>
    </Card>
  );
}
