

// Note: The key constraint is for enterprise edition.
// Existance and Uniqueness constraints are required
// to replicate the key constraint in community edition.

// Ward
CREATE CONSTRAINT ward_must_have_id IF NOT EXISTS 
FOR (ward:Ward) REQUIRE ward.ward_id IS NOT NULL;
CREATE CONSTRAINT ward_id_must_be_unique IF NOT EXISTS
FOR (ward:Ward) REQUIRE ward.ward_id IS UNIQUE;

// Department
CREATE CONSTRAINT department_must_have_id IF NOT EXISTS
FOR (department:Department) REQUIRE department.department_id IS NOT NULL;
CREATE CONSTRAINT department_id_must_be_unique IF NOT EXISTS
FOR (department:Department) REQUIRE department.department_id IS UNIQUE;

// Patient
CREATE CONSTRAINT patient_must_have_id IF NOT EXISTS
FOR (patient:Patient) REQUIRE patient.patient_id IS NOT NULL;
CREATE CONSTRAINT patient_id_must_be_unique IF NOT EXISTS
FOR (patient:Patient) REQUIRE patient.patient_id IS UNIQUE;

// Admission
CREATE CONSTRAINT admission_must_have_id IF NOT EXISTS
FOR (admission:Admission) REQUIRE admission.admission_id IS NOT NULL;
CREATE CONSTRAINT admission_id_must_be_unique IF NOT EXISTS
FOR (admission:Admission) REQUIRE admission.admission_id IS UNIQUE;

// Specimen
CREATE CONSTRAINT specimen_must_have_id IF NOT EXISTS
FOR (specimen:Specimen) REQUIRE specimen.specimen_id IS NOT NULL;
CREATE CONSTRAINT specimen_id_must_be_unique IF NOT EXISTS
FOR (specimen:Specimen) REQUIRE specimen.specimen_id IS UNIQUE;

// Sample
CREATE CONSTRAINT sample_must_have_id IF NOT EXISTS
FOR (sample:Sample) REQUIRE sample.sample_id IS NOT NULL;
CREATE CONSTRAINT sample_id_must_be_unique IF NOT EXISTS
FOR (sample:Sample) REQUIRE sample.sample_id IS UNIQUE;

//LabResult
/*
The model expects (:LabResult:<Subtype>)

The constrains on :LabResult applies to ALL nodes carrying the :LabResult label, including:
 - :LabResult:CBC
 - :LabResult:BacterialCulture
 - :LabResult:Pathology
 - etc.
*/
CREATE CONSTRAINT lab_result_id_exists IF NOT EXISTS
FOR (lr:LabResult) REQUIRE lr.lab_id IS NOT NULL;
CREATE CONSTRAINT lab_result_id_unique IF NOT EXISTS
FOR (lr:LabResult) REQUIRE lr.lab_id IS UNIQUE;

// Variant
// variant_key = REF_ACC + ":" + POS + ":" + REF + ">" + ALT
// i.e. NC_000001.11:123456:A>G
CREATE CONSTRAINT variant_key_must_exist IF NOT EXISTS
FOR (variant:Variant)
REQUIRE variant.variant_key IS NOT NULL;

CREATE CONSTRAINT variant_key_must_be_unique IF NOT EXISTS
FOR (variant:Variant)
REQUIRE variant.variant_key IS UNIQUE;

// Required component fields
CREATE CONSTRAINT variant_ref_acc_must_exist IF NOT EXISTS
FOR (variant:Variant)
REQUIRE variant.REF_ACC IS NOT NULL;

CREATE CONSTRAINT variant_ref_must_exist IF NOT EXISTS
FOR (variant:Variant)
REQUIRE variant.REF IS NOT NULL;

CREATE CONSTRAINT variant_alt_must_exist IF NOT EXISTS
FOR (variant:Variant)
REQUIRE variant.ALT IS NOT NULL;

CREATE CONSTRAINT variant_pos_must_exist IF NOT EXISTS
FOR (variant:Variant)
REQUIRE variant.POS IS NOT NULL;
