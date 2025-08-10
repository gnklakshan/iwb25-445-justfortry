import React, {
  useState,
  useEffect,
  useMemo,
  useCallback,
  useRef,
} from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  ComposedChart,
  Line,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import {
  Calendar,
  TrendingUp,
  TrendingDown,
  Wallet,
  RefreshCw,
  AlertCircle,
  BarChart3,
  PieChart as PieChartIcon,
  Activity,
} from "lucide-react";
import useAxios from "@/hooks/useAxios";
import { toast } from "sonner";

type AccountSummary = {
  id: string;
  name: string;
  accountType: string;
  balance: number;
  income: number;
  expenses: number;
};

type TooltipProps = {
  active?: boolean;
  payload?: Array<{
    payload: {
      fullName: string;
      accountType: string;
      income: number;
      expenses: number;
      netFlow: number;
      name: string;
      balance: number;
      percentage: number;
    };
  }>;
  label?: string;
};

const DATE_RANGES = {
  "7D": { label: "7 Days", value: "7D" },
  "1M": { label: "1 Month", value: "1M" },
  "3M": { label: "3 Months", value: "3M" },
  "6M": { label: "6 Months", value: "6M" },
  "1Y": { label: "1 Year", value: "1Y" },
  ALL: { label: "All Time", value: "ALL" },
};

type DateRangeKey = keyof typeof DATE_RANGES;
type ChartType = "bar" | "pie" | "composed";

// Chart configuration
const CHART_CONFIGS = {
  composed: {
    icon: Activity,
    title: "Complete Financial Overview",
    description: "Income, expenses, and balance trends",
    label: "Combined",
  },
  bar: {
    icon: BarChart3,
    title: "Income vs Expenses by Account",
    description: "Compare income and expenses across accounts",
    label: "Bar Chart",
  },
  pie: {
    icon: PieChartIcon,
    title: "Account Balance Distribution",
    description: "Balance distribution as percentage of total",
    label: "Pie Chart",
  },
};

// Chart order for circular navigation
const CHART_ORDER: ChartType[] = ["bar", "pie", "composed"];

// color palette
const COLORS = [
  "#2563eb",
  "#059669",
  "#d97706",
  "#dc2626",
  "#7c3aed",
  "#0891b2",
  "#65a30d",
  "#ea580c",
  "#db2777",
  "#4f46e5",
];

