// HL7 message structure
public type Hl7Message record {
    map&lt;string&gt; msh;
    map&lt;string&gt; pid;
    map&lt;string&gt; pv1;
    map&lt;string&gt; nk1;
};

// Transformed data structure
public type TransformedData record {
    string messageCode;
    string messageTriggerEvent;
    string firstName;
    string lastName;
    string dateOfBirth;
    Hl7JsonObject hl7JsonObject;
};

// HL7 JSON object structure
public type Hl7JsonObject record {
    string first_name;
    string last_name;
    string date_of_birth;
};

// Validation result
public type ValidationResult record {
    boolean isValid;
    string errorMessage;
};

// Patient data for database storage
public type PatientData record {
    string firstname;
    string lastname;
    string dateofbirth;
};