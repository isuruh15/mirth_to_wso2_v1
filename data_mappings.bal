import ballerina/log;

// Data mapping functions for HL7 field extraction
public function extractMessageCode(map&lt;string&gt; mshSegment) returns string {
    return getSegmentField(mshSegment, "MSH.9.1");
}

public function extractMessageTriggerEvent(map&lt;string&gt; mshSegment) returns string {
    return getSegmentField(mshSegment, "MSH.9.2");
}

public function extractFirstName(map&lt;string&gt; pidSegment) returns string {
    return getSegmentField(pidSegment, "PID.5.2");
}

public function extractLastName(map&lt;string&gt; pidSegment) returns string {
    return getSegmentField(pidSegment, "PID.5.1");
}

public function extractDateOfBirth(map&lt;string&gt; pidSegment) returns string {
    return getSegmentField(pidSegment, "PID.7.1");
}

function getSegmentField(map&lt;string&gt; segment, string fieldKey) returns string {
    if segment.hasKey(fieldKey) {
        string fieldValue = segment.get(fieldKey);
        return fieldValue.trim();
    }
    return "";
}

// Date formatting function (equivalent to moment.js formatting)
public function formatDate(string inputDate, string inputFormat, string outputFormat) returns string {
    if inputDate.length() == 8 && inputFormat == "YYYYMMDD" && outputFormat == "YYYY-MM-DD" {
        string year = inputDate.substring(0, 4);
        string month = inputDate.substring(4, 6);
        string day = inputDate.substring(6, 8);
        return string `${year}-${month}-${day}`;
    }
    return inputDate;
}