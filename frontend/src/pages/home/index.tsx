import AccountCard from "@/components/_account/accountCard";
import AddNewAccCard from "@/components/_account/addNewAccCard";
import ProtectedRoute from "@/components/ProtectedRoute";
import { Account } from "@/types/types";
import React from "react";

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
      <div className="space-y-8 pt-22 px-30">
        {/* account section */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <AddNewAccCard />
          {userAccounts.length > 0 &&
            userAccounts.map((account) => (
              <AccountCard key={account.id} account={account} />
            ))}
        </div>
      </div>
    </ProtectedRoute>
  );
};

export default Dashboard;
