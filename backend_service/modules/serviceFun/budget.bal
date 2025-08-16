import backend_service.auth;
import backend_service.database;
import backend_service.types;

import ballerina/http;

public isolated function updateUserBudget(http:Request request, types:UpdateBudgetRequest updateBudgetRequest) returns types:UpdateBudgetRequest|error {
    // Validate authorization header 
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to fetch account");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // Call the database function to update the budget
    error? result = database:updateBudget(authResult.userId, updateBudgetRequest.amount);
    if result is error {
        return error("Failed to update budget: " + result.message());
    }

    return updateBudgetRequest;
}

public isolated function getUserBudget(http:Request request) returns types:BudgetResponse|error {
    // Validate authorization header 
    types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

    if authResult is http:Unauthorized {
        return error("Unauthorized: Authentication required to fetch budget");
    }

    types:AuthenticatedUser authenticatedUser = authResult;
    string userId = authenticatedUser.userId;

    // get the budget
    types:Budget|error budget = database:getBudgetByUserId(userId);
    if budget is error {
        return error("Failed to fetch budget: " + budget.message());
    }

    types:Account|error account = database:getDefaultAccount(userId);
    if account is error {
        return error("Failed to fetch default account: " + account.message());
    }

    return {
        amount: budget.amount,
        accountName: account.name,
        accountType: account.accountType,
        balance: account.balance
    };
}
