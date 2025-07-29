import backend_service.auth;
import backend_service.database;
import backend_service.serviceFun;
import backend_service.types;

import ballerina/http;
import ballerina/time;
import ballerina/uuid;

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
            if result.message == "User already exists" {
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
                    "error": "Database connection failed",
                    "message": result.message()
                }
            };
        }

        // Create response with authenticated user info
        json responseWithUser = {
            "status": result.status,
            "test_connection": result.test_connection,
            "current_time": result.current_time,
            "authenticated_user": {
                "user_id": authenticatedUser.userId,
                "username": authenticatedUser.email
            }
        };

        return responseWithUser;
    }

    # Requires valid JWT token in Authorization header
    # + request - HTTP request with Authorization header
    # + createAccountRequest - Account creation data
    # + return - Account creation response or error
    isolated resource function post accounts/create(http:Request request, types:CreateAccountRequest createAccountRequest) returns types:CreateAccountResponse|http:BadRequest|http:Unauthorized|http:InternalServerError {

        createResult = serviceFun:createNewAccount(request, createAccountRequest);
        if createResult is error {
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to create account: " + createResult.message()
                }
            };
        }

        return {
            success: true,
                        userId: "",
                        createdAt: "",
                        updatedAt: ""
                    }
    }
};
}

return {
            success: true,
            data: newAccount
        } ;
}
}
