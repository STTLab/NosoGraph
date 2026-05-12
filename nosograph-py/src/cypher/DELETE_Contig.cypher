MATCH (c:Contig) WHERE c.contig_id = $contig_id
DETACH DELETE c