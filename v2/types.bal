// Configuration record
public type Config record {|
    int tcpPort;
    string outputDirectory;
    boolean prettyPrint;
|};

// Patient name structure
public type PatientName record {|
    string last?;
    string first?;
|};

// Next of kin structure
public type NextOfKinXML record {|
    string last?;
    string first?;
    string relationship?;
    string phoneNumber?;
|};

// Main patient XML structure
public type PatientXML record {|
    string patientId?;
    PatientName name?;
    string dateOfBirth?;
    string gender?;
    NextOfKinXML[] nextOfKin?;
|};

// Root XML structure
public type PatientDocument record {|
    PatientXML patient;
|};