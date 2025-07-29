import backend_service.database;
import backend_service.types;

import ballerina/crypto;
import ballerina/http;
import ballerina/time;
import ballerina/uuid;

# JWT secret key (in production, use a secure random key)
configurable string jwtSecret = "your-secret-key-change-this-in-production";

# Signup function using database
public isolated function signupUser(types:SignupRequest signupRequest) returns types:AuthResponse|error {
    string email = signupRequest.email.trim();
    string password = signupRequest.password;

    // Validate input
    if !isValidEmail(email) || password.length() < 6 {
        return {
            success: false,
            message: "Email must be valid and password must be at least 6 characters",
            token: ()
        };
    }

    // Check if user already exists
    boolean|error userExists = database:emailExists(email);
    if userExists is error {
        return error("Database error: " + userExists.message());
    }

    if userExists {
        return {
            success: false,
            message: "User already exists",
            token: ()
        };
    }

    // Hash password
    byte[] passwordBytes = password.toBytes();
    byte[] hashedPasswordBytes = crypto:hashSha256(passwordBytes);
    string hashedPassword = hashedPasswordBytes.toBase16();

    // Create new user
    string userId = uuid:createType1AsString();
    time:Utc currentTime = time:utcNow();

    types:User newUser = {
        id: userId,
        email: email,
        hashedPassword: hashedPassword,
        createdAt: currentTime,
        updatedAt: currentTime
    };

    // Save user to database
    error? createResult = database:createUser(newUser);
    if createResult is error {
        return error("Failed to create user: " + createResult.message());
    }

    return {
        success: true,
        message: "User created successfully",
        token: ()
    };
}

# Login function using database
public isolated function loginUser(types:LoginRequest loginRequest) returns types:AuthResponse|error {
    string email = loginRequest.email.trim();
    string password = loginRequest.password;

    //validate  email
    if !isValidEmail(email) {
        return {
            success: false,
            message: "Email must be valid",
            token: ()
        };
    }

    // Get user from database
    types:User|error userResult = database:getUserByEmail(email);
    if userResult is error {
        return {
            success: false,
            message: "Invalid credentials",
            token: ()
        };
    }

    types:User user = userResult;

    // Verify password
    byte[] passwordBytes = password.toBytes();
    byte[] hashedPasswordBytes = crypto:hashSha256(passwordBytes);
    string hashedPassword = hashedPasswordBytes.toBase16();

    if hashedPassword != user.hashedPassword {
        return {
            success: false,
            message: "Invalid credentials",
            token: ()
        };
    }

    // Generate JWT token
    string|error token = generateJwtToken(user);

    if token is error {
        return error("Failed to generate token: " + token.message());
    }

    return {
        success: true,
        message: "Login successful",
        token: token
    };
}

// === JWT GENERATION ===

isolated function generateJwtToken(types:User user) returns string|error {
    time:Utc now = time:utcNow();
    time:Utc exp = time:utcAddSeconds(now, 3600); // 1 hour

    decimal iat = <decimal>now[0] + ((<decimal>now[1]) / 1000000000d);
    decimal expVal = <decimal>exp[0] + ((<decimal>exp[1]) / 1000000000d);

    json header = {alg: "HS256", typ: "JWT"};
    json payload = {
        sub: user.id,
        email: user.email,
        iat: iat,
        exp: expVal
    };

    string headerEncoded = check encodeBase64Url(header.toJsonString().toBytes());
    string payloadEncoded = check encodeBase64Url(payload.toJsonString().toBytes());

    string signingInput = headerEncoded + "." + payloadEncoded;

    byte[] secretBytes = jwtSecret.toBytes();
    byte[] sigBytes = check crypto:hmacSha256(signingInput.toBytes(), secretBytes);

    string signatureEncoded = check encodeBase64Url(sigBytes);

    return signingInput + "." + signatureEncoded;
}

// === JWT VALIDATION ===

public isolated function validateJwtToken(string token) returns types:JwtPayload|error {

    string:RegExp dotPattern = re `\.`;
    string[] parts = dotPattern.split(token);

    if parts.length() != 3 {
        return error("Authentication failed: Invalid token format");
    }

    string headerEncoded = parts[0];
    string payloadEncoded = parts[1];
    string signatureEncoded = parts[2];

    string signingInput = headerEncoded + "." + payloadEncoded;

    byte[] expectedSig = check crypto:hmacSha256(signingInput.toBytes(), jwtSecret.toBytes());
    string expectedSigEncoded = check encodeBase64Url(expectedSig);

    if signatureEncoded != expectedSigEncoded {
        return error("Signature mismatch");
    }

    byte[] payloadBytes = check decodeBase64Url(payloadEncoded);
    string payloadJson = check string:fromBytes(payloadBytes);
    json payloadObj = check payloadJson.fromJsonString();
    types:JwtPayload payload = check payloadObj.cloneWithType();

    decimal nowSeconds = <decimal>time:utcNow()[0] + ((<decimal>time:utcNow()[1]) / 1000000000d);
    if payload.exp < nowSeconds {
        return error("Token expired");
    }

    return payload;
}

// === USER EXTRACTION FROM AUTH HEADER ===

public isolated function extractUserFromToken(string authHeader) returns types:AuthenticatedUser|error {
    string trimmedHeader = authHeader.trim();

    if !trimmedHeader.startsWith("Bearer ") {
        return error("Invalid Authorization header format");
    }

    string token = trimmedHeader.substring(7).trim();
    if token.length() == 0 {
        return error("Token is empty");
    }
    types:JwtPayload payload = check validateJwtToken(token);

    return {
        userId: payload.sub,
        email: payload.email
    };
}

// === AUTH HEADER VALIDATION (STANDARD) ===

public isolated function validateAuthHeader(http:Request req) returns types:AuthenticatedUser|http:Unauthorized {
    string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");

    if authHeader is http:HeaderNotFoundError {
        return <http:Unauthorized>{body: {message: "Authorization header not found"}};
    }

    types:AuthenticatedUser|error result = extractUserFromToken(authHeader);
    if result is error {
        return <http:Unauthorized>{body: {message: result.message()}};
    }

    return result;
}

// === AUTH HEADER VALIDATION (WITH CUSTOM ERROR BODY) ===

public isolated function validateAuthHeaderWithCustomError(http:Request req, json customError) returns types:AuthenticatedUser|http:Unauthorized {
    string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");

    if authHeader is http:HeaderNotFoundError {
        return <http:Unauthorized>{body: customError};
    }

    types:AuthenticatedUser|error result = extractUserFromToken(authHeader);
    if result is error {
        return <http:Unauthorized>{body: customError};
    }

    return result;
}

