import AccountCard from "@/components/_account/accountCard";
import AccountSummaryChart from "@/components/_account/accountsSummeryChart";
import AddNewAccCard from "@/components/_account/addNewAccCard";
import BudgetProgressCard from "@/components/_budget/budgetProgressCard";
import TransactionSummery from "@/components/_transaction/tansaction-summery";
import ProtectedRoute from "@/components/ProtectedRoute";
import useAxios from "@/hooks/useAxios";
import { Account, BudgetResponse } from "@/types/types";
import React, { useCallback, useEffect, useState } from "react";
import { BarLoader } from "react-spinners";
import { toast } from "sonner";

const Dashboard = () => {
  const { get, patch, loading, error } = useAxios();
  const [userAccounts, setUserAccounts] = useState<Account[]>([]);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [budgetData, setBudgetData] = useState<BudgetResponse | null>(null);

  //get all accounts of the user
  const getUserAccounts = useCallback(async () => {
    setUserAccounts([]);
    try {
      const response = await get("/accounts");
      if (response.success) {
        setUserAccounts(response.data);
      }
    } catch (err) {
      console.error("Error fetching user accounts:", err);
      toast.error("Error fetching user accounts", { description: error });
    }
  }, [get, error, isDrawerOpen]);

  //get budget for default account
  const getDefaultAccountBudget = useCallback(async () => {
    try {
      const response = await get("budget");
      if (response) {
        setBudgetData(response.data);
      }
    } catch (err) {
      console.error("Error fetching default account budget:", err);
    }
  }, [get, error]);

  useEffect(() => {
    getDefaultAccountBudget();
  }, [getDefaultAccountBudget]);

  // Fetch user accounts when the component mounts
  useEffect(() => {
    getUserAccounts();
  }, [getUserAccounts]);

  const handleUpdateBudget = async (newBudget: number) => {
    try {
      console.log("Updating budget to:", newBudget);
      const response = await patch("budget", {
        amount: newBudget,
      });
      if (response) {
        setBudgetData(response.data);
        toast.success("Budget updated successfully");
      }
    } catch (err) {
      console.error("Error updating budget:", err, error);
      toast.error("Error updating budget", { description: error });
    }
  };

  const handleUpdateAccountStatus = useCallback(
    async (accountId: string, isDefault: boolean) => {
      try {
        const response = await patch(
          `accounts/${accountId}?isDefault=${isDefault}`,
          {},
        );
        if (response) {
          getUserAccounts();
          toast.success(`Successfully updated default status `);
        }
      } catch (err) {
        console.error("Error updating account status:", err);
        toast.error(`Error updating account status for ${accountId}`);
      }
    },
    [patch],
  );

  return (
    <ProtectedRoute>
      {loading ? (
        <BarLoader className="mt-4" width={"100%"} color="#9333ea" />
      ) : (
        <div>
          <div className="space-y-8 pt-28 px-30">
            <div className="flex items-center justify-between mb-5">
              <h1 className="text-5xl bg-gradient-to-r from-green-500 to-blue-500 bg-clip-text text-transparent tracking-tight ">
                Account Overview
              </h1>
            </div>

            {/* budget for default account */}
            <BudgetProgressCard
              budget={
                budgetData || {
                  amount: 0,
                  expense: 0,
                }
              }
              onUpdateBudget={handleUpdateBudget}
            />

            {/* summery */}
            <AccountSummaryChart />
            <TransactionSummery />

            {/* account section */}
            <div className="py-4">
              <h2 className="text-2xl font-semibold mb-4">Accounts</h2>
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                <AddNewAccCard
                  isOpen={isDrawerOpen}
                  setIsOpen={setIsDrawerOpen}
                />
                {userAccounts.length > 0 &&
                  userAccounts.map((account) => (
                    <AccountCard
                      key={account.id}
                      account={account}
                      onUpdateStatus={handleUpdateAccountStatus}
                      loading={loading}
                    />
                  ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </ProtectedRoute>
  );
};

export default Dashboard;
