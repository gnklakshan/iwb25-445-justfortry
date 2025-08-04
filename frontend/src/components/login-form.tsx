import { Lock, Mail, User } from "lucide-react";
import Image from "next/image";
import { useState } from "react";

type FormData = {
  name?: string;
  email?: string;
  password?: string;
  confirmpassword?: string;
};

const initialFormData: FormData = {
  name: "",
  email: "",
  password: "",
  confirmpassword: "",
};

const AuthForm = () => {
  const [isSignup, setIsSignup] = useState(false);
  const [form, setForm] = useState<FormData>(initialFormData);

  const toggleMode = () => setIsSignup((prev) => !prev);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    console.log(isSignup ? "Signing up" : "Logging in", form);
  };

  return (
    <div>
      <div className="w-full max-w-md p-8 bg-white rounded-2xl shadow-md space-y-6">
        <div className="flex flex-col items-center space-y-2">
          <Image
            src="/avatar.png"
            alt="Logo"
            width={80}
            height={80}
            className="rounded-full"
          />
          <h1 className="text-2xl font-semibold text-gray-700">
            {isSignup ? "Create Account" : "Log In"}
          </h1>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {isSignup && (
            <div className="relative">
              <User className="absolute left-3 top-3.5 text-gray-400 pb-2" />
              <input
                type="text"
                name="name"
                placeholder="Full Name"
                value={form.name}
                onChange={handleChange}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg "
                required
              />
            </div>
          )}
          <div className="relative">
            <Mail className="absolute left-3 top-3.5 text-gray-400 pb-2" />
            <input
              type="email"
              name="email"
              placeholder="Email"
              value={form.email}
              onChange={handleChange}
              className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg "
              required
            />
          </div>
          <div className="relative">
            <Lock className="absolute left-3 top-3.5 text-gray-400 pb-2" />
            <input
              type="password"
              name="password"
              placeholder="Password"
              value={form.password}
              onChange={handleChange}
              className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg "
              required
            />
          </div>
          {isSignup && (
            <div className="relative">
              <Lock className="absolute left-3 top-3.5 text-gray-400 pb-2" />
              <input
                type="password"
                name="confirmpassword"
                placeholder="Confirm Password"
                value={form.confirmpassword}
                onChange={handleChange}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg "
                required
              />
            </div>
          )}
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 rounded-lg font-semibold hover:bg-blue-700 transition duration-200"
          >
            {isSignup ? "Sign Up" : "Log In"}
          </button>
        </form>

        <div className="text-sm text-center text-gray-600">
          {isSignup ? "Already have an account?" : "Don't have an account?"}{" "}
          <button
            type="button"
            onClick={toggleMode}
            className="text-blue-600 font-medium hover:underline"
          >
            {isSignup ? "Log In" : "Sign Up"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default AuthForm;
