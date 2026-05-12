MATCH (p:Patient {patient_id: $patient_id})
MATCH (a:Admission {admission_id: $admission_id})
MERGE (p)-[:HAS_ADMISSION]->(a)