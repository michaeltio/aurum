"use client";

import { useConnection } from "wagmi";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { ADMIN_ROUTES } from "@/lib/adminRoutes";
import { add } from "date-fns";

export function AdminAuthProvider({ children }: { children: React.ReactNode }) {
  const { address, isConnecting, isReconnecting, isConnected } =
    useConnection();

  const pathname = usePathname();
  const router = useRouter();

  const [mounted, setMounted] = useState(false);
  const [ready, setReady] = useState(false);

  const ADMIN_ADDRESS = "0x7bF1077e09d7882F7Bf9793b1baAEA1E5EC65E88";

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!isConnecting && !isReconnecting) {
      setReady(true);
    }
  }, [isConnecting, isReconnecting]);

  const isProtectedRoute = useMemo(
    () => ADMIN_ROUTES.some((route) => pathname.startsWith(route)),
    [pathname]
  );

  useEffect(() => {
    if (!mounted || !ready || !isProtectedRoute) return;

    if (!isConnected) {
      console.log("Redirecting non-connected user", address);
      router.replace("/dashboard");
      return;
    }

    if (address?.toLowerCase() !== ADMIN_ADDRESS.toLowerCase()) {
      console.log("Redirecting non-admin user", address);
      router.replace("/dashboard");
    }
  }, [mounted, ready, isProtectedRoute, isConnected, address, router]);

  return <>{children}</>;
}
