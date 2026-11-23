-- ============================================================
-- DIGIHEALTH SAMPLE DATA
-- Demonstrates the normalized OLTP relationships
-- ============================================================

USE DigiHealth_DB;


-- ============================================================
-- 1. PATIENTS
-- ============================================================

INSERT INTO Patient
    (FirstName, LastName, DateOfBirth, Phone, Email, Address)
VALUES
    ('Thabo', 'Mokoena', '1985-04-12',
     '0825550101', 'thabo.mokoena@example.com',
     '14 Sandton Drive, Johannesburg'),

    ('Naledi', 'Khumsane', '1992-09-23',
     '0835550102', 'naledi.khumsane@example.com',
     '72 Rivonia Road, Johannesburg'),

    ('Sipho', 'Dlamini', '1978-01-15',
     '0845550103', 'sipho.dlamini@example.com',
     '20 Oxford Road, Johannesburg'),

    ('Lerato', 'Molefe', '2001-06-30',
     '0725550104', 'lerato.molefe@example.com',
     '45 Main Road, Pretoria'),

    ('Ayanda', 'Nkomo', '1997-11-08',
     '0715550105', 'ayanda.nkomo@example.com',
     '18 Republic Road, Johannesburg');


-- ============================================================
-- 2. DOCTORS
-- ============================================================

INSERT INTO Doctor
    (FirstName, LastName, Phone, Email)
VALUES
    ('Karabo', 'Nkosi',
     '0115551001', 'karabo.nkosi@digihealth.example'),

    ('Amina', 'Patel',
     '0115551002', 'amina.patel@digihealth.example'),

    ('David', 'Naidoo',
     '0115551003', 'david.naidoo@digihealth.example'),

    ('Zanele', 'Mthembu',
     '0115551004', 'zanele.mthembu@digihealth.example');


-- ============================================================
-- 3. SPECIALIZATIONS
-- ============================================================

INSERT INTO Specialization
    (SpecializationName)
VALUES
    ('Cardiology'),
    ('Internal Medicine'),
    ('Neurology'),
    ('General Medicine'),
    ('Endocrinology');


-- ============================================================
-- 4. DOCTOR SPECIALIZATIONS
--
-- Demonstrates M:M:
-- one doctor can have multiple specializations
-- one specialization can have multiple doctors
-- ============================================================

INSERT INTO DoctorSpecialization
    (DoctorID, SpecializationID)
VALUES

    -- Dr Nkosi:
    -- Cardiology + Internal Medicine
    (1, 1),
    (1, 2),

    -- Dr Patel:
    -- General Medicine + Internal Medicine
    (2, 4),
    (2, 2),

    -- Dr Naidoo:
    -- Neurology
    (3, 3),

    -- Dr Mthembu:
    -- Endocrinology + Internal Medicine
    (4, 5),
    (4, 2);


-- ============================================================
-- 5. APPOINTMENTS
--
-- Patient 1:M Appointment
-- ============================================================

INSERT INTO Appointment
    (
        PatientID,
        AppointmentDateTime,
        AppointmentStatus,
        ReasonForVisit
    )
VALUES
    (1, '2026-09-10 09:00:00',
     'Completed',
     'Chest discomfort and elevated blood pressure'),

    (1, '2026-10-14 10:30:00',
     'Completed',
     'Blood pressure follow-up'),

    (2, '2026-10-20 14:00:00',
     'Completed',
     'Persistent headaches'),

    (3, '2026-11-05 11:00:00',
     'Completed',
     'Diabetes management review'),

    (4, '2026-11-25 09:30:00',
     'Scheduled',
     'Annual general health assessment'),

    (5, '2026-11-28 13:00:00',
     'Scheduled',
     'Fatigue and general consultation');


-- ============================================================
-- 6. APPOINTMENT <-> DOCTOR
--
-- Demonstrates M:M relationship.
--
-- Appointment 1 has TWO doctors.
-- Doctor 1 participates in multiple appointments.
-- ============================================================

INSERT INTO AppointmentDoctor
    (AppointmentID, DoctorID)
VALUES
    (1, 1),
    (1, 2),

    (2, 1),

    (3, 2),
    (3, 3),

    (4, 2),
    (4, 4),

    (5, 2),

    (6, 2);


-- ============================================================
-- 7. MEDICAL RECORDS
--
-- Patient 1:0..1 MedicalRecord
--
-- Patients 1-4 have established clinical histories.
-- Patient 5 currently demonstrates the optional "0" case.
-- ============================================================

INSERT INTO MedicalRecord
    (PatientID)
