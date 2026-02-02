import StakingStatus from "@/components/StakingStatus";
import WalletAddress from "@/components/WalletAddress";
import StakedBalance from "@/components/StakedBalance";
import PendingRewards from "@/components/PendingRewards";
import TotalStaked from "@/components/TotalStaked";
import RewardRate from "@/components/RewardRate";
import StakeForm from "@/components/StakeForm";
import WithdrawForm from "@/components/WithdrawForm";
import ClaimRewards from "@/components/ClaimRewards";
import EmergencyWithdraw from "@/components/EmergencyWithdraw";

export const dynamic = "force-dynamic";

export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-background">
      <main className="mx-auto max-w-6xl px-4 py-8">
        <h2 className="text-3xl font-bold mb-8 text-foreground">Dashboard</h2>

        <div className="mb-12 space-y-4">
          <StakingStatus />

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <StakedBalance />
            <PendingRewards />
            <TotalStaked />
            <RewardRate />
          </div>
        </div>

        <h3 className="text-xl font-semibold mb-4 text-foreground">
          Staking Actions
        </h3>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <StakeForm />
          <WithdrawForm />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <ClaimRewards />
          <EmergencyWithdraw />
        </div>
      </main>
    </div>
  );
}
