import { parseJwt } from "@/lib/auth";
import { createContext, useContext, useEffect, useState } from "react";

type User = { id: string; email: string };

type AuthContextType = {
  isLoggedIn: boolean;
  user?: User;
  login: (token: string) => void;
  logout: () => void;
};

export const AuthContext = createContext<AuthContextType | undefined>(
  undefined
);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | undefined>(undefined);

  useEffect(() => {
    const token = localStorage.getItem("authToken");
    if (token) {
      const payload = parseJwt(token);
      if (payload) {
        setUser({ id: payload.sub, email: payload.email });
      } else {
        logout();
      }
    }
  }, []);

  const login = (token: string) => {
    localStorage.setItem("authToken", token);
    const payload = parseJwt(token);
    if (payload) {
      setUser({ id: payload.sub, email: payload.email });
    }
  };

  const logout = () => {
    localStorage.removeItem("authToken");
    setUser(undefined);
  };

  return (
    <AuthContext.Provider value={{ isLoggedIn: !!user, user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
