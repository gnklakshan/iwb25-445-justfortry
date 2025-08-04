/* eslint-disable @typescript-eslint/no-explicit-any */
import { UserType } from "@/types/types";
import { createContext, useEffect, useState, ReactNode } from "react";

type AuthContextType = {
  isLoggedIn: boolean;
  login: (token: string, userData?: UserType) => void;
  logout: () => void;
  userInfo: UserType | null;
};

export const AuthContext = createContext<AuthContextType>({
  isLoggedIn: false,
  login: () => {},
  logout: () => {},
  userInfo: null,
});

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userInfo, setUserInfo] = useState<UserType | null>(null);

  useEffect(() => {
    const token = localStorage.getItem("token");
    const name = localStorage.getItem("name");
    const email = localStorage.getItem("email");
    const userId = localStorage.getItem("userId");

    if (token) {
      setIsLoggedIn(true);
      setUserInfo({
        name: name ?? "",
        email: email ?? "",
        userId: userId ?? "",
      });
    }
  }, []);

  const login = (token: string, userData?: UserType) => {
    localStorage.setItem("token", token);

    if (userData) {
      if (userData.name) localStorage.setItem("name", userData.name);
      if (userData.email) localStorage.setItem("email", userData.email);
      if (userData.userId) localStorage.setItem("userId", userData.userId);

      setUserInfo(userData);
    }

    setIsLoggedIn(true);
  };

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("name");
    localStorage.removeItem("email");
    localStorage.removeItem("userId");

    setIsLoggedIn(false);
    setUserInfo(null);
  };

  return (
    <AuthContext.Provider value={{ isLoggedIn, login, logout, userInfo }}>
      {children}
    </AuthContext.Provider>
  );
};
