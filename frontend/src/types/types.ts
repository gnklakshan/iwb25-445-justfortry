export type FormDataType = {
  name?: string;
  email?: string;
  password?: string;
  confirmpassword?: string;
};

export type UserType = {
  name: string;
  email: string;
  userId: string;
};

export type Account = {
  id: string;
  name: string;
  accountType: "CURRENT" | "SAVINGS";
  balance: number;
  isDefault: boolean;
};

export interface AccountDetailsType extends Account {
  transactions: Transaction[];
}

export type Transaction = {
  id: string;
  transactionType: string;
  amount: number;
  description: string;
  date: string;
  category: string;
  receiptUrl?: string;
  isRecurring: boolean;
  recurringInterval?: "DAILY" | "WEEKLY" | "MONTHLY" | "YEARLY";
  nextRecurringDate?: string;
  lastProcessed: string;
  status: string;
  userId: string;
  accountId: string;
  createdAt?: string;
  updatedAt?: string;
};
