-- ============================================================
-- DigiHealth PostgreSQL OLAP Warehouse
-- Part 2 - Task 2A
-- Grain: one fact_appointment row per source appointment event
-- PostgreSQL 13+
-- ============================================================

BEGIN;

-- ============================================================
-- 1. Schema creation/definition
-- ============================================================

CREATE SCHEMA IF NOT EXISTS digihealth_stg;
CREATE SCHEMA IF NOT EXISTS digihealth_dw;

-- ============================================================
-- 2. Staging tables
-- ============================================================

CREATE TABLE IF NOT EXISTS digihealth_stg.patient (
    patientid INTEGER PRIMARY KEY,
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    dateofbirth DATE,
    phone VARCHAR(20),
    email VARCHAR(255),
    address VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS digihealth_stg.doctor (
    doctorid INTEGER PRIMARY KEY,
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS digihealth_stg.specialization (
    specializationid INTEGER PRIMARY KEY,
    specializationname VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS digihealth_stg.appointment (
    appointmentid INTEGER PRIMARY KEY,
    patientid INTEGER,
    appointmentdatetime TIMESTAMP,
    appointmentstatus VARCHAR(30),
    reasonforvisit VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS digihealth_stg.appointmentdoctor (
    appointmentid INTEGER,
    doctorid INTEGER,
    PRIMARY KEY (appointmentid, doctorid)
);

CREATE TABLE IF NOT EXISTS digihealth_stg.doctorspecialization (
    doctorid INTEGER,
    specializationid INTEGER,
    PRIMARY KEY (doctorid, specializationid)
);

CREATE TABLE IF NOT EXISTS digihealth_stg.clinicalentry (
    clinicalentryid INTEGER PRIMARY KEY,
    appointmentid INTEGER,
    entrydatetime TIMESTAMP,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS digihealth_stg.diagnosis (
    diagnosisid INTEGER PRIMARY KEY,
    clinicalentryid INTEGER,
    diagnosisdescription VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS digihealth_stg.billing (
    billingid INTEGER PRIMARY KEY,
    appointmentid INTEGER,
    billingdate DATE,
    amount NUMERIC(12,2),
    paymentstatus VARCHAR(30),
    paymentmethod VARCHAR(50)
);

COMMIT;

-- ============================================================
-- 3. staging loading commands
-- ============================================================

-- TRUNCATE TABLE
--     digihealth_stg.patient,
--     digihealth_stg.doctor,
--     digihealth_stg.specialization,
--     digihealth_stg.appointment,
--     digihealth_stg.appointmentdoctor,
--     digihealth_stg.doctorspecialization,
--     digihealth_stg.clinicalentry,
--     digihealth_stg.diagnosis,
--     digihealth_stg.billing;

-- \copy digihealth_stg.patient (patientid, firstname, lastname, dateofbirth, phone, email, address) FROM '/home/project/digihealth_export/patient.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.doctor (doctorid, firstname, lastname, phone, email) FROM '/home/project/digihealth_export/doctor.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.specialization (specializationid, specializationname) FROM '/home/project/digihealth_export/specialization.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.appointment (appointmentid, patientid, appointmentdatetime, appointmentstatus, reasonforvisit) FROM '/home/project/digihealth_export/appointment.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.appointmentdoctor (appointmentid, doctorid) FROM '/home/project/digihealth_export/appointmentdoctor.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.doctorspecialization (doctorid, specializationid) FROM '/home/project/digihealth_export/doctorspecialization.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.clinicalentry (clinicalentryid, appointmentid, entrydatetime, notes) FROM '/home/project/digihealth_export/clinicalentry.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.diagnosis (diagnosisid, clinicalentryid, diagnosisdescription) FROM '/home/project/digihealth_export/diagnosis.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
-- \copy digihealth_stg.billing (billingid, appointmentid, billingdate, amount, paymentstatus, paymentmethod) FROM '/home/project/digihealth_export/billing.tsv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');

BEGIN;

SET search_path TO digihealth_dw, public;

-- ============================================================
-- 4. Dimension tables
-- ============================================================

CREATE TABLE IF NOT EXISTS dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_number SMALLINT NOT NULL CHECK (day_number BETWEEN 1 AND 31),
    day_name VARCHAR(10) NOT NULL,
    month_number SMALLINT NOT NULL CHECK (month_number BETWEEN 1 AND 12),
    month_name VARCHAR(10) NOT NULL,
    quarter_number SMALLINT NOT NULL CHECK (quarter_number BETWEEN 1 AND 4),
    year_number SMALLINT NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_patient (
    patient_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    age_band VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dim_appointment_status (
    status_key SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_code VARCHAR(30) NOT NULL UNIQUE,
    status_name VARCHAR(50) NOT NULL,
    CONSTRAINT chk_dim_status_code
        CHECK (status_code IN ('Scheduled', 'Completed', 'Cancelled'))
);

CREATE TABLE IF NOT EXISTS dim_doctor (
    doctor_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doctor_id INTEGER NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_specialization (
    specialization_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    specialization_id INTEGER NOT NULL UNIQUE,
    specialization_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_diagnosis (
    diagnosis_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    diagnosis_code VARCHAR(50) NOT NULL UNIQUE,
    diagnosis_description VARCHAR(255) NOT NULL UNIQUE
);

-- ============================================================
-- 5. fact table
-- ============================================================

CREATE TABLE IF NOT EXISTS fact_appointment (
    appointment_fact_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id INTEGER NOT NULL UNIQUE,
    patient_key BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    status_key SMALLINT NOT NULL,
    appointment_count SMALLINT NOT NULL DEFAULT 1,
    billing_amount NUMERIC(12,2),
    CONSTRAINT fk_fact_appointment_patient
        FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    CONSTRAINT fk_fact_appointment_date
        FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_appointment_status
        FOREIGN KEY (status_key) REFERENCES dim_appointment_status(status_key),
    CONSTRAINT chk_fact_appointment_count CHECK (appointment_count = 1),
    CONSTRAINT chk_fact_billing_amount
        CHECK (billing_amount IS NULL OR billing_amount >= 0)
);

-- ============================================================
-- 6. bridge tables for many-to-many relationships
-- ============================================================

CREATE TABLE IF NOT EXISTS bridge_appointment_doctor (
    appointment_fact_key BIGINT NOT NULL,
    doctor_key BIGINT NOT NULL,
    PRIMARY KEY (appointment_fact_key, doctor_key),
    CONSTRAINT fk_bridge_appointment_doctor_fact
        FOREIGN KEY (appointment_fact_key)
        REFERENCES fact_appointment(appointment_fact_key)
        ON DELETE CASCADE,
    CONSTRAINT fk_bridge_appointment_doctor_doctor
        FOREIGN KEY (doctor_key) REFERENCES dim_doctor(doctor_key)
);

CREATE TABLE IF NOT EXISTS bridge_doctor_specialization (
    doctor_key BIGINT NOT NULL,
    specialization_key BIGINT NOT NULL,
    PRIMARY KEY (doctor_key, specialization_key),
    CONSTRAINT fk_bridge_doctor_specialization_doctor
        FOREIGN KEY (doctor_key) REFERENCES dim_doctor(doctor_key)
        ON DELETE CASCADE,
    CONSTRAINT fk_bridge_doctor_specialization_specialization
        FOREIGN KEY (specialization_key)
        REFERENCES dim_specialization(specialization_key)
);

CREATE TABLE IF NOT EXISTS bridge_appointment_diagnosis (
    appointment_fact_key BIGINT NOT NULL,
    diagnosis_key BIGINT NOT NULL,
    PRIMARY KEY (appointment_fact_key, diagnosis_key),
    CONSTRAINT fk_bridge_appointment_diagnosis_fact
        FOREIGN KEY (appointment_fact_key)
        REFERENCES fact_appointment(appointment_fact_key)
        ON DELETE CASCADE,
    CONSTRAINT fk_bridge_appointment_diagnosis_diagnosis
        FOREIGN KEY (diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key)
);

-- ============================================================
-- 7.  Indexes for analytical performance
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_appointment_patient
    ON fact_appointment(patient_key);
CREATE INDEX IF NOT EXISTS idx_fact_appointment_date
    ON fact_appointment(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_appointment_status
    ON fact_appointment(status_key);
CREATE INDEX IF NOT EXISTS idx_bridge_appointment_doctor_doctor
    ON bridge_appointment_doctor(doctor_key);
CREATE INDEX IF NOT EXISTS idx_bridge_doctor_specialization_specialization
    ON bridge_doctor_specialization(specialization_key);
CREATE INDEX IF NOT EXISTS idx_bridge_appointment_diagnosis_diagnosis
    ON bridge_appointment_diagnosis(diagnosis_key);

-- ============================================================
-- 8. Dimension loading
-- ============================================================

INSERT INTO dim_date (
    date_key, full_date, day_number, day_name,
    month_number, month_name, quarter_number, year_number
)
SELECT
    TO_CHAR(calendar_date, 'YYYYMMDD')::INTEGER,
    calendar_date,
    EXTRACT(DAY FROM calendar_date)::SMALLINT,
    TO_CHAR(calendar_date, 'FMDay'),
    EXTRACT(MONTH FROM calendar_date)::SMALLINT,
    TO_CHAR(calendar_date, 'FMMonth'),
    EXTRACT(QUARTER FROM calendar_date)::SMALLINT,
    EXTRACT(YEAR FROM calendar_date)::SMALLINT
FROM (
    SELECT GENERATE_SERIES(
        MIN(appointmentdatetime)::DATE,
        MAX(appointmentdatetime)::DATE,
        INTERVAL '1 day'
    )::DATE AS calendar_date
    FROM digihealth_stg.appointment
) AS date_range
ON CONFLICT (date_key) DO UPDATE SET
    full_date = EXCLUDED.full_date,
    day_number = EXCLUDED.day_number,
    day_name = EXCLUDED.day_name,
    month_number = EXCLUDED.month_number,
    month_name = EXCLUDED.month_name,
    quarter_number = EXCLUDED.quarter_number,
    year_number = EXCLUDED.year_number;

INSERT INTO dim_patient (
    patient_id, first_name, last_name, date_of_birth, age_band
)
SELECT
    patientid,
    firstname,
    lastname,
    dateofbirth,
    CASE
        WHEN DATE_PART('year', AGE(CURRENT_DATE, dateofbirth)) < 18 THEN 'Under 18'
        WHEN DATE_PART('year', AGE(CURRENT_DATE, dateofbirth)) BETWEEN 18 AND 29 THEN '18-29'
        WHEN DATE_PART('year', AGE(CURRENT_DATE, dateofbirth)) BETWEEN 30 AND 44 THEN '30-44'
        WHEN DATE_PART('year', AGE(CURRENT_DATE, dateofbirth)) BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END
FROM digihealth_stg.patient
ON CONFLICT (patient_id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    date_of_birth = EXCLUDED.date_of_birth,
    age_band = EXCLUDED.age_band;

INSERT INTO dim_appointment_status (status_code, status_name)
SELECT DISTINCT appointmentstatus, appointmentstatus
FROM digihealth_stg.appointment
WHERE appointmentstatus IS NOT NULL
ON CONFLICT (status_code) DO UPDATE
SET status_name = EXCLUDED.status_name;

INSERT INTO dim_doctor (doctor_id, first_name, last_name)
SELECT doctorid, firstname, lastname
FROM digihealth_stg.doctor
ON CONFLICT (doctor_id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name;

INSERT INTO dim_specialization (specialization_id, specialization_name)
SELECT specializationid, specializationname
FROM digihealth_stg.specialization
ON CONFLICT (specialization_id) DO UPDATE
SET specialization_name = EXCLUDED.specialization_name;

INSERT INTO dim_diagnosis (diagnosis_code, diagnosis_description)
SELECT DISTINCT
    'DX-' || UPPER(SUBSTRING(MD5(LOWER(TRIM(diagnosisdescription))) FROM 1 FOR 12)),
    TRIM(diagnosisdescription)
FROM digihealth_stg.diagnosis
WHERE diagnosisdescription IS NOT NULL
  AND TRIM(diagnosisdescription) <> ''
ON CONFLICT (diagnosis_code) DO UPDATE
SET diagnosis_description = EXCLUDED.diagnosis_description;

-- ============================================================
-- 9. Fact loading
-- ============================================================

INSERT INTO fact_appointment (
    appointment_id,
    patient_key,
    date_key,
    status_key,
    appointment_count,
    billing_amount
)
SELECT
    a.appointmentid,
    dp.patient_key,
    TO_CHAR(a.appointmentdatetime::DATE, 'YYYYMMDD')::INTEGER,
    ds.status_key,
    1,
    b.amount
FROM digihealth_stg.appointment a
JOIN dim_patient dp
    ON dp.patient_id = a.patientid
JOIN dim_appointment_status ds
    ON ds.status_code = a.appointmentstatus
LEFT JOIN digihealth_stg.billing b
    ON b.appointmentid = a.appointmentid
ON CONFLICT (appointment_id) DO UPDATE SET
    patient_key = EXCLUDED.patient_key,
    date_key = EXCLUDED.date_key,
    status_key = EXCLUDED.status_key,
    appointment_count = EXCLUDED.appointment_count,
    billing_amount = EXCLUDED.billing_amount;

-- ============================================================
-- 10. Bridge table loading for many-to-many relationships
-- ============================================================

INSERT INTO bridge_appointment_doctor (
    appointment_fact_key, doctor_key
)
SELECT DISTINCT
    fa.appointment_fact_key,
    dd.doctor_key
FROM digihealth_stg.appointmentdoctor ad
JOIN fact_appointment fa
    ON fa.appointment_id = ad.appointmentid
JOIN dim_doctor dd
    ON dd.doctor_id = ad.doctorid
ON CONFLICT (appointment_fact_key, doctor_key) DO NOTHING;

INSERT INTO bridge_doctor_specialization (
    doctor_key, specialization_key
)
SELECT DISTINCT
    dd.doctor_key,
    ds.specialization_key
FROM digihealth_stg.doctorspecialization src
JOIN dim_doctor dd
    ON dd.doctor_id = src.doctorid
JOIN dim_specialization ds
    ON ds.specialization_id = src.specializationid
ON CONFLICT (doctor_key, specialization_key) DO NOTHING;

INSERT INTO bridge_appointment_diagnosis (
    appointment_fact_key, diagnosis_key
)
SELECT DISTINCT
    fa.appointment_fact_key,
    dd.diagnosis_key
FROM digihealth_stg.diagnosis src
JOIN digihealth_stg.clinicalentry ce
    ON ce.clinicalentryid = src.clinicalentryid
JOIN fact_appointment fa
    ON fa.appointment_id = ce.appointmentid
JOIN dim_diagnosis dd
    ON dd.diagnosis_code =
       'DX-' || UPPER(SUBSTRING(MD5(LOWER(TRIM(src.diagnosisdescription))) FROM 1 FOR 12))
WHERE src.diagnosisdescription IS NOT NULL
  AND TRIM(src.diagnosisdescription) <> ''
ON CONFLICT (appointment_fact_key, diagnosis_key) DO NOTHING;

COMMIT;

-- ============================================================
-- 11. End-to-end validation queries
-- ============================================================

SET search_path TO digihealth_dw, public;

-- Warehouse object counts
SELECT 'dim_date' AS object_name, COUNT(*) AS row_count FROM dim_date
UNION ALL SELECT 'dim_patient', COUNT(*) FROM dim_patient
UNION ALL SELECT 'dim_appointment_status', COUNT(*) FROM dim_appointment_status
UNION ALL SELECT 'dim_doctor', COUNT(*) FROM dim_doctor
UNION ALL SELECT 'dim_specialization', COUNT(*) FROM dim_specialization
UNION ALL SELECT 'dim_diagnosis', COUNT(*) FROM dim_diagnosis
UNION ALL SELECT 'fact_appointment', COUNT(*) FROM fact_appointment
UNION ALL SELECT 'bridge_appointment_doctor', COUNT(*) FROM bridge_appointment_doctor
UNION ALL SELECT 'bridge_doctor_specialization', COUNT(*) FROM bridge_doctor_specialization
UNION ALL SELECT 'bridge_appointment_diagnosis', COUNT(*) FROM bridge_appointment_diagnosis
ORDER BY object_name;

-- Grain test: expected 0 rows
SELECT appointment_id, COUNT(*) AS fact_rows
FROM fact_appointment
GROUP BY appointment_id
HAVING COUNT(*) > 1;

-- Fact-count test: 
SELECT
    MIN(appointment_count) AS minimum_count,
    MAX(appointment_count) AS maximum_count,
    SUM(appointment_count) AS total_appointments
FROM fact_appointment;

-- Source appointments missing from fact: 
SELECT a.appointmentid, a.appointmentdatetime, a.appointmentstatus
FROM digihealth_stg.appointment a
LEFT JOIN fact_appointment f
    ON f.appointment_id = a.appointmentid
WHERE f.appointment_fact_key IS NULL;

-- Fact appointments absent from source:
SELECT f.appointment_id
FROM fact_appointment f
LEFT JOIN digihealth_stg.appointment a
    ON a.appointmentid = f.appointment_id
WHERE a.appointmentid IS NULL;

-- Billing reconciliation: 
SELECT
    s.source_total,
    w.warehouse_total,
    w.warehouse_total - s.source_total AS difference
FROM (SELECT SUM(amount) AS source_total FROM digihealth_stg.billing) s
CROSS JOIN (SELECT SUM(billing_amount) AS warehouse_total FROM fact_appointment) w;

-- Lifecycle summary: 
SELECT
    s.status_name,
    SUM(f.appointment_count) AS appointments,
    COUNT(f.billing_amount) AS billed_appointments,
    SUM(f.billing_amount) AS billing_total
FROM fact_appointment f
JOIN dim_appointment_status s
    ON s.status_key = f.status_key
GROUP BY s.status_name
ORDER BY s.status_name;

-- Scheduled/cancelled appointments with billing: 
SELECT f.appointment_id, s.status_name, f.billing_amount
FROM fact_appointment f
JOIN dim_appointment_status s
    ON s.status_key = f.status_key
WHERE s.status_name IN ('Scheduled', 'Cancelled')
  AND f.billing_amount IS NOT NULL;

-- Date range: 
SELECT MIN(full_date) AS first_date,
       MAX(full_date) AS last_date,
       COUNT(*) AS date_rows
FROM dim_date;

-- Source/warehouse bridge counts
SELECT
    (SELECT COUNT(*) FROM digihealth_stg.appointmentdoctor) AS source_doctor_links,
    (SELECT COUNT(*) FROM bridge_appointment_doctor) AS warehouse_doctor_links,
    (SELECT COUNT(*) FROM digihealth_stg.doctorspecialization) AS source_specialization_links,
    (SELECT COUNT(*) FROM bridge_doctor_specialization) AS warehouse_specialization_links,
    (SELECT COUNT(*) FROM digihealth_stg.diagnosis) AS source_diagnoses,
    (SELECT COUNT(*) FROM bridge_appointment_diagnosis) AS warehouse_diagnosis_links;

-- Orphan checks: 
SELECT COUNT(*) AS invalid_doctor_bridge_rows
FROM bridge_appointment_doctor b
LEFT JOIN fact_appointment f
    ON f.appointment_fact_key = b.appointment_fact_key
LEFT JOIN dim_doctor d
    ON d.doctor_key = b.doctor_key
WHERE f.appointment_fact_key IS NULL OR d.doctor_key IS NULL;

SELECT COUNT(*) AS invalid_specialization_bridge_rows
FROM bridge_doctor_specialization b
LEFT JOIN dim_doctor d
    ON d.doctor_key = b.doctor_key
LEFT JOIN dim_specialization s
    ON s.specialization_key = b.specialization_key
WHERE d.doctor_key IS NULL OR s.specialization_key IS NULL;

SELECT COUNT(*) AS invalid_diagnosis_bridge_rows
FROM bridge_appointment_diagnosis b
LEFT JOIN fact_appointment f
    ON f.appointment_fact_key = b.appointment_fact_key
LEFT JOIN dim_diagnosis d
    ON d.diagnosis_key = b.diagnosis_key
WHERE f.appointment_fact_key IS NULL OR d.diagnosis_key IS NULL;

-- Final warehouse summary:
SELECT
    COUNT(*) AS appointment_count,
    COUNT(billing_amount) AS billed_appointments,
    SUM(billing_amount) AS total_billing,
    AVG(billing_amount) AS average_billing
FROM fact_appointment;

-- Analytical query: 
SELECT
    dt.year_number,
    dt.month_number,
    dt.month_name,
    st.status_name,
    SUM(f.appointment_count) AS appointments,
    SUM(f.billing_amount) AS billing_total
FROM fact_appointment f
JOIN dim_date dt
    ON dt.date_key = f.date_key
JOIN dim_appointment_status st
    ON st.status_key = f.status_key
GROUP BY
    dt.year_number,
    dt.month_number,
    dt.month_name,
    st.status_name
ORDER BY
    dt.year_number,
    dt.month_number,
    st.status_name;

-- Diagnostic detail query
SELECT
    f.appointment_id,
    d.diagnosis_code,
    d.diagnosis_description
FROM bridge_appointment_diagnosis b
JOIN fact_appointment f
    ON f.appointment_fact_key = b.appointment_fact_key
JOIN dim_diagnosis d
    ON d.diagnosis_key = b.diagnosis_key
ORDER BY f.appointment_id, d.diagnosis_description;

-- Doctor detail query
SELECT
    f.appointment_id,
    d.doctor_id,
    d.first_name,
    d.last_name
FROM bridge_appointment_doctor b
JOIN fact_appointment f
    ON f.appointment_fact_key = b.appointment_fact_key
JOIN dim_doctor d
    ON d.doctor_key = b.doctor_key
ORDER BY f.appointment_id, d.doctor_id;

