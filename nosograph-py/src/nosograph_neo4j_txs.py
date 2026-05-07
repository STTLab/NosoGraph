from neo4j import ManagedTransaction
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
