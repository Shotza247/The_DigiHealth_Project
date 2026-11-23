-- ============================================================
-- DIGIHEALTH OLTP TO OLAP ETL
-- PostgreSQL staging layer
-- ============================================================

CREATE SCHEMA IF NOT EXISTS digihealth_stg;

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

SET search_path TO digihealth_dw, public;


mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM Patient;" \
  | sed 's/\t/,/g' \
  > /home/project/digihealth_export/patient.csv

Inside MySQL
SELECT
    DoctorID,
    FirstName,
    LastName,
    Phone,
    Email
FROM Doctor
INTO OUTFILE '/var/lib/mysql-files/doctor.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n';

Inside Terminal:
mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT PatientID, FirstName, LastName, DateOfBirth, Phone, Email, Address FROM Patient;" \
  > /home/project/digihealth_export/patient.tsv

head -n 6 /home/project/digihealth_export/patient.tsv

\copy digihealth_stg.patient (
    patientid,
    firstname,
    lastname,
    dateofbirth,
    phone,
    email,
    address
)
FROM '/home/project/digihealth_export/patient.tsv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER E'\t',
    QUOTE E'\b'
);




mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM Doctor;" \
  | sed 's/\t/,/g' \
  > /home/project/digihealth_export/doctor.csv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM Specialization;" \
  | sed 's/\t/,/g' \
  > /home/project/digihealth_export/specialization.csv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM Specialization;" \
  > /home/project/digihealth_export/specialization.tsv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM Appointment;" \
  > /home/project/digihealth_export/appointment.csv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM AppointmentDoctor;" \
  | sed 's/\t/,/g' \
  > /home/project/digihealth_export/appointmentdoctor.csv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM DoctorSpecialization
;" \
  | sed 's/\t/,/g' \
  > /home/project/digihealth_export/doctorspecialization
.csv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM ClinicalEntry;" \
  | sed 's/\t/,/g' \
  > /home/project/digihealth_export/clinicalentry.csv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM Diagnosis;" \
  > /home/project/digihealth_export/diagnosis.tsv

mysql -u root -p \
  --database=DigiHealth_DB \
  --batch \
  --raw \
  -e "SELECT * FROM Billing;" \
  > /home/project/digihealth_export/billing.tsv

\copy digihealth_stg.billing (
    billingid,
    appointmentid,
    billingdate,
    amount,
    paymentstatus,
    paymentmethod
)
FROM '/home/project/digihealth_export/billing.tsv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER E'\t',
    QUOTE E'\b'
);

SELECT 'patient' AS table_name, COUNT(*) AS rows
FROM digihealth_stg.patient

UNION ALL

SELECT 'doctor', COUNT(*)
FROM digihealth_stg.doctor

UNION ALL

SELECT 'specialization', COUNT(*)
FROM digihealth_stg.specialization

UNION ALL

SELECT 'appointment', COUNT(*)
FROM digihealth_stg.appointment

UNION ALL

SELECT 'appointmentdoctor', COUNT(*)
FROM digihealth_stg.appointmentdoctor

UNION ALL

SELECT 'doctorspecialization', COUNT(*)
FROM digihealth_stg.doctorspecialization

UNION ALL

SELECT 'clinicalentry', COUNT(*)
FROM digihealth_stg.clinicalentry

UNION ALL

SELECT 'diagnosis', COUNT(*)
FROM digihealth_stg.diagnosis

UNION ALL

SELECT 'billing', COUNT(*)
FROM digihealth_stg.billing

ORDER BY table_name;
