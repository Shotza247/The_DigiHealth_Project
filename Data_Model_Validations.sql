
-- ============================================================
-- 14. SCHEMA VALIDATION
-- ============================================================
-- ------------------------------------------------------------
-- VALIDATION 1: Confirm all 12 tables were created
-- ------------------------------------------------------------
SHOW TABLES;
-- ------------------------------------------------------------
-- VALIDATION 2: Inspect the table structures
-- Confirms columns, data types, NULL rules and key information
-- ------------------------------------------------------------
DESCRIBE Patient;
DESCRIBE Doctor;
DESCRIBE Specialization;
DESCRIBE Appointment;
DESCRIBE MedicalRecord;
DESCRIBE AppointmentDoctor;
DESCRIBE DoctorSpecialization;
DESCRIBE ClinicalEntry;
DESCRIBE Diagnosis;
DESCRIBE Treatment;
DESCRIBE Prescription;
DESCRIBE Billing;
-- ------------------------------------------------------------
-- VALIDATION 3: Inspect the actual CREATE TABLE definitions
-- Useful for checking PK, FK, UNIQUE and CHECK constraints
-- ------------------------------------------------------------
SHOW CREATE TABLE Patient;
SHOW CREATE TABLE Doctor;
SHOW CREATE TABLE Specialization;
SHOW CREATE TABLE Appointment;
SHOW CREATE TABLE MedicalRecord;
SHOW CREATE TABLE AppointmentDoctor;
SHOW CREATE TABLE DoctorSpecialization;
SHOW CREATE TABLE ClinicalEntry;
SHOW CREATE TABLE Diagnosis;
SHOW CREATE TABLE Treatment;
SHOW CREATE TABLE Prescription;
SHOW CREATE TABLE Billing;
-- ------------------------------------------------------------
-- VALIDATION 4: Confirm all Foreign Key relationships
-- ------------------------------------------------------------
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    TABLE_SCHEMA = 'DigiHealth_DB'
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY
    TABLE_NAME,
    COLUMN_NAME;
-- ------------------------------------------------------------
-- VALIDATION 5: Confirm Primary Keys and Unique constraints
-- ------------------------------------------------------------
SELECT
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'DigiHealth_DB'
ORDER BY
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX;
-- ------------------------------------------------------------
-- VALIDATION 6: Validate Appointment-Doctor bridge structure
-- Expected composite PK:
-- (AppointmentID, DoctorID)
-- ------------------------------------------------------------
SHOW INDEX FROM AppointmentDoctor;
-- ------------------------------------------------------------
-- VALIDATION 7: Validate Doctor-Specialization bridge structure
-- Expected composite PK:
-- (DoctorID, SpecializationID)
-- ------------------------------------------------------------
SHOW INDEX FROM DoctorSpecialization;
-- ------------------------------------------------------------
-- VALIDATION 8: Validate Patient -> MedicalRecord 1:0..1
--
-- PatientID should be:
-- FK     -> Patient(PatientID)
-- UNIQUE -> prevents >1 MedicalRecord per patient
-- ------------------------------------------------------------
SHOW INDEX FROM MedicalRecord;
SELECT
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    TABLE_SCHEMA = 'DigiHealth_DB'
    AND TABLE_NAME = 'MedicalRecord';
-- ------------------------------------------------------------
-- VALIDATION 9: Validate Appointment -> Billing 1:0..1
--
-- AppointmentID should be:
-- FK     -> Appointment(AppointmentID)
-- UNIQUE -> prevents >1 Billing record per appointment
-- ------------------------------------------------------------
SHOW INDEX FROM Billing;
SELECT
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    TABLE_SCHEMA = 'DigiHealth_DB'
    AND TABLE_NAME = 'Billing';
-- ------------------------------------------------------------
-- VALIDATION 10: Confirm normalized ClinicalEntry structure
--
-- ClinicalEntry SHOULD contain AppointmentID.
--
-- ClinicalEntry SHOULD NOT contain:
-- PatientID
-- MedicalRecordID
-- ------------------------------------------------------------
DESCRIBE ClinicalEntry;
-- ------------------------------------------------------------
-- VALIDATION 11: Check table count
-- Expected result: 12
-- ------------------------------------------------------------
SELECT COUNT(*) AS TotalTables
FROM INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_SCHEMA = 'DigiHealth_DB'
    AND TABLE_TYPE = 'BASE TABLE';
-- ------------------------------------------------------------
-- VALIDATION 12: Final database summary
-- ------------------------------------------------------------
SELECT
    TABLE_NAME,
    TABLE_ROWS,
    ENGINE
FROM INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_SCHEMA = 'DigiHealth_DB'
    AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

