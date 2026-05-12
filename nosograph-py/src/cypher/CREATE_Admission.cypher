MERGE (a:Admission {admission_id: $admission_id})
ON CREATE SET
    a.date_of_admission = CASE
        WHEN $date_of_admission IS NOT NULL
             AND trim($date_of_admission) <> ""
        THEN date($date_of_admission)
        ELSE NULL
    END,
    
    a.date_of_discharge = CASE
        WHEN $date_of_discharge IS NOT NULL
             AND trim($date_of_discharge) <> ""
        THEN date($date_of_discharge)
        ELSE NULL
    END,

    a.length_of_stay = CASE
        WHEN $date_of_admission IS NOT NULL
             AND trim($date_of_admission) <> ""
             AND $date_of_discharge IS NOT NULL
             AND trim($date_of_discharge) <> ""
        THEN duration.inDays(
            date($date_of_admission),
            date($date_of_discharge)
        ).days
        ELSE NULL
    END