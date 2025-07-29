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