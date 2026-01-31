import { createConfig, http } from "wagmi";
import { mainnet, sepolia } from "wagmi/chains";
import { metaMask, injected } from "wagmi/connectors";

export const config = createConfig({
  chains: [sepolia],
  ssr: true,
  connectors: [metaMask()],
  transports: {
    [sepolia.id]: http(
      "https://sepolia.infura.io/v3/cacfe30346a54a1993934247d94a3cce"
    ),
  },
});
