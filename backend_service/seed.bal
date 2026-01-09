import backend_service.auth;
import backend_service.database;
import backend_service.types;

import ballerina/io;
import ballerina/random;
import ballerina/time;
import ballerina/uuid;

public function main() returns error? {
    io:println("Starting database seeding...");

    // Create users
    types:User[] users = check createUsers();
    io:println("Created users successfully");

    // Create accounts for each user
    map<types:Account[]> userAccounts = {};
    foreach types:User user in users {
        types:Account[] accounts = check createAccountsForUser(user.id);
        userAccounts[user.id] = accounts;
        io:println(string `Created accounts for user: ${user.email}`);
    }

    // Create transactions for each user
    foreach types:User user in users {
        types:Account[] accounts = userAccounts[user.id] ?: [];
        check createTransactionsForUser(user.id, accounts);
        io:println(string `Created transactions for user: ${user.email}`);
    }

    // Set budgets for each user
    foreach types:User user in users {
        check setBudgetForUser(user.id);
        io:println(string `Set budget for user: ${user.email}`);
    }

    io:println("Database seeding completed successfully!");
}

isolated function createUsers() returns types:User[]|error {
    types:User[] users = [];

    // User 1
    types:SignupRequest user1Request = {
        email: "john.doe@example.com",
        name: "John Doe",
        password: "password123"
    };

    types:AuthResponse|error user1Result = auth:signupUser(user1Request);
    if user1Result is error {
        return error("Failed to create user 1: " + user1Result.message());
    }

    if !user1Result.success {
        return error("Failed to create user 1: " + user1Result.message);
    }

    // Get created user from database
    types:User|error user1 = database:getUserByEmail(user1Request.email);
    if user1 is error {
        return error("Failed to fetch user 1: " + user1.message());
    }
    users.push(user1);

    // User 2
    types:SignupRequest user2Request = {
        email: "jane.smith@example.com",
        name: "Jane Smith",
        password: "password456"
    };

    types:AuthResponse|error user2Result = auth:signupUser(user2Request);
    if user2Result is error {
        return error("Failed to create user 2: " + user2Result.message());
    }

    if !user2Result.success {
        return error("Failed to create user 2: " + user2Result.message);
    }

    // Get created user from database
    types:User|error user2 = database:getUserByEmail(user2Request.email);
    if user2 is error {
        return error("Failed to fetch user 2: " + user2.message());
    }
    users.push(user2);

    return users;
}

isolated function createAccountsForUser(string userId) returns types:Account[]|error {
    types:Account[] accounts = [];
    time:Utc currentTime = time:utcNow();

    // Credit Card Account
    types:Account creditAccount = {
        id: uuid:createType1AsString(),
        name: "Credit Card",
        accountType: "CREDIT",
        balance: -500.00d,
        isDefault: false,
        userId: userId,
        createdAt: currentTime,
        updatedAt: currentTime
    };

    error? creditResult = database:createAccount(creditAccount);
    if creditResult is error {
        return error("Failed to create credit account: " + creditResult.message());
    }
    accounts.push(creditAccount);

    // Salary Account (Current)
    types:Account salaryAccount = {
        id: uuid:createType1AsString(),
        name: "Salary Account",
        accountType: "CURRENT",
        balance: 5000.00d,
        isDefault: true,
        userId: userId,
        createdAt: currentTime,
        updatedAt: currentTime
    };

    error? salaryResult = database:createAccount(salaryAccount);
    if salaryResult is error {
        return error("Failed to create salary account: " + salaryResult.message());
    }
    accounts.push(salaryAccount);

    // Part-time Account (Savings)
    types:Account partTimeAccount = {
        id: uuid:createType1AsString(),
        name: "Part-time Savings",
        accountType: "SAVINGS",
        balance: 1200.00d,
        isDefault: false,
        userId: userId,
        createdAt: currentTime,
        updatedAt: currentTime
    };

    error? partTimeResult = database:createAccount(partTimeAccount);
    if partTimeResult is error {
        return error("Failed to create part-time account: " + partTimeResult.message());
    }
    accounts.push(partTimeAccount);

    return accounts;
}

isolated function createTransactionsForUser(string userId, types:Account[] accounts) returns error? {
    if accounts.length() < 3 {
        return error("User must have at least 3 accounts");
    }

    types:Account creditAccount = accounts[0];
    types:Account salaryAccount = accounts[1];
    types:Account partTimeAccount = accounts[2];

    // Generate 1000+ transactions (distributed across accounts)
    int totalTransactions = 1200;
    int transactionsPerAccount = totalTransactions / 3;

    // Create transactions for credit account (mostly expenses)
    check createTransactionsForAccount(userId, creditAccount, transactionsPerAccount, 0.9d);

    // Create transactions for salary account (mix of income and expenses)
    check createTransactionsForAccount(userId, salaryAccount, transactionsPerAccount, 0.4d);

    // Create transactions for part-time account (mostly income)
    check createTransactionsForAccount(userId, partTimeAccount, transactionsPerAccount, 0.2d);

    return;
}

