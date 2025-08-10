import TransactionForm from "@/components/_transaction/transaction-form";
import ProtectedRoute from "@/components/ProtectedRoute";
import React from "react";

const NewTransaction: React.FC = () => {
  return (
    <ProtectedRoute>
      <div className="mt-28 max-w-3xl mx-auto px-5">
        <div className="flex justify-center md:justify-normal mb-8">
          <h1 className="text-5xl bg-gradient-to-r from-green-500 to-blue-500 bg-clip-text text-transparent">
            Add Transaction
          </h1>
        </div>
        <TransactionForm />
      </div>
    </ProtectedRoute>
  );
};

export default NewTransaction;
