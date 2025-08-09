import backend_service.types;

import ballerina/sql;
import ballerina/time;
import ballerinax/java.jdbc as jdbc;

# Database configuration - these will be read from Config.toml or environment variables
configurable string dbHost = "localhost";
configurable int dbPort = 5001;
configurable string dbName = "ballerina_db";
configurable string dbUsername = "postgres";
configurable string dbPassword = "1968";

//  Shared JDBC Client 
final jdbc:Client dbClient = checkpanic new (
    url = string `jdbc:postgresql://${dbHost}:${dbPort}/${dbName}`,
    user = dbUsername,
    password = dbPassword
);

# Test database connectivity
# + return - Connection status record or error
public isolated function testConnection() returns record {|string status; int test_connection; string current_time;|}|error {

    sql:ParameterizedQuery query = `SELECT 1 as test_connection, NOW() as current_time`;

    record {int test_connection; string current_time;}|sql:Error result = dbClient->queryRow(query);

    if result is sql:Error {
        return error("Database connection failed: " + result.message());
    }

    return {
        status: "Database connected successfully",
        test_connection: result.test_connection,
        current_time: result.current_time
    };
}

# Create a new user in the database
# + user - User data to insert
# + return - Success status or error
public isolated function createUser(types:User user) returns error? {

    string createdAtStr = time:utcToString(user.createdAt);
    string updatedAtStr = time:utcToString(user.updatedAt);

    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        INSERT INTO users (id, email, name, hashedPassword, createdAt, updatedAt)
        VALUES (${user.id}, ${user.email}, ${user.name}, ${user.hashedPassword}, ${createdAtStr}::timestamp, ${updatedAtStr}::timestamp)
    `);

    if result is sql:Error {
        return error("Failed to create user: " + result.message());
    }
    return;
}

# Get user by username from database
# + email - Email to search for
# + return - User record or error if not found
public isolated function getUserByEmail(string email) returns types:User|error {

    sql:ParameterizedQuery selectQuery = `
        SELECT id, email, name, hashedPassword, createdAt, updatedAt
        FROM users
        WHERE email = ${email}
    `;

    types:User|sql:Error result = dbClient->queryRow(selectQuery);

    if result is sql:Error {
        return error("User not found or database error: " + result.message());
    }

    return result;
}

# Check if email exists in database
# + email - email to check
# + return - True if exists, false otherwise, or error
public isolated function emailExists(string email) returns boolean|error {
    sql:ParameterizedQuery selectQuery = `
        SELECT COUNT(*) as count
        FROM users
        WHERE email = ${email}
    `;

    record {int count;}|sql:Error result = dbClient->queryRow(selectQuery);

    if result is sql:Error {
        return error("Database error while checking email: " + result.message());
    }
    return result.count > 0;
}

# Create a new account in the database
# + account - Account data to insert
# + return - Success status or error
public isolated function createAccount(types:Account account) returns error? {
    string createdAtStr = time:utcToString(account.createdAt);
    string updatedAtStr = time:utcToString(account.updatedAt);

    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        INSERT INTO accounts (id, name, accountType, balance, isDefault, userId, createdAt, updatedAt)
        VALUES (${account.id}, ${account.name}, ${account.accountType}, ${account.balance}, ${account.isDefault}, ${account.userId}, ${createdAtStr}::timestamp, ${updatedAtStr}::timestamp)
    `);

    if result is sql:Error {
        return error("Failed to create account: " + result.message());
    }
    return;
}

# Get accounts by user ID from database
# + userId - User ID to search for
# + return - Array of Account records or error
public isolated function getAccountsByUserId(string userId) returns types:AccountResponse[]|error {
    sql:ParameterizedQuery selectQuery = `
        SELECT id, name, accountType, balance, isDefault, userId
        FROM accounts
        WHERE userId = ${userId}
    `;

    stream<types:AccountResponse, sql:Error?> accountStream = dbClient->query(selectQuery);
    types:AccountResponse[] accountResponses = [];

    check from types:AccountResponse account in accountStream
        do {
            accountResponses.push(account);
        };

    check accountStream.close();
    return accountResponses;
}

# Get account by ID and user ID from database
# + accountId - Account ID to search for
# + userId - User ID to verify ownership
# + return - Account record or error if not found
public isolated function getAccountById(string accountId, string userId) returns types:AccountResponse|error {
    sql:ParameterizedQuery selectQuery = `
        SELECT id, name, accountType, balance, isDefault, userId
        FROM accounts
        WHERE id = ${accountId} AND userId = ${userId}
    `;

    types:AccountResponse|sql:Error result = dbClient->queryRow(selectQuery);

    if result is sql:Error {
        return error("Account not found or database error: " + result.message());
    }

    return result;
}

