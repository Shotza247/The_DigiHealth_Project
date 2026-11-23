-- ============================================================
-- DigiHealth OLTP Database (MySQL)
-- Part 2 - Task 1
-- Normalized relational schema, sample data, and validation
-- ============================================================

CREATE DATABASE IF NOT EXISTS DigiHealth_DB;
USE DigiHealth_DB;

-- ============================================================
-- Create Identified Entities (Tables) with constraints and relationships

CREATE TABLE Patient (
    PatientID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Phone VARCHAR(20),
    Email VARCHAR(255),
    Address VARCHAR(255)
);

CREATE TABLE Doctor (
    DoctorID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Phone VARCHAR(20),
    Email VARCHAR(255)
);

CREATE TABLE Specialization (
    SpecializationID INT AUTO_INCREMENT PRIMARY KEY,
    SpecializationName VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Appointment (
    AppointmentID INT AUTO_INCREMENT PRIMARY KEY,
    PatientID INT NOT NULL,
    AppointmentDateTime DATETIME NOT NULL,
    AppointmentStatus VARCHAR(30) NOT NULL,
    ReasonForVisit VARCHAR(255),
    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    CONSTRAINT chk_appointment_status
        CHECK (AppointmentStatus IN ('Scheduled','Completed','Cancelled'))
);

CREATE TABLE MedicalRecord (
    MedicalRecordID INT AUTO_INCREMENT PRIMARY KEY,
    PatientID INT NOT NULL UNIQUE,
    CONSTRAINT fk_medicalrecord_patient
        FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

CREATE TABLE AppointmentDoctor (
    AppointmentID INT NOT NULL,
    DoctorID INT NOT NULL,
    PRIMARY KEY (AppointmentID, DoctorID),
    CONSTRAINT fk_appointmentdoctor_appointment
        FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID),
    CONSTRAINT fk_appointmentdoctor_doctor
        FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID)
);

CREATE TABLE DoctorSpecialization (
    DoctorID INT NOT NULL,
    SpecializationID INT NOT NULL,
    PRIMARY KEY (DoctorID, SpecializationID),
    CONSTRAINT fk_doctorspecialization_doctor
        FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID),
    CONSTRAINT fk_doctorspecialization_specialization
        FOREIGN KEY (SpecializationID) REFERENCES Specialization(SpecializationID)
);

CREATE TABLE ClinicalEntry (
    ClinicalEntryID INT AUTO_INCREMENT PRIMARY KEY,
    AppointmentID INT NOT NULL,
    EntryDateTime DATETIME NOT NULL,
    Notes TEXT,
    CONSTRAINT fk_clinicalentry_appointment
        FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID)
);

CREATE TABLE Diagnosis (
    DiagnosisID INT AUTO_INCREMENT PRIMARY KEY,
    ClinicalEntryID INT NOT NULL,
    DiagnosisDescription VARCHAR(255) NOT NULL,
    CONSTRAINT fk_diagnosis_clinicalentry
        FOREIGN KEY (ClinicalEntryID) REFERENCES ClinicalEntry(ClinicalEntryID)
);

CREATE TABLE Treatment (
    TreatmentID INT AUTO_INCREMENT PRIMARY KEY,
    ClinicalEntryID INT NOT NULL,
    TreatmentDescription VARCHAR(255) NOT NULL,
    CONSTRAINT fk_treatment_clinicalentry
        FOREIGN KEY (ClinicalEntryID) REFERENCES ClinicalEntry(ClinicalEntryID)
);

CREATE TABLE Prescription (
    PrescriptionID INT AUTO_INCREMENT PRIMARY KEY,
    ClinicalEntryID INT NOT NULL,
    MedicationName VARCHAR(150) NOT NULL,
    Dosage VARCHAR(100),
    Frequency VARCHAR(100),
    CONSTRAINT fk_prescription_clinicalentry
        FOREIGN KEY (ClinicalEntryID) REFERENCES ClinicalEntry(ClinicalEntryID)
);

CREATE TABLE Billing (
    BillingID INT AUTO_INCREMENT PRIMARY KEY,
    AppointmentID INT NOT NULL UNIQUE,
    BillingDate DATE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentStatus VARCHAR(30) NOT NULL,
    PaymentMethod VARCHAR(50),
    CONSTRAINT fk_billing_appointment
        FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID),
    CONSTRAINT chk_billing_amount CHECK (Amount >= 0)
);

-- ============================================================
-- realistic sample data for testing and validation

