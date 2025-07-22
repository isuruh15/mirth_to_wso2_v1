import ballerina/tcp;
import ballerina/io;
import ballerinax/health.hl7v2;
import ballerinax/health.hl7v23;

// Configuration
configurable Config config = ?;

// TCP service to receive HL7 messages
service on new tcp:Listener(config.tcpPort) {
    
    remote function onConnect(tcp:Caller caller) returns tcp:ConnectionService {
        io:println("Client connected: ", caller.remotePort);
        return new HL7ConnectionService();
    }
}

// Connection service to handle HL7 message processing
service class HL7ConnectionService {
    *tcp:ConnectionService;
    
    remote function onBytes(tcp:Caller caller, readonly & byte[] data) returns tcp:Error? {
        string|error hl7Message = string:fromBytes(data);
        
        if hl7Message is error {
            io:println("Error converting bytes to string: ", hl7Message.message());
            return;
        }
        
        // Process the HL7 message
        error? result = processHL7Message(hl7Message, caller);
        if result is error {
            io:println("Error processing HL7 message: ", result.message());
        }
    }
    
    remote function onError(tcp:Error err) {
        io:println("Connection error: ", err.message());
    }
    
    remote function onClose() {
        io:println("Client disconnected");
    }
}

// Process incoming HL7 message
isolated function processHL7Message(string hl7Message, tcp:Caller caller) returns error? {
    // Parse HL7 message
    hl7v2:Message|error parsedMsg = hl7v2:parse(hl7Message);
    
    if parsedMsg is error {
        io:println("Error parsing HL7 message: ", parsedMsg.message());
        return parsedMsg;
    }
    
    // Determine message type and process accordingly
    string messageType = getMessageType(parsedMsg);
    
    match messageType {
        "ADT_A01"|"ADT_A03" => {
            return processADTMessage(parsedMsg, caller);
        }
        _ => {
            io:println("Unsupported message type: ", messageType);
            return error("Unsupported message type: " + messageType);
        }
    }
}

// Process ADT messages
isolated function processADTMessage(hl7v2:Message hl7Message, tcp:Caller caller) returns error? {
    // Convert to specific ADT message type
    hl7v23:ADT_A01|error adtA01 = hl7Message.ensureType();
    if adtA01 is hl7v23:ADT_A01 {
        return transformAndSave(adtA01, caller);
    }
    
    hl7v23:ADT_A03|error adtA03 = hl7Message.ensureType();
    if adtA03 is hl7v23:ADT_A03 {
        return transformAndSave(adtA03, caller);
    }
    
    return error("Unable to convert to supported ADT message type");
}

// Transform and save the message
isolated function transformAndSave(hl7v23:ADT_A01|hl7v23:ADT_A03 adtMsg, tcp:Caller caller) returns error? {
    // Transform HL7 to XML
    PatientXML patientData = transformHL7ToPatientXML(adtMsg);
    
    // Convert to XML string
    string|error xmlContent = convertToXML(patientData, config.prettyPrint);
    
    if xmlContent is error {
        io:println("Error converting to XML: ", xmlContent.message());
        return xmlContent;
    }
    
    // Generate filename
    string messageId = getMessageControlId(adtMsg);
    string channelId = "hl7_to_xml_transformer";
    string fileName = channelId + "_" + messageId + ".xml";
    string filePath = config.outputDirectory + "/" + fileName;
    
    // Write to file
    error? writeResult = io:fileWriteString(filePath, xmlContent);
    if writeResult is error {
        io:println("Error writing XML file: ", writeResult.message());
        return writeResult;
    }
    
    io:println("Successfully processed message and saved to: ", filePath);
    
    // Send acknowledgment back to client
    string ackMessage = generateACK(adtMsg, "AA");
    byte[] ackBytes = ackMessage.toBytes();
    error? sendResult = caller->writeBytes(ackBytes);
    
    if sendResult is error {
        io:println("Error sending ACK: ", sendResult.message());
        return sendResult;
    }
    
    return;
}

// Get message type from parsed HL7 message
isolated function getMessageType(hl7v2:Message hl7Message) returns string {
    // Extract message type from MSH segment
    if hl7Message is hl7v23:MSH {
        hl7v23:MSH msh = <hl7v23:MSH>hl7Message;
        if msh.msh9 is hl7v23:CM_MSG {
            hl7v23:CM_MSG msgType = <hl7v23:CM_MSG>msh.msh9;
            string messageCode = msgType.cm_msg1 is string ? msgType.cm_msg1: "";
            string triggerEvent = msgType.cm_msg2 is string ? msgType.cm_msg2: "";
            return messageCode + "_" + triggerEvent;
        }
    }
    return "UNKNOWN";
}

// Get message control ID
isolated function getMessageControlId(hl7v23:ADT_A01|hl7v23:ADT_A03 adtMsg) returns string {
    if adtMsg.msh is hl7v23:MSH {
        hl7v23:MSH msh = <hl7v23:MSH>adtMsg.msh;
        return msh.msh10 is string ? msh.msh10: "UNKNOWN";
    }
}

// Generate ACK message
isolated function generateACK(hl7v23:ADT_A01|hl7v23:ADT_A03 originalMsg, string ackCode) returns string {
    string messageControlId = getMessageControlId(originalMsg);
    
    // Simple ACK generation
    string ack = "MSH|^~\\&|HL7_TO_XML_TRANSFORMER|SYSTEM||" + 
                getCurrentDateTime() + "||ACK|" + messageControlId + "|P|2.3\r" +
                "MSA|" + ackCode + "|" + messageControlId + "\r";
    
    return ack;
}

// Get current date/time in HL7 format
isolated function getCurrentDateTime() returns string {
    // Simple timestamp - in production, use proper time formatting
    return "20250720120000";
}