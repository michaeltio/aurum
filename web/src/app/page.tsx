import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import AsciiBackground from "@/components/ASCIIBackground";
import {
  DashboardRewardRate,
  DashboardTotalStaked,
} from "@/components/DashboardComponents";

export const dynamic = "force-dynamic";

export default function Landing() {
  return (
    <div className=" text-foreground ">
      <AsciiBackground />

      <section className="relative z-10 flex flex-col items-center justify-center px-4">
        <div className="max-w-3xl mx-auto text-center">
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold mb-6 leading-tight text-balance">
            Earn Rewards by Staking
          </h1>

          <p className="text-lg md:text-xl text-muted-foreground mb-12 leading-relaxed max-w-2xl mx-auto">
            Stake your tokens and earn passive income with our secure platform.
            Join thousands of users growing their wealth through transparent,
            professional-grade crypto staking.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
            <Button asChild size="lg" className="rounded-full px-8">
              <Link href="/dashboard">Enter App</Link>
            </Button>
            <Button
              asChild
              variant="outline"
              size="lg"
              className="rounded-full px-8 bg-transparent"
            >
              <Link href="#learn">Learn More</Link>
            </Button>
          </div>
        </div>

        <Card className="w-full max-w-md border-border/50 bg-card/80 backdrop-blur-sm">
          <CardContent className="pt-8">
            <div className="grid grid-cols-2 gap-6 md:gap-8">
              <div className="text-center">
                <p className="text-muted-foreground text-sm mb-2">
                  Total Reward Emission
                </p>
                <DashboardRewardRate />
                <p className="text-muted-foreground text-xs">Tokens / sec</p>
              </div>
              <div className="text-center">
                <p className="text-muted-foreground text-sm mb-2">
                  Total Staked
                </p>
                <DashboardTotalStaked />
                <p className="text-muted-foreground text-xs">
                  by the community
                </p>
              </div>
            </div>
            <p className="text-muted-foreground text-xs text-center mt-6 pt-6 border-t border-border/30">
              Distributed proportionally among all stakers
            </p>
          </CardContent>
        </Card>
      </section>
    </div>
  );
}
