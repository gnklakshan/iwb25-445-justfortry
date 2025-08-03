import type { AppProps } from "next/app";
import { Inter } from "next/font/google";
import Head from "next/head";
import Header from "@/components/header";
import { AuthProvider } from "@/context/AuthContext";
import "@/styles/globals.css";

const inter = Inter({ subsets: ["latin"] });

export default function App({ Component, pageProps }: AppProps) {
  return (
    <AuthProvider>
      <Head>
        <title>finApp</title>
        <meta
          name="finApp"
          content="A simple personal finance management app"
        />
        <link rel="icon" href="/logo-sm.png" sizes="any" />
      </Head>
      <div className={`${inter.className} antialiased`}>
        <Header />
        <main className="min-h-screen">
          <Component {...pageProps} />
        </main>
      </div>
    </AuthProvider>
  );
}
