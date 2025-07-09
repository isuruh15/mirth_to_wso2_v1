import ballerina/http;

// Initialize HTTP clients for FHIR servers
final http:Client fhirClient1 = check new (fhirServer1Url);
final http:Client fhirClient2 = check new (fhirServer2Url);

// Function to send FHIR Bundle to both servers
public function sendToFhirServers(json fhirBundle) returns error? {
    // Send to first FHIR server
    http:Response response1 = check fhirClient1->post(path = "/Bundle", message = fhirBundle);

    // Send to second FHIR server  
    http:Response response2 = check fhirClient2->post(path = "/Bundle", message = fhirBundle);

    // Log responses or handle as needed
}

final http:Client recordsClient = check new (fhirServer2Url);