// HL7 message structure
public type Hl7Message record {
    string messageCode;
    string messageTriggerEvent;
    string firstName;
    string lastName;
    string dateOfBirth;
    string originalMessage;
};

// Patient data for database storage
public type PatientRecord record {
    string firstName;
    string lastName;
    string dateOfBirth;
};

// Validation result
public type ValidationResult record {
    boolean isValid;
    string[] errors;
};

// MLLP frame structure
public type MllpFrame record {
    string message;
    boolean isValid;
};

// Custom flat record for FHIR Bundle mapping (keeping existing structure)
public type FlatBundleRecord record {
    string id;
    int totalEntries;
    string patientId;
    string patientGivenName;
    string patientBirthdate;
    string encounterId;
};

// Configuration record for FHIR servers (keeping existing structure)
public type FhirServerConfig record {
    string url;
    string name;
};