MATCH (p:Patient {patient_id: $patient_id})
MATCH (s:Specimen {specimen_id: $specimen_id})
MERGE (s)-[:COLLECTED_FROM]->(p)