isolated function createTransactionsForAccount(string userId, types:Account account, int transactionCount, decimal expenseRatio) returns error? {
    string[] expenseCategories = ["Groceries", "Utilities", "Transportation", "Entertainment", "Healthcare", "Shopping", "Dining", "Gas", "Insurance", "Rent"];
    string[] incomeCategories = ["Salary", "Freelance", "Investment", "Bonus", "Part-time", "Commission", "Dividend", "Refund"];

    time:Utc currentTime = time:utcNow();
    
    int i = 0;
    while i < transactionCount {
        // Determine if this should be an expense or income
        float randomFloat = random:createDecimal();
        decimal randomValue = <decimal>randomFloat;
        boolean isExpense = randomValue < expenseRatio;

        string transactionType = isExpense ? "EXPENSE" : "INCOME";
        string[] categories = isExpense ? expenseCategories : incomeCategories;
        
        // Random category
        int categoryIndex = check random:createIntInRange(0, categories.length());
        string category = categories[categoryIndex];

        // Random amount based on transaction type
        decimal amount;
        if isExpense {
            int randomAmount = check random:createIntInRange(10, 500);
            amount = <decimal>randomAmount;
        } else {
            int randomAmount = check random:createIntInRange(100, 2000);
            amount = <decimal>randomAmount;
        }

        // Random date within last 6 months
        int daysBack = check random:createIntInRange(1, 180);
        time:Utc transactionDate = time:utcAddSeconds(currentTime, <time:Seconds>(-daysBack * 24 * 3600));
        string dateStr = time:utcToString(transactionDate);

        // Random recurring status
        float recurringFloat = random:createDecimal();
        decimal recurringDecimal = <decimal>recurringFloat;
        boolean isRecurring = recurringDecimal < 0.1d; // 10% chance of recurring
        string? recurringInterval = isRecurring ? getRandomRecurringInterval() : ();

        string nextRecurringDateStr = dateStr;
        if isRecurring && recurringInterval is string {
            time:Utc nextDate = calculateNextRecurringDate(transactionDate, recurringInterval);
            nextRecurringDateStr = time:utcToString(nextDate);
        }

        string transactionDescription = string `${category} transaction`;

        types:Transaction newTransaction = {
            id: uuid:createType1AsString(),
            transactionType: transactionType,
            amount: amount,
            description: transactionDescription,
            date: dateStr,
            category: category,
            receiptUrl: "",
            isRecurring: isRecurring,
            recurringInterval: recurringInterval,
            nextRecurringDate: nextRecurringDateStr,
            lastProcessed: time:utcToString(currentTime),
            status: "COMPLETED",
            userId: userId,
            accountId: account.id,
            createdAt: currentTime,
            updatedAt: currentTime
        };

        error? result = database:addTransaction(newTransaction);
        if result is error {
            return error(string `Failed to create transaction ${i}: ${result.message()}`);
        }

        i += 1;
    }

    return;
}

isolated function getRandomRecurringInterval() returns string {
    string[] intervals = ["DAILY", "WEEKLY", "MONTHLY", "YEARLY"];
    int|error index = random:createIntInRange(0, intervals.length());
    if index is error {
        return "MONTHLY"; // Default fallback
    }
    return intervals[index];
}

isolated function calculateNextRecurringDate(time:Utc baseDate, string interval) returns time:Utc {
    int daysToAdd = 0;
    if interval == "DAILY" {
        daysToAdd = 1;
    } else if interval == "WEEKLY" {
        daysToAdd = 7;
    } else if interval == "MONTHLY" {
        daysToAdd = 30;
    } else if interval == "YEARLY" {
        daysToAdd = 365;
    }

    return time:utcAddSeconds(baseDate, <time:Seconds>(daysToAdd * 24 * 3600));
}

isolated function setBudgetForUser(string userId) returns error? {
    // Set a random budget between 2000 and 5000
    int randomBudget = check random:createIntInRange(2000, 5000);
    decimal budgetAmount = <decimal>randomBudget;
    
    error? result = database:updateBudget(userId, budgetAmount);
    if result is error {
        return error("Failed to set budget: " + result.message());
    }

    return;
}