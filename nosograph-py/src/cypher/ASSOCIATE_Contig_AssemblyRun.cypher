MATCH (a:Assembly {assembly_id: $assembly_id})

    UNWIND $contigs AS contig

    MERGE (c:Contig {contig_id: contig.contig_id})
    ON CREATE SET
        c.length = contig.length,
        c.sequence = contig.sequence,
        c.hash_algorithm = contig.hash_algorithm,
        c.sequence_hash = contig.sequence_hash
    ON MATCH SET
        c.length = contig.length,
        c.sequence = contig.sequence,
        c.hash_algorithm = contig.hash_algorithm,
        c.sequence_hash = contig.sequence_hash

    MERGE (a)-[:HAS_CONTIG]->(c)
