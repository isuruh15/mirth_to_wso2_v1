import ballerina/regex;
import ballerina/log;

// Validate patient data fields
public function validatePatientData(Hl7Message hl7Msg) returns ValidationResult {
    string[] errors = [];
    boolean isValid = true;
    
    // Construct full name for validation
    string fullName = hl7Msg.lastName + " " + hl7Msg.firstName;
    
    // Full name pattern validation
    string fullNamePattern = "^([a-zA-Z]{2,}\\s[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\\s?([a-zA-Z]{1,})?)";
    boolean isFullNameValid = regex:matches(fullName, fullNamePattern);
    
    if !isFullNameValid {
        errors.push("Invalid full name format: " + fullName);
        isValid = false;
    }
    
    // Date of birth pattern validation (YYYYMMDD format)
    string datePattern = "([12]\\d{3}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01]))";
    boolean isDateValid = regex:matches(hl7Msg.dateOfBirth, datePattern);
    
    if !isDateValid {
        errors.push("Invalid date of birth format: " + hl7Msg.dateOfBirth);
        isValid = false;
    }
    
    // Log validation results
    if isValid {
        log:printInfo("Validation successful for patient: " + fullName);
    } else {
        log:printError("Validation failed for patient: " + fullName + ". Errors: " + errors.toString());
    }
    
    return {
        isValid: isValid,
        errors: errors
    };
}

// Create JSON object similar to Mirth's JavaScript transformation
public function createHl7JsonObject(Hl7Message hl7Msg) returns json {
    return {
        "first_name": hl7Msg.firstName,
        "last_name": hl7Msg.lastName,
        "date_of_birth": formatDateOfBirth(hl7Msg.dateOfBirth)
    };
}