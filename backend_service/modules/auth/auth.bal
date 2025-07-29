import backend_service.database;
import backend_service.types;

import ballerina/crypto;
import ballerina/http;
import ballerina/time;
import ballerina/uuid;

# JWT secret key (in production, use a secure random key)
configurable string jwtSecret = "your-secret-key-change-this-in-production";

# error messages
const string INVALID_CREDENTIALS = "Invalid email or password. Please check your credentials and try again.";
const string AUTHENTICATION_REQUIRED = "Authentication required. Please provide a valid access token.";
const string SESSION_EXPIRED = "Your session has expired. Please log in again.";
const string INVALID_EMAIL_FORMAT = "Please enter a valid email address.";
const string PASSWORD_TOO_SHORT = "Password must be at least 6 characters long.";
const string USER_ALREADY_EXISTS = "An account with this email already exists. Please use a different email or try logging in.";
const string ACCOUNT_CREATION_FAILED = "We couldn't create your account at this time. Please try again later.";
const string LOGIN_FAILED = "Login failed. Please check your credentials and try again.";

# Signup function using database
public isolated function signupUser(types:SignupRequest signupRequest) returns types:AuthResponse|error {
    string email = signupRequest.email.trim();
    string password = signupRequest.password;

    // Validate input with user-friendly messages
    if !isValidEmail(email) {
        return {
            success: false,
            message: INVALID_EMAIL_FORMAT,
            token: ()
        };
    }

    if password.length() < 6 {
        return {
            success: false,
            message: PASSWORD_TOO_SHORT,
            token: ()
        };
    }

    // Check if user already exists
    boolean|error userExists = database:emailExists(email);
    if userExists is error {
        return error(ACCOUNT_CREATION_FAILED);
    }

    if userExists {
        return {
            success: false,
            message: USER_ALREADY_EXISTS,
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
        return error(ACCOUNT_CREATION_FAILED);
    }

    return {
        success: true,
        message: "Account created successfully! You can now log in.",
        token: ()
    };
}

# Login function using database
public isolated function loginUser(types:LoginRequest loginRequest) returns types:AuthResponse|error {
    string email = loginRequest.email.trim();
    string password = loginRequest.password;

    // Validate email format
    if !isValidEmail(email) {
        return {
            success: false,
            message: INVALID_EMAIL_FORMAT,
            token: ()
        };
    }

    // Get user from database
    types:User|error userResult = database:getUserByEmail(email);
    if userResult is error {
        return {
            success: false,
            message: INVALID_CREDENTIALS,
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
            message: INVALID_CREDENTIALS,
            token: ()
        };
    }

    // Generate JWT token
    string|error token = generateJwtToken(user);

    if token is error {
        return error(LOGIN_FAILED);
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
        return error(AUTHENTICATION_REQUIRED);
    }

    string headerEncoded = parts[0];
    string payloadEncoded = parts[1];
    string signatureEncoded = parts[2];

    string signingInput = headerEncoded + "." + payloadEncoded;

    byte[] expectedSig = check crypto:hmacSha256(signingInput.toBytes(), jwtSecret.toBytes());
    string expectedSigEncoded = check encodeBase64Url(expectedSig);

    if signatureEncoded != expectedSigEncoded {
        return error(AUTHENTICATION_REQUIRED);
    }

    byte[] payloadBytes = check decodeBase64Url(payloadEncoded);
    string payloadJson = check string:fromBytes(payloadBytes);
    json payloadObj = check payloadJson.fromJsonString();
    types:JwtPayload payload = check payloadObj.cloneWithType();

    decimal nowSeconds = <decimal>time:utcNow()[0] + ((<decimal>time:utcNow()[1]) / 1000000000d);
    if payload.exp < nowSeconds {
        return error(SESSION_EXPIRED);
    }

    return payload;
}

// === USER EXTRACTION FROM AUTH HEADER ===

public isolated function extractUserFromToken(string authHeader) returns types:AuthenticatedUser|error {
    string trimmedHeader = authHeader.trim();

    if !trimmedHeader.startsWith("Bearer ") {
        return error(AUTHENTICATION_REQUIRED);
    }

    string token = trimmedHeader.substring(7).trim();
    if token.length() == 0 {
        return error(AUTHENTICATION_REQUIRED);
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
        return <http:Unauthorized>{
            body: {
                success: false,
                message: AUTHENTICATION_REQUIRED
            }
        };
    }

    types:AuthenticatedUser|error result = extractUserFromToken(authHeader);
    if result is error {
        string errorMessage = result.message();
        // Map technical errors to user-friendly messages
        if errorMessage.includes("expired") || errorMessage == SESSION_EXPIRED {
            errorMessage = SESSION_EXPIRED;
        } else {
            errorMessage = AUTHENTICATION_REQUIRED;
        }

        return <http:Unauthorized>{
            body: {
                success: false,
                message: errorMessage
            }
        };
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
