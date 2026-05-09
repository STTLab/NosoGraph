# pyright: reportUnusedFunction=false
import os
import glob
from neo4j import ManagedTransaction
from datetime import datetime, UTC
from custom_types import (
    AssemblyProps,
    ContigProps,
    NodeCreateOrMatchStats,
    NodeAndRelationshipCreationStats
)

dirname = os.path.dirname(__file__)
cypher_dir = os.path.join(dirname, 'cypher')
def _load_cypher(cypher_dir):
    cypher_files = glob.glob(os.path.join(cypher_dir, '*.cypher'))
    cypher_items = []
    for cypher_file in cypher_files:
        with open(cypher_file, 'r', encoding='utf-8') as f:
            cypher_script = f.read()
        cypher_items.append((os.path.splitext(os.path.basename(cypher_file))[0], cypher_script))
    return dict(cypher_items)

CYPHERS=_load_cypher(cypher_dir)

@staticmethod
def _get_patient_by_id(tx: ManagedTransaction, patient_id):
    record = tx.run(
        CYPHERS['MATCH_Patient'],
        patient_id=patient_id
    ).single()
    if record is None:
        return None

    node = record["p"]
    return dict(node)

@staticmethod
def _create_patient_tx(tx: ManagedTransaction, patient_id, firstname, lastname, sex, dob, age):
    result = tx.run(
        query=CYPHERS['create_patient'],
        patient_id=patient_id,
        firstname=firstname,
        lastname=lastname,
        sex=sex,
        dob=dob,
        age=age
    )
    return result.single()["id"]

def _create_assembly_run(
        tx: ManagedTransaction,
        assembly_id:str,
        assembler: str,
        created_at: datetime|None = None
    ) -> NodeCreateOrMatchStats:
    result = tx.run(
        query=CYPHERS['CREATE_AssemblyEvent'],
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
        """//cypher
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
    result = tx.run(
        query=CYPHERS['ASSOCIATE_Contig_AssemblyRun'],
        assembly_id=assembly_id,
        contigs=contigs,
    )
    summary = result.consume()
    return {
        "nodes_created": summary.counters.nodes_created,
        "relationships_created": summary.counters.relationships_created,
    }

@staticmethod
def _create_organism(
    tx: ManagedTransaction
):
    with open(f'{cypher_dir}/create_organism.cypher', 'r', encoding='utf-8') as f:
        query = f.read()
    new_organism = tx.run(query)

if __name__ == '__main__':
    print(_load_cypher())