const AccountSummaryChart: React.FC = () => {
  const { get, loading } = useAxios();
  const [dateRange, setDateRange] = useState<DateRangeKey>("1M");
  const [chartType, setChartType] = useState<ChartType>("bar");
  const [accountData, setAccountData] = useState<AccountSummary[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [isTransitioning, setIsTransitioning] = useState(false);

  // Touch/swipe handling
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const touchStartRef = useRef<{ x: number; y: number } | null>(null);
  const touchEndRef = useRef<{ x: number; y: number } | null>(null);

  const fetchAccountSummary = useCallback(
    async (range: string) => {
      setError(null);

      try {
        const response = await get(`accounts/summary?dateRange=${range}`);
        if (response?.data) {
          setAccountData(response.data);
        }
      } catch (err) {
        console.error("Error fetching account summary:", err);
        setError("Failed to load account data");
        toast.error("Failed to fetch account summary");
        setAccountData([]);
      }
    },
    [get],
  );

  useEffect(() => {
    fetchAccountSummary(DATE_RANGES[dateRange].value);
  }, [dateRange, fetchAccountSummary]);

  // Circular navigation functions
  const navigateChart = useCallback(
    (direction: "next" | "prev") => {
      if (isTransitioning) return;

      const currentIndex = CHART_ORDER.indexOf(chartType);
      let nextIndex: number;

      if (direction === "next") {
        nextIndex = (currentIndex + 1) % CHART_ORDER.length;
      } else {
        nextIndex =
          currentIndex === 0 ? CHART_ORDER.length - 1 : currentIndex - 1;
      }

      handleChartChange(CHART_ORDER[nextIndex]);
    },
    [chartType, isTransitioning],
  );

  // Touch event handlers
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    touchStartRef.current = {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY,
    };
  }, []);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!touchStartRef.current) return;

    touchEndRef.current = {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY,
    };
  }, []);

  const handleTouchEnd = useCallback(() => {
    if (!touchStartRef.current || !touchEndRef.current) return;

    const deltaX = touchEndRef.current.x - touchStartRef.current.x;
    const deltaY = touchEndRef.current.y - touchStartRef.current.y;
    const minSwipeDistance = 50;

    // Only trigger if horizontal swipe is more significant than vertical
    if (
      Math.abs(deltaX) > Math.abs(deltaY) &&
      Math.abs(deltaX) > minSwipeDistance
    ) {
      if (deltaX > 0) {
        // Swipe right - go to previous chart
        navigateChart("prev");
      } else {
        // Swipe left - go to next chart
        navigateChart("next");
      }
    }

    touchStartRef.current = null;
    touchEndRef.current = null;
  }, [navigateChart]);

  // Mouse wheel handler for desktop
  const handleWheel = useCallback(
    (e: React.WheelEvent) => {
      e.preventDefault();
      if (isTransitioning) return;

      if (e.deltaY > 0) {
        navigateChart("next");
      } else {
        navigateChart("prev");
      }
    },
    [navigateChart, isTransitioning],
  );

  const chartData = useMemo(() => {
    if (!accountData.length)
      return {
        barData: [],
        pieData: [],
        totals: { balance: 0, income: 0, expenses: 0 },
      };

    // Calculate totals
    const totals = accountData.reduce(
      (acc, account) => ({
        balance: acc.balance + account.balance,
        income: acc.income + account.income,
        expenses: acc.expenses + account.expenses,
      }),
      { balance: 0, income: 0, expenses: 0 },
    );

    // Data for bar chart - shows income/expense comparison per account
    const barData = accountData.map((account, index) => ({
      name:
        account.name.length > 12
          ? account.name.substring(0, 12) + "..."
          : account.name,
      fullName: account.name,
      income: account.income,
      expenses: account.expenses,
      balance: account.balance,
      accountType: account.accountType,
      netFlow: account.income - account.expenses,
      color: COLORS[index % COLORS.length],
    }));

    // Data for pie chart - shows balance distribution
    const pieData = accountData
      .filter((account) => Math.abs(account.balance) > 0)
      .map((account, index) => ({
        name: account.name,
        value: Math.abs(account.balance),
        balance: account.balance,
        income: account.income,
        expenses: account.expenses,
        accountType: account.accountType,
        color: COLORS[index % COLORS.length],
        percentage:
          (Math.abs(account.balance) / Math.abs(totals.balance || 1)) * 100,
      }));

    return { barData, pieData, totals };
  }, [accountData]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-LK", {
      style: "currency",
      currency: "LKR",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  // Handle chart type change with smooth transition
  const handleChartChange = (newChartType: ChartType) => {
    if (newChartType === chartType) return;

    setIsTransitioning(true);
    setTimeout(() => {
      setChartType(newChartType);
      setTimeout(() => setIsTransitioning(false), 150);
    }, 150);
  };

  const BarTooltip = ({ active, payload }: TooltipProps) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg p-4">
          <h3 className="font-semibold text-gray-900 dark:text-gray-100 mb-2">
            {data.fullName}
          </h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-3">
            {data.accountType}
          </p>
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-sm text-green-600">Income:</span>
              <span className="font-semibold text-green-600">
                {formatCurrency(data.income)}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-red-600">Expenses:</span>
              <span className="font-semibold text-red-600">
                {formatCurrency(data.expenses)}
              </span>
            </div>
            <div className="flex justify-between items-center pt-2 border-t border-gray-200">
              <span className="text-sm font-medium">Net Flow:</span>
              <span
                className={`font-bold ${data.netFlow >= 0 ? "text-green-600" : "text-red-600"}`}
              >
                {formatCurrency(data.netFlow)}
              </span>
            </div>
          </div>
        </div>
      );
    }
    return null;
  };

  const PieTooltip = ({ active, payload }: TooltipProps) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg p-4">
          <h3 className="font-semibold text-gray-900 dark:text-gray-100 mb-2">
            {data.name}
          </h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-3">
            {data.accountType}
          </p>
          <div className="space-y-1">
            <div className="flex justify-between">
              <span className="text-sm">Balance:</span>
              <span
                className={`font-semibold ${data.balance >= 0 ? "text-green-600" : "text-red-600"}`}
              >
                {formatCurrency(data.balance)} ({data.percentage.toFixed(1)}%)
              </span>
            </div>
          </div>
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
  }: {
    title: string;
    value: number;
    icon: React.ComponentType<{ className?: string }>;
    trend?: "positive" | "negative" | "neutral";
  }) => {
    const getColorClass = () => {
      if (trend === "positive") return "text-green-600";
      if (trend === "negative") return "text-red-600";
      return "text-gray-900 dark:text-gray-100";
    };

    return (
      <Card className="border-0 shadow-sm">
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">
                {title}
              </p>
              <p className={`text-2xl font-bold ${getColorClass()}`}>
                {formatCurrency(value)}
              </p>
            </div>
            <div className="p-3 bg-gray-100 dark:bg-gray-800 rounded-full">
              <Icon className="w-6 h-6 text-gray-600 dark:text-gray-300" />
            </div>
          </div>
        </CardContent>
      </Card>
    );
  };

  const renderChart = () => {
    if (loading) {
      return (
        <div className="h-[400px] flex items-center justify-center">
          <div className="text-center">
            <RefreshCw className="w-8 h-8 text-gray-400 animate-spin mx-auto mb-3" />
            <p className="text-gray-500">Loading account data...</p>
          </div>
        </div>
      );
    }

    if (chartData.barData.length === 0) {
      return (
        <div className="h-[400px] flex items-center justify-center">
          <div className="text-center">
            <Wallet className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-500">No account data available</p>
          </div>
        </div>
      );
    }

    const commonProps = {
      width: "100%",
      height: "100%",
    };

    switch (chartType) {
      case "bar":
        return (
          <ResponsiveContainer {...commonProps}>
            <BarChart
              data={chartData.barData}
              margin={{ top: 20, right: 30, left: 20, bottom: 60 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis
                dataKey="name"
                fontSize={12}
                angle={-45}
                textAnchor="end"
                height={80}
                tick={{ fill: "#6b7280" }}
              />
              <YAxis
                fontSize={12}
                tick={{ fill: "#6b7280" }}
                tickFormatter={(value) =>
                  formatCurrency(value).replace("LKR", "")
                }
              />
              <Tooltip content={<BarTooltip />} />
              <Bar
                dataKey="income"
                name="Income"
                fill="#10b981"
                radius={[4, 4, 0, 0]}
              />
              <Bar
                dataKey="expenses"
                name="Expenses"
                fill="#ef4444"
                radius={[4, 4, 0, 0]}
              />
            </BarChart>
          </ResponsiveContainer>
        );

      case "pie":
        return (
          <ResponsiveContainer {...commonProps}>
            <PieChart>
              <Pie
                data={chartData.pieData}
                cx="50%"
                cy="50%"
                outerRadius={140}
                innerRadius={60}
                paddingAngle={2}
                dataKey="value"
                label={({ percentage }) =>
                  percentage > 5 ? `${percentage.toFixed(0)}%` : ""
                }
                labelLine={false}
              >
                {chartData.pieData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip content={<PieTooltip />} />
            </PieChart>
          </ResponsiveContainer>
        );

      case "composed":
        return (
          <ResponsiveContainer {...commonProps}>
            <ComposedChart
              data={chartData.barData}
              margin={{ top: 20, right: 30, left: 20, bottom: 60 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis
                dataKey="name"
                fontSize={12}
                angle={-45}
                textAnchor="end"
                height={80}
                tick={{ fill: "#6b7280" }}
              />
              <YAxis
                fontSize={12}
                tick={{ fill: "#6b7280" }}
                tickFormatter={(value) =>
                  formatCurrency(value).replace("LKR", "")
                }
              />
              <Tooltip content={<BarTooltip />} />
              <Bar
                dataKey="income"
                name="Income"
                fill="#10b981"
                radius={[2, 2, 0, 0]}
              />
              <Bar
                dataKey="expenses"
                name="Expenses"
                fill="#ef4444"
                radius={[2, 2, 0, 0]}
              />
              <Line
                type="monotone"
                dataKey="balance"
                name="Balance"
                stroke="#2563eb"
                strokeWidth={3}
                dot={{ fill: "#2563eb", r: 4 }}
              />
            </ComposedChart>
          </ResponsiveContainer>
        );

      default:
        return null;
    }
  };

  const ChartNavigationButton = ({
    type,
    isActive,
    onClick,
  }: {
    type: ChartType;
    isActive: boolean;
    onClick: () => void;
  }) => {
    const config = CHART_CONFIGS[type];
    const Icon = config.icon;

    return (
      <button
        onClick={onClick}
        className={`
          flex  items-center gap-2 px-4 py-3 rounded-lg transition-all duration-300 min-w-[100px] relative
          ${
            isActive
              ? "bg-blue-600 text-white shadow-lg transform scale-105"
              : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700 hover:text-gray-800 dark:hover:text-gray-200"
          }
        `}
        disabled={isTransitioning}
      >
        <Icon className={`w-5 h-5 ${isActive ? "text-white" : ""}`} />
        <span className="text-xs font-medium">{config.label}</span>
      </button>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-end items-start sm:items-center gap-4">
        <div className="flex justify-end items-center gap-3">
          <button
            onClick={() => fetchAccountSummary(DATE_RANGES[dateRange].value)}
            disabled={loading}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </button>

          <Select
            value={dateRange}
            onValueChange={(value) => setDateRange(value as DateRangeKey)}
          >
            <SelectTrigger className="w-[140px]">
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
      </div>

      {/* Error State */}
      {error && (
        <Card className="border-red-200 bg-red-50 dark:bg-red-900/10">
          <CardContent className="p-4">
            <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
              <AlertCircle className="w-5 h-5" />
              <span className="text-sm font-medium">{error}</span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Summary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatCard
          title="Total Balance"
          value={chartData.totals.balance}
          icon={Wallet}
          trend={chartData.totals.balance >= 0 ? "positive" : "negative"}
        />
        <StatCard
          title="Total Income"
          value={chartData.totals.income}
          icon={TrendingUp}
          trend="positive"
        />
        <StatCard
          title="Total Expenses"
          value={chartData.totals.expenses}
          icon={TrendingDown}
          trend="negative"
        />
      </div>

      {/* Main Chart with Swipe Navigation */}
      <Card className="shadow-none overflow-hidden">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-lg font-semibold">
              {CHART_CONFIGS[chartType].title}
            </CardTitle>
            <div className="text-sm text-gray-500 dark:text-gray-400">
              {CHART_CONFIGS[chartType].description}
            </div>
          </div>
        </CardHeader>

        <CardContent>
          {/* Swipe Instructions */}
          <div className="mb-4 text-center">
            <p className="text-xs text-gray-400 dark:text-gray-500">
              👆 Swipe left/right or scroll to navigate charts
            </p>
          </div>

          {/* Chart Container with Swipe Support */}
          <div
            ref={chartContainerRef}
            className="relative overflow-hidden touch-pan-y"
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
            onWheel={handleWheel}
            style={{ touchAction: "pan-y" }}
          >
            <div
              className={`
                transition-all duration-300 ease-in-out h-[400px]
                ${isTransitioning ? "opacity-0 transform translate-x-2" : "opacity-100 transform translate-x-0"}
              `}
            >
              {renderChart()}
            </div>
          </div>

          <div className="mt-6">
            {/* Active Chart Legend */}
            {chartData.barData.length > 0 && (
              <div className="flex flex-wrap justify-center gap-6 text-sm mt-4 pt-4 border-t border-gray-100 dark:border-gray-800">
                {chartType !== "pie" && (
                  <>
                    <div className="flex items-center gap-2">
                      <div className="w-4 h-4 bg-green-500 rounded"></div>
                      <span className="text-gray-600 dark:text-gray-400">
                        Income
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-4 h-4 bg-red-500 rounded"></div>
                      <span className="text-gray-600 dark:text-gray-400">
                        Expenses
                      </span>
                    </div>
                  </>
                )}
                {chartType === "composed" && (
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-1 bg-blue-600 rounded"></div>
                    <span className="text-gray-600 dark:text-gray-400">
                      Account Balance
                    </span>
                  </div>
                )}
                {chartType === "pie" && (
                  <span className="text-gray-600 dark:text-gray-400">
                    Hover over segments for account details
                  </span>
                )}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
      {/* Chart Navigation Buttons */}
      <div>
        <div className="flex justify-center items-center gap-4">
          {CHART_ORDER.map((type) => (
            <ChartNavigationButton
              key={type}
              type={type}
              isActive={chartType === type}
              onClick={() => handleChartChange(type)}
            />
          ))}
        </div>

        {/* Chart Position Indicator */}
        <div className="flex justify-center mt-4">
          <div className="flex gap-2">
            {CHART_ORDER.map((type) => (
              <div
                key={type}
                className={`
                      w-2 h-2 rounded-full transition-all duration-300
                      ${
                        chartType === type
                          ? "bg-blue-600 w-6"
                          : "bg-gray-300 dark:bg-gray-600"
                      }
                    `}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AccountSummaryChart;
