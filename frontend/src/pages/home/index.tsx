import AccountCard from "@/components/_account/accountCard";
import AddNewAccCard from "@/components/_account/addNewAccCard";
import TransactionSummery from "@/components/_transaction/tansaction-summery";
import ProtectedRoute from "@/components/ProtectedRoute";
import useAxios from "@/hooks/useAxios";
import { Account } from "@/types/types";
import React, { useCallback, useEffect, useState } from "react";
import { BarLoader } from "react-spinners";
import { toast } from "sonner";

const Dashboard = () => {
  const { get, loading, error } = useAxios();
  const [userAccounts, setUserAccounts] = useState<Account[]>([]);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

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

  // Fetch user accounts when the component mounts
  useEffect(() => {
    getUserAccounts();
  }, [getUserAccounts]);

  return (
    <ProtectedRoute>
      {loading ? (
        <BarLoader className="mt-4" width={"100%"} color="#9333ea" />
      ) : (
        <div>
          <div className="space-y-8 pt-28 px-30">
            <div className="flex items-center justify-between mb-5">
              <h1 className="text-5xl bg-gradient-to-r from-green-500 to-blue-500 bg-clip-text text-transparent tracking-tight ">
                Dashboard
              </h1>
            </div>

            {/* summery */}
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
