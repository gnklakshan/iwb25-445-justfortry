import backend_service.auth;
import backend_service.database;
import backend_service.serviceFun;
import backend_service.types;

import ballerina/http;

# Main service with authentication endpoints and protected resources
service / on new http:Listener(9090) {
    # User signup endpoint
    # + signupRequest - User signup data
    # + return - Authentication response or error
    isolated resource function post auth/signup(types:SignupRequest signupRequest) returns types:AuthResponse|http:BadRequest|http:Conflict|http:InternalServerError {
        types:AuthResponse|error result = auth:signupUser(signupRequest);

        if result is error {
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Internal server error: " + result.message(),
                    token: ()
                }
            };
        }

        if !result.success {
            if result.message.includes("already exists") {
                return <http:Conflict>{
                    body: result
                };
            } else {
                return <http:BadRequest>{
                    body: result
                };
            }
        }

        return result;
    }

    # User login endpoint
    # + loginRequest - User login credentials
    # + return - Authentication response with token or error
    isolated resource function post auth/login(types:LoginRequest loginRequest) returns types:AuthResponse|http:Unauthorized|http:InternalServerError {
        types:AuthResponse|error result = auth:loginUser(loginRequest);

        if result is error {
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Internal server error: " + result.message(),
                    token: ()
                }
            };
        }

        if !result.success {
            return <http:Unauthorized>{
                body: result
            };
        }

        return result;
    }

    # Protected database connectivity test endpoint
    # Requires valid JWT token in Authorization header
    # + request - HTTP request with Authorization header
    # + return - JSON response with connection status or error
    isolated resource function get test\-db(http:Request request) returns json|http:InternalServerError|http:Unauthorized {
        // Validate authorization header using utility function
        types:AuthenticatedUser|http:Unauthorized authResult = auth:validateAuthHeader(request);

        if authResult is http:Unauthorized {
            return authResult;
        }

        types:AuthenticatedUser authenticatedUser = authResult;

        // Token is valid, proceed with database test
        record {|string status; int test_connection; string current_time;|}|error result = database:testConnection();

        if result is error {
            return <http:InternalServerError>{
                body: {
                    "success": false,
                    "message": "Unable to connect to the database. "
                }
            };
        }

        // Create response with authenticated user info
        json responseWithUser = {
            "success": true,
            "message": "Database connection successful",
            "data": {
                "status": result.status,
                "test_connection": result.test_connection,
                "current_time": result.current_time,
                "authenticated_user": {
                    "user_id": authenticatedUser.userId,
                    "username": authenticatedUser.email
                }
            }
        };

        return responseWithUser;
    }

    # Create new account endpoint
    # Requires valid JWT token in Authorization header
    # + request - HTTP request with Authorization header
    # + createAccountRequest - Account creation data
    # + return - Account creation response or error
    isolated resource function post accounts/create(http:Request request, types:CreateAccountRequest createAccountRequest) returns types:CreateAccountResponse|http:BadRequest|http:Unauthorized|http:InternalServerError {

        types:CreateAccountResponse|error createResult = serviceFun:createNewAccount(request, createAccountRequest);

        if createResult is error {
            string errorMessage = createResult.message();

            // Check if it's an authentication error
            if errorMessage.includes("Unauthorized") {
                return <http:Unauthorized>{
                    body: {
                        success: false,
                        message: "Authentication required. Please provide a valid access token."
                    }
                };
            }

            // Generic error for other issues
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: createResult.message()
                }
            };
        }

        return createResult;
    }

    # Get all accounts endpoint
    # Requires valid JWT token in Authorization header
    # + request - HTTP request with Authorization header
    # + return - JSON response with accounts array or error
    isolated resource function get accounts(http:Request request) returns json|http:BadRequest|http:Unauthorized|http:InternalServerError {
        types:AccountResponse[]|error accountsResult = serviceFun:getAllAccounts(request);

        if accountsResult is error {
            string errorMessage = accountsResult.message();

            // Check if it's an authentication error
            if errorMessage.includes("Unauthorized") {
                return <http:Unauthorized>{
                    body: {
                        success: false,
                        message: "Authentication required. Please provide a valid access token."
                    }
                };
            }

            // Generic error for other issues
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: errorMessage
                }
            };
        }

        // Return accounts data
        json response = {
            "success": true,
            "data": accountsResult.toJson()
        };

        return response;
    }

    # Get single account by ID endpoint with transactions
    # Requires valid JWT token in Authorization header
    # + request - HTTP request with Authorization header
    # + accountId - Account ID to retrieve
    # + return - JSON response with account data and transactions or error
    isolated resource function get accounts/[string accountId](http:Request request) returns json|http:BadRequest|http:Unauthorized|http:InternalServerError {
        types:AccountWithTransactionsResponse|error accountResult = serviceFun:getAccountWithTransactions(request, accountId);

        if accountResult is error {
            string errorMessage = accountResult.message();

            // Check if it's an authentication error
            if errorMessage.includes("Unauthorized") {
                return <http:Unauthorized>{
                    body: {
                        success: false,
                        message: "Authentication required. Please provide a valid access token."
                    }
                };
            }

            // Generic error for other issues
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: errorMessage
                }
            };
        }

        json response = accountResult.toJson();

        return response;
    }

    // get all transactions of a user
    isolated resource function get transactions(http:Request request) returns json|http:BadRequest|http:Unauthorized|http:InternalServerError {
        types:Transaction[]|error transactionsResult = serviceFun:getAllTransactionOfUser(request);

        if transactionsResult is error {
            string errorMessage = transactionsResult.message();

            // an authentication error
            if errorMessage.includes("Unauthorized") {
                return <http:Unauthorized>{
                    body: {
                        success: false,
                        message: "Authentication required. Please provide a valid access token."
                    }
                };
            }

            //  error for other issues
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: errorMessage
                }
            };
        }

        json response = {
            "success": true,
            "data": transactionsResult.toJson()
        };

        return response;
    }

    //update account status
    isolated resource function patch accounts/[string accountId](http:Request request, boolean isDefault) returns json|http:BadRequest|http:Unauthorized|http:InternalServerError {
        map<anydata>|error accountResult = serviceFun:updateAccountStatus(request, accountId, isDefault);

        if accountResult is error {
            string errorMessage = accountResult.message();

            //  authentication error
            if errorMessage.includes("Unauthorized") {
                return <http:Unauthorized>{
                    body: {
                        success: false,
                        message: "Authentication required. Please provide a valid access token."
                    }
                };
            }

            //error for other issues
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: errorMessage
                }
            };
        }

        json response = accountResult.toJson();

        return response;
    }

    isolated resource function post transactions(http:Request request, types:NewTransactionRequest newTransaction) returns json|http:BadRequest|http:Unauthorized|http:InternalServerError {
        types:Transaction|error addResult = serviceFun:createNewTransaction(request, newTransaction);

        if addResult is error {
            string errorMessage = addResult.message();

            // authentication error
            if errorMessage.includes("Unauthorized") {
                return <http:Unauthorized>{
                    body: {
                        success: false,
                        message: "Authentication required. Please provide a valid access token."
                    }
                };
            }

            //  error for other issues
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: errorMessage
                }
            };
        }

        json response = {
            "success": true,
            "data": addResult.toJson()
        };

        return response;
    }
}
