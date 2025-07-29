import ballerina/lang.array;
import ballerina/lang.regexp;

// 
isolated function encodeBase64Url(byte[] data) returns string|error {
    string b64 = array:toBase64(data);

    // Create regex patterns for replacement
    string:RegExp plusPattern = re `\+`;
    string:RegExp slashPattern = re `/`;
    string:RegExp equalPattern = re `=`;

    string result = plusPattern.replaceAll(b64, "-");
    result = slashPattern.replaceAll(result, "_");
    result = equalPattern.replaceAll(result, "");
    return result;
}

isolated function decodeBase64Url(string encoded) returns byte[]|error {
    string padded = encoded;
    int mod = encoded.length() % 4;
    if mod != 0 {
        int paddingCount = 4 - mod;
        int i = 0;
        while i < paddingCount {
            padded += "=";
            i += 1;
        }
    }

    // Create regex patterns for replacement
    string:RegExp dashPattern = re `-`;
    string:RegExp underscorePattern = re `_`;

    padded = dashPattern.replaceAll(padded, "+");
    padded = underscorePattern.replaceAll(padded, "/");
    return array:fromBase64(padded);
}

isolated function isValidEmail(string email) returns boolean {
    string:RegExp|error regexPattern = regexp:fromString("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");
    if regexPattern is error {
        return false;
    }
    return regexPattern.isFullMatch(email);
}
