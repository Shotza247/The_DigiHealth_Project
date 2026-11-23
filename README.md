# 🏥 DigiHealth Enterprise Data Architecture

> **An end-to-end healthcare data architecture project covering conceptual modeling, 3NF normalization, MySQL OLTP implementation, ETL, PostgreSQL dimensional modeling, and OLAP validation.**

---

## 📌 Project Overview

**DigiHealth** demonstrates how healthcare business requirements can be progressively transformed into a normalized operational database and ultimately into an analytics-ready dimensional warehouse.

The project follows the complete data architecture lifecycle:

```text
Business Requirements
        ↓
Conceptual Model
        ↓
Logical Model
        ↓
Dependency Analysis
        ↓
1NF → 2NF → 3NF
        ↓
MySQL OLTP
        ↓
Extract & Stage
        ↓
Transform & Load
        ↓
PostgreSQL OLAP
        ↓
Validation
        ↓
Analytics-Ready Data
```

Rather than starting with SQL, the project begins by understanding the healthcare business process, identifying entities and relationships, defining cardinalities, resolving many-to-many relationships, and normalizing the data model.

The normalized model is then implemented as a **MySQL OLTP database** before being transformed into a **PostgreSQL dimensional warehouse**.

---

# 🧭 Architecture Journey

## 1. Conceptual Data Model

The project started with five core healthcare concepts:

- **Patient**
- **Appointment**
- **Doctor**
- **Medical Record**
- **Billing**

The initial healthcare workflow established:

```text
Patient
   ↓
Appointment
   ↓
Doctor(s)
   ↓
Clinical Activity
   ↓
Billing
```

One of the most important early design decisions was identifying:

> **Appointment as the central healthcare business event.**

This allowed patient, doctor, clinical, and billing activities to be modeled around a specific healthcare encounter.

---

# 2. Logical Data Model

The conceptual relationships were translated into explicit cardinalities.

## Patient → Appointment

```text
Patient 1 : M Appointment
```

A patient can have multiple appointments.

Each appointment belongs to one patient.

---

## Appointment ↔ Doctor

A single appointment can involve multiple doctors.

A doctor can also participate in multiple appointments.

Therefore:

```text
Appointment M : M Doctor
```

This relationship was resolved using an associative entity:

```text
AppointmentDoctor
```

Resulting in:

```text
Appointment
     1
     |
     M
AppointmentDoctor
     M
     |
     1
   Doctor
```

---

## Patient → MedicalRecord

The relationship was refined to:

```text
Patient 1 : 0..1 MedicalRecord
```

A newly registered patient may initially have no medical record.

Once clinical history exists, the patient can have one longitudinal medical record.

---

## Appointment → Billing

```text
Appointment 1 : 0..1 Billing
```

An appointment may exist before billing occurs.

Scheduled and cancelled appointments may therefore have no billing record.

---

# 🔄 3. First Normal Form — 1NF

The first major normalization challenge involved the patient's clinical history.

A single medical record can accumulate:

- multiple diagnoses
- multiple treatments
- multiple prescriptions
- multiple clinical events

Storing these values directly inside one `MedicalRecord` row would create repeating groups.

The model therefore evolved into:

```text
Patient
   ↓
MedicalRecord
   ↓
ClinicalEntry
```

A `ClinicalEntry` represents an individual clinical event.

Because a clinical event can contain multiple diagnoses, treatments, and prescriptions, these were further decomposed into:

```text
ClinicalEntry
     |
     ├── Diagnosis
     |
     ├── Treatment
     |
     └── Prescription
```

Each clinical fact is therefore stored as an individual atomic row.

---

# 🩺 4. Doctor Specializations

Doctors can hold multiple medical specializations.

Instead of storing:

```text
Specialization = "Cardiology, Internal Medicine"
```

which would violate 1NF, the model introduces:

```text
Specialization
DoctorSpecialization
```

creating:

```text
Doctor M : M Specialization
```

resolved through:

```text
DoctorSpecialization
```

---

# 🔑 5. Second Normal Form — 2NF

The 2NF audit focused particularly on associative entities with **composite primary keys**.

### AppointmentDoctor

```text
PK (AppointmentID, DoctorID)
```

### DoctorSpecialization

```text
PK (DoctorID, SpecializationID)
```

The model ensures that attributes belonging to an appointment remain in `Appointment`, attributes describing doctors remain in `Doctor`, and specialization attributes remain in `Specialization`.

This prevents partial dependencies on only part of a composite primary key.

✅ **No additional decomposition was required during the final 2NF audit.**

---

# 🧩 6. Third Normal Form — 3NF

