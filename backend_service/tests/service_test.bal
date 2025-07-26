import ballerina/http;
import ballerina/io;
import ballerina/test;

http:Client testClient = check new ("http://localhost:9090");

// Before Suite Function
@test:BeforeSuite
function beforeSuiteFunc() {
    io:println("I'm the before suite function!");
}

// Test function
@test:Config {}
function testServiceWithProperName() {
    string|error response = testClient->/greeting(name = "John");
    test:assertEquals(response, "Hello, John");
}

// Negative test function
@test:Config {}
function testServiceWithEmptyName() returns error? {
    http:Response response = check testClient->/greeting;
    test:assertEquals(response.statusCode, 500);
    json errorPayload = check response.getJsonPayload();
    test:assertEquals(errorPayload.message, "name should not be empty!");
}

// After Suite Function
@test:AfterSuite
function afterSuiteFunc() {
    io:println("I'm the after suite function!");
}

// import ballerina/http;

// // Create one HTTP listener
// listener http:Listener backendListener = new (8080);

// // Attach each controller service to a sub-path (e.g. /accounts, /transactions)
// service /finance on backendListener {
//     // *accounts_controller.accountsService,
//     // *transactions_controller.transactionsService,
//     // *budgets_controller.budgetsService
// }
