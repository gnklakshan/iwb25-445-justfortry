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

    // Fetch transactions for the account
    types:Transaction[]|error transactionsResult = database:getTransactionsByAccountId(accountId, userId);

    if accountResult is error || transactionsResult is error {
        return error("Failed to fetch account or transactions. ");
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
