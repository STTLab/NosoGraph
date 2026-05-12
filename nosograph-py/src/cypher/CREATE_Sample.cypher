MERGE (s:Sample {sample_id: $sample_id})
ON CREATE SET
    s.created_at: datetime()