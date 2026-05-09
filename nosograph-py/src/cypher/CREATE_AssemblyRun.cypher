MERGE (a:Assembly {assembly_id: $assembly_id})
        ON CREATE SET
            a.assembler = $assembler,
            a.created_at = Date($created_at)
        WITH a, a.created_at = Date($created_at) AS was_created
        RETURN
            CASE WHEN was_created THEN 1 ELSE 0 END AS nodes_created,
            CASE WHEN was_created THEN 0 ELSE 1 END AS nodes_matched