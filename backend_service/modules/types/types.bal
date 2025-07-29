import ballerina/time;

//commn Types

public type timeMetadata record {|
    time:Utc createdAt;
    time:Utc updatedAt;
|};

// authentication module types__________________________________________________________
public type User record {|
    string id;
    string email;
    string name?;
    string hashedPassword;
    *timeMetadata;
|};

public type LoginRequest record {|
    string email;
    string password;
|};

# Signup request payload
public type SignupRequest record {|
    string email;
    string name;
    string password;
|};

# Authentication response
public type AuthResponse record {|
    boolean success;
    string message;
    string? token;
|};

# JWT payload
public type JwtPayload record {|
    string sub; // subject (user ID)
    string email;
    decimal exp; // expiration time
    decimal iat; // issued at time
|};

# Authenticated user info
public type AuthenticatedUser record {|
    string userId;
    string email;
|};

// Account module types__________________________________________________________

public type AccountType "CURRENT"|"SAVINGS"|"CREDIT"|"LOAN";

public type Account record {|
    string id;
    string name;
    AccountType accountType;
    decimal balance;
    boolean isDefault;
    string userId;
    *timeMetadata;
|};

public type CreateAccountRequest record {|
    string name;
    AccountType accountType;
    decimal balance;
    boolean isDefault;
|};

public type CreateAccountResponse record {|
    boolean success;
    Account data;
|};
