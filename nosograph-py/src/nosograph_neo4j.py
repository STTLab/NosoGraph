import logging
from neo4j import GraphDatabase, Driver
from nosograph_neo4j_txs import _create_assembly_run, _associate_contigs
from custom_types import (
    AssemblyProps,
    ContigProps,
    NodeCreateOrMatchStats,
    NodeAndRelationshipCreationStats
)

class NosoGraph(GraphDatabase):
    def __init__(self, database_uri, username, password):
        self._logger = logging.getLogger(self.__class__.__name__)
        self._logger.info("Initializing NosoGraph")

        self._driver = super().driver(
            uri=database_uri, 
            auth=(username, password)
        )

    def __enter__(self):
        self.verify()
        return self
    
    def __exit__(self, exc_type, exc, tb):
        self.close()

    @property
    def driver(self) -> Driver:
        return self._driver

    def verify(self) -> None:
        '''
        Verify database connection.
        '''
        try:
            self._logger.info("Verifying database connectivity...")
            self._driver.verify_connectivity()
            self._logger.info("Connection successful")
        except BaseException as e:
            self._logger.error(e)

    def close(self) -> None:
        '''
        Shut down, closing any open connections in the pool.
        '''
        self._logger.info("Closing driver")
        self._driver.close()

    def add_assembly(
        self,
        **assembly_data: AssemblyProps
    ) -> NodeCreateOrMatchStats:
        with self._driver.session() as session:
            stats = session.execute_write(
                _create_assembly_event,
                assembly_id=assembly_data.get('assembly_id'),
                assembler=assembly_data.get('assembler'),
                created_at=assembly_data.get('created_at')
            )
            self._logger.info(stats)
            return stats

    def add_contigs(
        self,
        assembly_id: str,
        contigs: list[ContigProps]
    ) -> NodeAndRelationshipCreationStats:
        with self._driver.session() as session:
            stats = session.execute_write(
                _associate_contigs,
                assembly_id,
                contigs
            )
            self._logger.info(stats)
            return stats

if __name__ == '__main__':

    logging.basicConfig(
        level='INFO',
        format="%(asctime)s [%(levelname)s] [%(name)s] %(message)s"
    )

    URI='neo4j://localhost:7687'
    with NosoGraph(URI, 'neo4j', 'minamini114') as conn:
        conn.add_assembly(
            assembly_id='test_assembly'
        )
        conn.add_contigs('test_assembly', [
            {
                'contig_id': '1',
                'length': 4,
                'sequence': 'ATCG',
                'hash_algorithm': 'md5',
                'hash': ''
            }
        ])
