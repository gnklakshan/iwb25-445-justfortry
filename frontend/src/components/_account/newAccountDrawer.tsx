import React, { useEffect, useState } from "react";
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
  DrawerTrigger,
} from "../ui/drawer";
import { Button } from "../ui/button";
import { Loader2 } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import { Input } from "../ui/input";
import { Switch } from "../ui/switch";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { accountSchema } from "@/lib/schema";
import useAxios from "@/hooks/useAxios";
import { toast } from "sonner";
import { useRouter } from "next/router";

const NewAccountDrawer: React.FC<{
  children: React.ReactNode;
  isOpen: boolean;
  setIsOpen: React.Dispatch<React.SetStateAction<boolean>>;
}> = ({ children, isOpen, setIsOpen }) => {
  const router = useRouter();
  const { post, error, loading } = useAxios();

  // Set search param when drawer opens/closes
  useEffect(() => {
    if (isOpen) {
      router.replace(
        {
          pathname: router.pathname,
          query: { ...router.query, "new-account": "True" },
        },
        undefined,
        { shallow: true },
      );
    } else {
      const { "new-account": _removed, ...rest } = router.query;
      router.replace(
        {
          pathname: router.pathname,
          query: rest,
        },
        undefined,
        { shallow: true },
      );
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
    reset,
  } = useForm({
    resolver: zodResolver(accountSchema),
    defaultValues: {
      name: "",
      accountType: "CURRENT",
      balance: 0,
      isDefault: false,
    },
  });

  const onSubmit = async () => {
    try {
      await post("accounts/create", {
        name: watch("name"),
        accountType: watch("accountType"),
        balance: watch("balance"),
        isDefault: watch("isDefault"),
      });
      toast.success(`${watch("name")}: Account created successfully!`);
      reset(); // Reset form after success
      setIsOpen(false);
    } catch (err) {
      console.error("Error creating account:", error);
      toast.error("Failed to create account", {
        description: err instanceof Error ? err.message : "Unknown error",
      });
    }
  };
  return (
    <Drawer open={isOpen} onOpenChange={setIsOpen}>
      <DrawerTrigger asChild>{children}</DrawerTrigger>
      <DrawerContent>
        <DrawerHeader>
          <DrawerTitle>Create New Account</DrawerTitle>
        </DrawerHeader>
        <div className="px-4 pb-4">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <label
                htmlFor="name"
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                Account Name
              </label>
              <Input
                id="name"
                placeholder="e.g., Main Checking"
                {...register("name")}
              />
              {errors.name && (
                <p className="text-sm text-red-500">{errors.name.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <label
                htmlFor="type"
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                Account Type
              </label>
              <Select
                onValueChange={(value: "CURRENT" | "SAVINGS") =>
                  setValue("accountType", value)
                }
                defaultValue={watch("accountType")}
              >
                <SelectTrigger id="accountType">
                  <SelectValue placeholder="Select type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="CURRENT">Current</SelectItem>
                  <SelectItem value="SAVINGS">Savings</SelectItem>
                </SelectContent>
              </Select>
              {errors.accountType && (
                <p className="text-sm text-red-500">
                  {errors.accountType.message}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <label
                htmlFor="balance"
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                Initial Balance
              </label>
              <Input
                id="balance"
                type="number"
                step="0.01"
                placeholder="0.00"
                {...register("balance", { valueAsNumber: true })}
              />
              {errors.balance && (
                <p className="text-sm text-red-500">{errors.balance.message}</p>
              )}
            </div>

            <div className="flex items-center justify-between rounded-lg border p-3">
              <div className="space-y-0.5">
                <label
                  htmlFor="isDefault"
                  className="text-base font-medium cursor-pointer"
                >
                  Set as Default
                </label>
                <p className="text-sm text-muted-foreground">
                  This account will be selected by default for transactions
                </p>
              </div>
              <Switch
                id="isDefault"
                checked={watch("isDefault")}
                onCheckedChange={(checked) => setValue("isDefault", checked)}
              />
            </div>

            <div className="flex gap-4 pt-4">
              <DrawerClose asChild onClick={() => reset()}>
                <Button type="button" variant="outline" className="flex-1">
                  Cancel
                </Button>
              </DrawerClose>
              <Button type="submit" className="flex-1" disabled={loading}>
                {loading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Creating...
                  </>
                ) : (
                  "Create Account"
                )}
              </Button>
            </div>
          </form>
        </div>
      </DrawerContent>
    </Drawer>
  );
};

export default NewAccountDrawer;