The 3NF audit focused on eliminating transitive and redundant dependencies.

One important example was **Billing**.

It would have been possible to design:

```text
Billing
----------------
BillingID
AppointmentID
PatientID
```

However:

```text
BillingID
    ↓
AppointmentID
    ↓
PatientID
```

The patient is already determined through the appointment.

Storing `PatientID` again inside `Billing` would therefore duplicate the relationship.

The final design uses:

```text
Billing
----------------
BillingID
AppointmentID
BillingDate
Amount
PaymentStatus
PaymentMethod
```

The patient is derived through:

```text
Billing → Appointment → Patient
```

---

## ClinicalEntry Dependency Decision

The same principle was applied to `ClinicalEntry`.

Instead of storing both:

```text
AppointmentID
MedicalRecordID
```

the final relationship follows:

```text
ClinicalEntry
      ↓
Appointment
      ↓
Patient
      ↓
MedicalRecord
```

This eliminates redundant dependency paths.

---

# ✅ Final 3NF OLTP Model

The normalized operational model contains **12 entities**:

1. `Patient`
2. `Appointment`
3. `Doctor`
4. `AppointmentDoctor`
5. `Specialization`
6. `DoctorSpecialization`
7. `MedicalRecord`
8. `ClinicalEntry`
9. `Diagnosis`
10. `Treatment`
11. `Prescription`
12. `Billing`

### Final Relationship Structure

```text
PATIENT
   |
   | 1:M
   ↓
APPOINTMENT
   |
   ├──────── M:M ──────── DOCTOR
   |             via AppointmentDoctor
   |
   ├──────── 1:0..M ───── CLINICAL_ENTRY
   |                         |
   |                         ├── Diagnosis
   |                         ├── Treatment
   |                         └── Prescription
   |
   └──────── 1:0..1 ───── BILLING


PATIENT
   |
   └──────── 1:0..1 ───── MEDICAL_RECORD


DOCTOR
   |
   └──────── M:M ──────── SPECIALIZATION
             via DoctorSpecialization
```

---

# 🗄️ 7. MySQL OLTP Implementation

The normalized logical model was implemented as a physical **MySQL OLTP database**.

The physical implementation includes:

- Primary Keys
- Foreign Keys
- Composite Keys
- `UNIQUE` constraints
- `CHECK` constraints
- Realistic healthcare sample data
- Relationship validation queries

---

## Appointment Lifecycle

Three appointment states were implemented:

```text
Scheduled
Completed
Cancelled
```

using:

```sql
CHECK (
    AppointmentStatus IN (
        'Scheduled',
        'Completed',
        'Cancelled'
    )
)
```

The sample workload intentionally includes all three states.

Cancelled appointments remain available for operational history but do not generate clinical or billing activity.

---

# 🧪 8. OLTP Validation

The sample operational dataset includes:

| Object | Records |
|---|---:|
| Patients | 5 |
| Doctors | 4 |
| Specializations | 5 |
| Appointments | 8 |
| Appointment–Doctor relationships | 11 |
| Doctor–Specialization relationships | 7 |
| Clinical Entries | 4 |
| Diagnoses | 5 |
| Billing Records | 4 |

### Appointment Distribution

```text
Completed    4
Scheduled    2
Cancelled    2
```

### Total Sample Billing

```text
R5,150.00
```

The MySQL implementation was successfully executed and validated before beginning the analytical warehouse.

---

# 📊 9. From OLTP to OLAP

The analytical phase changes the modeling objective.

The OLTP database answers questions such as:

> What happened during a specific appointment?

The OLAP warehouse needs to answer questions such as:

> How many appointments occurred each month?

> Which doctors participate in the most appointments?

> Which diagnoses occur most frequently?

> How much billing is associated with completed appointments?

This required moving from normalized relational modeling to **dimensional modeling**.

---

# 🎯 10. Final OLAP Grain

The most important warehouse decision was defining the fact grain.

> **One row in `FactAppointment` represents one appointment event.**

The grain remains unchanged regardless of:

- the number of doctors participating;
- the number of doctor specializations;
- the number of diagnoses associated with the appointment.

This prevents analytical measures from being physically duplicated.

---

# ⭐ 11. FactAppointment

The central fact table contains:

```text
FactAppointment
---------------------------
AppointmentFactKey
AppointmentID
PatientKey
DateKey
StatusKey

AppointmentCount
BillingAmount
```

### AppointmentCount

Every appointment contributes:

```text
AppointmentCount = 1
```

### BillingAmount

Billing is stored once at the appointment grain.

```text
Completed + billed → actual amount

Scheduled → NULL

Cancelled → NULL
```

