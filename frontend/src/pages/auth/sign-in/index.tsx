import AuthForm from "@/components/login-form";
import { useAuth } from "@/hooks/useAuth";
import useAxios from "@/hooks/useAxios";
import { FormDataType, UserType } from "@/types/types";
import { useRouter } from "next/router";
import React from "react";

const SignIN = () => {
  const { login } = useAuth();
  const router = useRouter();
  const { post, loading, error } = useAxios();

  const handleLogin = async (data: FormDataType) => {
    const { email, password } = data;
    if (!email || !password) return;

    const payload = {
      email: email,
      password: password,
    };
    try {
      const response = await post("auth/login", payload);
      if (response) {
        const user: UserType = {
          name: response.name,
          email: response.email,
          userId: response.userId,
        };
        login(response.token, user);
        router.push("/");
      }
    } catch (err) {
      console.error("Login error:", error);
      return;
    }
  };

  return (
    <div className="pt-20 pb-20 px-4 min-h-screen flex items-center justify-center">
      <AuthForm onSubmit={handleLogin} isSignup={false} loading={loading} />
    </div>
  );
};

export default SignIN;
