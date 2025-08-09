import { useAuth } from "@/hooks/useAuth";
import { LayoutDashboard, PenBox } from "lucide-react";
import Image from "next/image";
import React from "react";
import { Button } from "./ui/button";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";
import { useRouter } from "next/router";

const Header = () => {
  const router = useRouter();
  const { isLoggedIn, logout } = useAuth();
  return (
    <header className="fixed top-0 w-full bg-white/80 backdrop-blur-md z-50 border-b">
      <nav className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Image
          src={"/logo.png"}
          alt="Welth Logo"
          width={150}
          height={30}
          className="h-12 w-auto object-contain"
          onClick={() => (window.location.href = "/")}
        />

        <div className="hidden md:flex items-center space-x-8">
          {!isLoggedIn && (
            <>
              <a href="#features" className="text-gray-600 hover:text-blue-600">
                Features
              </a>
              <a
                href="#testimonials"
                className="text-gray-600 hover:text-blue-600"
              >
                About
              </a>
            </>
          )}
        </div>

        {/* Action Buttons */}
        <div className="flex items-center space-x-4">
          {isLoggedIn && (
            <>
              <Button
                variant="outline"
                className="text-gray-600 hover:text-blue-600 flex items-center gap-2 py-1"
                onClick={() => router.push("/home")}
              >
                <LayoutDashboard size={18} />
                <span className="hidden md:inline">Dashboard</span>
              </Button>

              <Button
                className="flex items-center gap-2"
                onClick={() => {
                  router.push("/transaction?create=true");
                }}
              >
                <PenBox size={18} />
                <span className="hidden md:inline">Add Transaction</span>
              </Button>
            </>
          )}

          {/* button to login and sign out */}
          {!isLoggedIn ? (
            <Button
              variant="outline"
              className="px-6 py-2 rounded-full font-semibold shadow hover:bg-blue-50 transition"
              onClick={() => router.push("/auth/sign-in")}
            >
              Login
            </Button>
          ) : (
            <Popover>
              <PopoverTrigger asChild>
                <Image
                  src="/avatar.png"
                  alt="User Avatar"
                  width={36}
                  height={36}
                  className="rounded-full object-cover bg-amber-100 hover:cursor-pointer hover:ring-2 hover:ring-blue-400 transition"
                />
              </PopoverTrigger>
              <PopoverContent
                className="w-48 p-0 border-none shadow-lg rounded-xl"
                align="end"
                alignOffset={10}
              >
                <div className="flex flex-col">
                  <div className="px-4 py-3 border-b">
                    <span className="font-medium text-gray-800">John Doe</span>
                    <span className="block text-xs text-gray-500">
                      john@gamai.com
                    </span>
                  </div>
                  <Button
                    variant="ghost"
                    className="w-full justify-start px-4 py-2 text-red-600 hover:bg-red-50 rounded-b-xl"
                    onClick={() => {
                      logout();
                      router.push("/auth/sign-in");
                    }}
                  >
                    Logout
                  </Button>
                </div>
              </PopoverContent>
            </Popover>
          )}
        </div>
      </nav>
    </header>
  );
};

export default Header;
