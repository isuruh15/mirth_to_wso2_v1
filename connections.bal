import ballerina/sql;
import ballerinax/mysql;
import ballerina/log;

// Database connection management
public class DatabaseManager {
    private mysql:Client? dbClient = ();
    
    public function init() returns error? {
        if enableDatabaseStorage {
            self.dbClient = check new (host = dbHost, port = dbPort, user = dbUser, password = dbPassword, database = dbName);
            log:printInfo("Database connection established");
        }
    }
    
    public function insertPatient(PatientData patientData) returns error? {
        if self.dbClient is mysql:Client {
            mysql:Client client = &lt;mysql:Client&gt;self.dbClient;
            sql:ExecutionResult result = check client->execute(`
                INSERT INTO patients (firstname, lastname, dateofbirth) 
                VALUES (${patientData.firstname}, ${patientData.lastname}, ${patientData.dateofbirth})
            `);
            log:printInfo(string `Patient data inserted with ID: ${result.lastInsertId}`);
        } else {
            log:printInfo("Database storage is disabled");
        }
    }
    
    public function close() returns error? {
        if self.dbClient is mysql:Client {
            mysql:Client client = &lt;mysql:Client&gt;self.dbClient;
            check client.close();
            log:printInfo("Database connection closed");
        }
    }
}

// Global database manager instance
public final DatabaseManager dbManager = new;