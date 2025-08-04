import AccountCard from "@/components/_account/accountCard";
import NewAccountDrawer from "@/components/_account/newAccountDrawer";
import { Card, CardContent } from "@/components/ui/card";
import { Account } from "@/types/types";
import { Plus } from "lucide-react";
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
    <div className="space-y-8">
      {/* account section */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <NewAccountDrawer>
          <Card className="hover:shadow-md transition-shadow cursor-pointer border-dashed">
            <CardContent className="flex flex-col items-center justify-center text-muted-foreground h-full pt-5">
              <Plus className="h-10 w-10 mb-2" />
              <p className="text-sm font-medium">Add New Account</p>
            </CardContent>
          </Card>
        </NewAccountDrawer>
        {userAccounts.length > 0 &&
          userAccounts.map((account) => (
            <AccountCard key={account.id} account={account} />
          ))}
      </div>
    </div>
  );
};

export default Dashboard;
