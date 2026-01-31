import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("StakingSystem", (m) => {
  const stakeToken = m.contract("StakeToken");
  const rewardToken = m.contract("RewardToken");

  const staking = m.contract("Staking", [stakeToken, rewardToken]);

  return {
    stakeToken,
    rewardToken,
    staking,
  };
});
