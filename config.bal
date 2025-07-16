// TCP server configuration
configurable int tcpPort = 6662;
configurable string tcpHost = "0.0.0.0";

// MySQL database configurations
configurable string dbHost = "localhost";
configurable int dbPort = 3306;
configurable string dbName = "mydatabase";
configurable string dbUser = "root";
configurable string dbPassword = "root";

// MLLP protocol configuration
configurable string startOfMessage = "\u{000B}";
configurable string endOfMessage = "\u{001C}\u{000D}";
configurable string ackMessage = "\u{0006}";
configurable string nackMessage = "\u{0015}";

// HTTP server configuration (keeping existing)
configurable int httpPort = 8080;

// FHIR server configurations (keeping existing)
configurable string fhirServer1Url = "http://localhost:8243/fhir/r4";
configurable string fhirServer2Url = "http://localhost:8243/fhir/r4";