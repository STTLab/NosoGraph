MATCH (a:Assembly {assembly_id: $assembly_id})-[:HAS_CONTIG]->(c:Contig)
DETACH DELETE a,c