MERGE (s:Specimen {specimen_id: $specimen_id})
ON CREATE SET
    s.created_at: datetime()