INSERT INTO Patient (FirstName, LastName, DateOfBirth, Phone, Email, Address) VALUES
('Thabo','Mokoena','1985-04-12','0825550101','thabo.mokoena@example.com','14 Sandton Drive, Johannesburg'),
('Naledi','Khumsane','1992-09-23','0835550102','naledi.khumsane@example.com','72 Rivonia Road, Johannesburg'),
('Sipho','Dlamini','1978-01-15','0845550103','sipho.dlamini@example.com','20 Oxford Road, Johannesburg'),
('Lerato','Molefe','2001-06-30','0725550104','lerato.molefe@example.com','45 Main Road, Pretoria'),
('Ayanda','Nkomo','1997-11-08','0715550105','ayanda.nkomo@example.com','18 Republic Road, Johannesburg');

INSERT INTO Doctor (FirstName, LastName, Phone, Email) VALUES
('Karabo','Nkosi','0115551001','karabo.nkosi@digihealth.example'),
('Amina','Patel','0115551002','amina.patel@digihealth.example'),
('David','Naidoo','0115551003','david.naidoo@digihealth.example'),
('Zanele','Mthembu','0115551004','zanele.mthembu@digihealth.example');

INSERT INTO Specialization (SpecializationName) VALUES
('Cardiology'),('Internal Medicine'),('Neurology'),('General Medicine'),('Endocrinology');

INSERT INTO DoctorSpecialization (DoctorID, SpecializationID) VALUES
(1,1),(1,2),(2,4),(2,2),(3,3),(4,5),(4,2);

INSERT INTO Appointment (PatientID, AppointmentDateTime, AppointmentStatus, ReasonForVisit) VALUES
(1,'2026-09-10 09:00:00','Completed','Chest discomfort and elevated blood pressure'),
(1,'2026-10-14 10:30:00','Completed','Blood pressure follow-up'),
(2,'2026-10-20 14:00:00','Completed','Persistent headaches'),
(3,'2026-11-05 11:00:00','Completed','Diabetes management review'),
(4,'2026-11-25 09:30:00','Scheduled','Annual general health assessment'),
(5,'2026-11-28 13:00:00','Scheduled','Fatigue and general consultation'),
(2,'2026-11-12 15:00:00','Cancelled','Follow-up consultation for recurring headaches'),
(3,'2026-11-18 10:00:00','Cancelled','Diabetes monitoring and medication review');

INSERT INTO AppointmentDoctor (AppointmentID, DoctorID) VALUES
(1,1),(1,2),(2,1),(3,2),(3,3),(4,2),(4,4),(5,2),(6,2),(7,3),(8,4);

INSERT INTO MedicalRecord (PatientID) VALUES (1),(2),(3),(4);

INSERT INTO ClinicalEntry (AppointmentID, EntryDateTime, Notes) VALUES
(1,'2026-09-10 09:40:00','Cardiovascular assessment completed following presentation with chest discomfort.'),
(2,'2026-10-14 10:55:00','Follow-up consultation completed. Blood pressure response reviewed.'),
(3,'2026-10-20 14:45:00','Neurological review completed following recurring headaches.'),
(4,'2026-11-05 11:35:00','Diabetes management reviewed and treatment plan discussed.');

INSERT INTO Diagnosis (ClinicalEntryID, DiagnosisDescription) VALUES
(1,'Hypertension'),(1,'Elevated cholesterol'),(2,'Essential hypertension'),(3,'Migraine'),(4,'Type 2 diabetes mellitus');

INSERT INTO Treatment (ClinicalEntryID, TreatmentDescription) VALUES
(1,'Blood pressure management and cardiovascular risk counselling'),
(1,'Dietary and lifestyle modification'),
(2,'Continue blood pressure management plan'),
(3,'Migraine management and trigger monitoring'),
(4,'Diabetes management and lifestyle counselling');

INSERT INTO Prescription (ClinicalEntryID, MedicationName, Dosage, Frequency) VALUES
(1,'Amlodipine','5 mg','Once daily'),
(1,'Atorvastatin','20 mg','Once daily'),
(2,'Amlodipine','5 mg','Once daily'),
(3,'Sumatriptan','50 mg','As required for migraine'),
(4,'Metformin','500 mg','Twice daily');

INSERT INTO Billing (AppointmentID, BillingDate, Amount, PaymentStatus, PaymentMethod) VALUES
(1,'2026-09-10',1450.00,'Paid','Card'),
(2,'2026-10-14',850.00,'Paid','Medical Aid'),
(3,'2026-10-20',1650.00,'Pending','Medical Aid'),
(4,'2026-11-05',1200.00,'Paid','Card');

-- ============================================================
-- structure and relationship validation

SHOW TABLES;

SELECT COUNT(*) AS TotalTables
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DigiHealth_DB'
  AND TABLE_TYPE = 'BASE TABLE';

SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'DigiHealth_DB'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;

