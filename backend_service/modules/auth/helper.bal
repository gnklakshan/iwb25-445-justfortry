import ballerina/lang.regexp;

# Validates email format using regular expression
# + email - Email address to validate
# + return - True if email format is valid, false otherwise
public isolated function isValidEmail(string email) returns boolean {
    string pattern = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$";

    // Convert string pattern to RegExp using fromString function
    string:RegExp|error regexPattern = regexp:fromString(pattern);

    if regexPattern is error {
        // If pattern is invalid, return false
        return false;
    }
    return regexp:isFullMatch(regexPattern, email);
}

# to get character at specific index
public isolated function getCharAt(string str, int index) returns string {
    return str.substring(index, index + 1);
}

# Base64 decoding 
isolated function decodeBase64(string input) returns byte[]|error {
    string base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    byte[] result = [];
    int i = 0;

    while i < input.length() {
        if i + 3 >= input.length() {
            break;
        }

        string char1 = getCharAt(input, i);
        string char2 = getCharAt(input, i + 1);
        string char3 = getCharAt(input, i + 2);
        string char4 = getCharAt(input, i + 3);

        int? index1 = base64Chars.indexOf(char1);
        int? index2 = base64Chars.indexOf(char2);
        int? index3 = (char3 == "=") ? 0 : base64Chars.indexOf(char3);
        int? index4 = (char4 == "=") ? 0 : base64Chars.indexOf(char4);

        if index1 is () || index2 is () || index3 is () || index4 is () {
            return error("Invalid base64 character");
        }

        int combined = (index1 << 18) | (index2 << 12) | (index3 << 6) | index4;

        result.push(<byte>((combined >> 16) & 255));
        if char3 != "=" {
            result.push(<byte>((combined >> 8) & 255));
        }
        if char4 != "=" {
            result.push(<byte>(combined & 255));
        }

        i += 4;
    }

    return result;
}

# Base64 encoding implementation
isolated function encodeBase64(byte[] input) returns string {
    string base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    string result = "";
    int i = 0;

    while i < input.length() {
        int byte1 = input[i];
        int byte2 = (i + 1 < input.length()) ? input[i + 1] : 0;
        int byte3 = (i + 2 < input.length()) ? input[i + 2] : 0;

        int combined = (byte1 << 16) | (byte2 << 8) | byte3;

        // Extract 6-bit indices and get corresponding base64 characters
        int index1 = (combined >> 18) & 63;
        int index2 = (combined >> 12) & 63;
        int index3 = (combined >> 6) & 63;
        int index4 = combined & 63;

        result += getCharAt(base64Chars, index1);
        result += getCharAt(base64Chars, index2);
        result += (i + 1 < input.length()) ? getCharAt(base64Chars, index3) : "=";
        result += (i + 2 < input.length()) ? getCharAt(base64Chars, index4) : "=";

        i += 3;
    }

    return result;
}

