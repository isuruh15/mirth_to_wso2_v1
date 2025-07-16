// Server configuration
configurable string serverHost = "0.0.0.0";
configurable int serverPort = 6662;

// Database configuration (for future use)
configurable string dbHost = "localhost";
configurable int dbPort = 3306;
configurable string dbUser = "root";
configurable string dbPassword = "root";
configurable string dbName = "mydatabase";

// Processing configuration
configurable boolean enableDatabaseStorage = false;
configurable int maxConnections = 10;
configurable int receiveTimeout = 0;
configurable int bufferSize = 65536;