VALUES
    (1),
    (2),
    (3),
    (4);


-- ============================================================
-- 8. CLINICAL ENTRIES
--
-- ClinicalEntry links directly to Appointment.
-- Patient and MedicalRecord are derivable through Appointment.
-- ============================================================

INSERT INTO ClinicalEntry
    (
        AppointmentID,
        EntryDateTime,
        Notes
    )
VALUES
    (1,
     '2026-09-10 09:40:00',
     'Cardiovascular assessment completed following presentation with chest discomfort.'),

    (2,
     '2026-10-14 10:55:00',
     'Follow-up consultation completed. Blood pressure response reviewed.'),

    (3,
     '2026-10-20 14:45:00',
     'Neurological review completed following recurring headaches.'),

    (4,
     '2026-11-05 11:35:00',
     'Diabetes management reviewed and treatment plan discussed.');


-- ============================================================
-- 9. DIAGNOSES
--
-- ClinicalEntry 1 deliberately has TWO diagnoses.
-- This demonstrates why diagnoses are separate rows rather
-- than comma-separated values inside ClinicalEntry.
-- ============================================================

INSERT INTO Diagnosis
    (ClinicalEntryID, DiagnosisDescription)
VALUES
    (1, 'Hypertension'),
    (1, 'Elevated cholesterol'),

    (2, 'Essential hypertension'),

    (3, 'Migraine'),

    (4, 'Type 2 diabetes mellitus');


-- ============================================================
-- 10. TREATMENTS
-- ============================================================

INSERT INTO Treatment
    (ClinicalEntryID, TreatmentDescription)
VALUES
    (1, 'Blood pressure management and cardiovascular risk counselling'),

    (1, 'Dietary and lifestyle modification'),

    (2, 'Continue blood pressure management plan'),

    (3, 'Migraine management and trigger monitoring'),

    (4, 'Diabetes management and lifestyle counselling');


-- ============================================================
-- 11. PRESCRIPTIONS
--
-- ClinicalEntry 1 receives multiple prescriptions,
-- further demonstrating the 1:M structure.
-- ============================================================

INSERT INTO Prescription
    (
        ClinicalEntryID,
        MedicationName,
        Dosage,
        Frequency
    )
VALUES
    (1, 'Amlodipine', '5 mg', 'Once daily'),
    (1, 'Atorvastatin', '20 mg', 'Once daily'),
    (2, 'Amlodipine', '5 mg', 'Once daily'),
    (3, 'Sumatriptan', '50 mg', 'As required for migraine'),
    (4, 'Metformin', '500 mg', 'Twice daily');


-- ============================================================
-- 12. BILLING
--
-- Only COMPLETED appointments receive billing records.
--
-- Scheduled Appointments 5 and 6 intentionally have
-- no Billing rows, demonstrating Appointment 1:0..1 Billing.
-- ============================================================

INSERT INTO Billing
    (
        AppointmentID,
        BillingDate,
        Amount,
        PaymentStatus,
        PaymentMethod
    )
VALUES
    (1, '2026-09-10', 1450.00, 'Paid', 'Card'),
    (2, '2026-10-14', 850.00, 'Paid', 'Medical Aid'),
    (3, '2026-10-20', 1650.00, 'Pending', 'Medical Aid'),
    (4, '2026-11-05', 1200.00, 'Paid', 'Card');

-- ============================================================
-- 13. CANCELLED APPOINTMENTS
--
-- Cancelled appointments remain in Appointment for history.
-- They have doctor assignments but no:
--   ClinicalEntry
--   Diagnosis
--   Treatment
--   Prescription
--   Billing
-- ============================================================

INSERT INTO Appointment
    (
        PatientID,
        AppointmentDateTime,
        AppointmentStatus,
        ReasonForVisit
    )
VALUES
    (2, '2026-11-12 15:00:00',
     'Cancelled',
     'Follow-up consultation for recurring headaches'),

    (3, '2026-11-18 10:00:00',
     'Cancelled',
     'Diabetes monitoring and medication review');

INSERT INTO Appointment (
    PatientID,
    AppointmentDateTime,
    AppointmentStatus,
    ReasonForVisit
)
VALUES (
    1,
    '2026-12-10 10:00:00',
    'InvalidStatus',
    'Constraint test'
);

-- Assign doctors to the appointments.
-- Assuming the previous inserts generated AppointmentIDs 1-6,
-- these two appointments will be IDs 7 and 8.

INSERT INTO AppointmentDoctor
    (AppointmentID, DoctorID)
VALUES
    (7, 3),
    (8, 4);
