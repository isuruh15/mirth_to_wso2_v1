import ballerina/regex;

// Parse HL7v2 message and extract required fields
public function parseHl7Message(string hl7Data) returns Hl7Message|error {
    // Split HL7 message into segments
    string[] segments = regex:split(hl7Data, "\r");

    string messageCode = "";
    string messageTriggerEvent = "";
    string firstName = "";
    string lastName = "";
    string dateOfBirth = "";

    foreach string segment in segments {
        string[] fields = regex:split(segment, "\\|");

        if fields.length() > 0 {
            string segmentType = fields[0];

            // Extract MSH segment data
            if segmentType == "MSH" && fields.length() > 9 {
                string[] msh9Fields = regex:split(fields[9], "\\^");
                if msh9Fields.length() > 0 {
                    messageCode = msh9Fields[0].trim();
                }
                if msh9Fields.length() > 1 {
                    messageTriggerEvent = msh9Fields[1].trim();
                }
            }

            // Extract PID segment data
            if segmentType == "PID" && fields.length() > 7 {
                // Extract patient name from PID.5
                if fields.length() > 5 {
                    string[] nameFields = regex:split(fields[5], "\\^");
                    if nameFields.length() > 0 {
                        lastName = nameFields[0].trim();
                    }
                    if nameFields.length() > 1 {
                        firstName = nameFields[1].trim();
                    }
                }

                // Extract date of birth from PID.7
                if fields.length() > 7 {
                    dateOfBirth = fields[7].trim();
                }
            }
        }
    }

    return {
        messageCode: messageCode,
        messageTriggerEvent: messageTriggerEvent,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        originalMessage: hl7Data
    };
}

// Format date from YYYYMMDD to YYYY-MM-DD
public function formatDateOfBirth(string rawDate) returns string {
    if rawDate.length() == 8 {
        string year = rawDate.substring(0, 4);
        string month = rawDate.substring(4, 6);
        string day = rawDate.substring(6, 8);
        return year + "-" + month + "-" + day;
    }
    return rawDate;
}