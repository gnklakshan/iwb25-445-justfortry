import React, { useCallback, useEffect, useState } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { TransactionFormData, transactionSchema } from "@/lib/schema";
import { Account } from "@/types/types";
import { Input } from "../ui/input";
import { Button } from "../ui/button";
import NewAccountDrawer from "../_account/newAccountDrawer";
import { Switch } from "../ui/switch";
import { Popover, PopoverContent, PopoverTrigger } from "../ui/popover";
import { CalendarIcon, Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { Calendar } from "../ui/calendar";
import { useRouter } from "next/router";
import { format } from "date-fns";
import useAxios from "@/hooks/useAxios";
import { toast } from "sonner";

const TransactionForm: React.FC = () => {
  const router = useRouter();
  const { post, get, patch, loading, error } = useAxios();
  const { isEdit, create, transactionId } = router.query;
  const editMode = isEdit === "true" || create !== "true";
  const id = transactionId ? transactionId : null;

  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const categories = [
    { id: "1", name: "Food", type: "EXPENSE" },
    { id: "2", name: "Salary", type: "INCOME" },
  ];

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    setValue,
    getValues,
    reset,
  } = useForm<TransactionFormData>({
    resolver: zodResolver(transactionSchema),
    defaultValues: {
      transactionType: "EXPENSE",
      amount: 0,
      date: new Date().toISOString(),
      accountId: "",
      category: "",
      description: "",
      isRecurring: false,
      receiptUrl: "",
      status: "PENDING",
      recurringInterval: undefined,
    },
  });

  const transactionType = watch("transactionType");
  const isRecurring = watch("isRecurring");
  const date = watch("date");
  const status = watch("status");

  console.log(isRecurring);
  useEffect(() => {
    const subscription = watch((value) => {
      console.log("Form data:", value);
    });
    return () => subscription.unsubscribe();
  }, [watch]);

  const filteredCategories = categories.filter(
    (category) => category.type === transactionType
  );

  const fetchAccounts = useCallback(async () => {
    try {
      const response = await get("/accounts");
      if (response.success) {
        setAccounts(response.data);
      }
    } catch (err) {
      console.error("Error fetching accounts:", error, err);
      toast.error("Failed to load accounts");
    }
  }, [get]);

  const handleCreateTransaction = useCallback(
    async (data: TransactionFormData) => {
      try {
        let response = {};
        if (editMode && id) {
          response = await patch(`transactions/${id}`, data);
        } else {
          response = await post("transactions", data);
        }
        if (response) {
          toast.success("Transaction created successfully");
          reset({
            transactionType: "EXPENSE",
            amount: 0,
            date: new Date().toISOString(),
            accountId: "",
            category: "",
            description: "",
            isRecurring: false,
            receiptUrl: "",
            status: "PENDING",
            recurringInterval: undefined,
          });
        } else {
          const message = "Failed to create transaction";
          toast.error(message);
          console.error("Transaction creation failed:", response);
        }
      } catch (err) {
        const message = "Error creating transaction";
        toast.error(message);
        console.error("Error creating transaction:", err);
      }
    },
    [post, reset]
  );

  useEffect(() => {
    const loadData = async () => {
      await fetchAccounts(); // first get accounts
      if (editMode && transactionId) {
        try {
          const response = await get(`transactions/${transactionId}`);
          if (response) {
            const tx = response;
            reset({
              transactionType: tx.transactionType,
              amount: Number(tx.amount),
              date: tx.date
                ? new Date(tx.date).toISOString()
                : new Date().toISOString(),
              accountId: tx.accountId,
              category: tx.category || "",
              description: tx.description || "",
              isRecurring: Boolean(tx.isRecurring),
              receiptUrl: tx.receiptUrl || "",
              status: tx.status,
              recurringInterval: tx.recurringInterval ?? undefined,
            });
          }
        } catch (err) {
          console.error("Error fetching transaction:", error, err);
          toast.error("Failed to load transaction data");
        }
      }
    };
    loadData();
  }, [editMode, transactionId, fetchAccounts, get, reset]);

  // onSubmit handler
  const onSubmit = (data: TransactionFormData) => {
    handleCreateTransaction(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* select transaction type */}
        <div className="space-y-2 w-full">
          <label className="text-sm font-medium">Type</label>
          <Select
            onValueChange={(value: "EXPENSE" | "INCOME") =>
              setValue("transactionType", value)
            }
            value={transactionType || "EXPENSE"}
          >
            <SelectTrigger className="w-full">
              <SelectValue placeholder="Select type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="EXPENSE">Expense</SelectItem>
              <SelectItem value="INCOME">Income</SelectItem>
            </SelectContent>
          </Select>
          {errors.transactionType && (
            <p className="text-sm text-red-500">
              {errors.transactionType.message}
            </p>
          )}
        </div>
        {/* Category */}
        <div className="space-y-2 w-full">
          <label className="text-sm font-medium">Category</label>
          <Select
            onValueChange={(value) => setValue("category", value)}
            value={watch("category") || ""}
          >
            <SelectTrigger className="w-full">
              <SelectValue placeholder="Select category" />
            </SelectTrigger>
            <SelectContent>
              {filteredCategories.map((category) => (
                <SelectItem key={category.id} value={category.name}>
                  {category.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.category && (
            <p className="text-sm text-red-500">{errors.category.message}</p>
          )}
        </div>
      </div>

      {/* account and amount */}
      <div className="grid gap-6 md:grid-cols-2">
        <div className="space-y-2">
          <label className="text-sm font-medium">Amount</label>
          <Input
            type="number"
            step="0.01"
            placeholder="0.00"
            {...register("amount", { valueAsNumber: true })}
          />
          {errors.amount && (
            <p className="text-sm text-red-500">{errors.amount.message}</p>
          )}
        </div>

        <div className="space-y-2 w-full">
          <label className="text-sm font-medium">Account</label>
          <Select
            onValueChange={(value) => setValue("accountId", value)}
            value={watch("accountId") || ""}
          >
            <SelectTrigger className="w-full" onClick={fetchAccounts}>
              <SelectValue placeholder="Select account" />
            </SelectTrigger>
            <SelectContent>
              {accounts.map((account) => (
                <SelectItem key={account.id} value={account.id}>
                  {account.name} (LKR {account.balance.toFixed(2)})
                </SelectItem>
              ))}
              <NewAccountDrawer
                isOpen={isDrawerOpen}
                setIsOpen={setIsDrawerOpen}
              >
                <Button
                  variant="ghost"
                  className="relative flex w-full cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none hover:bg-accent hover:text-accent-foreground"
                >
                  Create Account
                </Button>
              </NewAccountDrawer>
            </SelectContent>
          </Select>
          {errors.accountId && (
            <p className="text-sm text-red-500">{errors.accountId.message}</p>
          )}
        </div>
      </div>

      {/* Date */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <label className="text-sm font-medium">Date</label>
          <Popover>
            <PopoverTrigger asChild>
              <Button
                variant="outline"
                className={cn(
                  "w-full pl-3 text-left font-normal",
                  !date && "text-muted-foreground"
                )}
              >
                {date ? format(date, "PPP") : <span>Pick a date</span>}
                <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="start">
              <Calendar
                mode="single"
                selected={
                  typeof date === "string"
                    ? date
                      ? new Date(date)
                      : undefined
                    : date
                }
                onSelect={(date) => {
                  if (date instanceof Date)
                    setValue("date", date.toISOString());
                }}
                disabled={(date) =>
                  date > new Date() || date < new Date("1900-01-01")
                }
                initialFocus
              />
            </PopoverContent>
          </Popover>
          {errors.date && (
            <p className="text-sm text-red-500">{errors.date.message}</p>
          )}
        </div>

        {/* status */}
        <div className="space-y-2 w-full">
          <label className="text-sm font-medium">Transaction Status</label>
          <Select
            onValueChange={(value: "PENDING" | "COMPLETED" | "FAILED") =>
              setValue("status", value)
            }
            value={status || "PENDING"}
          >
            <SelectTrigger className="w-full">
              <SelectValue placeholder="Select status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="PENDING">Pending</SelectItem>
              <SelectItem value="COMPLETED">Completed</SelectItem>
              <SelectItem value="FAILED">Failed</SelectItem>
            </SelectContent>
          </Select>
          {errors.status && (
            <p className="text-sm text-red-500">{errors.status.message}</p>
          )}
        </div>
      </div>

      {/* Description */}
      <div className="space-y-2">
        <label className="text-sm font-medium">Description</label>
        <Input placeholder="Enter description" {...register("description")} />
        {errors.description && (
          <p className="text-sm text-red-500">{errors.description.message}</p>
        )}
      </div>

      {/* Recurring Toggle */}
      <div className="flex flex-row items-center justify-between rounded-lg border p-4">
        <div className="space-y-0.5">
          <label className="text-base font-medium">Recurring Transaction</label>
          <div className="text-sm text-muted-foreground">
            Set up a recurring schedule for this transaction
          </div>
        </div>
        <Switch
          checked={isRecurring}
          onCheckedChange={(checked) => setValue("isRecurring", checked)}
        />
      </div>

      {/* Recurring Interval */}
      {isRecurring && (
        <div className="space-y-2">
          <label className="text-sm font-medium">Recurring Interval</label>
          <Select
            onValueChange={(value: "DAILY" | "WEEKLY" | "MONTHLY" | "YEARLY") =>
              setValue("recurringInterval", value)
            }
            defaultValue={getValues("recurringInterval")}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select interval" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="DAILY">Daily</SelectItem>
              <SelectItem value="WEEKLY">Weekly</SelectItem>
              <SelectItem value="MONTHLY">Monthly</SelectItem>
              <SelectItem value="YEARLY">Yearly</SelectItem>
            </SelectContent>
          </Select>
          {errors.recurringInterval && (
            <p className="text-sm text-red-500">
              {errors.recurringInterval.message}
            </p>
          )}
        </div>
      )}

      {/* Actions */}
      <div className="flex flex-col gap-4">
        <Button
          type="button"
          variant="outline"
          className="w-full"
          onClick={() => router.back()}
        >
          Cancel
        </Button>
        <Button type="submit" className="w-full" disabled={loading}>
          {loading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              {editMode ? "Updating..." : "Creating..."}
            </>
          ) : editMode ? (
            "Update Transaction"
          ) : (
            "Create Transaction"
          )}
        </Button>
      </div>
    </form>
  );
};

export default TransactionForm;
