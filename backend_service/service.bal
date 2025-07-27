import ballerina/http;
import backend_service.database;

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

# A simple service for testing database connectivity
# bound to port `9090`.
service / on new http:Listener(9090) {

    # Database connectivity test endpoint
    # + return - JSON response with connection status or error
    isolated resource function get test\-db() returns json|http:InternalServerError {
        record {|string status; int test_connection; string current_time; string database; string host; int port;|}|error result = database:testConnection(dbConfig);
        
        if result is error {
            return <http:InternalServerError>{
                body: {
                    "error": "Database connection failed",
                    "message": result.message()
                }
            };
        }
        
        return result.toJson();
    }
}