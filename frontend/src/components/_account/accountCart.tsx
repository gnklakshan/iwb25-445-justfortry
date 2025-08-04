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

const AccountCart: React.FC<Account> = (account) => {
  const { id, name, type, balance, isDefault } = account;
  const loading = false;
  const handleDefaultChange = () => {
    console.log(`Toggling default status for account ${id}`);
  };

  return (
    <Card
      className="hover:shadow-md transition-shadow group relative"
      onClick={() => console.log("Account clicked")}
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
          {type.charAt(0) + type.slice(1).toLowerCase()} Account
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

export default AccountCart;
