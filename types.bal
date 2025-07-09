// Custom flat record for FHIR Bundle mapping
public type FlatBundleRecord record {
    string id;
    int totalEntries;
    string patientId;
    string patientGivenName;
    string patientBirthdate;
    string encounterId;
};

// Configuration record for FHIR servers
public type FhirServerConfig record {
    string url;
    string name;
};