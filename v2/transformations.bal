import ballerinax/health.hl7v23;

// Extract patient ID from PID segment
isolated function extractPatientId(hl7v23:PID? pid) returns string {
    if pid is hl7v23:PID {
        return pid.pid2?.cx1 is string ?pid.pid2?.cx1: "";
    }
    return "";
}

// Extract patient name from PID segment
isolated function extractPatientName(hl7v23:PID? pid) returns PatientName {
    PatientName patientName = {};
    
    if pid is hl7v23:PID && pid.pid5 is hl7v23:XPN[] {
        hl7v23:XPN[] names = <hl7v23:XPN[]>pid.pid5;
        if names.length() > 0 {
            hl7v23:XPN primaryName = names[0];
            patientName.last = primaryName.xpn1;
            patientName.first = primaryName.xpn2;
        }
    }
    
    return patientName;
}

// Extract date of birth from PID segment
isolated function extractDateOfBirth(hl7v23:PID? pid) returns string {
    if pid is hl7v23:PID {
        return pid.pid7?.ts1 is string ?pid.pid7?.ts1: "";
    }
    return "";
}

// Extract gender from PID segment
isolated function extractGender(hl7v23:PID? pid) returns string {
    if pid is hl7v23:PID {
        return pid.pid8 is string ? pid.pid8: "";
    }
    return "";
}

// Extract next of kin information from NK1 segments
isolated function extractNextOfKin(hl7v23:NK1[]? nk1Segments) returns NextOfKinXML[] {
    NextOfKinXML[] nextOfKinList = [];
    
    if nk1Segments is hl7v23:NK1[] {
        foreach hl7v23:NK1 nk1 in nk1Segments {
            NextOfKinXML nextOfKin = {};
            
            // Extract name
            if nk1.nk12 is hl7v23:XPN[] {
                hl7v23:XPN nkName = <hl7v23:XPN>nk1.nk12[0];
                nextOfKin.last = nkName.xpn1;
                nextOfKin.first = nkName.xpn2;
            }
            
            // Extract relationship
            if nk1.nk13 is hl7v23:CE {
                hl7v23:CE relationship = <hl7v23:CE>nk1.nk13;
                nextOfKin.relationship = relationship.ce1;
            }
            
            // Extract phone number
            if nk1.nk15 is hl7v23:XTN[] {
                hl7v23:XTN[] phoneNumbers = <hl7v23:XTN[]>nk1.nk15;
                if phoneNumbers.length() > 0 {
                    nextOfKin.phoneNumber = phoneNumbers[0].xtn1;
                }
            }
            
            nextOfKinList.push(nextOfKin);
        }
    }
    
    return nextOfKinList;
}

// Main transformation function
public isolated function transformHL7ToPatientXML(hl7v23:ADT_A01|hl7v23:ADT_A03 adtMsg) returns PatientXML {
    PatientXML patientXml = {};
    
    // Extract patient ID
    patientXml.patientId = extractPatientId(adtMsg.pid);
    
    // Extract patient name
    patientXml.name = extractPatientName(adtMsg.pid);
    
    // Extract date of birth
    patientXml.dateOfBirth = extractDateOfBirth(adtMsg.pid);
    
    // Extract gender
    patientXml.gender = extractGender(adtMsg.pid);
    
    // Extract next of kin information
    if adtMsg is hl7v23:ADT_A01 {
        patientXml.nextOfKin = extractNextOfKin(adtMsg.nk1);
    }
    
    return patientXml;
}