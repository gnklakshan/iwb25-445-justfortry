import ballerina/sql;
import ballerinax/java.jdbc as jdbc;

# Database configuration record
public type DatabaseConfig record {|
    string host;
    int port;
    string database;
    string username;
    string password;
|};

# Initialize JDBC client with configuration
isolated function getDbClient(DatabaseConfig config) returns jdbc:Client|error {
    return new (
        url = string `jdbc:postgresql://${config.host}:${config.port}/${config.database}`,
        user = config.username,
        password = config.password
    );
}

# Test database connectivity
# + config - Database configuration
# + return - Connection status record or error
public isolated function testConnection(DatabaseConfig config) returns record {|string status; int test_connection; string current_time; string database; string host; int port;|}|error {
    jdbc:Client dbClient = check getDbClient(config);
    
    sql:ParameterizedQuery query = `SELECT 1 as test_connection, NOW() as current_time`;
    
    record {int test_connection; string current_time;}|sql:Error result = dbClient->queryRow(query);
    
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error but don't fail the test
    }
    
    if result is sql:Error {
        return error("Database connection failed: " + result.message());
    }
    
    return {
        status: "Database connected successfully",
        test_connection: result.test_connection,
        current_time: result.current_time,
        database: config.database,
        host: config.host,
        port: config.port
    };
}