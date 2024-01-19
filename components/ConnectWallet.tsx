import "@rainbow-me/rainbowkit/styles.css";
import {
  ConnectButton,
  getDefaultWallets,
  RainbowKitProvider,
} from "@rainbow-me/rainbowkit";
import { configureChains, createConfig, WagmiConfig } from "wagmi";
import { mainnet, polygon, polygonMumbai } from "wagmi/chains";
import { infuraProvider } from "wagmi/providers/infura";
import { publicProvider } from "wagmi/providers/public";

const { chains, publicClient } = configureChains(
  [mainnet, polygon, polygonMumbai],
  [
    infuraProvider({
      apiKey: "c358621366b54f90aa8a220804e28dbe",
    }),
    publicProvider(),
  ]
);

const { connectors } = getDefaultWallets({
  appName: "streamsphere",
  projectId: "859bca88c8fa13587201c76493609fd1",
  chains,
});

const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
});

export default function App() {
  return (
    <>
      <WagmiConfig config={wagmiConfig}>
        <RainbowKitProvider chains={chains}>
          <div>
            <ConnectButton />
          </div>
        </RainbowKitProvider>
      </WagmiConfig>
    </>
  );
}
