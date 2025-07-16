import ballerina/regex;
import ballerina/log;

// Utility functions for HL7 processing

// Function to check if a value is not null and has valid length
public function isNotNull(string value) returns boolean {
    return value.length() > 0;
}

// Function to validate full name using regex pattern
public function validateFullName(string fullName) returns boolean {
    string pattern = "^([a-zA-Z]{2,}\\s[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\\s?([a-zA-Z]{1,})?)";
    return regex:matches(fullName, pattern);
}

// Function to validate date of birth using regex pattern
public function validateDateOfBirth(string dateOfBirth) returns boolean {
    string pattern = "([12]\\d{3}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01]))";
    // Remove hyphens for validation
    string cleanDate = dateOfBirth.replace("-", "");
    return regex:matches(cleanDate, pattern);
}

// Function to create HL7 ACK message
public function createAckMessage(string messageControlId) returns string {
    time:Utc currentTime = time:utcNow();
    string timestamp = time:utcToString(currentTime);
    
    return string `MSH|^~\\&|SYSTEM-B|systemB|SYSTEM-A|systemA|${timestamp}||ACK|${messageControlId}|D|2.5
MSA|AA|${messageControlId}|Message accepted`;
}

// Function to create HL7 NACK message
public function createNackMessage(string messageControlId, string errorMessage) returns string {
    time:Utc currentTime = time:utcNow();
    string timestamp = time:utcToString(currentTime);
    
    return string `MSH|^~\\&|SYSTEM-B|systemB|SYSTEM-A|systemA|${timestamp}||ACK|${messageControlId}|D|2.5
MSA|AE|${messageControlId}|${errorMessage}`;
}

// Function to extract message control ID from HL7 message
public function extractMessageControlId(string hl7Message) returns string {
    string[] segments = regex:split(hl7Message, "\r");
    foreach string segment in segments {
        if segment.startsWith("MSH") {
            string[] fields = regex:split(segment, "\\|");
            if fields.length() > 9 {
                return fields[9];
            }
        }
    }
    return "UNKNOWN";
}

// Function to log processing information
public function logProcessingInfo(string context, string message) {
    log:printInfo(string `[${context}] ${message}`);
}

// Function to log error information
public function logProcessingError(string context, string message, error? err = ()) {
    if err is error {
        log:printError(string `[${context}] ${message}`, err);
    } else {
        log:printError(string `[${context}] ${message}`);
    }
}