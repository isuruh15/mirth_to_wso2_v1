// Parse MLLP frame from TCP data
public function parseMllpFrame(byte[] data) returns MllpFrame {
    string dataStr = checkpanic string:fromBytes(data);

    // Check for MLLP start and end markers
    if dataStr.startsWith(startOfMessage) && dataStr.endsWith(endOfMessage) {
        // Extract message content between MLLP markers
        string message = dataStr.substring(1, dataStr.length() - 2);
        return {
            message: message,
            isValid: true
        };
    }

    return {
        message: dataStr,
        isValid: false
    };
}

// Create MLLP ACK response
public function createMllpAck() returns byte[] {
    return (startOfMessage + ackMessage + endOfMessage).toBytes();
}

// Create MLLP NACK response
public function createMllpNack() returns byte[] {
    return (startOfMessage + nackMessage + endOfMessage).toBytes();
}