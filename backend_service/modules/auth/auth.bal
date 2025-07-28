import backend_service.database;
import backend_service.types;

import ballerina/crypto;
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

# Generate JWT token
isolated function generateJwtToken(types:User user) returns string|error {
    time:Utc currentTime = time:utcNow();
    time:Utc expirationTime = time:utcAddSeconds(currentTime, 3600); // 1 hour expiration

    // Convert time:Utc to decimal seconds properly
    decimal currentSeconds = convertUtcToDecimal(currentTime);
    decimal expirationSeconds = convertUtcToDecimal(expirationTime);

    types:JwtPayload payload = {
        sub: user.id,
        email: user.email,
        exp: expirationSeconds,
        iat: currentSeconds
    };

    string payloadJson = payload.toJsonString();
    byte[] payloadBytes = payloadJson.toBytes();
    string encodedPayload = encodeBase64(payloadBytes);

    // Create signature using HMAC
    byte[] secretBytes = jwtSecret.toBytes();
    byte[]|crypto:Error signature = crypto:hmacSha256(payloadBytes, secretBytes);
    if signature is crypto:Error {
        return error("Failed to create signature: " + signature.message());
    }
    string encodedSignature = encodeBase64(signature);

    // Simple token format: payload.signature
    return encodedPayload + "." + encodedSignature;
}

# Validate JWT token
public isolated function validateJwtToken(string token) returns types:JwtPayload|error {
    // Find the last dot to separate payload and signature
    int? lastDotIndex = findLastIndexOf(token, ".");

    if lastDotIndex is () {
        return error("Invalid token format");
    }

    string encodedPayload = token.substring(0, lastDotIndex);
    string encodedSignature = token.substring(lastDotIndex + 1);

    // Decode payload
    byte[]|error payloadBytesResult = decodeBase64(encodedPayload);
    if payloadBytesResult is error {
        return error("Invalid token payload encoding");
    }
    byte[] payloadBytes = payloadBytesResult;

    string|error payloadJsonResult = string:fromBytes(payloadBytes);
    if payloadJsonResult is error {
        return error("Invalid token payload");
    }
    string payloadJson = payloadJsonResult;

    json|error payloadJsonValue = payloadJson.fromJsonString();
    if payloadJsonValue is error {
        return error("Invalid JSON in token");
    }

    types:JwtPayload|error payload = payloadJsonValue.cloneWithType();
    if payload is error {
        return error("Invalid token structure");
    }

    // Verify signature
    byte[] secretBytes = jwtSecret.toBytes();
    byte[]|crypto:Error expectedSignatureResult = crypto:hmacSha256(payloadBytes, secretBytes);
    if expectedSignatureResult is crypto:Error {
        return error("Signature verification failed");
    }
    byte[] expectedSignature = expectedSignatureResult;
    string expectedEncodedSignature = encodeBase64(expectedSignature);

    if encodedSignature != expectedEncodedSignature {
        return error("Invalid token signature");
    }

    // Check expiration using proper time conversion
    time:Utc currentTime = time:utcNow();
    decimal currentSeconds = convertUtcToDecimal(currentTime);

    if payload.exp < currentSeconds {
        return error("Token has expired");
    }

    return payload;
}

# Extract user info from token
public isolated function extractUserFromToken(string authHeader) returns types:AuthenticatedUser|error {
    // Extract token from "Bearer <token>" format
    if !authHeader.startsWith("Bearer ") {
        return error("Invalid authorization format");
    }

    string token = authHeader.substring(7); // Remove "Bearer " prefix

    // Validate JWT token
    types:JwtPayload payload = check validateJwtToken(token);

    return {
        userId: payload.sub,
        email: payload.email
    };
}

# Helper function to convert time:Utc to decimal seconds
isolated function convertUtcToDecimal(time:Utc utcTime) returns decimal {
    // time:Utc is a tuple [int, decimal]
    int integralSeconds = utcTime[0];
    decimal fractionalSeconds = utcTime[1];
    return <decimal>integralSeconds + fractionalSeconds;
}

# Helper function to find last index of a substring
isolated function findLastIndexOf(string str, string substr) returns int? {
    int? lastIndex = ();
    int startIndex = 0;

    while true {
        int? currentIndex = str.indexOf(substr, startIndex);
        if currentIndex is () {
            break;
        }
        lastIndex = currentIndex;
        startIndex = currentIndex + 1;
    }

    return lastIndex;
}

