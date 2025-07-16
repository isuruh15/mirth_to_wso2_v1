import ballerina/tcp;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerina/regex;

// MLLP protocol constants
const byte MLLP_START = 0x0B;
const byte MLLP_END_1 = 0x1C;
const byte MLLP_END_2 = 0x0D;
const byte MLLP_ACK = 0x06;
const byte MLLP_NACK = 0x15;

// Configuration
configurable int serverPort = 6662;
configurable string serverHost = "0.0.0.0";

// Global variables for channel processing
map<string> channelMap = {};

public function main() returns error? {
    tcp:Listener tcpListener = check new (serverPort, localHost = serverHost);
    
    log:printInfo(string `HL7 Conversion Channel started on ${serverHost}:${serverPort}`);
    
    check tcpListener.attach(hl7Service);
    check tcpListener.'start();
    
    // Keep the service running
    runtime:sleep(300);
}

service tcp:Service hl7Service = service object {
    remote function onConnect(tcp:Caller caller) returns tcp:ConnectionService {
        log:printInfo("New HL7 client connected");
        return new Hl7ConnectionService();
    }
};

service class Hl7ConnectionService {
    *tcp:ConnectionService;
    
    remote function onBytes(tcp:Caller caller, readonly & byte[] data) returns tcp:Error? {
        log:printInfo("Received HL7 message data");
        
        // Process MLLP wrapped HL7 message
        string|error hl7Message = extractHl7FromMllp(data);
        if hl7Message is error {
            log:printError("Error extracting HL7 message", hl7Message);
            check sendNack(caller);
            return;
        }
        
        // Process the HL7 message
        error? processResult = processHl7Message(hl7Message);
        if processResult is error {
            log:printError("Error processing HL7 message", processResult);
            check sendNack(caller);
            return;
        }
        
        // Send ACK response
        check sendAck(caller);
    }
    
    remote function onError(tcp:Error err) {
        log:printError("TCP connection error", err);
    }
    
    remote function onClose() {
        log:printInfo("HL7 client disconnected");
    }
}

function extractHl7FromMllp(readonly & byte[] data) returns string|error {
    // Check for MLLP start byte
    if data.length() < 3 || data[0] != MLLP_START {
        return error("Invalid MLLP message format");
    }
    
    // Find MLLP end sequence
    int endIndex = -1;
    foreach int i in 1...(data.length() - 2) {
        if data[i] == MLLP_END_1 && data[i + 1] == MLLP_END_2 {
            endIndex = i;
            break;
        }
    }
    
    if endIndex == -1 {
        return error("MLLP end sequence not found");
    }
    
    // Extract HL7 message content
    byte[] hl7Bytes = data.slice(1, endIndex);
    return string:fromBytes(hl7Bytes);
}

function processHl7Message(string hl7Message) returns error? {
    log:printInfo("Processing HL7 message");
    
    // Parse HL7 message
    Hl7Message parsedMessage = check parseHl7Message(hl7Message);
    
    // Apply source transformer logic
    TransformedData transformedData = applySourceTransformer(parsedMessage);
    
    // Validate fields
    ValidationResult validationResult = validateFields(transformedData);
    if !validationResult.isValid {
        log:printError(string `Validation failed: ${validationResult.errorMessage}`);
        return error(validationResult.errorMessage);
    }
    
    // Store in database (if enabled)
    check storePatientData(transformedData);
    
    log:printInfo("HL7 message processed successfully");
}

function parseHl7Message(string hl7Message) returns Hl7Message|error {
    string[] segments = regex:split(hl7Message, "\r");
    
    Hl7Message parsedMessage = {
        msh: {},
        pid: {},
        pv1: {},
        nk1: {}
    };
    
    foreach string segment in segments {
        if segment.startsWith("MSH") {
            parsedMessage.msh = parseSegment(segment);
        } else if segment.startsWith("PID") {
            parsedMessage.pid = parseSegment(segment);
        } else if segment.startsWith("PV1") {
            parsedMessage.pv1 = parseSegment(segment);
        } else if segment.startsWith("NK1") {
            parsedMessage.nk1 = parseSegment(segment);
        }
    }
    
    return parsedMessage;
}

function parseSegment(string segment) returns map&lt;string&gt; {
    string[] fields = regex:split(segment, "\\|");
    map&lt;string&gt; segmentMap = {};
    
    foreach int i in 0...(fields.length() - 1) {
        string fieldKey = string `${fields[0]}.${i}`;
        segmentMap[fieldKey] = fields[i];
        
        // Parse subcomponents for specific fields
        if fields[i].includes("^") {
            string[] subComponents = regex:split(fields[i], "\\^");
            foreach int j in 0...(subComponents.length() - 1) {
                string subKey = string `${fieldKey}.${j + 1}`;
                segmentMap[subKey] = subComponents[j];
            }
        }
    }
    
    return segmentMap;
}

