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