# Get transactions by account ID and user ID from database
# + accountId - Account ID to search for
# + userId - User ID to verify ownership
# + return - Array of Transaction records or error
public isolated function getTransactionsByAccountId(string accountId, string userId) returns types:Transaction[]|error {
    sql:ParameterizedQuery selectQuery = `
        SELECT 
            id, 
            transactionType::text as transactionType, 
            amount, 
            description, 
            date, 
            category, 
            receiptUrl, 
            isRecurring, 
            recurringInterval::text as recurringInterval, 
            nextRecurringDate, 
            lastProcessed, 
            status::text as status, 
            userId, 
            accountId, 
            createdAt, 
            updatedAt
        FROM transactions
        WHERE accountId = ${accountId} AND userId = ${userId}
    `;

    stream<types:Transaction, sql:Error?> transactionStream = dbClient->query(selectQuery);
    types:Transaction[] transactions = [];

    check from types:Transaction txn in transactionStream
        do {
            transactions.push(txn);
        };

    check transactionStream.close();
    return transactions;
}

public isolated function updateAccountStatus(string accountId, string userId, boolean isDefault) returns error? {
    // unset isDefault for all accounts of the user
    sql:ExecutionResult|sql:Error unsetResult = dbClient->execute(`
        UPDATE accounts
        SET isDefault = false
        WHERE userId = ${userId}
    `);

    if unsetResult is sql:Error {
        return error(unsetResult.message());
    }

    // set isDefault for the specified account
    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        UPDATE accounts
        SET isDefault = ${isDefault}
        WHERE id = ${accountId} AND userId = ${userId}
    `);

    if result is sql:Error {
        return error("Failed to update account status: " + result.message());
    }
    return;
}

isolated function updateAccountBalance(string userId, string transactionType, decimal amount, string accountId) returns error? {
    decimal transactionAmount = transactionType == "EXPENSE" ? -amount : amount;

    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        UPDATE accounts
        SET balance = balance + ${transactionAmount}
        WHERE id = ${accountId} AND userId = ${userId}
    `);

    if result is sql:Error {
        return error("Failed to update account balance: " + result.message());
    }
    return;
}

