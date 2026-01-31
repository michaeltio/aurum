import WalletConnect from "./WalletConnect";

export default function Header() {
  return (
    <header className="w-full py-4 border-b mb-8 bg-zinc-950">
      <div className="max-w-6xl mx-auto flex justify-between items-center px-4">
        <h1 className="text-2xl font-bold text-center">Vaulta</h1>
        <WalletConnect />
      </div>
    </header>
  );
}
