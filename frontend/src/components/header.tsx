import { Link } from "lucide-react";
import React from "react";

const Header = () => {
  return (
    <header className="fixed top-0 w-full bg-white/80 backdrop-blur-md z-50 border-b">
      <nav className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link href="/">
          {/* <Image
            src={"/logo.png"}
            alt="Logo"
            width={200}
            height={60}
            className="h-12 w-auto object-contain"
          /> */}
        </Link>
      </nav>
    </header>
  );
};

export default Header;
