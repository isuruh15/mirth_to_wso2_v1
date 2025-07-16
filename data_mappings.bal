// Data mapper function to map FHIR Bundle to flat record structure
import ballerinax/health.fhir.r4;

public function mapBundleToFlat(json bundle) returns FlatBundleRecord|error {
    // Extract bundle ID
    json bundleIdJson = check bundle.id;
    string id = bundleIdJson.toString();

    // Extract total entries
    json entryArrayJson = check bundle.entry;
    json[] entries = check entryArrayJson.ensureType();
    int totalEntries = entries.length();

    // Extract patient information (assuming first entry is patient)
    json patientEntry = entries[0];
    map<json> patientEntryMap = check patientEntry.ensureType();
    json patientResourceJson = check patientEntryMap["resource"];
    map<json> patientResource = check patientResourceJson.ensureType();

    json patientIdJson = check patientResource["id"];
    string patientId = patientIdJson.toString();

    json patientNameJson = check patientResource["name"];
    json[] nameArray = check patientNameJson.ensureType();
    map<json> firstName = check nameArray[0].ensureType();
    json givenNamesJson = check firstName["given"];
    json[] givenArray = check givenNamesJson.ensureType();
    json firstGivenJson = givenArray[0];
    string patientGivenName = firstGivenJson.toString();

    json birthDateJson = check patientResource["birthDate"];
    string patientBirthdate = birthDateJson.toString();

    // Extract encounter information (assuming second entry is encounter)
    json encounterEntry = entries[1];
    map<json> encounterEntryMap = check encounterEntry.ensureType();
    json encounterResourceJson = check encounterEntryMap["resource"];
    map<json> encounterResource = check encounterResourceJson.ensureType();
    json encounterIdJson = check encounterResource["id"];
    string encounterId = encounterIdJson.toString();

    return {
        id: id,
        totalEntries: totalEntries,
        patientId: patientId,
        patientGivenName: patientGivenName,
        patientBirthdate: patientBirthdate,
        encounterId: encounterId
    };
}

function transformBundle(r4:Bundle rawBundle) returns FlatBundleRecord => {
    patientId: "",
    patientGivenName: "",
    id: rawBundle.id ?: "",
    totalEntries: rawBundle.total ?: 0,
    patientBirthdate: "",
    encounterId: ""
};