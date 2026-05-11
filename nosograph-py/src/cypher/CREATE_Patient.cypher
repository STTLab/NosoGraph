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