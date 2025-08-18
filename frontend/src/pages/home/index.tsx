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
        setBudgetData(response);
      }
    } catch (err) {
      console.error("Error fetching default account budget:", err);
    }
  }, [get, error]);

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
                  accountName: "",
                  initialBudget: 0,
                  currentExpenses: 0,
                }
              }
              onUpdateBudget={handleUpdateBudget}
            />

            {/* summery */}
            <AccountSummaryChart />
            <TransactionSummery />

            {/* account section */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              <AddNewAccCard
                isOpen={isDrawerOpen}
                setIsOpen={setIsDrawerOpen}
              />
              {userAccounts.length > 0 &&
                userAccounts.map((account) => (
                  <AccountCard key={account.id} account={account} />
                ))}
            </div>
          </div>
        </div>
      )}
    </ProtectedRoute>
  );
};

export default Dashboard;
