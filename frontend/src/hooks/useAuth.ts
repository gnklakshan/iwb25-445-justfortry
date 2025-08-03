import { AuthContext } from "@/context/AuthContext";
import React, { useContext } from "react";

export const useAuth = () => useContext(AuthContext);
