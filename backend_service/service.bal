import ballerina/http;
import ballerina/sql;
import ballerinax/java.jdbc as jdbc;

# Database configuration
configurable string dbHost = "localhost";
configurable int dbPort = 5001;
configurable string dbName = "ballerina_db";
configurable string dbUsername = "postgres";
configurable string dbPassword = "1968";

# Initialize JDBC client with PostgreSQL
final jdbc:Client dbClient = check new (
    url = string `jdbc:postgresql://${dbHost}:${dbPort}/${dbName}`,
    user = dbUsername,
    password = dbPassword
);

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # Simple database connectivity test endpoint
    # + return - JSON response with connection status or error
    isolated resource function get test\-db() returns json|http:InternalServerError {
        sql:ParameterizedQuery query = `SELECT 1 as test_connection, NOW() as current_time`;
        
        record {int test_connection; string current_time;}|sql:Error result = dbClient->queryRow(query);
        
        if result is sql:Error {
            return <http:InternalServerError>{
                body: {
                    "error": "Database connection failed",
                    "message": result.message()
                }
            };
        }
        
        return {
            "status": "Database connected successfully",
            "test_connection": result.test_connection,
            "current_time": result.current_time,
            "database": dbName,
            "host": dbHost,
            "port": dbPort
        };
    }

    # Simple accounts endpoint to test table connectivity
    # + return - JSON response with table access status or error
    isolated resource function get accounts() returns json|http:InternalServerError {
        sql:ParameterizedQuery query = `SELECT COUNT(*) as account_count FROM accounts`;
        
        record {int account_count;}|sql:Error result = dbClient->queryRow(query);
        
        if result is sql:Error {
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to query accounts table",
                    "message": result.message(),
                    "suggestion": "Make sure the accounts table exists in your database"
                }
            };
        }
        
        return {
            "status": "Accounts table accessible",
            "account_count": result.account_count,
            "message": "Database connectivity test successful"
        };
    }
}