SHOW INDEX FROM AppointmentDoctor;
SHOW INDEX FROM DoctorSpecialization;
SHOW INDEX FROM MedicalRecord;
SHOW INDEX FROM Billing;
SHOW CREATE TABLE Appointment;

-- ============================================================
-- Data validation queries

-- Patient -> Appointment
SELECT p.PatientID, p.FirstName, p.LastName,
       a.AppointmentID, a.AppointmentDateTime, a.AppointmentStatus
FROM Patient p
LEFT JOIN Appointment a ON p.PatientID = a.PatientID
ORDER BY p.PatientID, a.AppointmentDateTime;

-- Appointment <-> Doctor M:M (we instroduced an associative entity here)
SELECT a.AppointmentID, a.AppointmentDateTime,
       CONCAT(p.FirstName,' ',p.LastName) AS Patient,
       CONCAT(d.FirstName,' ',d.LastName) AS Doctor
FROM Appointment a
JOIN Patient p ON a.PatientID = p.PatientID
JOIN AppointmentDoctor ad ON a.AppointmentID = ad.AppointmentID
JOIN Doctor d ON ad.DoctorID = d.DoctorID
ORDER BY a.AppointmentID, d.DoctorID;

-- Doctor <-> Specialization M:M (we instroduced an associative entity here)
SELECT d.DoctorID,
       CONCAT(d.FirstName,' ',d.LastName) AS Doctor,
       s.SpecializationName
FROM Doctor d
JOIN DoctorSpecialization ds ON d.DoctorID = ds.DoctorID
JOIN Specialization s ON ds.SpecializationID = s.SpecializationID
ORDER BY d.DoctorID, s.SpecializationName;

-- Clinical history path
SELECT p.PatientID,
       CONCAT(p.FirstName,' ',p.LastName) AS Patient,
       a.AppointmentID, a.AppointmentDateTime,
       ce.ClinicalEntryID, ce.EntryDateTime,
       d.DiagnosisDescription
FROM Patient p
JOIN Appointment a ON p.PatientID = a.PatientID
JOIN ClinicalEntry ce ON a.AppointmentID = ce.AppointmentID
LEFT JOIN Diagnosis d ON ce.ClinicalEntryID = d.ClinicalEntryID
ORDER BY p.PatientID, a.AppointmentDateTime, d.DiagnosisID;

-- Billing -> Appointment -> Patient; no Billing.PatientID needed
SELECT b.BillingID, b.AppointmentID, p.PatientID,
       CONCAT(p.FirstName,' ',p.LastName) AS Patient,
       b.BillingDate, b.Amount, b.PaymentStatus, b.PaymentMethod
FROM Billing b
JOIN Appointment a ON b.AppointmentID = a.AppointmentID
JOIN Patient p ON a.PatientID = p.PatientID
ORDER BY b.BillingID;

-- Scheduled/cancelled appointments without billing
SELECT a.AppointmentID, a.AppointmentDateTime,
       a.AppointmentStatus,
       CONCAT(p.FirstName,' ',p.LastName) AS Patient
FROM Appointment a
JOIN Patient p ON a.PatientID = p.PatientID
LEFT JOIN Billing b ON a.AppointmentID = b.AppointmentID
WHERE b.BillingID IS NULL
ORDER BY a.AppointmentID;

-- Cancelled appointments should have neither clinical entries nor bills
SELECT a.AppointmentID, a.AppointmentStatus,
       ce.ClinicalEntryID, b.BillingID
FROM Appointment a
LEFT JOIN ClinicalEntry ce ON a.AppointmentID = ce.AppointmentID
LEFT JOIN Billing b ON a.AppointmentID = b.AppointmentID
WHERE a.AppointmentStatus = 'Cancelled';

-- Patients without a MedicalRecord demonstrate Patient 1:0..1 MedicalRecord
SELECT p.PatientID, p.FirstName, p.LastName
FROM Patient p
LEFT JOIN MedicalRecord mr ON p.PatientID = mr.PatientID
WHERE mr.MedicalRecordID IS NULL;

-- Counts proving M:M behavior
SELECT a.AppointmentID, COUNT(ad.DoctorID) AS NumberOfDoctors
FROM Appointment a
LEFT JOIN AppointmentDoctor ad ON a.AppointmentID = ad.AppointmentID
GROUP BY a.AppointmentID
ORDER BY a.AppointmentID;

SELECT d.DoctorID,
       CONCAT(d.FirstName,' ',d.LastName) AS Doctor,
       COUNT(ds.SpecializationID) AS NumberOfSpecializations
FROM Doctor d
LEFT JOIN DoctorSpecialization ds ON d.DoctorID = ds.DoctorID
GROUP BY d.DoctorID, d.FirstName, d.LastName
ORDER BY d.DoctorID;
