import { Account } from "@/types/types";
import React from "react";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { Switch } from "@radix-ui/react-switch";
import { ArrowUpRight, ArrowDownRight } from "lucide-react";
import { useRouter } from "next/router";

const AccountCard: React.FC<{ account: Account }> = ({ account }) => {
  const { id, name, accountType, balance, isDefault } = account;

  const router = useRouter();
  const loading = false;
  const handleDefaultChange = () => {
    console.log(`Toggling default status for account ${id}`);
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
          onClick={handleDefaultChange}
          disabled={loading}
        />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">${balance.toFixed(2)}</div>
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
