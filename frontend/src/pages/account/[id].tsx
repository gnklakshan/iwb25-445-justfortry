import TransactionTable from "@/components/_account/transactionTable";
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
  const { accountId } = router.query;
  const [accountDetails, setAccountDetails] = useState<AccountDetailsType>(
    initialAccountDetails,
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
    <div className="mt-24 space-y-8 px-5">
      {getLoading ? (
        <BarLoader className="mt-4" width={"100%"} color="#9333ea" />
      ) : error ? (
        <p className="text-red-500">Error loading account details: {error}</p>
      ) : (
        <div>
          {/* account basic details */}
          <div className="flex gap-4 items-end justify-between">
            <div>
              <h1 className="text-5xl sm:text-6xl font-bold tracking-tight gradient-title capitalize">
                {accountDetails.name}
              </h1>
              <p className="text-muted-foreground">
                {accountDetails.accountType.charAt(0) +
                  accountDetails.accountType.slice(1).toLowerCase()}{" "}
                Account
              </p>
            </div>
            <div className="text-right pb-2">
              <div className="text-xl sm:text-2xl font-bold">
                ${accountDetails.balance.toFixed(2)}
              </div>
              <p className="text-sm text-muted-foreground">
                {accountDetails.transactions.length} Transactions
              </p>
            </div>
          </div>

          {/* transaction Table */}
          <TransactionTable />
        </div>
      )}
    </div>
  );
};

export default AccountDetails;
