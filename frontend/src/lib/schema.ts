import { z } from "zod";

export const accountSchema = z.object({
  name: z.string().min(1, "Name is required"),
  accountType: z.enum(["CURRENT", "SAVINGS"]),
  balance: z.number().min(0, "Initial balance is required"),
  isDefault: z.boolean().default(false),
});

// export const transactionSchema = z
//   .object({
//     accountType: z.enum(["INCOME", "EXPENSE"]),
//     amount: z.string().min(1, "Amount is required"),
//     description: z.string().optional(),
//     date: z.date({ error: "Date is required" }),
//     accountId: z.string().min(1, "Account is required"),
//     category: z.string().min(1, "Category is required"),
//     isRecurring: z.boolean().default(false),
//     recurringInterval: z
//       .enum(["DAILY", "WEEKLY", "MONTHLY", "YEARLY"])
//       .optional(),
//   })
//   .superRefine((data, ctx) => {
//     if (data.isRecurring && !data.recurringInterval) {
//       ctx.addIssue({
//         code: z.ZodIssueCode.custom,
//         message: "Recurring interval is required for recurring transactions",
//         path: ["recurringInterval"],
//       });
//     }
//   });

export const transactionSchema = z
  .object({
    transactionType: z.enum(["INCOME", "EXPENSE"]),
    amount: z.number().positive("Amount must be positive"),
    date: z.string(),
    accountId: z.string().min(1, "Account is required"),
    category: z.string().min(1, "Category is required"),
    description: z.string().optional(),
    isRecurring: z.boolean().optional(),
    receiptUrl: z.string().url().optional(),
    nextRecurringDate: z.string().optional(),
    recurringInterval: z
      .enum(["DAILY", "WEEKLY", "MONTHLY", "YEARLY"])
      .optional(),
  })
  .refine(
    (data) => {
      // If isRecurring is true, recurringInterval must be provided
      if (data.isRecurring && !data.recurringInterval) {
        return false;
      }
      return true;
    },
    {
      message: "Recurring interval is required for recurring transactions",
      path: ["recurringInterval"],
    },
  );

export type TransactionFormData = z.infer<typeof transactionSchema>;
