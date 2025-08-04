import AuthForm from "@/components/login-form";
import useAxios from "@/hooks/useAxios";
import { FormDataType } from "@/types/types";
import { useRouter } from "next/router";
import React from "react";

const SignUP = () => {
  const router = useRouter();
  const { post, loading, error } = useAxios<FormDataType>();

  const handleSignUp = async (data: FormDataType) => {
    const { email, password, confirmpassword, name } = data;
    if (!email || !password || !confirmpassword || !name) return;

    if (password !== confirmpassword) {
      console.error("Passwords do not match");
      return;
    }

    const payload = {
      email: email,
      password: password,
      name: name,
    };
    try {
      const response = await post("auth/signup", payload);
      if (response) {
        router.replace("/auth/sign-in");
      }
    } catch (err) {
      console.error("Sign up error:", error);
      return;
    }
  };
  return (
    <div className="pt-20 pb-20 px-4 min-h-screen flex items-center justify-center">
      <AuthForm onSubmit={handleSignUp} isSignup={true} loading={loading} />
    </div>
  );
};

export default SignUP;
