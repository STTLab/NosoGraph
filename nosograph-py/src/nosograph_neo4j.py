import logging
from neo4j import GraphDatabase, Driver

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

if __name__ == '__main__':

    logging.basicConfig(
        level='INFO',
        format="%(asctime)s [%(levelname)s] [%(name)s] %(message)s"
    )

    URI='neo4j://localhost:7687'
    with NosoGraph(URI, 'neo4j', 'neo4j') as conn:
        pass
