import backend_service.auth;
import backend_service.database;
import backend_service.types;

import ballerina/http;
import ballerina/time;
import ballerina/uuid;

# Create new account function
# + request - HTTP request with Authorization header
# + createAccountRequest - Account creation data
# + return - Account creation response or error
public isolated function createNewAccount(http:Request request, types:CreateAccountRequest createAccountRequest) returns types:CreateAccountResponse|error {

    // Validate authorization header using utility function
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to create an account");
    }

    types:AuthenticatedUser authenticatedUser = authResult;

    // Generate account ID and timestamps
    string accountId = uuid:createType1AsString();
    time:Utc currentTime = time:utcNow();

    // Create account record
    types:Account newAccount = {
        id: accountId,
        name: createAccountRequest.name,
        accountType: createAccountRequest.accountType,
        balance: createAccountRequest.balance,
        isDefault: createAccountRequest.isDefault,
        userId: authenticatedUser.userId,
        createdAt: currentTime,
        updatedAt: currentTime
    };

    // Save account to database
    error? createResult = database:createAccount(newAccount);
    if createResult is error {
        return error("Account creation failed. Please try again later.");
    }

    return {
        success: true,
        data: newAccount
    };
}

# Get all accounts function
# + request - HTTP request with Authorization header
# + return - Array of account responses or error
public isolated function getAllAccounts(http:Request request) returns types:AccountResponse[]|error {
    // Validate authorization header using utility function
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to fetch accounts");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Fetch accounts from database
    types:AccountResponse[]|error accountsResult = database:getAccountsByUserId(userId);
    if accountsResult is error {
        return error("Failed to fetch accounts. " + accountsResult.message());
    }

    types:AccountResponse[] accounts = accountsResult;

    return accounts;
}

# Get account by ID function
# + request - HTTP request with Authorization header
# + accountId - Account ID to retrieve
# + return - Account response or error
public isolated function getAccountById(http:Request request, string accountId) returns types:AccountResponse|error {
    // Validate authorization header using utility function
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to fetch account");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Fetch account from database
    types:AccountResponse|error accountResult = database:getAccountById(accountId, userId);
    if accountResult is error {
        return error("Failed to fetch account. " + accountResult.message());
    }

    return accountResult;
}

# Get account by ID function with transactions
# + request - HTTP request with Authorization header
# + accountId - Account ID to retrieve
# + return - Account with transactions response or error
public isolated function getAccountWithTransactions(http:Request request, string accountId) returns types:AccountWithTransactionsResponse|error {
    // Validate authorization header 
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to fetch account");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Fetch account from database
    types:AccountResponse|error accountResult = database:getAccountById(accountId, userId);
    if accountResult is error {
        return error("Failed to fetch account. " + accountResult.message());
    }

    // Fetch transactions for the account
    types:Transaction[]|error transactionsResult = database:getTransactionsByAccountId(accountId, userId);
    if transactionsResult is error {
        return error("Failed to fetch transactions. " + transactionsResult.message());
    }

    types:AccountResponse account = accountResult;
    types:Transaction[] transactions = transactionsResult;

    return {
        id: account.id,
        name: account.name,
        accountType: account.accountType,
        balance: account.balance,
        isDefault: account.isDefault,
        userId: account.userId,
        transactions: transactions
    };
}

//update account status
public isolated function updateAccountStatus(http:Request request, string accountId, boolean isDefault) returns error|map<anydata> {
    // Validate authorization header using utility function
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to update account status");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Update account status in database
    error? updateResult = database:updateAccountStatus(accountId, userId, isDefault);
    if updateResult is error {
        return error("Failed to update account status. " + updateResult.message());
    }

    return {
        success: true,
        message: "Account status updated successfully"
    };
}

public isolated function createNewTransaction(http:Request request, types:NewTransactionRequest newTransaction) returns types:Transaction|error {
    // Validate authorization header using utility function
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to create a transaction");
    }

    types:AuthenticatedUser authenticatedUser = authResult;

    // Generate transaction ID and timestamps
    string transactionId = uuid:createType1AsString();
    time:Utc currentTime = time:utcNow();

    // Calculate next recurring date if applicable
    string nextRecurringDateStr = "";
    if newTransaction.isRecurring == true && newTransaction.recurringInterval is types:RecurringInterval {
        types:RecurringInterval interval = <types:RecurringInterval>newTransaction.recurringInterval;

        // Calculate days based on interval type
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

        time:Utc nextRecurringDate = time:utcAddSeconds(currentTime, 86400 * daysToAdd);
        nextRecurringDateStr = time:utcToString(nextRecurringDate);
    }

    // Create transaction record
    types:Transaction newTransactionData = {
        id: transactionId,
        transactionType: newTransaction.transactionType,
        amount: newTransaction.amount,
        description: newTransaction.description,
        date: newTransaction.date,
        category: newTransaction.category,
        receiptUrl: newTransaction.receiptUrl,
        isRecurring: newTransaction.isRecurring,
        recurringInterval: newTransaction.recurringInterval,
        nextRecurringDate: nextRecurringDateStr,
        lastProcessed: time:utcToString(currentTime),
        status: newTransaction.transactionStatus,
        userId: authenticatedUser.userId,
        accountId: newTransaction.accountId,
        createdAt: currentTime,
        updatedAt: currentTime
    };

    // Save transaction to database
    error? createResult = database:addTransaction(newTransactionData);
    if createResult is error {
        return error("Transaction creation failed: " + createResult.message());
    }

    return newTransactionData;
}

public isolated function updateTransaction(http:Request request, string transactionId, types:UpdateRequest updateRequest) returns types:Transaction|error {
    // Validate authorization header using utility function
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to update transaction");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Update transaction in database
    types:Transaction|error updatedTransaction = check database:updateTransaction(transactionId, userId, updateRequest);
    if updatedTransaction is error {
        return error("Failed to update transaction. " + updatedTransaction.message());
    }

    return updatedTransaction;
}

public isolated function getAllTransactionOfUser(http:Request request) returns types:Transaction[]|error {
    // Validate authorization header 
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to fetch account");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Fetch all transactions from database
    types:Transaction[]|error allTransactons = database:fetchAllTransactionOfUser(userId);

    if allTransactons is error {
        return error("Failed to fetch transactions. " + allTransactons.message());
    }

    return allTransactons;

}

public isolated function getTransactionById(http:Request request, string transactionId) returns types:Transaction|error {
    // Validate authorization 
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to fetch transaction");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Fetch transaction from database
    types:Transaction|error transactionResult = database:fetchTransactionById(transactionId, userId);
    if transactionResult is error {
        return error("Failed to fetch transaction. " + transactionResult.message());
    }
    return transactionResult;
}
