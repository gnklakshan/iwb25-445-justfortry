import { Account } from "@/types/types";
import React, { useCallback } from "react";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { ArrowUpRight, ArrowDownRight } from "lucide-react";
import { useRouter } from "next/router";
import { Switch } from "../ui/switch";
import useAxios from "@/hooks/useAxios";

const AccountCard: React.FC<{
  account: Account;
  onUpdateStatus: (id: string, isDefault: boolean) => void;
  loading: boolean;
}> = ({ account, onUpdateStatus, loading }) => {
  const { id, name, accountType, balance, isDefault } = account;

  const router = useRouter();

  const handleDefaultChange = () => {
    console.log(`Toggling default status for account ${id}`);
    onUpdateStatus(id, !isDefault);
  };

  return (
    <Card
      className="hover:shadow-md transition-shadow group relative"
      onClick={() => router.push(`/account/${id}`)}
    >
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium capitalize">{name}</CardTitle>
        <Switch
          checked={isDefault}
          onClick={(e) => {
            e.stopPropagation();
            handleDefaultChange();
          }}
          disabled={loading}
        />
      </CardHeader>
      <CardContent>
        <div
          className={`text-2xl font-bold ${balance < 0 ? "text-red-600" : ""}`}
        >
          LKR
          {balance < 0
            ? `- ${Math.abs(balance).toFixed(2)}`
            : balance.toFixed(2)}
        </div>
        <p className="text-xs text-muted-foreground">
          {accountType.charAt(0) + accountType.slice(1).toLowerCase()} Account
        </p>
      </CardContent>
      <CardFooter className="flex justify-between text-sm text-muted-foreground">
        <div className="flex items-center">
          <ArrowUpRight className="mr-1 h-4 w-4 text-green-500" />
          Income
        </div>
        <div className="flex items-center">
          <ArrowDownRight className="mr-1 h-4 w-4 text-red-500" />
          Expense
        </div>
      </CardFooter>
    </Card>
  );
};

export default AccountCard;
