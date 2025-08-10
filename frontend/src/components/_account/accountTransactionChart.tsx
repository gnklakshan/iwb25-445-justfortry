/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { useMemo, useState } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  AreaChart,
  Area,
} from "recharts";
import {
  format,
  subDays,
  startOfDay,
  endOfDay,
  isValid,
  parseISO,
} from "date-fns";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import { TrendingUp, TrendingDown, DollarSign, Calendar } from "lucide-react";

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

type AccountTransactionChartProps = {
  transactions: Transaction[];
};

const DATE_RANGES = {
  "7D": { label: "7 Days", days: 7 },
  "1M": { label: "1 Month", days: 30 },
  "3M": { label: "3 Months", days: 90 },
  "6M": { label: "6 Months", days: 180 },
  "1Y": { label: "1 Year", days: 365 },
  ALL: { label: "All Time", days: null },
};

type DateRangeKey = keyof typeof DATE_RANGES;

const AccountTransactionChart: React.FC<AccountTransactionChartProps> = ({
  transactions,
}) => {
  const [dateRange, setDateRange] = useState<DateRangeKey>("1M");
  const [chartType, setChartType] = useState<"line" | "area">("area");

  const { filteredData, totals } = useMemo(() => {
    const range = DATE_RANGES[dateRange];
    const now = new Date();
    const startDate = range.days
      ? startOfDay(subDays(now, range.days))
      : startOfDay(new Date(0));

    // Filter transactions with more flexible date parsing and status checking
    const filtered = transactions.filter((t) => {
      // Try multiple date parsing methods
      let transactionDate: Date;
      try {
        // First try parsing as ISO string
        transactionDate = parseISO(t.date);
        if (!isValid(transactionDate)) {
          // If that fails, try creating a new Date directly
          transactionDate = new Date(t.date);
        }
      } catch (error) {
        // If all parsing fails, try direct Date constructor
        transactionDate = new Date(t.date);
      }

      // Check if date is valid and within range
      const isDateValid = isValid(transactionDate);
      const isInRange =
        isDateValid &&
        transactionDate >= startDate &&
        transactionDate <= endOfDay(now);

      // Don't filter by status - include all transactions
      return isInRange;
    });

    console.log(
      "Filtered transactions:",
      filtered.length,
      "out of",
      transactions.length,
    );

    // Group transactions by date with better date formatting
    const grouped = filtered.reduce(
      (
        acc: {
          [key: string]: {
            date: string;
            dateKey: string;
            income: number;
            expense: number;
          };
        },
        transaction,
      ) => {
        let transactionDate: Date;
        try {
          transactionDate = parseISO(transaction.date);
          if (!isValid(transactionDate)) {
            transactionDate = new Date(transaction.date);
          }
        } catch (error) {
          transactionDate = new Date(transaction.date);
        }

        const dateKey = format(transactionDate, "yyyy-MM-dd");
        const displayDate = format(
          transactionDate,
          range.days && range.days <= 30 ? "MMM dd" : "MMM yyyy",
        );

        if (!acc[dateKey]) {
          acc[dateKey] = { date: displayDate, dateKey, income: 0, expense: 0 };
        }

        // Check transaction type more flexibly
        const type = transaction.transactionType?.toUpperCase();
        if (type === "INCOME" || type === "CREDIT") {
          acc[dateKey].income += Math.abs(transaction.amount);
        } else {
          acc[dateKey].expense += Math.abs(transaction.amount);
        }
        return acc;
      },
      {},
    );

    console.log("Grouped data:", Object.keys(grouped).length, "days");

    // Convert to array and sort by date
    const chartData = Object.values(grouped)
      .sort(
        (a, b) => new Date(a.dateKey).getTime() - new Date(b.dateKey).getTime(),
      )
      .map((item) => ({
        ...item,
        net: item.income - item.expense,
      }));

    // Calculate totals
    const periodTotals = chartData.reduce(
      (acc, day) => ({
        income: acc.income + day.income,
        expense: acc.expense + day.expense,
        net: acc.net + day.net,
      }),
      { income: 0, expense: 0, net: 0 },
    );

    return { filteredData: chartData, totals: periodTotals };
  }, [transactions, dateRange]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-LK", {
      style: "currency",
      currency: "LKR",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg p-3">
          <p className="font-medium text-gray-900 dark:text-gray-100 mb-2">
            {label}
          </p>
          {payload.map((entry: any, index: number) => (
            <div key={index} className="flex items-center gap-2">
              <div
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: entry.color }}
              />
              <span className="text-sm text-gray-600 dark:text-gray-300">
                {entry.name}: {formatCurrency(entry.value)}
              </span>
            </div>
          ))}
        </div>
      );
    }
    return null;
  };

  const StatCard = ({
    title,
    value,
    icon: Icon,
    trend,
    color = "text-gray-900",
  }: {
    title: string;
    value: number;
    icon: any;
    trend?: number;
    color?: string;
  }) => (
    <div className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-100 dark:border-gray-700">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <Icon className="w-4 h-4 text-gray-500" />
          <span className="text-sm font-medium text-gray-600 dark:text-gray-300">
            {title}
          </span>
        </div>
        {trend !== undefined && (
          <div
            className={`flex items-center gap-1 text-xs ${trend >= 0 ? "text-green-600" : "text-red-600"}`}
          >
            {trend >= 0 ? (
              <TrendingUp className="w-3 h-3" />
            ) : (
              <TrendingDown className="w-3 h-3" />
            )}
            {Math.abs(trend).toFixed(1)}%
          </div>
        )}
      </div>
      <div className={`text-xl font-bold ${color}`}>
        {formatCurrency(value)}
      </div>
    </div>
  );

  return (
    <div className="space-y-6">
      {/* Chart */}
      <Card className="border border-gray-100 shadow-none mb-6">
        <CardHeader className="pb-4">
          <CardTitle className="flex justify-between items-center">
            <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Transaction Trends
            </span>
            <div className="flex gap-3">
              <Select
                value={chartType}
                onValueChange={(value) =>
                  setChartType(value as "line" | "area")
                }
              >
                <SelectTrigger className="w-[100px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="area">Area</SelectItem>
                  <SelectItem value="line">Line</SelectItem>
                </SelectContent>
              </Select>
              <Select
                value={dateRange}
                onValueChange={(value) => setDateRange(value as DateRangeKey)}
              >
                <SelectTrigger className="w-[120px]">
                  <Calendar className="w-4 h-4 mr-2" />
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(DATE_RANGES).map(([key, { label }]) => (
                    <SelectItem key={key} value={key}>
                      {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardTitle>
          {/* Statistics Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
            <StatCard
              title="Total Income"
              value={totals.income}
              icon={TrendingUp}
              color="text-green-600"
            />
            <StatCard
              title="Total Expenses"
              value={totals.expense}
              icon={TrendingDown}
              color="text-red-600"
            />
            <StatCard
              title="Net Balance"
              value={totals.net}
              icon={DollarSign}
              color={totals.net >= 0 ? "text-green-600" : "text-red-600"}
            />
          </div>
        </CardHeader>
        <CardContent>
          {filteredData.length === 0 ? (
            <div className="h-[400px] flex items-center justify-center">
              <div className="text-center">
                <DollarSign className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400">
                  No transaction data available for the selected period
                </p>
              </div>
            </div>
          ) : (
            <div className="h-[400px]">
              <ResponsiveContainer width="100%" height="100%">
                {chartType === "area" ? (
                  <AreaChart
                    data={filteredData}
                    margin={{ top: 20, right: 20, left: 20, bottom: 20 }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      stroke="#e5e7eb"
                      vertical={false}
                    />
                    <XAxis
                      dataKey="date"
                      fontSize={12}
                      tickLine={false}
                      axisLine={false}
                      tick={{ fill: "#6b7280" }}
                    />
                    <YAxis
                      fontSize={12}
                      tickLine={false}
                      axisLine={false}
                      tick={{ fill: "#6b7280" }}
                      tickFormatter={(value) =>
                        formatCurrency(value).replace("LKR", "LKR ")
                      }
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ paddingTop: "20px" }} />
                    <Area
                      type="monotone"
                      dataKey="income"
                      name="Income"
                      stroke="#10b981"
                      fill="#10b981"
                      fillOpacity={0.1}
                      strokeWidth={2}
                    />
                    <Area
                      type="monotone"
                      dataKey="expense"
                      name="Expenses"
                      stroke="#ef4444"
                      fill="#ef4444"
                      fillOpacity={0.1}
                      strokeWidth={2}
                    />
                  </AreaChart>
                ) : (
                  <LineChart
                    data={filteredData}
                    margin={{ top: 20, right: 20, left: 20, bottom: 20 }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      stroke="#e5e7eb"
                      vertical={false}
                    />
                    <XAxis
                      dataKey="date"
                      fontSize={12}
                      tickLine={false}
                      axisLine={false}
                      tick={{ fill: "#6b7280" }}
                    />
                    <YAxis
                      fontSize={12}
                      tickLine={false}
                      axisLine={false}
                      tick={{ fill: "#6b7280" }}
                      tickFormatter={(value) =>
                        formatCurrency(value).replace("LKR", "LKR ")
                      }
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ paddingTop: "20px" }} />
                    <Line
                      type="monotone"
                      dataKey="income"
                      name="Income"
                      stroke="#10b981"
                      strokeWidth={3}
                      dot={{ fill: "#10b981", r: 4 }}
                      activeDot={{ r: 6, stroke: "#10b981", strokeWidth: 2 }}
                    />
                    <Line
                      type="monotone"
                      dataKey="expense"
                      name="Expenses"
                      stroke="#ef4444"
                      strokeWidth={3}
                      dot={{ fill: "#ef4444", r: 4 }}
                      activeDot={{ r: 6, stroke: "#ef4444", strokeWidth: 2 }}
                    />
                  </LineChart>
                )}
              </ResponsiveContainer>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default AccountTransactionChart;
