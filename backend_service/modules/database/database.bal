import backend_service.types;

import ballerina/sql;
import ballerinax/java.jdbc as jdbc;

# Database configuration - these will be read from Config.toml or environment variables
configurable string dbHost = "localhost";
configurable int dbPort = 5001;
configurable string dbName = "ballerina_db";
configurable string dbUsername = "postgres";
configurable string dbPassword = "1968";

//  Shared JDBC Client 
final jdbc:Client dbClient = checkpanic new (
    url = string `jdbc:postgresql://${dbHost}:${dbPort}/${dbName}`,
    user = dbUsername,
    password = dbPassword
);

// # Initialize JDBC client with configuration
// isolated function getDbClient() returns jdbc:Client|error {
//     return new (
//         url = string `jdbc:postgresql://${dbHost}:${dbPort}/${dbName}`,
//         user = dbUsername,
//         password = dbPassword
//     );
// }

# Test database connectivity
# + return - Connection status record or error
public isolated function testConnection() returns record {|string status; int test_connection; string current_time;|}|error {

    sql:ParameterizedQuery query = `SELECT 1 as test_connection, NOW() as current_time`;

    record {int test_connection; string current_time;}|sql:Error result = dbClient->queryRow(query);

    if result is sql:Error {
        return error("Database connection failed: " + result.message());
    }

    return {
        status: "Database connected successfully",
        test_connection: result.test_connection,
        current_time: result.current_time
    };
}

# Create a new user in the database
# + user - User data to insert
# + return - Success status or error
public isolated function createUser(types:User user) returns error? {

    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        INSERT INTO users (id, email, name, hashedPassword, createdAt, updatedAt)
        VALUES (${user.id}, ${user.email}, ${user.name}, ${user.hashedPassword}, ${user.createdAt}, ${user.updatedAt})
    `);

    if result is sql:Error {
        return error("Failed to create user: " + result.message());
    }
    return;
}

# Get user by username from database
# + email - Email to search for
# + return - User record or error if not found
public isolated function getUserByEmail(string email) returns types:User|error {

    sql:ParameterizedQuery selectQuery = `
        SELECT id, email, name, hashedPassword, createdAt, updatedAt
        FROM users
        WHERE email = ${email}
    `;

    types:User|sql:Error result = dbClient->queryRow(selectQuery);

    if result is sql:Error {
        return error("User not found or database error: " + result.message());
    }

    return result;
}

# Get user by ID from database
# + userId - User ID to search for
# + return - User record or error if not found
// public isolated function getUserById(string userId) returns types:User|error {

//     sql:ParameterizedQuery selectQuery = `
//         SELECT id, username, hashed_password, created_at, updated_at
//         FROM users
//         WHERE id = ${userId}
//     `;

//     record {|
//         string id;
//         string email;
//         string hashed_password;
//         time:Utc created_at;
//         time:Utc updated_at;
//     |}|sql:Error result = dbClient->queryRow(selectQuery);

//     if result is sql:Error {
//         return error("User not found or database error: " + result.message());
//     }

//     return {
//         id: result.id,
//         email: result.email,
//         hashedPassword: result.hashed_password,
//         createdAt: result.created_at,
//         updatedAt: result.updated_at
//     };
// }

# Check if email exists in database
# + email - email to check
# + return - True if exists, false otherwise, or error
public isolated function emailExists(string email) returns boolean|error {
    sql:ParameterizedQuery selectQuery = `
        SELECT COUNT(*) as count
        FROM users
        WHERE email = ${email}
    `;

    record {int count;}|sql:Error result = dbClient->queryRow(selectQuery);

    if result is sql:Error {
        return error("Database error while checking email: " + result.message());
    }
    return result.count > 0;
}

# Create a new account in the database
# + account - Account data to insert
# + return - Success status or error
public isolated function createAccount(types:Account account) returns error? {
    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        INSERT INTO accounts (id, name, accountType, balance, isDefault, userId, createdAt, updatedAt)
        VALUES (${account.id}, ${account.name}, ${account.accountType}, ${account.balance}, ${account.isDefault}, ${account.userId}, ${account.createdAt}, ${account.updatedAt})
    `);

    if result is sql:Error {
        return error("Failed to create account: " + result.message());
    }
    return;
}
