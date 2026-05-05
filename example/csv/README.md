# Example CSV files

## IDs

IDs are used to uniquely identify records and link data together (for example, connecting a patient to their admissions or a ward to a department).

- An ID must uniquely identify one record (no duplicates).
- If your data already includes IDs, you can use them directly.
- If not, you can create your own IDs—there’s no single “correct” format.

If the database is to be used by multiple users or integrate data accross projects,
users should agree on a consistent format for IDs before starting, and make sure
everyone follows the same approach to avoid duplicates or broken links

Examples of creating IDs:

| ID           | Recommendation               | Example                          |
| :----------- | :--------------------------- | :------------------------------- |
| patient_id   | Directly use HN              | P001, P002                       |
| ward_id      | -                            | W01, ICU_01                      |
| admission_id | Obtain form admission record | patient_id + ward_id + date      |
| specimen_id  | Obtain form lab barcode no.  | patient_id + sample_type + date  |

> [!NOTE]
> Beware when combining data from multiple sources.
>
> The same ID may refer to different entities in different systems.
>
> For example, HN:0001 from Hospital A is not the same as HN:0001 from Hospital B
> Using them as-is could lead to overwriting or merging unrelated records

## Setting up our hospital

Before loading patients and clinical events, we first establish a core hospital backbone.
This includes static reference data such as departments and wards,
which other entities (patients, admissions, transfers) will link to.

### Departments.csv

Defines the high-level organizational units within the hospital.

| Property      | Type   | Required | Description                            | Example            |
| ------------- | ------ | -------- | -------------------------------------- | ------------------ |
| department_id | String | ☑        | Unique identifier for the department   | D01                |
| name          | String | ☑        | Department name                        | Cardiology         |
| description   | String | ☐        | Optional description of the department | Heart-related care |

### Wards.csv

Defines physical wards within departments. Each ward typically belongs to a department.

| Property      | Type    | Required | Description                          | Example       |
| ------------- | ------- | -------- | ------------------------------------ | -------       |
| ward_id       | String  | ☑        | Unique identifier for the ward       | W05           |
| name          | String  | ☑        | Ward name                            | Male Surgical |
| department_id | String  | ☑        | Reference to the department          | D03           |
| description   | String  | ☐        | Optional description of the ward     | general ward  |

## Patient metadata

### Patients.csv

This file outline properties of Patient nodes.

| Property      | Type   | Required | Description                                                                     | Example    |
| ------------- | ------ | -------- | ------------------------------------------------------------------------------- | ---------- |
| patient_id    | String | ☑        | Unique identifier for the patient (primary key used for matching/merging nodes) | P001       |
| firstname     | String | ☑        | Patient’s given name                                                            | John       |
| lastname      | String | ☑        | Patient’s family name                                                           | Doe        |
| sex           | String | ☐        | Biological sex of the patient (e.g., "M", "F", "Other")                         | M          |
| date_of_birth | Date   | ☐        | Patient’s date of birth (ISO format: YYYY-MM-DD)                                | 1985-06-15 |

## Admissions

### Admissions.csv

This file outlines properties of Admission nodes (or events).

| Property          | Type     | Required | Description                                                       | Example             |
| ----------------- | -------- | -------- | ----------------------------------------------------------------- | ------------------- |
| patient_id        | String   | ☑        | Reference to the patient                                          | P001                |
| admission_id      | String   | ☐        | Unique identifier for the admission (can be generated if missing) | A1001               |
| ward_id           | String   | ☑        | Identifier for the ward                                           | W01                 |
| room_no           | String   | ☐        | Room number within the ward                                       | 101                 |
| bed_no            | String   | ☐        | Bed number within the room                                        | B1                  |
| date_of_admission | DateTime | ☑        | Admission timestamp                                               | 2025-01-10T14:00:00 |
| date_of_discharge | DateTime | ☐        | Discharge timestamp                                               | 2025-01-15T10:00:00 |
| length_of_stay    | Integer  | ☐        | Duration of stay in days (used if discharge date is unavailable)  | 5                   |

> [!NOTE]
> **Admission ID generation**
>
> `admission_id` is requried to maintain uniqueness of a node
> can be user generated if missing e.g.:
>
> `admission_id = patient_id + "_" + ward_id + "_" + date_of_admission`
> `admission_id = P001_W01_2025-01-10`

## Transfers

### Transfers_option_A.csv

This approach links admissions directly.

| Property          | Type     | Required | Description              | Example             |
| ----------------- | -------- | -------- | ------------------------ | ------------------- |
| patient_id        | String   | ☑        | Reference to the patient | P001                |
| from_admission_id | String   | ☑        | Source admission         | A1001               |
| to_admission_id   | String   | ☑        | Target admission         | A1002               |
| date_of_transfer  | DateTime | ☑        | Transfer timestamp       | 2025-01-12T09:30:00 |

### Transfers_option_B.csv

This approach captures full movement details without relying strictly on admission IDs.

| Property          | Type     | Required | Description                                           | Example             |
| ----------------- | -------- | -------- | ----------------------------------------------------- | ------------------- |
| patient_id        | String   | ☑        | Reference to the patient                              | P001                |
| from_admission_id | String   | ☐        | Source admission (if available)                       | A1001               |
| from_ward_id      | String   | ☑        | Origin ward                                           | W01                 |
| from_room_no      | String   | ☐        | Origin room                                           | 101                 |
| from_bed_no       | String   | ☐        | Origin bed                                            | B1                  |
| date_of_admission | DateTime | ☑        | Start time of stay in origin location                 | 2025-01-10T14:00:00 |
| date_of_transfer  | DateTime | ☑        | Transfer timestamp                                    | 2025-01-12T09:30:00 |
| to_admission_id   | String   | ☐        | Target admission (if available)                       | A1002               |
| to_ward_id        | String   | ☑        | Destination ward                                      | W02                 |
| to_room_no        | String   | ☐        | Destination room                                      | 202                 |
| to_bed_no         | String   | ☐        | Destination bed                                       | B2                  |
| date_of_discharge | DateTime | ☐        | End time of stay in destination location              | 2025-01-15T10:00:00 |
| length_of_stay    | Integer  | ☐        | Duration in days (fallback if discharge date missing) | 5                   |
