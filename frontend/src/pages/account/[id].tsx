import TransactionTable from "@/components/_account/transactionTable";
import ProtectedRoute from "@/components/ProtectedRoute";
import useAxios from "@/hooks/useAxios";
import { AccountDetailsType } from "@/types/types";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";
import { BarLoader } from "react-spinners";

const initialAccountDetails: AccountDetailsType = {
  id: "",
  name: "",
  accountType: "SAVINGS",
  transactions: [],
  balance: 0,
  isDefault: false,
};

const AccountDetails = () => {
  const { get, getLoading, error } = useAxios();
  const router = useRouter();
  const accountId = router.query.id;
  const [accountDetails, setAccountDetails] = useState<AccountDetailsType>(
    initialAccountDetails
  );

  //get account data
  const getAccountData = useCallback(async () => {
    try {
      const response = await get(`/accounts/${accountId}`);
      if (response) {
        setAccountDetails(response);
      }
    } catch (error) {
      console.error("Error fetching account data:", error);
    }
  }, [get, accountId, error]);

  useEffect(() => {
    if (accountId) {
      getAccountData();
    }
  }, [accountId, getAccountData]);

  return (
    <ProtectedRoute>
      <div className="mt-24 space-y-8 px-5">
        {getLoading ? (
          <BarLoader className="mt-4" width={"100%"} color="#9333ea" />
        ) : error ? (
          <p className="text-red-500">Error loading account details: {error}</p>
        ) : (
          <div className="px-30 ">
            {/* account basic details */}
            <div className="flex flex-col sm:flex-row gap-6 sm:gap-8 items-start sm:items-end justify-between  rounded-xl  p-6 border border-zinc-200 mb-6">
              <div>
                <h1 className="text-4xl sm:text-5xl font-bold text-zinc-900 dark:text-white mb-2">
                  {accountDetails.name}
                </h1>
                <span className="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-200 mb-2">
                  {accountDetails.accountType.charAt(0) +
                    accountDetails.accountType.slice(1).toLowerCase()}{" "}
                  Account
                </span>
                {accountDetails.isDefault && (
                  <span className="ml-2 inline-block px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900 text-emerald-700 dark:text-emerald-300">
                    Default
                  </span>
                )}
              </div>
              <div className="text-right">
                <div className="text-3xl sm:text-4xl font-bold text-zinc-900 dark:text-white mb-1">
                  LKR{" "}
                  {accountDetails.balance.toLocaleString(undefined, {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}
                </div>
                <p className="text-sm text-zinc-500 dark:text-zinc-400">
                  {accountDetails.transactions.length} Transaction
                  {accountDetails.transactions.length !== 1 && "s"}
                </p>
              </div>
            </div>

            {/* transaction Table */}

            <TransactionTable
              transactions={accountDetails.transactions}
              deleteTransaction={() => {}}
            />
          </div>
        )}
      </div>
    </ProtectedRoute>
  );
};

export default AccountDetails;