This distinguishes:

> no billing record exists

from:

> an actual zero-value financial transaction.

---

# 📐 12. OLAP Dimensions

The analytical warehouse contains six dimensions.

## DimPatient

Supports patient-related analysis.

---

## DimDate

Supports time-based analysis using:

- Day
- Month
- Month Name
- Quarter
- Year

The warehouse date key uses:

```text
YYYYMMDD
```

For example:

```text
20260910
```

represents:

```text
10 September 2026
```

---

## DimAppointmentStatus

Contains the controlled states:

```text
Scheduled
Completed
Cancelled
```

---

## DimDoctor

Supports doctor-level analytical slicing.

---

## DimSpecialization

Supports analysis by medical specialization.

---

## DimDiagnosis

Represents reusable diagnosis concepts rather than individual transactional diagnosis occurrences.

---

# 🌉 13. OLAP Bridge Tables

The appointment grain introduced an important analytical challenge.

Suppose:

```text
Appointment A001

BillingAmount = R1,450

Doctors:
D001
D002
```

Flattening this relationship would create:

```text
A001 | D001 | 1450
A001 | D002 | 1450
```

Running:

```sql
SUM(BillingAmount)
```

could incorrectly return:

```text
R2,900
```

instead of:

```text
R1,450
```

The warehouse therefore uses bridge tables.

### Appointment ↔ Doctor

```text
BridgeAppointmentDoctor
```

### Doctor ↔ Specialization

```text
BridgeDoctorSpecialization
```

### Appointment ↔ Diagnosis

```text
BridgeAppointmentDiagnosis
```

The bridges preserve the one-appointment fact grain while retaining many-to-many analytical relationships.

---

# 🏗️ 14. Final Dimensional Architecture

```text
                     DIM_DATE
                        |
                        |
DIM_PATIENT ------ FACT_APPOINTMENT ------ DIM_STATUS
                        |
               +--------+--------+
               |                 |
               |                 |
 BRIDGE_APPOINTMENT       BRIDGE_APPOINTMENT
      _DOCTOR                  _DIAGNOSIS
               |                 |
               |                 |
          DIM_DOCTOR        DIM_DIAGNOSIS
               |
               |
      BRIDGE_DOCTOR
      _SPECIALIZATION
               |
               |
      DIM_SPECIALIZATION
```

---

# 🔄 15. ETL Architecture

The completed data pipeline follows:

```text
MySQL
DigiHealth_DB
      ↓
TSV Extraction
      ↓
PostgreSQL Staging
digihealth_stg
      ↓
Dimension Transformation
      ↓
FactAppointment
      ↓
Bridge Transformation
      ↓
PostgreSQL Warehouse
digihealth_dw
      ↓
Validation
      ↓
Analytics
```

TSV extraction was used during the migration because fields such as patient addresses and clinical notes may contain commas.

This avoided delimiter issues encountered with a simple CSV export approach.

---

# 📥 16. ETL Load Order

Warehouse objects were loaded in dependency order.

## Phase 1 — Dimensions

```text
DimDate
DimPatient
DimAppointmentStatus
DimDoctor
DimSpecialization
DimDiagnosis
```

## Phase 2 — Fact

```text
FactAppointment
```

## Phase 3 — Bridges

```text
BridgeAppointmentDoctor
BridgeDoctorSpecialization
BridgeAppointmentDiagnosis
```

Bridge tables are loaded after fact and dimension records because they depend on warehouse-generated surrogate keys.

---

# ✅ 17. PostgreSQL Warehouse Validation

The completed warehouse was validated across the full ETL pipeline.

### Warehouse Counts

```text
Fact Appointments              8
Appointment-Doctor Links      11
Doctor-Specialization Links    7
Appointment-Diagnosis Links    5
```

### Financial Reconciliation

```text
MySQL / Staging       R5,150.00

PostgreSQL Warehouse  R5,150.00

Difference                R0.00
```

Additional validation checks confirmed:

- zero duplicate appointment facts;
- zero missing source appointments;
- zero orphan bridge relationships;
- scheduled appointments were not billed;
- cancelled appointments were not billed;
- foreign-key relationships resolved correctly.

---

# ⚠️ 18. Analytical Measure Safety

One important lesson from the project was that:

> **Correct physical modeling does not automatically guarantee correct analytical aggregation.**

For example:

```sql
SELECT SUM(f.billing_amount)
FROM fact_appointment f
JOIN bridge_appointment_doctor b
    ON f.appointment_fact_key =
       b.appointment_fact_key;
```

can duplicate billing measures when appointments contain multiple doctors.

For overall billing:

