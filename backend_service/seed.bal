import backend_service.database;
import backend_service.types;

import ballerina/crypto;
import ballerina/io;
import ballerina/time;
import ballerina/uuid;

# Sample data for generating realistic transactions
final readonly & string[] TRANSACTION_CATEGORIES = [
    "Food & Dining", "Shopping", "Transportation", "Bills & Utilities", 
    "Entertainment", "Healthcare", "Travel", "Education", "Investment", 
    "Salary", "Freelance", "Business", "Gift", "Other"
];

final readonly & string[] TRANSACTION_DESCRIPTIONS = [
    "Grocery shopping", "Restaurant dinner", "Gas station", "Electric bill",
    "Movie tickets", "Doctor visit", "Flight booking", "Online course",
    "Stock purchase", "Monthly salary", "Freelance project", "Business expense",
    "Birthday gift", "ATM withdrawal", "Coffee shop", "Uber ride",
    "Netflix subscription", "Gym membership", "Phone bill", "Internet bill"
];

final readonly & string[] ACCOUNT_NAMES = [
    "Primary Checking", "Savings Account", "Emergency Fund", "Investment Account",
    "Credit Card", "Business Account", "Travel Fund", "Education Savings"
];

# Reduced to 3 sample users only
final readonly & string[] SAMPLE_EMAILS = [
    "john.doe@example.com", "jane.smith@example.com", "mike.johnson@example.com"
];

final readonly & string[] SAMPLE_NAMES = [
    "John Doe", "Jane Smith", "Mike Johnson"
];

final readonly & types:AccountType[] ACCOUNT_TYPES = ["CURRENT", "SAVINGS", "CREDIT"];

# Main function to run the seed data migration
public function main() returns error? {
    io:println("Starting data migration for 90 days...");
    
    // Create sample users
    types:User[]|error sampleUsersResult = createSampleUsers();
    if sampleUsersResult is error {
        return sampleUsersResult;
    }
    types:User[] sampleUsers = sampleUsersResult;
    io:println("Created/verified sample users");
    
    // Create accounts for each user
    types:Account[]|error sampleAccountsResult = createSampleAccounts(sampleUsers);
    if sampleAccountsResult is error {
        return sampleAccountsResult;
    }
    types:Account[] sampleAccounts = sampleAccountsResult;
    io:println("Created sample accounts");
    
    // Generate transactions for the past 90 days
    error? transactionResult = generateTransactionsFor90Days(sampleUsers, sampleAccounts);
    if transactionResult is error {
        return transactionResult;
    }
    io:println("Generated transactions for 90 days");
    
    io:println("Data migration completed successfully!");
}

# Create sample users with realistic data - handles existing users
isolated function createSampleUsers() returns types:User[]|error {
    types:User[] users = [];
    
    time:Utc currentTime = time:utcNow();
    
    foreach int i in 0 ..< SAMPLE_EMAILS.length() {
        string userEmail = SAMPLE_EMAILS[i];
        string userName = SAMPLE_NAMES[i];
        
        // Check if user already exists
        boolean|error userExists = database:emailExists(userEmail);
        if userExists is error {
            io:println("Error checking if user exists: " + userEmail);
            return userExists;
        }
        
        if userExists {
            io:println("User already exists, fetching: " + userEmail);
            // Get existing user
            types:User|error existingUser = database:getUserByEmail(userEmail);
            if existingUser is error {
                io:println("Failed to fetch existing user: " + userEmail);
                return existingUser;
            }
            users.push(existingUser);
        } else {
            // Create new user
            string userId = uuid:createType1AsString();
            
            // Hash a default password for all sample users
            byte[] passwordBytes = "password123".toBytes();
            byte[] hashedPasswordBytes = crypto:hashSha256(passwordBytes);
            string hashedPassword = hashedPasswordBytes.toBase16();
            
            types:User user = {
                id: userId,
                email: userEmail,
                name: userName,
                hashedPassword: hashedPassword,
                createdAt: currentTime,
                updatedAt: currentTime
            };
            
            // Save user to database
            error? createResult = database:createUser(user);
            if createResult is error {
                io:println("Failed to create user: " + user.email);
                return createResult;
            }
            
            io:println("Created new user: " + userEmail);
            users.push(user);
        }
    }
    
    return users;
}

