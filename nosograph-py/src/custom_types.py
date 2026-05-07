from typing import TypedDict

class AssemblyProps(TypedDict):
    assembly_id: str
    assembler: str
    created_at: str

class ContigProps(TypedDict):
    contig_id: str
    length: int
    sequence: str
    hash_algorithm: str
    sequence_hash: str

class NodeCreateOrMatchStats(TypedDict):
    nodes_matched: int
    nodes_created: int

class NodeAndRelationshipCreationStats(TypedDict):
    nodes_created: int
    relationships_created: int