public isolated function addTransaction(types:Transaction trans) returns error? {
    string createdAtStr = time:utcToString(trans.createdAt);
    string updatedAtStr = time:utcToString(trans.updatedAt);

    // Handle nullable recurringInterval
    string? recurringIntervalStr = trans.recurringInterval;

    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        INSERT INTO transactions (id, transactionType, amount, description, date, category, receiptUrl, isRecurring, recurringInterval, nextRecurringDate, lastProcessed, status, userId, accountId, createdAt, updatedAt)
        VALUES (${trans.id}, ${trans.transactionType}::transactiontype, ${trans.amount}, ${trans.description}, ${trans.date}::timestamp, ${trans.category}, ${trans.receiptUrl}, ${trans.isRecurring}, ${recurringIntervalStr}::recurringinterval, ${trans.nextRecurringDate}::timestamp, ${trans.lastProcessed}::timestamp, ${trans.status}::transactionstatus, ${trans.userId}, ${trans.accountId}, ${createdAtStr}::timestamp, ${updatedAtStr}::timestamp)
    `);

    if result is sql:Error {
        return error("Failed to add transaction: " + result.message());
    }
    if trans.status === "COMPLETED" {
        // Update account balance if transaction is completed
        check updateAccountBalance(trans.userId, trans.transactionType, trans.amount, trans.accountId);
    }

    return;
}

public isolated function updateTransaction(string transactionId, string userId, types:dbTransactionUpdate updateRequest) returns types:Transaction|error {
    string updatedAtStr = time:utcToString(time:utcNow());

    //get previous transactions
    types:Transaction|error previousTransaction = fetchTransactionById(transactionId, userId);
    if previousTransaction is error {
        return error("Failed to fetch previous transaction: " + previousTransaction.message());
    }

    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        UPDATE transactions
        SET transactionType = COALESCE(${updateRequest.transactionType}    ::transactiontype, transactionType),
        amount = COALESCE(${updateRequest.amount}, amount),
        description = COALESCE(${updateRequest.description}, description),
        date = COALESCE(${updateRequest.date}    ::timestamp, date),
        category = COALESCE(${updateRequest.category}, category),
        receiptUrl = COALESCE(${updateRequest.receiptUrl}, receiptUrl),
        isRecurring = COALESCE(${updateRequest.isRecurring}, isRecurring),
        recurringInterval = COALESCE(${updateRequest.recurringInterval}    ::recurringinterval, recurringInterval),
        nextRecurringDate = COALESCE(${updateRequest.nextRecurringDate}    ::timestamp, nextRecurringDate),
        lastProcessed = COALESCE(${updateRequest.lastProcessed}    ::timestamp, lastProcessed),
        status = COALESCE(${updateRequest.status}    ::transactionstatus, status),
        updatedAt = ${updatedAtStr}    ::timestamp
        WHERE    id = ${transactionId}    AND userId = ${userId}`
    );

    if result is sql:Error {
        return error("Failed to update transaction: " + result.message());
    }

    // //compare previous amount,type and status and then update the account balance
    boolean isAmountChanged = previousTransaction.amount != updateRequest.amount;
    boolean isTypeChanged = previousTransaction.transactionType != updateRequest.transactionType;
    boolean isStatusChanged = previousTransaction.status != updateRequest.status;

    boolean wasCompleted = previousTransaction.status == "COMPLETED";
    boolean isNowCompleted = updateRequest.status == "COMPLETED";

    if isAmountChanged || isTypeChanged || isStatusChanged {
        if isStatusChanged {
            if wasCompleted {
                // Revert previous completed transaction
                decimal revertAmount = previousTransaction.transactionType == "INCOME"
                    ? -previousTransaction.amount : previousTransaction.amount;
                check updateAccountBalance(userId, previousTransaction.transactionType, revertAmount, previousTransaction.accountId);
            }
            if isNowCompleted {
                // Apply new completed transaction
                decimal applyAmount = updateRequest.transactionType == "INCOME"
                    ? updateRequest.amount ?: 0.0 : -(updateRequest.amount ?: 0.0);
                check updateAccountBalance(userId, <string>updateRequest.transactionType, applyAmount, previousTransaction.accountId);
            }
        } else if wasCompleted {
            // Status unchanged but transaction was completed
            // Revert old transaction
            decimal revertAmount = previousTransaction.transactionType == "INCOME"
                ? -previousTransaction.amount : previousTransaction.amount;
            check updateAccountBalance(userId, previousTransaction.transactionType, revertAmount, previousTransaction.accountId);

            // Apply new transaction
            decimal applyAmount = updateRequest.transactionType == "INCOME"
                ? updateRequest.amount ?: 0.0 : -(updateRequest.amount ?: 0.0);
            check updateAccountBalance(userId, <string>updateRequest.transactionType, applyAmount, previousTransaction.accountId);
        }
    }

    types:Transaction|error updatedTransaction = fetchTransactionById(transactionId, userId);
    if updatedTransaction is error {
        return error("Failed to fetch updated transaction: " + updatedTransaction.message());
    }

    return updatedTransaction;
}

public isolated function fetchAllTransactionOfUser(string userId) returns types:Transaction[]|error {
    sql:ParameterizedQuery selectQuery = `
        SELECT 
            id, 
            transactionType::text as transactionType, 
            amount, 
            description, 
            date, 
            category, 
            receiptUrl, 
            isRecurring, 
            recurringInterval::text as recurringInterval, 
            nextRecurringDate, 
            lastProcessed, 
            status::text as status, 
            userId, 
            accountId, 
            createdAt, 
            updatedAt
        FROM transactions
        WHERE userId = ${userId}
    `;

    stream<types:Transaction, sql:Error?> transactionStream = dbClient->query(selectQuery);
    types:Transaction[] transactions = [];

    check from types:Transaction txn in transactionStream
        do {
            transactions.push(txn);
        };

    check transactionStream.close();
    return transactions;
}

public isolated function fetchTransactionById(string transactionId, string userId) returns types:Transaction|error {
    sql:ParameterizedQuery selectQuery = `
        SELECT 
            id, 
            transactionType::text as transactionType, 
            amount, 
            description, 
            date, 
            category, 
            receiptUrl, 
            isRecurring, 
            recurringInterval::text as recurringInterval, 
            nextRecurringDate, 
            lastProcessed, 
            status::text as status, 
            userId, 
            accountId, 
            createdAt, 
            updatedAt
        FROM transactions
        WHERE id = ${transactionId} AND userId = ${userId}
    `;

    types:Transaction|sql:Error result = dbClient->queryRow(selectQuery);

    if result is sql:Error {
        return error("Transaction not found or database error: " + result.message());
    }

    return result;
}