# Create sample accounts for users
isolated function createSampleAccounts(types:User[] users) returns types:Account[]|error {
    types:Account[] accounts = [];
    
    time:Utc currentTime = time:utcNow();
    
    foreach types:User user in users {
        // Check if user already has accounts
        types:AccountResponse[]|error existingAccounts = database:getAccountsByUserId(user.id);
        if existingAccounts is error {
            io:println("Error checking existing accounts for user: " + user.email);
            return existingAccounts;
        }
        
        if existingAccounts.length() > 0 {
            io:println("User already has accounts, skipping account creation: " + user.email);
            // Convert AccountResponse to Account for consistency
            foreach types:AccountResponse accResp in existingAccounts {
                types:Account account = {
                    id: accResp.id,
                    name: accResp.name,
                    accountType: <types:AccountType>accResp.accountType,
                    balance: accResp.balance,
                    isDefault: accResp.isDefault,
                    userId: accResp.userId,
                    createdAt: currentTime, // We don't have the original timestamps
                    updatedAt: currentTime
                };
                accounts.push(account);
            }
            continue;
        }
        
        // Create 2-3 accounts per user
        int accountCount = 2 + (user.id.length() % 2); // Random between 2-3
        
        foreach int i in 0 ..< accountCount {
            string accountId = uuid:createType1AsString();
            types:AccountType accountType = ACCOUNT_TYPES[i % ACCOUNT_TYPES.length()];
            
            // Generate realistic balances based on account type
            decimal balance = 0.0;
            if accountType == "CURRENT" {
                balance = 1000.0 + <decimal>(user.id.length() * 100); // $1000-$2600
            } else if accountType == "SAVINGS" {
                balance = 5000.0 + <decimal>(user.id.length() * 200); // $5000-$12200
            } else if accountType == "CREDIT" {
                balance = -500.0 - <decimal>(user.id.length() * 50); // -$500 to -$2300
            }
            
            string accountName = ACCOUNT_NAMES[i % ACCOUNT_NAMES.length()];
            
            types:Account account = {
                id: accountId,
                name: accountName,
                accountType: accountType,
                balance: balance,
                isDefault: i == 0, // First account is default
                userId: user.id,
                createdAt: currentTime,
                updatedAt: currentTime
            };
            
            // Save account to database
            error? createResult = database:createAccount(account);
            if createResult is error {
                io:println("Failed to create account: " + account.name);
                return createResult;
            }
            
            accounts.push(account);
        }
    }
    
    return accounts;
}

# Generate transactions for the past 90 days
isolated function generateTransactionsFor90Days(types:User[] users, types:Account[] accounts) returns error? {
    time:Utc currentTime = time:utcNow();
    
    // Generate transactions for each day in the past 90 days
    foreach int dayOffset in 0 ..< 90 {
        time:Utc transactionDate = time:utcAddSeconds(currentTime, -86400 * dayOffset);
        
        // Generate 3-6 transactions per day across all users (reduced from 5-15)
        int dailyTransactionCount = 3 + (dayOffset % 4);
        
        foreach int txnIndex in 0 ..< dailyTransactionCount {
            // Select random user and their account
            int userIndex = txnIndex % users.length();
            types:User selectedUser = users[userIndex];
            
            // Get accounts for this user
            types:Account[] userAccounts = [];
            foreach types:Account account in accounts {
                if account.userId == selectedUser.id {
                    userAccounts.push(account);
                }
            }
            
            if userAccounts.length() == 0 {
                continue;
            }
            
            types:Account selectedAccount = userAccounts[txnIndex % userAccounts.length()];
            
            // Generate transaction
            types:Transaction|error transactionResult = generateRandomTransaction(
                selectedUser, selectedAccount, transactionDate, dayOffset, txnIndex
            );
            
            if transactionResult is error {
                io:println("Failed to generate transaction for day " + dayOffset.toString());
                return transactionResult;
            }
            
            types:Transaction generatedTransaction = transactionResult;
            
            // Save transaction to database
            error? createResult = database:addTransaction(generatedTransaction);
            if createResult is error {
                io:println("Failed to create transaction for day " + dayOffset.toString());
                return createResult;
            }
        }
    }
    
    return;
}

