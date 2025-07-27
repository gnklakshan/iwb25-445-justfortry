public type LoginRequest record {|
    string username;
    string password;
|};

# Signup request payload
public type SignupRequest record {|
    string username;
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
    string username;
    decimal exp; // expiration time
    decimal iat; // issued at time
|};

# Authenticated user info
public type AuthenticatedUser record {|
    string userId;
    string username;
|};
