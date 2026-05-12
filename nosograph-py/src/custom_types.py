from typing import Literal, TypedDict, NamedTuple

class Neo4JAuth(NamedTuple):
    user: Literal['neo4j']
    password: str
    '''
    Neo4j authentication credentials.

    Neo4j requires authentication strings in the format:

        neo4j/<password>

    The initial username is fixed to ``neo4j`` and cannot
    be changed during container initialization.
    '''
    @classmethod
    def from_string(cls, value: str | None) -> "Neo4JAuth | None":
        '''
        Parse a Neo4j authentication string.

        Parameters
        ----------
        value:
            Authentication string in the format
            ``neo4j/<password>``.

            If ``None`` or an empty string is provided,
            ``None`` is returned.

        Returns
        -------
        Neo4JAuth | None
            A tuple-like ``Neo4JAuth`` object where:

            - The first element is the fixed username
              ``"neo4j"`` as required by Neo4j.
            - The second element is the authentication
              password.

            Returns ``None`` if the input is ``None`` or empty.

        Raises
        ------
        ValueError
            If the string is not in the expected format or
            the username is not ``neo4j``.
        '''
        if value is None:
            return None

        value = value.strip()

        if not value:
            return None

        try:
            user, password = value.split("/", 1)
        except ValueError:
            raise ValueError(
                "Auth string must be in format 'neo4j/password'"
            )

        if user != "neo4j":
            raise ValueError(
                "Neo4j username must be 'neo4j'"
            )

        return cls(user="neo4j", password=password)

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
