import ballerina/lang.runtime;
import ballerina/log;
import ballerina/tcp;

// TCP service to handle HL7v2 messages with MLLP protocol
service on new tcp:Listener(tcpPort) {

    remote function onConnect(tcp:Caller caller) returns tcp:ConnectionService {
        log:printInfo("Client connected from: " + caller.remotePort.toString());
        return new Hl7ConnectionService();
    }
}

// Connection service to handle individual client connections
service class Hl7ConnectionService {
    *tcp:ConnectionService;

    remote function onBytes(tcp:Caller caller, readonly & byte[] data) returns tcp:Error? {
        log:printInfo("Received HL7 message of size: " + data.length().toString());

        // Parse MLLP frame
        MllpFrame frame = parseMllpFrame(data);

        if !frame.isValid {
            log:printError("Invalid MLLP frame received");
            byte[] nackResponse = createMllpNack();
            check caller->writeBytes(nackResponse);
            return;
        }

        // Process HL7 message
        error? result = processHl7Message(frame.message);

        if result is error {
            log:printError("Failed to process HL7 message: " + result.message());
            byte[] nackResponse = createMllpNack();
            check caller->writeBytes(nackResponse);
        } else {
            log:printInfo("HL7 message processed successfully");
            byte[] ackResponse = createMllpAck();
            check caller->writeBytes(ackResponse);
        }
    }

    remote function onError(tcp:Error err) {
        log:printError("TCP connection error: " + err.message());
    }

    remote function onClose() {
        log:printInfo("Client connection closed");
    }
}

// Process HL7v2 message
function processHl7Message(string hl7Data) returns error? {
    // Parse HL7 message
    Hl7Message hl7Msg = check parseHl7Message(hl7Data);

    // Validate patient data
    ValidationResult validation = validatePatientData(hl7Msg);

    if !validation.isValid {
        return error("Validation failed: " + validation.errors.toString());
    }

    // Create JSON object for logging (similar to Mirth's JavaScript step)
    json hl7JsonObject = createHl7JsonObject(hl7Msg);
    log:printInfo("HL7 JSON object: " + hl7JsonObject.toString());

    // Store patient data in database
    PatientRecord patient = {
        firstName: hl7Msg.firstName,
        lastName: hl7Msg.lastName,
        dateOfBirth: formatDateOfBirth(hl7Msg.dateOfBirth)
    };

    check insertPatientData(patient);
    log:printInfo("Patient data stored successfully");

    return;
}

// Keep the service running and handle graceful shutdown
public function main() returns error? {
    log:printInfo("HL7 Conversion Service started on " + tcpHost + ":" + tcpPort.toString());

    // Keep the service running
    runtime:onGracefulStop(function() returns error? {
                log:printInfo("Shutting down HL7 Conversion Service...");
                check closeDatabaseConnection();
                log:printInfo("Database connection closed");
                return;
            });

    // Keep the main function running indefinitely
    while true {
        runtime:sleep(60);
    }
}