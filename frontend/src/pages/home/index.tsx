import AccountCard from "@/components/_account/accountCard";
import AddNewAccCard from "@/components/_account/addNewAccCard";
import TransactionSummery from "@/components/_transaction/tansaction-summery";
import ProtectedRoute from "@/components/ProtectedRoute";
import { Account } from "@/types/types";
import React, { Suspense } from "react";
import { BarLoader } from "react-spinners";

const Dashboard = () => {
  const userAccounts: Account[] = [
    {
      id: "1",
      name: "Personal Savings",
      type: "SAVINGS",
      balance: 1500.0,
      isDefault: true,
    },
    {
      id: "2",
      name: "Business Checking",
      type: "CURRENT",
      balance: 3000.0,
      isDefault: false,
    },
  ];
  return (
    <ProtectedRoute>
      <Suspense
        fallback={<BarLoader className="mt-4" width={"100%"} color="#9333ea" />}
      >
        <div>
          <div className="space-y-8 pt-22 px-30">
            <div className="flex items-center justify-between mb-5">
              <h1 className="text-5xl bg-gradient-to-r from-green-500 to-blue-500 bg-clip-text text-transparent tracking-tight ">
                Dashboard
              </h1>
            </div>

            {/* summery */}
            <TransactionSummery />

            {/* account section */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              <AddNewAccCard />
              {userAccounts.length > 0 &&
                userAccounts.map((account) => (
                  <AccountCard key={account.id} account={account} />
                ))}
            </div>
          </div>
        </div>
      </Suspense>
    </ProtectedRoute>
  );
};

export default Dashboard;
