import ballerina/sql;
import ballerinax/java.jdbc as jdbc;
import ballerina/time;

# Database configuration record
public type DatabaseConfig record {|
    string host;
    int port;
    string database;
    string username;
    string password;
|};

# User record for database operations
public type User record {|
    string id;
    string username;
    string hashedPassword;
    time:Utc createdAt;
    time:Utc updatedAt;
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

# Initialize database tables
# + config - Database configuration
# + return - Success status or error
public isolated function initializeDatabase(DatabaseConfig config) returns error? {
    jdbc:Client dbClient = check getDbClient(config);
    
    // Create users table if it doesn't exist
    sql:ParameterizedQuery createUsersTable = `
        CREATE TABLE IF NOT EXISTS users (
            id VARCHAR(255) PRIMARY KEY,
            username VARCHAR(100) UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        )
    `;
    
    sql:ExecutionResult|sql:Error result = dbClient->execute(createUsersTable);
    
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error
    }
    
    if result is sql:Error {
        return error("Failed to create users table: " + result.message());
    }
    
    return;
}

# Create a new user in the database
# + config - Database configuration
# + user - User data to insert
# + return - Success status or error
public isolated function createUser(DatabaseConfig config, User user) returns error? {
    jdbc:Client dbClient = check getDbClient(config);
    
    sql:ParameterizedQuery insertQuery = `
        INSERT INTO users (id, username, hashed_password, created_at, updated_at)
        VALUES (${user.id}, ${user.username}, ${user.hashedPassword}, ${user.createdAt}, ${user.updatedAt})
    `;
    
    sql:ExecutionResult|sql:Error result = dbClient->execute(insertQuery);
    
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error
    }
    
    if result is sql:Error {
        return error("Failed to create user: " + result.message());
    }
    
    return;
}

# Get user by username from database
# + config - Database configuration
# + username - Username to search for
# + return - User record or error if not found
public isolated function getUserByUsername(DatabaseConfig config, string username) returns User|error {
    jdbc:Client dbClient = check getDbClient(config);
    
    sql:ParameterizedQuery selectQuery = `
        SELECT id, username, hashed_password, created_at, updated_at
        FROM users
        WHERE username = ${username}
    `;
    
    record {|
        string id;
        string username;
        string hashed_password;
        time:Utc created_at;
        time:Utc updated_at;
    |}|sql:Error result = dbClient->queryRow(selectQuery);
    
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error
    }
    
    if result is sql:Error {
        return error("User not found or database error: " + result.message());
    }
    
    return {
        id: result.id,
        username: result.username,
        hashedPassword: result.hashed_password,
        createdAt: result.created_at,
        updatedAt: result.updated_at
    };
}

# Get user by ID from database
# + config - Database configuration
# + userId - User ID to search for
# + return - User record or error if not found
public isolated function getUserById(DatabaseConfig config, string userId) returns User|error {
    jdbc:Client dbClient = check getDbClient(config);
    
    sql:ParameterizedQuery selectQuery = `
        SELECT id, username, hashed_password, created_at, updated_at
        FROM users
        WHERE id = ${userId}
    `;
    
    record {|
        string id;
        string username;
        string hashed_password;
        time:Utc created_at;
        time:Utc updated_at;
    |}|sql:Error result = dbClient->queryRow(selectQuery);
    
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error
    }
    
    if result is sql:Error {
        return error("User not found or database error: " + result.message());
    }
    
    return {
        id: result.id,
        username: result.username,
        hashedPassword: result.hashed_password,
        createdAt: result.created_at,
        updatedAt: result.updated_at
    };
}

# Check if username exists in database
# + config - Database configuration
# + username - Username to check
# + return - True if exists, false otherwise, or error
public isolated function usernameExists(DatabaseConfig config, string username) returns boolean|error {
    jdbc:Client dbClient = check getDbClient(config);
    
    sql:ParameterizedQuery selectQuery = `
        SELECT COUNT(*) as count
        FROM users
        WHERE username = ${username}
    `;
    
    record {int count;}|sql:Error result = dbClient->queryRow(selectQuery);
    
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error
    }
    
    if result is sql:Error {
        return error("Database error while checking username: " + result.message());
    }
    
    return result.count > 0;
}