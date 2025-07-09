// Mock function to create sample FHIR Bundle for demonstration
public function createMockFhirBundle() returns json {
    return {
        "id": "bundle-123",
        "entry": [
            {
                "resource": {
                    "id": "patient-456",
                    "name": [
                        {
                            "given": ["John"]
                        }
                    ],
                    "birthDate": "1990-01-01"
                }
            },
            {
                "resource": {
                    "id": "encounter-789"
                }
            }
        ]
    };
}