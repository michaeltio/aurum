"use client";

import { Wallet } from "lucide-react";
import {
  useConnect,
  useConnectors,
  useConnection,
  useConnectionEffect,
  useDisconnect,
} from "wagmi";
import { useState, useEffect } from "react";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";

import ClientWrapper from "./ClientWrapper";
import { shortWallet } from "@/lib/shortWallet";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
  DrawerTrigger,
} from "@/components/ui/drawer";

import { Separator } from "@/components/ui/separator";

export default function WalletConnectButton() {
  const [open, setOpen] = useState(false);
  const { address } = useConnection();

  const isDesktop = useMediaQuery("(min-width: 768px)");

  useEffect(() => {
    if (address) {
      setOpen(false);
    }
  });

  if (address) {
    return <ConnectedIcon address={address} />;
  }

  if (isDesktop) {
    return (
      <ClientWrapper>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button className="bg-transparent text-white hover:bg-white/10 border-1 border-white/20">
              <p> Connect Wallet</p>
              <Wallet />
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[425px]">
            <DialogHeader>
              <DialogTitle>Connect With Vaulta</DialogTitle>
            </DialogHeader>

            <Separator className=" bg-white" />

            <WalletButton />
          </DialogContent>
        </Dialog>
      </ClientWrapper>
    );
  }

  return (
    <ClientWrapper>
      <Drawer open={open} onOpenChange={setOpen}>
        <DrawerTrigger asChild>
          <Button className="bg-transparent text-white hover:bg-white/10 border-1 border-white/20">
            <p> Connect Wallet</p>
            <Wallet />
          </Button>
        </DrawerTrigger>
        <DrawerContent>
          <DrawerHeader className="text-left">
            <DrawerTitle>Connect With Vaulta</DrawerTitle>
          </DrawerHeader>
          <WalletButton />
          <DrawerFooter className="pt-2">
            <DrawerClose asChild>
              <Button variant="outline">Cancel</Button>
            </DrawerClose>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
    </ClientWrapper>
  );
}

function WalletButton() {
  const connectors = useConnectors();
  const { connect } = useConnect();
  const [activeId, setActiveId] = useState<string | null>(null);

  useConnectionEffect({
    onConnect({ connector }) {
      setActiveId(connector?.id ?? null);
    },
    onDisconnect() {
      setActiveId(null);
    },
  });

  const getIcon = (id?: string) => {
    if (id === "com.brave.wallet") return "/brave-browser-icon.svg";
    if (id === "metaMaskSDK" || id === "io.metamask")
      return "/metamask-icon.svg";
    return "/icons/wallet.svg";
  };

  return (
    <>
      {connectors.map((connector) => {
        const isActive = connector.id === activeId;

        return (
          <button
            key={connector.uid}
            onClick={() => connect({ connector })}
            className={`
              w-full flex items-center gap-3
              px-4 py-3 rounded-xl border transition
              ${isActive ? "border-blue-500" : "border-white/10 "}
              hover:bg-zinc-800
            `}
          >
            <img
              src={getIcon(isActive ? activeId : connector.id)}
              className="w-6 h-6"
              alt={connector.name}
            />
            <span className="flex-1 text-left">{connector.name}</span>
            {isActive && (
              <span className="text-xs text-blue-400">Connected</span>
            )}
          </button>
        );
      })}
    </>
  );
}

function ConnectedIcon({ address }: { address: string }) {
  const { disconnect } = useDisconnect();

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button className="bg-transparent text-white hover:bg-white/10 border-1 border-white/20">
          <p>{shortWallet(address)}</p>
          <Wallet />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-80">
        <div className="grid gap-4">
          <div className="space-y-2">
            <p>{shortWallet(address)}</p>
            <p>Total Staked</p>
          </div>
          <div className="grid gap-2">
            <Button onClick={() => disconnect()}>Disconnect</Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}
