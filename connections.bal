import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;

// Initialize MySQL client
final mysql:Client dbClient = check new (
    host = dbHost,
    port = dbPort,
    database = dbName,
    user = dbUser,
    password = dbPassword
);

// Function to insert patient data into database
public function insertPatientData(PatientRecord patient) returns error? {
    sql:ParameterizedQuery query = `
        INSERT INTO patients (firstname, lastname, dateofbirth)
        VALUES (${patient.firstName}, ${patient.lastName}, ${patient.dateOfBirth})
    `;

    sql:ExecutionResult result = check dbClient->execute(query);
    return;
}

// Function to close database connection
public function closeDatabaseConnection() returns error? {
    check dbClient.close();
}

// Keep existing FHIR functions for compatibility
final http:Client fhirClient1 = check new (fhirServer1Url);
final http:Client fhirClient2 = check new (fhirServer2Url);

public function sendToFhirServers(json fhirBundle) returns error? {
    http:Response response1 = check fhirClient1->post(path = "/Bundle", message = fhirBundle);
    http:Response response2 = check fhirClient2->post(path = "/Bundle", message = fhirBundle);
    return;
}

final http:Client recordsClient = check new (fhirServer2Url);