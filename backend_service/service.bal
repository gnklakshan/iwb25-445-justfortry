import backend_service.database;
import backend_service.auth;
import backend_service.types;

import ballerina/http;

# Database configuration
configurable string dbHost = "localhost";
configurable int dbPort = 5001;
configurable string dbName = "ballerina_db";
configurable string dbUsername = "postgres";
configurable string dbPassword = "1968";

# Initialize database with configuration (immutable)
final readonly & database:DatabaseConfig dbConfig = {
    host: dbHost,
    port: dbPort,
    database: dbName,
    username: dbUsername,
    password: dbPassword
};

# Main service with authentication endpoints and protected resources
service / on new http:Listener(9090) {

    # User signup endpoint
    # + signupRequest - User signup data
    # + return - Authentication response or error
    isolated resource function post auth/signup(types:SignupRequest signupRequest) returns types:AuthResponse|http:BadRequest|http:Conflict|http:InternalServerError {
        types:AuthResponse|error result = auth:signupUser(dbConfig, signupRequest);
        
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
        types:AuthResponse|error result = auth:loginUser(dbConfig, loginRequest);
        
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
        // Extract Authorization header
        string|http:HeaderNotFoundError authHeader = request.getHeader("Authorization");
        
        if authHeader is http:HeaderNotFoundError {
            return <http:Unauthorized>{
                body: {
                    "error": "Authorization header required",
                    "message": "Please provide a valid JWT token in Authorization header"
                }
            };
        }

        // Extract and validate user from token
        types:AuthenticatedUser|error authenticatedUser = auth:extractUserFromToken(authHeader);
        
        if authenticatedUser is error {
            return <http:Unauthorized>{
                body: {
                    "error": "Invalid or expired token",
                    "message": authenticatedUser.message()
                }
            };
        }

        // Token is valid, proceed with database test
        record {|string status; int test_connection; string current_time; string database; string host; int port;|}|error result = database:testConnection(dbConfig);
        
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
            "database": result.database,
            "host": result.host,
            "port": result.port,
            "authenticated_user": {
                "user_id": authenticatedUser.userId,
                "username": authenticatedUser.username
            }
        };
        
        return responseWithUser;
    }
}