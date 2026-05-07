# pyright: reportUnusedFunction=false

from neo4j import ManagedTransaction
from datetime import datetime, UTC
from custom_types import (
    AssemblyProps,
    ContigProps,
    NodeCreateOrMatchStats,
    NodeAndRelationshipCreationStats
)

def _get_patient_by_id(tx: ManagedTransaction, patient_id):
    record = tx.run(
        'MATCH (p:Patient) WHERE p.patient_id = $patient_id RETURN p',
        patient_id=patient_id
    ).single()
    if record is None:
        return None

    node = record["p"]
    return dict(node)

@staticmethod
def _create_patient_tx(tx: ManagedTransaction, patient_id, firstname, lastname, sex, dob, age):
    result = tx.run(
        '''
        CREATE (p:Patient {
            patient_id: $patient_id,
            firstname: $firstname,
            lastname: $lastname,
            sex: $sex,
            date_of_birth: $dob,
            age: $age,
            created_at: datetime()
        })
        RETURN p.patient_id AS id
        ''',
        patient_id=patient_id,
        firstname=firstname,
        lastname=lastname,
        sex=sex,
        dob=dob,
        age=age
    )
    return result.single()["id"]

def _create_assembly_event(
        tx: ManagedTransaction,
        assembly_id:str,
        assembler: str,
        created_at: datetime|None = None
    ) -> NodeCreateOrMatchStats:
    result = tx.run(
        '''
        MERGE (a:Assembly {assembly_id: $assembly_id})
        ON CREATE SET
            a.assembler = $assembler,
            a.created_at = Date($created_at)
        WITH a, a.created_at = Date($created_at) AS was_created
        RETURN
            CASE WHEN was_created THEN 1 ELSE 0 END AS nodes_created,
            CASE WHEN was_created THEN 0 ELSE 1 END AS nodes_matched
        ''',
        assembly_id=assembly_id,
        assembler=assembler,
        created_at=created_at or datetime.now(UTC)
    )
    record = result.single()
    return {
        "nodes_created": record["nodes_created"],
        "nodes_matched": record["nodes_matched"],
    }

def _associate_contigs(
    tx: ManagedTransaction,
    assembly_id: str,
    contigs: list[ContigProps],
) -> NodeAndRelationshipCreationStats:
    """
    Associate contigs with an assembly node.

    Each contig dict should contain:
        - contig_id: str
        - length: int
        - sequence: str
        - hash_algorithm: str
        - sequence_hash: str
    """

    # Ensure assembly exists
    assembly_exists = tx.run(
        """
        MATCH (a:Assembly {assembly_id: $assembly_id})
        RETURN a
        LIMIT 1
        """,
        assembly_id=assembly_id,
    ).single()

    if assembly_exists is None:
        raise ValueError(
            f"Assembly with assembly_id '{assembly_id}' was not found."
        )

    query = """
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
    """
    result = tx.run(
        query,
        assembly_id=assembly_id,
        contigs=contigs,
    )
    summary = result.consume()
    return {
        "nodes_created": summary.counters.nodes_created,
        "relationships_created": summary.counters.relationships_created,
    }