# Generate a random transaction with realistic data
isolated function generateRandomTransaction(
    types:User user, 
    types:Account account, 
    time:Utc transactionDate,
    int dayOffset,
    int txnIndex
) returns types:Transaction|error {
    
    string transactionId = uuid:createType1AsString();
    
    // Determine transaction type based on account type and randomness
    string transactionType = "EXPENSE";
    if account.accountType == "SAVINGS" && (txnIndex % 5) == 0 {
        transactionType = "INCOME";
    } else if account.accountType == "CURRENT" && (txnIndex % 7) == 0 {
        transactionType = "INCOME";
    } else if (txnIndex % 10) == 0 {
        transactionType = "TRANSFER";
    }
    
    // Generate amount based on transaction type and day pattern
    decimal amount = 0.0;
    if transactionType == "INCOME" {
        amount = 500.0 + <decimal>((dayOffset + txnIndex) % 2000); // $500-$2500
    } else {
        amount = 10.0 + <decimal>((dayOffset * txnIndex) % 500); // $10-$510
    }
    
    // Select category and description
    int categoryIndex = txnIndex % TRANSACTION_CATEGORIES.length();
    int descriptionIndex = txnIndex % TRANSACTION_DESCRIPTIONS.length();
    string category = TRANSACTION_CATEGORIES[categoryIndex];
    string description = TRANSACTION_DESCRIPTIONS[descriptionIndex];
    
    // Determine if transaction is recurring (10% chance)
    boolean isRecurring = (txnIndex % 10) == 0;
    types:RecurringInterval? recurringInterval = ();
    string nextRecurringDate = "";
    
    if isRecurring {
        types:RecurringInterval[] intervals = ["DAILY", "WEEKLY", "MONTHLY", "YEARLY"];
        int intervalIndex = txnIndex % intervals.length();
        recurringInterval = intervals[intervalIndex];
        
        // Calculate next recurring date
        int daysToAdd = 1;
        if recurringInterval == "WEEKLY" {
            daysToAdd = 7;
        } else if recurringInterval == "MONTHLY" {
            daysToAdd = 30;
        } else if recurringInterval == "YEARLY" {
            daysToAdd = 365;
        }
        
        time:Utc nextDate = time:utcAddSeconds(transactionDate, 86400 * daysToAdd);
        nextRecurringDate = time:utcToString(nextDate);
    } else {
        // For non-recurring transactions, set nextRecurringDate to current timestamp
        // This avoids the empty string issue with PostgreSQL timestamp fields
        nextRecurringDate = time:utcToString(transactionDate);
    }
    
    // Determine transaction status (90% completed, 8% pending, 2% failed)
    types:TransactionStatus status = "COMPLETED";
    int statusRandom = txnIndex % 50;
    if statusRandom < 1 {
        status = "FAILED";
    } else if statusRandom < 5 {
        status = "PENDING";
    }
    
    string? recurringIntervalStr = ();
    if recurringInterval is types:RecurringInterval {
        recurringIntervalStr = recurringInterval;
    }
    
    string statusStr = status;
    
    return {
        id: transactionId,
        transactionType: transactionType,
        amount: amount,
        description: description,
        date: time:utcToString(transactionDate),
        category: category,
        receiptUrl: "https://example.com/receipts/" + transactionId + ".pdf",
        isRecurring: isRecurring,
        recurringInterval: recurringIntervalStr,
        nextRecurringDate: nextRecurringDate,
        lastProcessed: time:utcToString(transactionDate),
        status: statusStr,
        userId: user.id,
        accountId: account.id,
        createdAt: transactionDate,
        updatedAt: transactionDate
    };
}