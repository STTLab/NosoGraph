MERGE (refg:ReferenceGenoem {accession_no: $accession_no})
ON CREATE SET
    refg.name = $name,
    refg.molecular_type = $molecular_type
    refg.strain = $strain
    refg.annotation_source = $annotation_source
    refg.source_database = $source_database
RETURN refg