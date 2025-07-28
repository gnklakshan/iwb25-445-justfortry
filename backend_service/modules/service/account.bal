import backend_service.types

// add new account
isolated function createNewAccount(types:CreateAccountRequest createAccountRequest) returns types:CreateAccountResponse|error {
    // Generate account ID and timestamps
    string accountId = uuid:createType1AsString();
    time:Utc currentTime = time:utcNow();
    string currentTimeString = time:utcToString(currentTime);
    string userId = "";

    // Create account record
    types:Account newAccount = {
        ...createAccountRequest,
        id: accountId,
        userId: userId,
        createdAt: currentTimeString,
        updatedAt: currentTimeString
    };

    // Save account to database
    error? createResult = database:createAccount(newAccount);
    if createResult is error {
        return error("Failed to create account: " + createResult.message());
    }

    return {
        success: true,
        data: newAccount
    };
}