```sql
SELECT SUM(billing_amount)
FROM fact_appointment;
```

should be used.

Provider-level financial analysis requires an explicit allocation rule.

One possible approach is to distribute an appointment amount equally across participating doctors.

---

# 🛠️ Technologies & Concepts

## Data Modeling

- Conceptual Data Modeling
- Logical Data Modeling
- Functional Dependency Analysis
- First Normal Form — 1NF
- Second Normal Form — 2NF
- Third Normal Form — 3NF
- Dimensional Modeling

## Databases

- **MySQL**
- **PostgreSQL**

## Data Engineering

- ETL
- TSV extraction
- PostgreSQL `\copy`
- Source-to-target mapping
- Surrogate keys
- Fact tables
- Dimension tables
- Bridge tables
- Data reconciliation

## Architecture

- OLTP
- OLAP
- Star-style dimensional modeling
- Enterprise data architecture
- Transactional vs analytical modeling

## Design & Modeling

- **diagrams.net / draw.io**

---

# 📁 Project Deliverables

```text
DigiHealth_Project/
│
├── Part 1_Task 1.pdf
│   └── Final normalized OLTP ERD
│
├── Part_2_Task1.sql
│   └── MySQL OLTP implementation
│
├── Part_2_Task2A.sql
│   └── PostgreSQL OLAP schema, ETL and validation
│
├── Part_2_Task 2B.docx
│   └── OLTP-to-OLAP architecture report
│
└── DigiHealth Architecture.drawio
    └── Conceptual-to-OLAP design evolution
```

---

# 💡 Key Engineering Decisions

The most important decisions made throughout the project included:

1. **Treating Appointment as the central healthcare business event.**

2. **Resolving Appointment ↔ Doctor using an associative entity.**

3. **Modeling Patient → MedicalRecord as 1:0..1 rather than mandatory 1:1.**

4. **Separating longitudinal clinical history into atomic clinical entities.**

5. **Supporting multiple doctor specializations through an M:M relationship.**

6. **Avoiding redundant `PatientID` storage in Billing.**

7. **Removing the redundant `MedicalRecordID` dependency from ClinicalEntry.**

8. **Freezing the OLAP grain at one appointment per fact row.**

9. **Using bridge tables for Doctor and Diagnosis multiplicity.**

10. **Storing BillingAmount only once at the appointment grain.**

11. **Validating OLTP → staging → OLAP using both row counts and financial reconciliation.**

---

# 🎓 Key Takeaways

This project reinforced one of the most important lessons in data architecture:

> **A good data model does not begin with tables. It begins with understanding the business process and what each relationship actually means.**

Normalization solved operational problems such as:

- repeating groups;
- data duplication;
- inconsistent relationships;
- partial dependencies;
- transitive dependencies.

Dimensional modeling then addressed a different question:

> **How should operational data be structured for reliable analytical queries?**

The transition from **3NF OLTP** to an **appointment-grain OLAP warehouse** became one of the most valuable parts of the project.

It demonstrated why transactional and analytical systems require different modeling strategies.

---

# 🚀 Future Enhancements

Potential extensions include:

- ICD-10 diagnosis codes
- Medication/Product dimensions
- Treatment dimensions
- Provider billing-allocation models
- Insurance and medical-aid dimensions
- Slowly Changing Dimensions
- Incremental ETL
- Change Data Capture
- Apache Airflow orchestration
- Automated data-quality testing
- Data observability
- Power BI dashboards
- Dedicated clinical and financial data marts

---

# 🏁 Final Outcome

DigiHealth demonstrates an end-to-end enterprise data architecture journey:

```text
Business Requirements
        ↓
Conceptual Modeling
        ↓
Logical Modeling
        ↓
Dependency Analysis
        ↓
1NF → 2NF → 3NF
        ↓
MySQL OLTP
        ↓
Extract & Stage
        ↓
Transform & Load
        ↓
PostgreSQL OLAP
        ↓
Validation & Reconciliation
        ↓
Analytics-Ready Data
```

The final solution combines a **normalized operational healthcare database** with a **validated dimensional analytical warehouse**, connected through a traceable ETL pipeline and supported by documented architecture decisions.

---

## Repository Tagline

> **From healthcare business requirements to 3NF MySQL OLTP and an appointment-grain PostgreSQL analytical warehouse.**

---

## Project Architecture

The full architecture and decision canvas was developed using **diagrams.net**, documenting the progression from conceptual entities and dependency analysis through normalization, physical OLTP implementation, and final OLAP grain design.

---

### Author

**Romeo Ndlovu**

*Data & AI Engineering | Data Architecture | Data Engineering*
