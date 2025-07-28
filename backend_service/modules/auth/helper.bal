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
