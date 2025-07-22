import ballerina/data.xmldata;

// Convert PatientXML to XML string
public isolated function convertToXML(PatientXML patientData, boolean prettyPrint = true) returns string|error {
    PatientDocument document = {patient: patientData};
    
    xml xmlData = check xmldata:toXml(document);
    
    if prettyPrint {
        return prettyPrintXML(xmlData.toString());
    }
    
    return xmlData.toString();
}

// Pretty print XML with proper indentation
public isolated function prettyPrintXML(string xmlString) returns string {

    // Regex based string split
    string:RegExp r = re `>`;
    // Simple pretty printing - add indentation
    string[] lines = r.split(xmlString);
    string result = "";
    int indentLevel = 0;
    
    foreach string line in lines {
        if line.trim().length() > 0 {
            if line.includes("</") {
                indentLevel -= 1;
            }
            
            string indent = "";
            int i = 0;
            while i < indentLevel {
                indent += "    ";
                i += 1;
            }
            
            if line.trim().startsWith("<") && !line.trim().startsWith("</") {
                result += indent + line.trim() + ">\n";
                if !line.includes("</") && !line.endsWith("/>") {
                    indentLevel += 1;
                }
            } else {
                result += line.trim();
            }
        }
    }
    
    return result;
}