import TransactionForm from "@/components/_transaction/transaction-form";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

const NewTransaction = () => {
  const router = useRouter();
  const setQueryParam = (key: string, value: string) => {
    router.replace(
      {
        pathname: router.pathname,
        query: { [key]: value },
      },
      undefined,
      { shallow: true },
    );
  };
  const isEdit = true;
  useEffect(() => {
    if (isEdit) {
      setQueryParam("edit", "true");
    } else {
      setQueryParam("create", "true");
    }
  }, [isEdit]);

  return (
    <div className="mt-28 max-w-3xl mx-auto px-5">
      <div className="flex justify-center md:justify-normal mb-8">
        <h1 className="text-5xl bg-gradient-to-r from-green-500 to-blue-500 bg-clip-text text-transparent">
          Add Transaction
        </h1>
      </div>
      <TransactionForm editMode={isEdit} />
    </div>
  );
};

export default NewTransaction;
