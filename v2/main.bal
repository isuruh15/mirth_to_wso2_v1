import ballerina/io;

public function main() returns error? {
    io:println("HL7 to XML Transformer Service");
    io:println("Listening on port: ", config.tcpPort);
    io:println("Output directory: ", config.outputDirectory);
    io:println("Pretty print enabled: ", config.prettyPrint);
    io:println("Service started successfully!");
}