function applySourceTransformer(Hl7Message msg) returns TransformedData {
    // Extract message code and trigger event from MSH.9
    string messageCode = getFieldValue(msg.msh, "MSH.9.1");
    string messageTriggerEvent = getFieldValue(msg.msh, "MSH.9.2");
    
    // Extract patient information from PID segment
    string firstName = getFieldValue(msg.pid, "PID.5.2");
    string lastName = getFieldValue(msg.pid, "PID.5.1");
    string dateOfBirth = getFieldValue(msg.pid, "PID.7.1");
    
    // Store in channel map (equivalent to Mirth's channelMap)
    channelMap["Message code"] = messageCode;
    channelMap["Message Trigger Event"] = messageTriggerEvent;
    channelMap["First Name"] = firstName;
    channelMap["Last Name"] = lastName;
    channelMap["Date Of Birth"] = dateOfBirth;
    
    // Create HL7 JSON object (equivalent to JavaScript conversion)
    Hl7JsonObject hl7JsonObject = {
        first_name: firstName,
        last_name: lastName,
        date_of_birth: formatDateOfBirth(dateOfBirth)
    };
    
    channelMap["hl7_json_object"] = hl7JsonObject.toJsonString();
    
    return {
        messageCode: messageCode,
        messageTriggerEvent: messageTriggerEvent,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        hl7JsonObject: hl7JsonObject
    };
}

function getFieldValue(map&lt;string&gt; segment, string fieldKey) returns string {
    return segment.hasKey(fieldKey) ? segment.get(fieldKey) : "";
}

function formatDateOfBirth(string dateOfBirth) returns string {
    if dateOfBirth.length() == 8 {
        // Convert YYYYMMDD to YYYY-MM-DD
        string year = dateOfBirth.substring(0, 4);
        string month = dateOfBirth.substring(4, 6);
        string day = dateOfBirth.substring(6, 8);
        return string `${year}-${month}-${day}`;
    }
    return dateOfBirth;
}

function validateFields(TransformedData data) returns ValidationResult {
    // Validation logic equivalent to JavaScript validation
    string fullName = string `${data.lastName} ${data.firstName}`;
    string dateOfBirth = data.dateOfBirth;
    
    // Regex patterns for validation
    string fullNamePattern = "^([a-zA-Z]{2,}\\s[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\\s?([a-zA-Z]{1,})?)";
    string dateOfBirthPattern = "([12]\\d{3}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01]))";
    
    boolean isFullNameValid = regex:matches(fullName, fullNamePattern);
    boolean isDateOfBirthValid = regex:matches(dateOfBirth.replace("-", ""), dateOfBirthPattern);
    
    log:printInfo(string `Full name validation: ${isFullNameValid}`);
    log:printInfo(string `Date of birth validation: ${isDateOfBirthValid}`);
    log:printInfo(string `HL7 JSON object: ${data.hl7JsonObject.toJsonString()}`);
    
    if !isFullNameValid {
        return {
            isValid: false,
            errorMessage: "Invalid full name format"
        };
    }
    
    if !isDateOfBirthValid {
        return {
            isValid: false,
            errorMessage: "Invalid date of birth format"
        };
    }
    
    return {
        isValid: true,
        errorMessage: ""
    };
}

function storePatientData(TransformedData data) returns error? {
    // Database storage logic (equivalent to MySQL insert query)
    // This would be enabled based on configuration
    log:printInfo("Storing patient data in database");
    
    // For now, just log the data that would be stored
    log:printInfo(string `Would insert: firstname=${data.firstName}, lastname=${data.lastName}, dateofbirth=${data.dateOfBirth}`);
    
    // Actual database implementation would use mysql:Client here
    // mysql:Client dbClient = check new (host = dbHost, user = dbUser, password = dbPassword, database = dbName);
    // sql:ExecutionResult result = check dbClient->execute(`INSERT INTO patients (firstname, lastname, dateofbirth) VALUES (${data.firstName}, ${data.lastName}, ${data.dateOfBirth})`);
    // check dbClient.close();
}

function sendAck(tcp:Caller caller) returns tcp:Error? {
    byte[] ackMessage = [MLLP_START, MLLP_ACK, MLLP_END_1, MLLP_END_2];
    check caller->writeBytes(ackMessage);
    log:printInfo("ACK sent to client");
}

function sendNack(tcp:Caller caller) returns tcp:Error? {
    byte[] nackMessage = [MLLP_START, MLLP_NACK, MLLP_END_1, MLLP_END_2];
    check caller->writeBytes(nackMessage);
    log:printInfo("NACK sent to client");
}