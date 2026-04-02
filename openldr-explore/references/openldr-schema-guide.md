# OpenLDR Schema Reference Guide

**Purpose**: Built-in knowledge base for the openldr-explore skill. Search this document first before falling back to live database queries.

---

## 1. Overview

### What is OpenLDR?

OpenLDR (Open Laboratory Data Repository) is a centralized electronic data storage system for country-wide laboratory requests and results. Its mission: **"Good Infrastructure = Better Data = Increase Demand for Data = Better Patient Outcomes."**

The system is designed to receive data from multiple Laboratory Information Systems (LIS), instruments, and mobile devices without requiring data standardization at the source. It supports HIV Viral Load (VL), HIV Early Infant Diagnosis (EID), TB GeneXpert, and Advanced Diseases (CD4, CrAg, TB-LAM).

### Core Design Principles

1. **Simplicity**: Three primary data tables + supporting tables. Minimalistic approach prioritizing usability.
2. **Report-Oriented**: Direct SQL-based reporting against single tables or views. Compatible with Crystal Reports, SSRS, Excel, GIS tools.
3. **Patient Privacy**: No patient identifiers in the core data tables. Only encrypted patient IDs. The separate `Patients` table stores identifiable data with controlled access.
4. **International Standards**: SI units, HL7 v2.5, LOINC identifiers, ICD-10 coding, Latin organism nomenclature.
5. **Multi-Level Scalability**: Works at facility, national, or regional level. Stores both standardized and vendor-specific codes.
6. **Flexible Data Structure**: Hybrid horizontal-vertical model. Fixed columns for common fields; supplementary data stored as rows in LabResults using `LIMSObservationCode` identifiers.

### Data Sovereignty

Each country maintains secure, controlled ownership of its OpenLDRData database while participating in a shared technology model. Countries can exchange import methodologies, visualization views, reporting templates, and best practices.

### The Two Databases

| Database | Bind Key | Purpose |
|----------|----------|---------|
| **OpenLDRData** | `vl`, `tb`, `dpi`, `ad` (varies by test type) | Operational data — all laboratory test requests and results |
| **OpenLDRDict** | `dict` | Reference/dictionary data — facilities, geographic hierarchy, HL7 codes, LOINC |

---

## 2. OpenLDRData — Table Architecture

The OpenLDRData database contains **6 base tables**, **15+ SQL views**, and **10+ user-defined functions**.

### Base Tables

| Table | HL7 Mapping | Purpose |
|-------|-------------|---------|
| **Requests** | OBR + PID + PV1 | Laboratory test requests/orders with demographics |
| **LabResults** | OBX | Individual test result observations |
| **Monitoring** | OBX | Microbiology organisms and drug susceptibility |
| **ASTResults** | OBX | Antimicrobial Susceptibility Testing results |
| **Patients** | PID | Patient identifying information (restricted access) |
| **VersionControl** | — | Database schema version tracking |

### Database Connection

| Property | Value |
|----------|-------|
| **Database Name** | `OpenLDRData` |
| **Engine** | Microsoft SQL Server |
| **ORM (Python)** | SQLAlchemy 2.0 via `mssql+pyodbc` (ODBC Driver 17) |
| **ORM (TypeScript)** | Sequelize 6.28 via `tedious` (legacy) |
| **Related Database** | `OpenLDRDict` (dictionary/reference data) |

---

## 3. OpenLDRData — Table Schemas

### 3.1 Requests Table

The Requests table is the core of OpenLDR's request-centric data model. It represents the **OBR (Observation Request)**, **PID (Patient Identity)**, and **PV1 (Patient Visit)** segments of an HL7 message. Demographics are stored at the time of request rather than in a separate patient index, preserving temporal context.

| Column | Data Type | Nullable | HL7 Segment | Description |
|--------|-----------|----------|-------------|-------------|
| **DateTimeStamp** | `datetime` | YES | — | OpenLDR record timestamp (when imported/updated) |
| **Versionstamp** | `varchar(30)` | YES | — | OpenLDR version tracking |
| **LIMSDateTimeStamp** | `datetime` | YES | — | Source LIMS record timestamp |
| **LIMSVersionstamp** | `varchar(30)` | YES | — | Source LIMS version tracking |
| **RequestID** | `varchar(26)` | YES | OBR | Unique specimen/request identifier |
| **OBRSetID** | `int` | YES | OBR-1 | Panel sequence number within request |
| **LOINCPanelCode** | `varchar(10)` | YES | OBR-4 | Standardized LOINC panel code |
| **LIMSPanelCode** | `varchar(10)` | YES | OBR-4 | Vendor-specific panel code (e.g., HIVVL, VIRAL, PCRGX) |
| **LIMSPanelDesc** | `varchar(50)` | YES | OBR-4 | Vendor-specific panel description |
| **HL7PriorityCode** | `char(1)` | YES | OBR-5 | Priority: S=Stat, R=Routine, A=ASAP |
| **SpecimenDateTime** | `datetime` | YES | OBR-7 | When specimen was collected |
| **LIMSPreReg_RegistrationDateTime** | `datetime` | YES | — | Pre-registration timestamp (hub/transport) |
| **LIMSPreReg_ReceivedDateTime** | `datetime` | YES | — | Pre-registration received timestamp |
| **LIMSPreReg_RegistrationFacilityCode** | `varchar(15)` | YES | — | Pre-registration facility (hub) |
| **RegisteredDateTime** | `datetime` | YES | OBR-6 | When registered in LIMS |
| **ReceivedDateTime** | `datetime` | YES | OBR-14 | When received at testing lab |
| **AnalysisDateTime** | `datetime` | YES | OBR-22 | When analysis was performed |
| **AuthorisedDateTime** | `datetime` | YES | OBR-22 | When result was authorized/released |
| **AdmitAttendDateTime** | `datetime` | YES | PV1-44 | Patient admit/attendance date |
| **CollectionVolume** | `float` | YES | OBR-9 | Specimen collection volume |
| **RequestingFacilityCode** | `varchar(15)` | YES | OBR-21 | Health facility that ordered the test |
| **ReceivingFacilityCode** | `varchar(10)` | YES | MSH-6 | Hub/transport facility that received specimen |
| **LIMSPointOfCareDesc** | `varchar(50)` | YES | PV1-3 | Point of care description (ward~location) |
| **RequestTypeCode** | `varchar(3)` | YES | OBR-29 | Request type classification |
| **ICD10ClinicalInfoCodes** | `varchar(50)` | YES | DG1-3 | ICD-10 diagnosis codes |
| **ClinicalInfo** | `varchar(250)` | YES | OBR-13 | Free-text clinical information |
| **HL7SpecimenSourceCode** | `varchar(10)` | YES | OBR-15 | HL7 specimen source code |
| **LIMSSpecimenSourceCode** | `varchar(10)` | YES | OBR-15 | LIMS specimen source code |
| **LIMSSpecimenSourceDesc** | `varchar(50)` | YES | OBR-15 | LIMS specimen source description |
| **HL7SpecimenSiteCode** | `varchar(10)` | YES | OBR-15 | HL7 anatomical site code |
| **LIMSSpecimenSiteCode** | `varchar(10)` | YES | OBR-15 | LIMS specimen site code |
| **LIMSSpecimenSiteDesc** | `varchar(50)` | YES | OBR-15 | LIMS specimen site description |
| **WorkUnits** | `float` | YES | OBR | Workload units for the panel |
| **CostUnits** | `float` | YES | OBR | Cost units for the panel |
| **HL7SectionCode** | `varchar(3)` | YES | OBR-24 | Lab section (CH, HM, MB, VR, etc.) |
| **HL7ResultStatusCode** | `char(1)` | YES | OBR-25 | Result status (F=Final, P=Preliminary) |
| **RegisteredBy** | `varchar(250)` | YES | OBR-10 | Person who registered the specimen |
| **TestedBy** | `varchar(250)` | YES | OBR-34 | Technician who performed the test |
| **AuthorisedBy** | `varchar(250)` | YES | OBR-32 | Person who authorized the result |
| **OrderingNotes** | `varchar(250)` | YES | NTE | Ordering notes |
| **EncryptedPatientID** | `varchar(64)` | YES | PID-3 | Encrypted patient identifier |
| **AgeInYears** | `int` | YES | PID-7 | Patient age in years at time of request |
| **AgeInDays** | `int` | YES | PID-7 | Patient age in days (for infants) |
| **HL7SexCode** | `char(1)` | YES | PID-8 | Sex: M, F, U, O |
| **HL7EthnicGroupCode** | `char(3)` | YES | PID-22 | Ethnic group code |
| **Deceased** | `bit` | YES | PID-30 | Deceased flag |
| **Newborn** | `bit` | YES | PID-7 | Newborn flag |
| **HL7PatientClassCode** | `char(1)` | YES | PV1-2 | Patient class: I, O, E |
| **AttendingDoctor** | `varchar(50)` | YES | PV1-7 | Attending physician |
| **TestingFacilityCode** | `varchar(10)` | YES | OBR-21 | Laboratory that performed the test |
| **ReferringRequestID** | `varchar(25)` | YES | OBR-18 | Reference to related/previous request |
| **Therapy** | `varchar(250)` | YES | RXA | Current therapy/treatment |
| **LIMSAnalyzerCode** | `varchar(10)` | YES | OBX-18 | Instrument/analyzer code used for testing |
| **TargetTimeDays** | `int` | YES | OBR-27 | Target turnaround time (days) |
| **TargetTimeMins** | `int` | YES | OBR-27 | Target turnaround time (minutes) |
| **LIMSRejectionCode** | `varchar(10)` | YES | OBR-31 | Rejection code |
| **LIMSRejectionDesc** | `varchar(250)` | YES | OBR-31 | Rejection description |
| **LIMSFacilityCode** | `varchar(15)` | YES | MSH-4 | LIMS sending facility code |
| **Repeated** | `tinyint` | YES | OBR-17 | Repeat test indicator |
| **LIMSVendorCode** | `varchar(4)` | YES | MSH-3 | Sending LIMS vendor code |
| **RequestingFacilityNationalCode** | `varchar(15)` | YES | OBR-21 | National facility code for requesting facility |
| **FirstPrinted** | `datetime` | YES | OBR-22 | First print date of result |
| **TestingLabRequestID** | `varchar(20)` | YES | — | Testing lab's internal request ID |

#### Facility Chain

Every request tracks **four facilities** in the sample journey:

```
RequestingFacility → ReceivingFacility → TestingFacility
        ↑                    ↑                  ↑
  Health Facility     Hub/Transport Lab    Testing Laboratory
  (where ordered)    (where received)    (where tested)

LIMSFacility = The LIMS system that sent the data
```

#### Turnaround Time (TAT) Segments

```
SpecimenDateTime → RegisteredDateTime → ReceivedDateTime → AnalysisDateTime → AuthorisedDateTime
   (Collection)      (Lab registration)    (Lab receipt)      (Testing)         (Result release)
```

Pre-registration adds additional tracking:
```
SpecimenDateTime → LIMSPreReg_RegistrationDateTime → LIMSPreReg_ReceivedDateTime → RegisteredDateTime → ...
   (Collection)      (Hub registration)                (Hub receipt)                 (Lab registration)
```

---

### 3.2 LabResults Table

Contains test result observations. Each row represents one result line on a laboratory report. Maps to HL7 OBX segments.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **DateTimeStamp** | `datetime` | YES | OpenLDR record timestamp |
| **Versionstamp** | `varchar(30)` | YES | Version tracking |
| **LIMSDateTimeStamp** | `datetime` | YES | Source LIMS timestamp |
| **LIMSVersionStamp** | `varchar(30)` | YES | Source LIMS version |
| **RequestID** | `varchar(26)` | YES | Links to Requests.RequestID |
| **OBRSetID** | `int` | YES | Links to Requests.OBRSetID |
| **OBXSetID** | `int` | YES | Result sequence within panel |
| **OBXSubID** | `int` | YES | Sub-result sequence |
| **LOINCCode** | `varchar(30)` | YES | Standardized LOINC test code |
| **HL7ResultTypeCode** | `varchar(2)` | YES | Result type: NM, CE, TX, FT, ST |
| **SIValue** | `float` | YES | Standardized SI unit numeric value |
| **SIUnits** | `varchar(25)` | YES | SI unit designation |
| **SILoRange** | `float` | YES | SI low reference range |
| **SIHiRange** | `float` | YES | SI high reference range |
| **HL7AbnormalFlagCodes** | `varchar(5)` | YES | Abnormal flags: H, L, HH, LL, A, N |
| **DateTimeValue** | `datetime` | YES | Date/time type result value |
| **CodedValue** | `varchar(1)` | YES | Single character coded result |
| **ResultSemiquantitive** | `int` | YES | Semi-quantitative result (ordinal scale) |
| **Note** | `bit` | YES | Flag indicating this is a note/comment |
| **LIMSObservationCode** | `varchar(10)` | YES | LIMS vendor observation identifier (the critical pivot key) |
| **LIMSObservationDesc** | `varchar(50)` | YES | LIMS observation description |
| **LIMSRptResult** | `varchar(80)` | YES | Original reported result as text |
| **LIMSRptUnits** | `varchar(25)` | YES | Original reported units |
| **LIMSRptFlag** | `varchar(25)` | YES | Original reported flag |
| **LIMSRptRange** | `varchar(25)` | YES | Original reported reference range |
| **LIMSCodedValue** | `varchar(5)` | YES | LIMS coded value for the result |
| **WorkUnits** | `float` | YES | Workload units for this result |
| **CostUnits** | `float` | YES | Cost units for this result |
| **FirstPrinted** | `datetime` | YES | First print date |

#### Result Value Types

Results accommodate three value types:
1. **Numeric values**: Converted to SI units in `SIValue`; original reported value preserved in `LIMSRptResult`
2. **Coded values**: LIMS codes stored in `LIMSCodedValue`; full text in `LIMSRptResult`
3. **Text results**: Multi-line text in `LIMSRptResult`; `Note` flag indicates commentary

#### The LIMSObservationCode System

The `LIMSObservationCode` is the critical field for extracting specific data elements from the vertical storage model. Each code identifies a specific type of observation/data element. Views use LEFT JOIN with filtered `LIMSObservationCode` values to pivot rows into columns. See Section 9 for the full panel code and observation code reference.

---

### 3.3 Monitoring Table

Specialized table for microbiology organism identifications and antimicrobial susceptibility results. A single specimen may yield ~3 organisms, each tested against ~20 antibiotics (Sensitive, Resistant, or Indeterminate).

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **DateTimeStamp** | `datetime` | YES | OpenLDR record timestamp |
| **Versionstamp** | `varchar(30)` | YES | Version tracking |
| **LIMSDateTimeStamp** | `datetime` | YES | Source LIMS timestamp |
| **LIMSVersionstamp** | `varchar(30)` | YES | Source LIMS version |
| **RequestID** | `varchar(26)` | YES | Links to Requests.RequestID |
| **OBRSetID** | `int` | YES | Links to Requests.OBRSetID |
| **OBXSetID** | `int` | YES | Links to LabResults.OBXSetID |
| **OBXSubID** | `int` | YES | Sub-observation sequence |
| **LOINCCode** | `varchar(30)` | YES | LOINC test code |
| **ORGANISM** | `varchar(50)` | YES | Organism name (Latin nomenclature) |
| **SurveillanceCode** | `varchar(5)` | YES | Surveillance classification code |
| **SpecimenDateTime** | `datetime` | YES | Specimen collection datetime |
| **LIMSObservationCode** | `varchar(25)` | YES | LIMS observation identifier |
| **LIMSObservationDesc** | `varchar(50)` | YES | LIMS observation description |
| **LIMSOrganismGroup** | `varchar(25)` | YES | Organism group classification |
| **CodedValue** | `varchar(1)` | YES | Coded result value |
| **ResultSemiquantitive** | `int` | YES | Semi-quantitative result |
| **ResultNotConfirmed** | `bit` | YES | Confirmation status flag |
| **ResistantDrugs** | `varchar(250)` | YES | Comma-separated resistant drug list |
| **IntermediateDrugs** | `varchar(250)` | YES | Comma-separated intermediate drug list |
| **SensitiveDrugs** | `varchar(250)` | YES | Comma-separated sensitive drug list |
| **MDRCode** | `char(1)` | YES | Multi-drug resistance classification |

**Join Path**: `Requests → LabResults → Monitoring` (via `RequestID` + `OBRSetID` + `OBXSetID`)

---

### 3.4 ASTResults Table

Antimicrobial Susceptibility Testing results. A more detailed companion to the Monitoring table, storing individual drug sensitivity test results.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **DateTimeStamp** | `datetime` | YES | Record timestamp |
| **Versionstamp** | `varchar(30)` | YES | Version tracking |
| **LIMSDateTimeStamp** | `datetime` | YES | Source LIMS timestamp |
| **LIMSVersionstamp** | `varchar(30)` | YES | Source LIMS version |
| **RequestID** | `varchar(26)` | YES | Links to Requests.RequestID |
| **OBRSetID** | `int` | YES | Panel sequence |
| **OBXSetID** | `int` | YES | Result sequence |
| **OBXSubID** | `int` | YES | Sub-result sequence |
| **LOINCCode** | `varchar(30)` | YES | LOINC code |
| **LIMSSubstanceCode** | `varchar(50)` | YES | Antimicrobial substance code |
| **LIMSSubstanceName** | `varchar(50)` | YES | Antimicrobial substance name |
| **LISMSSpecimenCode** | `varchar(5)` | YES | Specimen code |
| **LISMSSpecimenDesc** | `varchar(30)` | YES | Specimen description |
| **ORGANISM** | `varchar(50)` | YES | Tested organism |
| **LIMSOrganismCode** | `varchar(50)` | YES | Organism code |
| **LIMSORGGroupCode** | `varchar(50)` | YES | Organism group code |
| **LIMSORGGroupName** | `varchar(50)` | YES | Organism group name |
| **BreakpointType** | `varchar(10)` | YES | CLSI/EUCAST breakpoint type |
| **Methodology** | `varchar(10)` | YES | Testing methodology |
| **Units** | `varchar(10)` | YES | Result units (e.g., ug/mL) |
| **ASTValue** | `varchar(10)` | YES | Raw AST measurement value |
| **ASTResult** | `varchar(5)` | YES | Interpretation: S, R, I |
| **ASTDescription** | `varchar(100)` | YES | Result description |
| **ASTNotes** | `varchar(250)` | YES | Additional notes |

---

### 3.5 Patients Table

Contains patient identifying information. This table is **access-restricted** and is only joined when patient-level data is explicitly needed (e.g., SMS notifications, individual follow-up). **No patient identifiers exist in the core Requests/LabResults tables** — only the encrypted patient ID and demographics like age and sex.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **DateTimeStamp** | `datetime` | YES | Record timestamp |
| **Versionstamp** | `varchar(30)` | YES | Version tracking |
| **LIMSDateTimeStamp** | `datetime` | YES | Source LIMS timestamp |
| **LIMSVersionStamp** | `varchar(30)` | YES | Source LIMS version |
| **RequestID** | `varchar(26)` | YES | Links to Requests.RequestID |
| **REFNO** | `varchar(56)` | YES | Lab reference number |
| **REGISTEREDDATE** | `datetime` | YES | Registration date |
| **LOCATION** | `varchar(5)` | YES | Patient location code |
| **WARD** | `varchar(5)` | YES | Ward code |
| **HOSPID** | `varchar(26)` | YES | Hospital ID |
| **NATIONALITY** | `varchar(5)` | YES | Nationality code |
| **NATIONALID** | `varchar(26)` | YES | National ID number |
| **UNIQUEID** | `varchar(31)` | YES | Unique patient ID (ART number, etc.) |
| **SURNAME** | `varchar(31)` | YES | Patient surname |
| **FIRSTNAME** | `varchar(31)` | YES | Patient first name |
| **INITIALS** | `varchar(16)` | YES | Patient initials |
| **REFDRCODE** | `varchar(5)` | YES | Referring doctor code |
| **REFDR** | `varchar(41)` | YES | Referring doctor name |
| **MEDAID** | `varchar(5)` | YES | Medical aid code |
| **MEDAIDNO** | `varchar(26)` | YES | Medical aid number |
| **BILLACCNO** | `varchar(23)` | YES | Billing account number |
| **DOB** | `datetime` | YES | Date of birth |
| **DOBType** | `varchar(25)` | YES | DOB type (exact, estimated) |
| **TELHOME** | `varchar(20)` | YES | Home telephone |
| **TELWORK** | `varchar(20)` | YES | Work telephone |
| **MOBILE** | `varchar(20)` | YES | Mobile phone |
| **EMAIL** | `varchar(60)` | YES | Email address |
| **HealthcareNo** | `varchar(25)` | YES | Healthcare number |
| **UUID** | `varchar(50)` | YES | Universal unique identifier |

---

### 3.6 VersionControl Table

Tracks database schema versions.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **DateTimeStamp** | `datetime` | YES | Record timestamp |
| **VersionActivationDate** | `datetime` | YES | When version was activated |
| **VERBase** | `int` | YES | Major version number |
| **VERUpdate** | `int` | YES | Update/minor version |
| **VERBuild** | `int` | YES | Build number |
| **VersionStamp** | `varchar(20)` | YES | Version string |

---

## 4. OpenLDRData — Composite Key Structure

OpenLDR uses a **three-level composite key** to uniquely identify data:

| Level | Key | Description |
|-------|-----|-------------|
| **Request** | `RequestID` | Unique specimen/request identifier (varchar 26) |
| **Panel** | `RequestID` + `OBRSetID` | Specific test panel within a request |
| **Result** | `RequestID` + `OBRSetID` + `OBXSetID` | Individual result within a panel |

A single specimen (`RequestID`) can have multiple panels (`OBRSetID` = 1, 2, 3...), and each panel can have multiple results (`OBXSetID` = 1, 2, 3...).

### How Keys Relate Across Tables

```
Requests           LabResults           Monitoring            ASTResults
──────────         ──────────           ──────────            ──────────
RequestID ─────►  RequestID            RequestID             RequestID
OBRSetID  ─────►  OBRSetID             OBRSetID              OBRSetID
                  OBXSetID ─────────►  OBXSetID              OBXSetID
                  OBXSubID             OBXSubID              OBXSubID

Patients
─────────
RequestID ──────► (links to Requests.RequestID only)
```

---

## 5. OpenLDRData — Relationship Model

```
┌─────────────────────────────────────────────────────────────┐
│                      OpenLDRData                             │
│                                                              │
│  ┌─────────────────────┐     ┌──────────────────────┐       │
│  │      Requests        │     │      LabResults       │       │
│  │─────────────────────│     │──────────────────────│       │
│  │ RequestID (FK)       │◄───►│ RequestID (FK)        │       │
│  │ OBRSetID             │◄───►│ OBRSetID              │       │
│  │ [Request/Order info] │     │ OBXSetID              │       │
│  │ [Demographics]       │     │ [Result values]       │       │
│  │ [Facility codes]     │     │ [LOINC/LIMS codes]    │       │
│  │ [Dates/times]        │     │ [Observation codes]   │       │
│  └──────────┬──────────┘     └──────────┬───────────┘       │
│             │                            │                    │
│             │  RequestID                 │ RequestID          │
│             ▼                            │ OBRSetID           │
│  ┌─────────────────────┐                │ OBXSetID           │
│  │      Patients        │                ▼                    │
│  │─────────────────────│     ┌──────────────────────┐       │
│  │ RequestID (FK)       │     │      Monitoring       │       │
│  │ [Names, DOB, etc.]  │     │──────────────────────│       │
│  │ [Contact info]       │     │ RequestID (FK)        │       │
│  │ [National IDs]       │     │ OBRSetID              │       │
│  └─────────────────────┘     │ [Organisms]           │       │
│                               │ [Drug susceptibility] │       │
│  ┌─────────────────────┐     └──────────────────────┘       │
│  │     ASTResults       │                                     │
│  │─────────────────────│     ┌──────────────────────┐       │
│  │ RequestID (FK)       │     │    VersionControl     │       │
│  │ OBRSetID             │     │──────────────────────│       │
│  │ [AST drug results]   │     │ VERBase, VERUpdate    │       │
│  │ [Organisms]          │     │ VERBuild              │       │
│  └─────────────────────┘     └──────────────────────┘       │
│                                                              │
│  Cross-Database References:                                  │
│  Requests.RequestingFacilityCode ──► OpenLDRDict.Facilities  │
│  Requests.TestingFacilityCode ────► OpenLDRDict.Laboratories │
│  LabResults.LOINCCode ────────────► OpenLDRDict.LOINC        │
│  Requests.HL7SexCode ────────────► OpenLDRDict.HL7SexCodes  │
└─────────────────────────────────────────────────────────────┘
```

### Cross-Database References (OpenLDRData → OpenLDRDict)

| OpenLDRData Field | OpenLDRDict Table | Join Field | Purpose |
|-------------------|-------------------|------------|---------|
| `Requests.RequestingFacilityCode` | `viewFacilities` | `FacilityCode` | Requesting health facility name/location |
| `Requests.ReceivingFacilityCode` | `viewFacilities` | `FacilityCode` | Receiving/hub facility |
| `Requests.TestingFacilityCode` | `viewFacilities` | `FacilityCode` | Testing facility |
| `Requests.TestingFacilityCode` | `Laboratories` | `LabCode` | Laboratory name/type |
| `Requests.TestingFacilityCode` | `DisaPoc` | `LEFT(DisaPocLabNo,3)` | POC facility (DISA) |
| `Requests.ReceivingFacilityCode` | `DisaPoc` | `LEFT(DisaPocLabNo,3)` | Receiving POC facility |
| `Requests.RequestingFacilityCode` | `DisaLink` | `DlinkCode` | DISA Link referral hub |
| `Requests.LIMSFacilityCode` | `viewFacilities` | `FacilityCode` | LIMS sending facility |
| `Requests.RequestingFacilityNationalCode` | `viewFacilities` | `FacilityNationalCode` | National facility code lookup |
| `Requests.*FacilityCode` | `HFLattLong` | `FacilityCode` | GPS coordinates for mapping |
| `LabResults.LOINCCode` | `LOINC` | `LOINC_NUM` | Standardized test identification |
| `LabResults.LIMSCodedValue` | `LIMSCodedValues` | `LIMSCodedValue` | Coded value descriptions |
| `Monitoring.SurveillanceCode` | `Surveillance` | `SurveillanceCode` | Surveillance classification |
| `Monitoring.MDRCode` | `MDRCodes` | `MDRCode` | MDR classification |

---

## 6. OpenLDRData — SQL Views

Views pre-join Requests with specific LabResults rows, pivoting observation codes into columns. They also resolve facility names by joining with `OpenLDRDict.dbo.viewFacilities`.

### View Inventory

| View Name | Panel Filter | Purpose |
|-----------|-------------|---------|
| **viewVL_Info** | `VIRAL` | HIV VL registration metadata as columns (pregnant, breastfeeding, ART dates, reason for test, etc.) |
| **viewVL_Result** | `HIVVL` | HIV VL test results as columns, with computed `FinalViralLoadResult` |
| **viewPCR** | `PCR`, `POCED` | HIV EID PCR results (conventional + POC) |
| **viewPCR_Info** | `FSR` | HIV EID registration metadata (conventional) |
| **viewEID_Info** | `FSR`, `POFSR` | HIV EID info — conventional + point-of-care combined |
| **viewEID_Result** | `PCR`, `POCED` | HIV EID results with PCR/POC classification |
| **viewFullPCR** | `PCR` | Combined HIV EID patient + info + result in one view |
| **viewTbGenexpert** | `PCRGX`, `POCGT` | TB GeneXpert results with patient data (conventional + POC) |
| **viewTbMTXDR** | `MTXDR` | MDR/XDR TB drug resistance results |
| **viewTBLAM** | `TBLAM` | TB LAM Antigen test results |
| **viewCryptococcus** | `CRAG` | Cryptococcal Antigen (CrAg) results |
| **viewCD4** | `CD4` | CD4 cell count results (conventional + POC) |
| **viewCovid19_Info** | — | COVID-19 registration metadata |
| **viewCovid19_Result** | — | COVID-19 test results |
| **viewTB** | TB panels | General TB combined view |
| **viewTbPCRGenexpert** | `PCRGX` | TB PCR GeneXpert — conventional lab only |
| **viewTbPOCGenexpert** | `POCGT` | TB POC GeneXpert — point-of-care only |
| **WHONET_AST** | — | WHONET-compatible AST data export for AMR surveillance |
| **WHONET_LabResults** | IMM, MB, MCB, MYC, PAR, TX, SP, VR | WHONET-compatible lab results export |
| **WHONET_MONITORING** | — | WHONET-compatible monitoring data export |
| **viewFacilities** | — | (In OpenLDRDict) Denormalized facility + geography + GPS view |

### Common View Pattern

All disease-specific views follow the same pattern:

1. Start with `Requests` table filtered by `LIMSPanelCode`
2. LEFT JOIN specific `LabResults` rows filtered by `LIMSObservationCode`
3. LEFT JOIN `OpenLDRDict.dbo.viewFacilities` for facility resolution (4 joins: LIMS, Requesting, Receiving, Testing)
4. LEFT JOIN `OpenLDRDict.dbo.Laboratories` for lab name resolution
5. LEFT JOIN `OpenLDRDict.dbo.DisaPoc` for POC facility resolution
6. LEFT JOIN `OpenLDRDict.dbo.HFLattLong` for GPS coordinates
7. Optionally LEFT JOIN `Patients` for patient-level data

### Facility Resolution Logic (Pattern Used in All Views)

Views resolve facility names with a cascade priority:

```sql
-- Testing Facility name resolution
CASE
    WHEN viewFacilities.Description IS NOT NULL THEN viewFacilities.Description
    WHEN DisaPoc.DisaPocName IS NOT NULL THEN DisaPoc.DisaPocName
    ELSE Laboratories.LabName
END AS TestingFacilityName
```

#### Three Facility Resolution Patterns

**Pattern A — Requesting Facility** (health facility that ordered):
- Primary: `OpenLDRDict.viewFacilities` joined on `RequestingFacilityCode`
- Provides: `RequestingFacilityName`, `ProvinceName`, `DistrictName`, `CountryName`, GPS

**Pattern B — Receiving Facility** (hub/transport intermediary):
- Primary: `OpenLDRDict.viewFacilities` joined on `ReceivingFacilityCode`
- Also checks: `DisaLink` for DISA referral hubs

**Pattern C — Testing Facility** (where test was run):
- Primary: `OpenLDRDict.viewFacilities` joined on `TestingFacilityCode`
- Fallback 1: `DisaPoc` joined on `LEFT(DisaPocLabNo,3) = TestingFacilityCode`
- Fallback 2: `Laboratories.LabName`

---

## 7. OpenLDRData — User-Defined Functions

### Table-Valued Functions (Data Extraction)

These functions accept a date range and return complete datasets for specific test types, combining views + patients + dictionary lookups + derived columns.

| Function | Panel Filter | Returns |
|----------|-------------|---------|
| `getVL_Vendor1_WithPatients_DateTimeStamp(@startDate, @endDate)` | VIRAL, HIVVL | HIV VL data with patient info |
| `getEID_Vendor1_WithPatients_DateTimeStamp(@startDate, @endDate)` | FSR, PCR, POFSR, POCED | HIV EID data with patient info |
| `getTbGenexpert_WithPatients_DateTimeStamp(@startDate, @endDate)` | PCRGX, POCGT | TB GeneXpert with patient info |
| `getXDR_WithPatients_DateTimeStamp(@startDate, @endDate)` | MTXDR | MDR/XDR TB with patient info |
| `getTBLamWithPatientsDateTimeStamp(@startDate, @endDate)` | TBLAM | TB LAM with patient info |
| `getCragWithPatientsDateTimeStamp(@startDate, @endDate)` | CRAG | Cryptococcal with patient info |
| `getCD4_WithPatients_DateTimeStamp(@startDate, @endDate)` | CD4 | CD4 with patient info |
| `getRequestIDsWithUpdatedDateTimeStamp(@startDate, @endDate)` | VIRAL, HIVVL | Changed VL RequestIDs in date range |

**Common Date Filter Pattern** (used by all extraction functions):
```sql
WHERE (Requests.DateTimeStamp >= @startDate AND Requests.DateTimeStamp < @endDate)
   OR (LabResults.DateTimeStamp IS NOT NULL
       AND LabResults.DateTimeStamp >= @startDate
       AND LabResults.DateTimeStamp < @endDate)
```

### Scalar Functions

| Function | Signature | Purpose |
|----------|-----------|---------|
| `generatePatientID` | `generatePatientID(@uniqueID)` | Normalizes ART patient IDs to standard format |
| `GetAgeGroup` | `GetAgeGroup(@age)` | Classifies age into groups: <2, 2-5, 6-14, 15-49, 50+ |
| `getHealthCareCode` | `getHealthCareCode(@facilityCode)` | Looks up HealthcareDistrictCode from OpenLDRDict |
| `GetReasonForTest` | `GetReasonForTest(@reason)` | Normalizes reason-for-test strings (Portuguese to English) |
| `IfEmptyReturnValue` | `IfEmptyReturnValue(@input, @default)` | Returns default if input is NULL or empty/whitespace |
| `ViralLoadFinalResult` | `ViralLoadFinalResult(@vlResult, @capctm)` | Merges VL result fields into single final result |
| `ViralLoadResultMerge` | `ViralLoadResultMerge(@result, @coded)` | Resolves coded VL values using LIMSCodedValues dictionary |
| `ViralLoadResultRange` | `ViralLoadResultRange(@finalResult)` | Classifies VL as "Suppressed" (<1000) or "Not Suppressed" |
| `ufn_GetAgeGroupJSON` | `ufn_GetAgeGroupJSON(@alias)` | Returns age group CASE expression as JSON for dynamic queries |

### Viral Load Suppression Logic

```
FinalViralLoadResult = ViralLoadFinalResult(HIVVD, COALESCE(HIVVR, HIVVC, HIVVF))

If FinalViralLoadResult is numeric:
    < 1000  = "Suppressed"
    >= 1000 = "Not Suppressed"
If text containing "<" = "Suppressed" (below detection)
If text "> 10000000" or ">1000000 copias/ml" = "Not Suppressed"
```

### Age Group Classification

The `GetAgeGroup` function classifies patients:

| Age Range | Group Label |
|-----------|-------------|
| NULL | No Age Specified |
| < 2 years | <2 |
| 2-5 years | 2-5 |
| 6-14 years | 6-14 |
| 15-49 years | 15-49 |
| >= 50 years | 50+ |

Age is calculated from: `COALESCE(Requests.AgeInYears, Requests.AgeInDays/365)`

---

## 8. OpenLDRDict — Table Schemas

The OpenLDR Dictionary database (`OpenLDRDict`) is the master reference data repository. It contains lookup/reference tables that enable users to decode codified fields in the Data databases (OpenLDRData). **The Dict database does not contain test data** — it exclusively holds reference information about facilities, laboratories, geographic areas, HL7 code lookups, LOINC mappings, and other standardization dictionaries.

### Database Connection

| Property | Value |
|----------|-------|
| **Bind Key** | `dict` |
| **Database Name** | Configurable via `DB_DICT` env var (default: `OpenLDRDict`) |
| **Engine** | Microsoft SQL Server |
| **ORM (Python)** | SQLAlchemy 2.0 via `mssql+pyodbc` (ODBC Driver 17) |
| **ORM (TypeScript)** | Sequelize 6.28 via `tedious` (legacy) |

### Complete Table Inventory

**Operational Tables (Actively Used)**

| Table | Type | Purpose | Used By |
|-------|------|---------|---------|
| **Facilities** | Base Table | Health facility master list | All modules |
| **HealthcareAreas** | Base Table | Geographic area descriptions and hierarchy | All modules |
| **Laboratories** | Base Table | Laboratory identification and classification | TB, HIV VL, HIV EID |
| **HFLattLong** | Base Table | Facility GPS coordinates | Mapping features |
| **DisaPoc** | Base Table | DISA Point-of-Care testing sites | HIV EID (Mozambique) |
| **Disalink** | Base Table | DISA Link referral/transport hubs | HIV EID (Mozambique) |
| **viewFacilities** | SQL View | Denormalized facility view joining Facilities + HealthcareAreas + HFLattLong | Primary API access layer |

**HL7 Reference Tables (Standard Dictionaries)**

| Table | Purpose |
|-------|---------|
| **HL7AbnormalFlagCodes** | Abnormal flag code definitions (H, L, A, etc.) |
| **HL7EthnicGroupCodes** | Ethnic group code definitions |
| **HL7PatientClassCodes** | Patient classification codes (inpatient, outpatient, etc.) |
| **HL7ResultStatusCodes** | Result status codes (final, preliminary, corrected, etc.) |
| **HL7ResultTypeCodes** | Result type codes (numeric, coded, text, etc.) |
| **HL7SectionCodes** | Laboratory section codes (chemistry, hematology, micro, etc.) |
| **HL7SexCodes** | Sex/gender codes (M, F, U, etc.) |
| **HL7SpecimenSiteCodes** | Specimen collection site codes |
| **HL7SpecimenSourceCodes** | Specimen source/type codes (blood, urine, sputum, etc.) |

**Analytical and Standardization Tables**

| Table | Purpose |
|-------|---------|
| **LOINC** | Complete LOINC dataset for standardized test identification |
| **MDRCodes** | Multi-drug-resistant flags and classification codes |
| **Surveillance** | Defines items used to generate surveillance reports |
| **Analyzers** | Laboratory instrument/analyzer inventory (manufacturer, serial number, installation date) |
| **VersionControl** | Database schema version tracking |

> **Note**: Many HL7 tables, Analyzers, MDRCodes, and Surveillance tables have not been actively utilized by all implementations. The primary operational tables are **Facilities**, **HealthcareAreas**, **Laboratories**, and **HFLattLong**.

---

### 8.1 Facilities (Base Table)

The Facilities table is the core reference table listing all health facilities that submit laboratory test requests.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **FacilityCode** | `VARCHAR(15)` | NO (PK) | Internal facility identifier used by data providers. Ideally aligns with official Ministry of Health (MoH) facility codes |
| DateTimeStamp | `DATETIME` | YES | Timestamp of last modification |
| VersionStamp | `VARCHAR(30)` | YES | Version tracking identifier |
| Description | `VARCHAR(50)` | YES | Facility name and supplementary information |
| FacilityType | `VARCHAR(3)` | YES | Type classification: `"H"` = Health Facility, `"L"` = Laboratory |
| MoHFacilityCode | `VARCHAR(15)` | YES | Official Ministry of Health facility code |
| CountryCode | `VARCHAR(2)` | YES | ISO 2-letter country code (e.g., `"MZ"` for Mozambique) |
| ProvinceCode | `VARCHAR(4)` | YES | 2-digit province code within country |
| RegionCode | `VARCHAR(4)` | YES | 2-digit region code within province |
| DistrictCode | `VARCHAR(4)` | YES | 2-digit district code within province |
| SubDistrictCode | `VARCHAR(4)` | YES | 2-digit sub-district code |
| LattLong | `GEOGRAPHY` | YES | SQL Server geographic point (latitude/longitude) |
| HFStatus | `INT` | YES | Active status: `1` = Active, `0` = Inactive |
| HealthCareID | `VARCHAR(30)` | YES | Concatenated healthcare area identifier |

**Key Relationships:**
- `FacilityCode` is referenced by all data tables (`Requests.RequestingFacilityCode`, `Requests.TestingFacilityCode`, `Requests.ReceivingFacilityCode`)
- Geographic codes concatenate to form `HealthcareAreaCode` for joining with `HealthcareAreas`
- Outer joined with `HFLattLong` on `FacilityCode` for precise GPS coordinates

---

### 8.2 HealthcareAreas (Base Table)

Lookup table providing descriptive names for geographic administrative levels. Each geographic level receives its own row.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **HealthcareAreaCode** | `VARCHAR(10)` | NO (PK) | Concatenated hierarchical code |
| HealthcareAreaDesc | `VARCHAR(50)` | YES | Human-readable area name (e.g., "Maputo Provincia") |
| LattLong | `GEOGRAPHY` | YES | Geographic center point for the area |

**Hierarchical Code Structure:**

| Level | Code Length | Example | Description |
|-------|------------|---------|-------------|
| Country | 2 chars | `MZ` | Mozambique |
| Province | 4 chars | `MZ11` | Maputo Provincia |
| District | 6 chars | `MZ1101` | Matola District |
| Sub-District | 8 chars | `MZ110101` | Sub-district within Matola |

**How to Join with Facilities:**
```sql
-- Get province name for a facility
SELECT f.FacilityCode, f.Description, ha.HealthcareAreaDesc AS ProvinceName
FROM Facilities f
LEFT JOIN HealthcareAreas ha
  ON ha.HealthcareAreaCode = f.CountryCode + f.ProvinceCode

-- Get district name for a facility
SELECT f.FacilityCode, f.Description, ha.HealthcareAreaDesc AS DistrictName
FROM Facilities f
LEFT JOIN HealthcareAreas ha
  ON ha.HealthcareAreaCode = f.CountryCode + f.ProvinceCode + f.DistrictCode
```

---

### 8.3 Laboratories (Base Table)

Identifies individual laboratories within facilities. A single facility may house multiple laboratories (e.g., a hospital with both a conventional lab and a point-of-care testing lab).

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **LabCode** | `VARCHAR(15)` | NO (PK) | Unique laboratory identifier |
| DateTimeStamp | `DATETIME` | YES | Last modification timestamp |
| VersionStamp | `VARCHAR(30)` | YES | Version tracking |
| LIMSVendorCode | `VARCHAR(4)` | YES | LIMS vendor identifier (e.g., DISA, Meditech) |
| FacilityCode | `VARCHAR(15)` | YES (FK) | Parent facility code (references `Facilities.FacilityCode`) |
| LabName | `VARCHAR(50)` | YES | Laboratory name |
| LabType | `VARCHAR(25)` | YES | Laboratory classification |
| StaffingLevel | `VARCHAR(25)` | YES | Staffing level category |

**LabType Values:**

| Value | Description |
|-------|-------------|
| `"VL/EID"` | Viral Load / Early Infant Diagnosis laboratory |
| `"Conventional"` | Conventional laboratory testing |
| `"Point_Of_Care"` | Point-of-care testing site |
| `"TB"` | Tuberculosis testing laboratory |

**Relationship:** `Laboratories.FacilityCode → Facilities.FacilityCode → HealthcareAreas` (full geographic context: Lab → Facility → Province/District)

> **Implementation Note**: The Python API currently populates laboratory listings from the TB GeneXpert `TBMaster` table (using `TestingFacilityCode`, `TestingFacilityName` fields) rather than querying the Laboratories table directly. The TypeScript API queries Laboratories directly. The long-term plan uses `TestingLabCode`/`ReceivingLabCode` fields to replace facility-based lab identification.

---

### 8.4 HFLattLong (Base Table)

Stores precise GPS coordinates for health facilities. Provides simple string-based coordinates as an alternative to the SQL Server GEOGRAPHY type used in the Facilities table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **FacilityCode** | `VARCHAR(20)` | NO (PK) | Facility identifier (maps to `Facilities.FacilityCode`) |
| FacilityNationalCode | `INT` | YES | National facility registration code |
| LattLong | `VARCHAR(255)` | YES | Combined "latitude,longitude" string |
| Latt | `VARCHAR(255)` | YES | Latitude coordinate as string |
| Long | `VARCHAR(255)` | YES | Longitude coordinate as string |

**Usage**: Outer joined with `viewFacilities` to provide coordinates for mapping and distance calculations. String-based format ensures compatibility across reporting tools that may not support SQL Server's GEOGRAPHY data type.

---

### 8.5 DisaPoc (Base Table)

DISA Point-of-Care testing sites. DISA is the Laboratory Information System used in Mozambique. POC sites perform rapid testing at the health facility level rather than sending specimens to central laboratories.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| DisaPocCode | `VARCHAR` | YES | Unique DISA POC facility code |
| DisaPocName | `VARCHAR` | YES | Facility name |
| DisaPocNationalCode | `VARCHAR` | YES | National registration code |
| DisaPocLabNo | `VARCHAR` | YES | Associated laboratory number |
| DisaPocPrefix | `VARCHAR` | YES | Sample code prefix identifier |
| DisaPocProvinceName | `VARCHAR` | YES | Province name |
| DisapocDistrictName | `VARCHAR` | YES | District name (note: lowercase "poc" in column name) |
| DisaPocLicence | `VARCHAR` | YES | Licensing/accreditation information |

---

### 8.6 Disalink (Base Table)

DISA Link facilities serve as referral and sample transport hubs. They connect health facilities to testing laboratories in the sample routing network.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| DlinkCode | `VARCHAR` | YES | DISA Link facility code |
| DlinkName | `VARCHAR` | YES | Facility name |
| DlinkNationalCode | `VARCHAR` | YES (Optional) | National registration code |
| DlinkProvinceName | `VARCHAR` | YES | Province name |
| DistrictName | `VARCHAR` | YES | District name |

---

### 8.7 viewFacilities (SQL View)

A denormalized view that pre-joins Facilities with HealthcareAreas at multiple geographic levels, plus HFLattLong for coordinates. **This is the primary access layer used by the API** — most code queries this view rather than the base tables directly.

| Column | Data Type | Nullable | Source | Description |
|--------|-----------|----------|--------|-------------|
| **FacilityCode** | `VARCHAR(15)` | NO (PK) | Facilities | Unique facility identifier |
| DateTimeStamp | `DATETIME` | YES | Facilities | Last modification timestamp |
| VersionStamp | `VARCHAR(30)` | YES | Facilities | Version tracking |
| Description | `VARCHAR(50)` | YES | Facilities | Facility name |
| FacilityType | `VARCHAR(3)` | YES | Facilities | Facility type (`"H"`, `"L"`) |
| CountryCode | `VARCHAR(2)` | YES | Facilities | ISO country code |
| ProvinceCode | `VARCHAR(4)` | YES | Facilities | Province code |
| RegionCode | `VARCHAR(4)` | YES | Facilities | Region code |
| DistrictCode | `VARCHAR(4)` | YES | Facilities | District code |
| SubDistrictCode | `VARCHAR(4)` | YES | Facilities | Sub-district code |
| LattLong | `GEOGRAPHY/TEXT` | YES | HFLattLong | Facility coordinates |
| HFStatus | `INT` | YES | Facilities | Active status flag |
| HealthCareID | `VARCHAR(30)` | YES | Facilities | Healthcare area ID |
| FacilityNationalCode | `VARCHAR(15)` | YES | HFLattLong | National facility code |
| HealthcareCountryCode | `VARCHAR(2)` | YES | HealthcareAreas | Resolved country code |
| HealthcareProvinceCode | `VARCHAR(2052)` | NO | HealthcareAreas | Province area code |
| HealthcareDistrictCode | `VARCHAR(4104)` | NO | HealthcareAreas | District area code |
| CountryName | `VARCHAR(50)` | YES | HealthcareAreas | Resolved country name |
| CountryLattLong | `GEOGRAPHY/TEXT` | YES | HealthcareAreas | Country center coordinates |
| ProvinceName | `VARCHAR(50)` | YES | HealthcareAreas | Resolved province name |
| ProvinceLattLong | `GEOGRAPHY/TEXT` | YES | HealthcareAreas | Province center coordinates |
| DistrictName | `VARCHAR(50)` | YES | HealthcareAreas | Resolved district name |
| DistrictLattLong | `GEOGRAPHY/TEXT` | YES | HealthcareAreas | District center coordinates |

**Standard API Filters Applied (Python API):**
```python
# Only active health facilities with valid geographic data
Facilities.HFStatus == 1
Facilities.FacilityType == "H"
Facilities.ProvinceName.isnot(None)
Facilities.DistrictName.isnot(None)
Facilities.Description.isnot(None)
```

**Conceptual View Definition:**
```sql
SELECT
    f.*,
    hf.Latt, hf.Long, hf.LattLong,
    ha_country.HealthcareAreaDesc AS CountryName,
    ha_country.LattLong AS CountryLattLong,
    ha_province.HealthcareAreaDesc AS ProvinceName,
    ha_province.LattLong AS ProvinceLattLong,
    ha_district.HealthcareAreaDesc AS DistrictName,
    ha_district.LattLong AS DistrictLattLong
FROM Facilities f
LEFT JOIN HFLattLong hf ON hf.FacilityCode = f.FacilityCode
LEFT JOIN HealthcareAreas ha_country
    ON ha_country.HealthcareAreaCode = f.CountryCode
LEFT JOIN HealthcareAreas ha_province
    ON ha_province.HealthcareAreaCode = f.CountryCode + f.ProvinceCode
LEFT JOIN HealthcareAreas ha_district
    ON ha_district.HealthcareAreaCode = f.CountryCode + f.ProvinceCode + f.DistrictCode
```

---

### 8.8 Analyzers (Base Table)

Laboratory instrument/analyzer inventory tracking.

| Column | Data Type | Description |
|--------|-----------|-------------|
| AnalyzerCode | `VARCHAR` | Unique analyzer identifier |
| Manufacturer | `VARCHAR` | Equipment manufacturer |
| SerialNumber | `VARCHAR` | Instrument serial number |
| InstallationDate | `DATETIME` | Date of installation |
| LabCode | `VARCHAR` | Laboratory where installed (FK to Laboratories) |

> **Status**: Referenced in documentation but not actively populated in current implementations.

---

### 8.9 LOINC (Base Table)

Complete LOINC (Logical Observation Identifiers Names and Codes) dataset. LOINC is the international standard for identifying laboratory observations.

| Column | Description |
|--------|-------------|
| LOINC_NUM | LOINC code (e.g., "20447-9" for HIV-1 RNA) |
| COMPONENT | Test component name |
| PROPERTY | Property measured (e.g., "NCnc" for number concentration) |
| TIME_ASPCT | Time aspect (e.g., "Pt" for point in time) |
| SYSTEM | Specimen type (e.g., "Ser/Plas" for serum/plasma) |
| SCALE_TYP | Scale type (e.g., "Qn" for quantitative) |
| METHOD_TYP | Method type |
| LONG_COMMON_NAME | Human-readable test name |
| STATUS | Active/deprecated status |

**Usage in OpenLDR**: The `LOINCCode` field in the `LabResults` table maps to `LOINC.LOINC_NUM` for standardized test identification. Enables cross-vendor reporting where different LIMS systems use different proprietary test codes but map to the same LOINC code.

---

### 8.10 HL7 Reference Tables

All HL7 reference tables follow a consistent structure:

| Column | Data Type | Description |
|--------|-----------|-------------|
| Code | `VARCHAR` | HL7-defined code value |
| Description | `VARCHAR` | Human-readable description |

#### HL7AbnormalFlagCodes
Maps to `LabResults.HL7AbnormalFlagCodes` field.

| Code | Meaning |
|------|---------|
| `H` | Above high normal |
| `L` | Below low normal |
| `HH` | Above upper panic/critical |
| `LL` | Below lower panic/critical |
| `A` | Abnormal |
| `N` | Normal |
| `null` | Not applicable |

#### HL7SexCodes
Maps to `Requests.HL7SexCode` field.

| Code | Meaning |
|------|---------|
| `M` | Male |
| `F` | Female |
| `U` | Unknown |
| `O` | Other |

#### HL7ResultStatusCodes
Maps to `LabResults.HL7ResultStatusCode` field.

| Code | Meaning |
|------|---------|
| `F` | Final result |
| `P` | Preliminary |
| `C` | Corrected |
| `X` | Cancelled |
| `I` | Pending |

#### HL7ResultTypeCodes
Indicates the format of the result value. Maps to `LabResults.HL7ResultTypeCode`.

| Code | Meaning |
|------|---------|
| `NM` | Numeric |
| `CE` | Coded element |
| `TX` | Text |
| `FT` | Formatted text |
| `ST` | String |

#### HL7SectionCodes
Laboratory department/section classification. Maps to `Requests.HL7SectionCode`.

| Code | Meaning |
|------|---------|
| `CH` | Chemistry |
| `HM` | Hematology |
| `MB` | Microbiology |
| `IM` | Immunology |
| `VR` | Virology |
| `IMM` | Immunology (alternate) |
| `MCB` | Mycobacteriology |
| `MYC` | Mycology |
| `PAR` | Parasitology |
| `SP` | Serology/Parasitology |

#### HL7SpecimenSourceCodes
Maps to `Requests.HL7SpecimenSourceCode`. Common values: Blood, Serum, Plasma, Urine, Sputum, CSF, DBS (Dried Blood Spot), etc.

#### HL7SpecimenSiteCodes
Maps to `Requests.HL7SpecimenSiteCode`. Identifies the anatomical site of specimen collection.

#### HL7PatientClassCodes
Maps to `Requests.HL7PatientClassCode`.

| Code | Meaning |
|------|---------|
| `I` | Inpatient |
| `O` | Outpatient |
| `E` | Emergency |

#### HL7EthnicGroupCodes
Maps to `Requests.HL7EthnicGroupCode`. Country-specific ethnic/race classification.

---

### 8.11 MDRCodes (Base Table)

Multi-drug-resistant organism classification codes. Used primarily with TB testing to flag resistance patterns.

| Column | Description |
|--------|-------------|
| MDRCode | Resistance classification code |
| Description | Human-readable resistance description |

Relevant for TB GeneXpert results where rifampicin resistance is detected.

---

### 8.12 Surveillance (Base Table)

Defines items extracted from laboratory data for public health surveillance reporting.

| Column | Description |
|--------|-------------|
| SurveillanceCode | Unique surveillance item identifier |
| Description | Surveillance item description |
| LOINCCode | Associated LOINC code(s) |

---

### 8.13 VersionControl (Base Table — in OpenLDRDict)

Tracks database schema versions for the dictionary database.

| Column | Description |
|--------|-------------|
| VersionNumber | Schema version identifier |
| Description | Change description |
| DateApplied | When the version was applied |

---

## 9. Facility Hierarchy and Geographic System

### Country → Province → Region → District → Sub-District → Facility

OpenLDR uses a concatenated code system to represent administrative geography. This is a core concept for understanding how facilities, provinces, and districts relate.

### The Concatenation Pattern

```
Level 1: Country       → "MZ"                       (2 chars)
Level 2: Province      → "MZ" + "11"     = "MZ11"   (4 chars)
Level 3: District      → "MZ11" + "01"   = "MZ1101" (6 chars)
Level 4: Sub-District  → "MZ1101" + "01" = "MZ110101" (8 chars)
```

> **IMPORTANT**: Geographic codes are NOT nationally unique. Province "AA" District "01" and Province "BB" District "01" both have `DistrictCode = "01"`. Always qualify district codes with their parent province code.

### Example Geographic Hierarchy (Mozambique)

```
MZ (Mozambique)
├── MZ01 (Niassa)
│   ├── MZ0101 (Cuamba)
│   └── MZ0102 (Lichinga)
├── MZ02 (Cabo Delgado)
│   ├── MZ0201 (Pemba)
│   └── MZ0202 (Montepuez)
├── MZ11 (Maputo Provincia)
│   ├── MZ1101 (Matola)
│   └── MZ1102 (Boane)
└── MZ12 (Maputo Cidade)
    └── MZ1201 (Maputo)
```

### Geographic Code Fields in Facilities Table

| Field | Length | Contains |
|-------|--------|---------|
| `CountryCode` | 2 | ISO country code (e.g., `MZ`) |
| `ProvinceCode` | 2 | Province suffix (e.g., `11`) — NOT the full code |
| `RegionCode` | 2 | Region suffix |
| `DistrictCode` | 2 | District suffix (e.g., `01`) — NOT the full code |
| `SubDistrictCode` | 2 | Sub-district suffix |

To get the full HealthcareAreaCode for a district: `CountryCode + ProvinceCode + DistrictCode`

### Key Join Fields (Dict ↔ Data)

| Data Table Field | Dict Table | Dict Field | Purpose |
|------------------|------------|------------|---------|
| `RequestingFacilityCode` | viewFacilities | FacilityCode | Where the test was ordered |
| `ReceivingFacilityCode` | viewFacilities | FacilityCode | Hub/transport facility |
| `TestingFacilityCode` | viewFacilities | FacilityCode | Where testing was performed |
| `TestingLabCode` | Laboratories | LabCode | Specific lab (planned migration) |
| `LOINCCode` | LOINC | LOINC_NUM | Standardized test identification |
| `HL7SexCode` | HL7SexCodes | Code | Patient sex lookup |
| `HL7ResultStatusCode` | HL7ResultStatusCodes | Code | Result status lookup |
| `HL7AbnormalFlagCodes` | HL7AbnormalFlagCodes | Code | Abnormal flag lookup |
| `HL7SpecimenSourceCode` | HL7SpecimenSourceCodes | Code | Specimen type lookup |
| `HL7SectionCode` | HL7SectionCodes | Code | Lab section lookup |

---

## 10. Panel Code Reference (LIMSPanelCode)

Panel codes identify the type of test/data group. Each code determines which `LIMSObservationCode` values to expect in LabResults. The `LIMSPanelCode` field in the Requests table is the primary filter used by all views and functions.

### LOINC Panel Code Mapping

The `LIMSPanelCodes` table in OpenLDRDict includes a `LOINCPanelCode` column that maps each vendor-specific panel code to its corresponding international LOINC code. This enables standardized identification and allows looking up detailed test information from the official LOINC registry at `https://loinc.org/{LOINCPanelCode}`.

**LIMSPanelCodes Table Schema:**

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| **LIMSPanelCode** | `varchar(10)` | NO | Vendor-specific panel code (e.g., HIVVL, VIRAL) |
| **LIMSPanelDesc** | `varchar(50)` | YES | Panel description |
| **LIMSObservationCode** | `varchar(10)` | NO | Observation code within the panel |
| **LIMSObservationDesc** | `varchar(100)` | YES | Observation description |
| **LOINCPanelCode** | `varchar(20)` | YES | Corresponding LOINC code for the test panel |

**Known LOINC Mappings:**

| LIMSPanelCode | LOINCPanelCode | LOINC Long Common Name | loinc.org URL |
|---------------|----------------|------------------------|---------------|
| HIVVL | 25836-8 | HIV 1 RNA [#/volume] (Viral Load) | https://loinc.org/25836-8 |
| VIRAL | 25836-8 | HIV 1 RNA [#/volume] (Viral Load) | https://loinc.org/25836-8 |
| PCR | 9836-8 | HIV 1 DNA [Presence] (EID Qualitative PCR) | https://loinc.org/9836-8 |
| FSR | 9836-8 | HIV 1 DNA [Presence] (EID Qualitative PCR) | https://loinc.org/9836-8 |
| PCRGX | 38376-3 | MTB DNA [Presence] (TB GeneXpert) | https://loinc.org/38376-3 |
| CD4 | 24467-3 | CD4 cells [#/volume] in Blood | https://loinc.org/24467-3 |
| CRAG | 31795-8 | Cryptococcal Ag [Presence] in Serum | https://loinc.org/31795-8 |
| TBLAM | 94053-5 | MTB Ag [Presence] in Urine (TB LAM) | https://loinc.org/94053-5 |

To look up LOINC codes for panels not listed above, query the live database:
```sql
SELECT DISTINCT LIMSPanelCode, LOINCPanelCode, LIMSPanelDesc
FROM [OpenLDRDict].[dbo].[LIMSPanelCodes]
WHERE LOINCPanelCode IS NOT NULL
ORDER BY LIMSPanelCode
```

### HIV Viral Load

| LIMSPanelCode | Description | Obs Codes | Test Type |
|---------------|-------------|-----------|-----------|
| **HIVVL** | HIV Viral Load test result panel | 5 | VL results |
| **VIRAL** | HIV Viral Load registration/metadata panel | 16 | VL metadata |

**HIVVL Panel — Observation Codes:**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `HIVVD` | CAP/CTM Viral Load result |
| `HIVVR` | Viral Load Result |
| `HIVVC` | HIV Viral Load (low value) |
| `HIVVF` | HIV Viral |
| `HIVRL` | Log Value |

**VIRAL Panel — Observation Codes (Registration Metadata):**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `ENCON` | Pregnant (Yes/No) |
| `AMAME` | Breastfeeding (Yes/No) |
| `VIRAP` | First time VL test |
| `LABDA` | Collection date |
| `LABHO` | Collection hour |
| `TARVD` | ART start date |
| `TARVP` | First-line ART regimen |
| `TARVS` | Second-line ART regimen |
| `TARVQ` | Current ART regimen |
| `ESCOL` | Reason for test |
| `LABTI` | Type of sample collection |
| `VIRAD` | Last viral load date |
| `VIRR1` | Last viral load result |
| `LABNO` | Requesting clinician |
| `CONSE` | Consent for contact |
| `LABLO` | Collection location |

---

### HIV Early Infant Diagnosis (EID)

| LIMSPanelCode | Description | Test Type |
|---------------|-------------|-----------|
| **FSR** | EID registration/info panel (conventional lab) | EID metadata |
| **PCR** | EID result panel (conventional PCR) | EID results |
| **POFSR** | EID registration panel (point-of-care) | EID POC metadata |
| **POCED** | EID result panel (point-of-care) | EID POC results |

**EID Result Observation Codes (PCR / POCED):**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `HIVPC` | Infant HIV DNA PCR result |
| `HIVVR` | Viral Load result |
| `HIVVD` | CAP/CTM result |
| `HIVRL` | Log value |
| `PII1` | PII1 marker |
| `HIV2` | HIV-2 detection |
| `HIVMN` | HIV-1 M/N detection |
| `HIVO` | HIV-1 O detection |
| `TXT` | Remarks/comments |

**EID Info Observation Codes — Registration Metadata (FSR / POFSR):**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `AGE` | Age weaned |
| `ALEIC` | Breastfeeding information |
| `ALEIT` | Currently breastfeeding (Yes/No) |
| `CONSE` | Patient consent |
| `EIDCM` | Caregiver name |
| `EIDCN` | Caregiver contact |
| `EIDCP` | Caregiver mobile contact |
| `EIDDT` | EID date |
| `EIDID` | EID ID number |
| `EIDRS` | Rapid HIV test result |
| `PCRAN` | PCR previously done (Yes/No) |
| `PCRF` | PCR collection type |
| `PORS` | Number of weeks |
| `PTVC` | PTV (PMTCT) child prophylaxis |
| `PTVM` | PTV (PMTCT) mother prophylaxis |
| `QUALF` | Previous result information |

---

### TB GeneXpert

| LIMSPanelCode | Description | Test Type |
|---------------|-------------|-----------|
| **PCRGX** | TB GeneXpert (conventional lab) | TB GeneXpert |
| **POCGT** | TB GeneXpert (point-of-care) | TB GeneXpert POC |

**TB GeneXpert Observation Codes:**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `GXTB` | GeneXpert TB detection result |
| `GXTBR` | GeneXpert TB result (alternative code) |
| `GXRIF` | Rifampicin resistance result |
| `GXTRA` | MTB Trace detection |
| `!GX` | GeneXpert instrument result |
| `GEND` | GeneXpert date |
| `HCOM` | Comments |
| `RJREA` | Rejection reason |
| `RJREM` | Rejection remark |
| `TBTXT` | TB text remarks |

---

### TB MDR/XDR (Multi/Extensively Drug-Resistant TB)

| LIMSPanelCode | Description | Test Type |
|---------------|-------------|-----------|
| **MTXDR** | MDR/XDR TB drug susceptibility testing | MDR/XDR TB |

**MTXDR Observation Codes:**

| LIMSObservationCode | Description | Result Values |
|---------------------|-------------|---------------|
| `GXFLQ` | Fluoroquinolone resistance | DET / NDET / Indeterminate |
| `GXISO` / `GXINH` | Isoniazid resistance | DET / NDET / Indeterminate |
| `GXKAN` | Kanamycin resistance | DET / NDET / Indeterminate |
| `GXAMI` | Amikacin resistance | DET / NDET / Indeterminate |
| `GXCAP` | Capreomycin resistance | DET / NDET / Indeterminate |
| `GXETH` | Ethionamide resistance | DET / NDET / Indeterminate |
| `GXRIF` | Rifampicin resistance | DET / NDET / Indeterminate |
| `GXTBR` | PCR detection result | — |

---

### Advanced Diseases

| LIMSPanelCode | Description | Test Type |
|---------------|-------------|-----------|
| **CD4** | CD4 cell count panel | Advanced Disease |
| **TBLAM** | TB LAM Antigen test panel | Advanced Disease |
| **CRAG** | Cryptococcal Antigen test panel | Advanced Disease |

**CD4 Observation Codes:**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `CBAC` | Control Bead Absolute Count |
| `CD3` | CD3 Count |
| `CD3L` | CD3 Percentage |
| `CD4` | CD4 Count (conventional) |
| `VCD4` | VCD4 Result |
| `CD4L` | CD4 Percentage |
| `THSR` | T Helper/Suppressor Ratio |
| `NCD4` | CD4 Count (POC) |
| `NCD4P` | CD4 Percentage (POC) |
| `CD4TX` | POC Remarks |

**TBLAM Observation Codes:**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `TBLAM` | Urine TB LAM Ag result |
| `CD4TX` | CD4 Rate |
| `NCD4` | CD4 Count |
| `NCD4P` | CD4 Percentage |
| `CRYP` | Cryptococcal Latex |
| `THSR` | T Helper/Suppressor Ratio |
| `TBTXT` / `REM` | Remarks |

**CRAG Observation Codes:**

| LIMSObservationCode | Description |
|---------------------|-------------|
| `CRYP` | Cryptococcus result |
| `REM` | Remarks |

---

### Panel Code Summary Table

| LIMSPanelCode | LOINCPanelCode | Test Area | Type | Analytics View | Notes |
|---------------|----------------|-----------|------|----------------|-------|
| `HIVVL` | `25836-8` | HIV Viral Load | Results | viewVL_Result | Primary VL result panel |
| `VIRAL` | `25836-8` | HIV Viral Load | Metadata | viewVL_Info | Registration info panel |
| `PCR` | `9836-8` | HIV EID | Results | viewEID_Result | Conventional PCR |
| `POCED` | `9836-8` | HIV EID | Results | viewEID_Result | Point-of-care EID |
| `FSR` | `9836-8` | HIV EID | Metadata | viewEID_Info | Conventional EID info |
| `POFSR` | `9836-8` | HIV EID | Metadata | viewEID_Info | POC EID info |
| `PCRGX` | `38376-3` | TB GeneXpert | Results | viewTbGenexpert | Conventional GeneXpert |
| `POCGT` | `38376-3` | TB GeneXpert | Results | viewTbGenexpert | POC GeneXpert |
| `MTXDR` | — | TB MDR/XDR | Results | viewTbMTXDR | Drug resistance |
| `CD4` | `24467-3` | Advanced Disease | Results | viewCD4 | CD4 count |
| `TBLAM` | `94053-5` | Advanced Disease | Results | viewTBLAM | TB LAM antigen |
| `CRAG` | `31795-8` | Advanced Disease | Results | viewCryptococcus | CrAg test |

---

## 11. Analytics Datasets

Analytics datasets are **denormalized master tables** that store pre-extracted, pre-joined, and pre-enhanced laboratory data for a specific test type. They are generated by combining views, the Patients table, dictionary lookups, and computed/derived columns.

### Architecture

```
Views (pivot data)  →  Table-Valued Function  →  Analytics Dataset Table  →  Python ORM
```

### Existing Datasets

| Dataset | Test Type | Views Used | Includes Patients | Database Bind | Database Name |
|---------|-----------|-----------|-------------------|---------------|---------------|
| **VlData** | HIV Viral Load | `viewVL_Result` + `viewVL_Info` | Yes | `vl` | `ViralLoadData` |
| **EIDMaster** | HIV EID | `viewEID_Result` + `viewEID_Info` | Yes | `dpi` | DPI database |
| **TBMaster** | TB GeneXpert | `viewTbGenexpert` | Yes | `tb` | TB database |

### Planned Datasets

| Dataset | Test Type | Views to Use | Database Bind |
|---------|-----------|-------------|---------------|
| CD4 | Advanced Disease — CD4 | `viewCD4` | `ad` |
| CrAg | Advanced Disease — CrAg | `viewCryptococcus` | `ad` |
| TB-LAM | Advanced Disease — TB LAM | `viewTBLAM` | `ad` |

### Dataset Generation Process

1. **Identify the test and its views** — determine which views cover the test type
2. **Create the table-valued function** — SQL function accepting `(@startDate DATETIME, @endDate DATETIME)` that combines views + patients + computed columns
3. **Create the analytics dataset table** — DDL `CREATE TABLE` with all columns from the function
4. **Populate the table** — `INSERT ... SELECT * FROM getFunction(@start, @end)` for the full date range
5. **Create the Python ORM model** — SQLAlchemy model mapping to the dataset table

### Dataset Table Column Blocks (Standard Structure)

All datasets follow this column block pattern:

| Block | Source | Columns |
|-------|--------|---------|
| A — Patient info (optional) | Patients table | SURNAME, FIRSTNAME, DOB, NATIONALID, MOBILE, etc. |
| B — Demographics | Result view | AgeInDays, AgeInYears, HL7SexCode |
| C — Pre-registration timeline | Info view | LIMSPreReg_* timestamps |
| D — Core timeline | Result view | SpecimenDatetime, ReceivedDateTime, RegisteredDateTime, AnalysisDateTime, AuthorisedDateTime |
| E — Pivoted info columns | Info view | Test-specific metadata (pregnant, regimen, reason for test, etc.) |
| F — Pivoted result columns | Result view | Test-specific results (viral load value, PCR result, etc.) |
| G — Facility resolution | OpenLDRDict.viewFacilities | RequestingFacilityName, TestingFacilityName, ProvinceName, DistrictName, GPS |
| H — Computed/derived | Functions | AgeGroup, FinalResult, SuppressedFlag, year/month from dates |

### Why Use Analytics Datasets vs Raw Tables?

| Benefit | Explanation |
|---------|-------------|
| **Better Architecture** | Single table per test type instead of querying across Requests + LabResults + Patients + Dictionary |
| **Improved Data Quality** | Pre-cleaned data with NULL defaults, standardized values, and derived fields |
| **Better Query Performance** | Pre-joined and indexed single table eliminates complex multi-table joins at query time |
| **Single Test Focus** | Each dataset contains data for exactly one test type |
| **API-Ready** | The Python API ORM models map directly to these dataset tables |

---

## 12. Equipment and Analyzer Codes

The `LIMSAnalyzerCode` field in the Requests table identifies the testing instrument.

### HIV VL/EID Analyzers

| Code | Manufacturer | Platform |
|------|-------------|----------|
| `CAPCTM` | Roche | COBAS AmpliPrep/TaqMan |
| `C6800` | Roche | COBAS 6800 |
| `AL-IM` | Roche | Alinity m |
| `ALIND` | Roche | Alinity m |
| `ALINK` | Roche | Alinity m |
| `ALINA` | Roche | Alinity m |
| `ALINB` | Roche | Alinity m |
| `ALINC` | Roche | Alinity m |
| `M2000` | Abbott | m2000 |
| `M200A` | Abbott | m2000 |
| `PANTHER` | Hologic | Panther |
| `MPIMA` | Abbott | m-PIMA (POC) |
| `MANUAL` | — | Manual testing |

### TB GeneXpert Analyzers

GeneXpert instruments are identified by `TestingFacilityCode` mapping to DISA POC or Laboratory codes rather than a specific `LIMSAnalyzerCode`.

---

## 13. Rejection Codes

Common rejection codes found in `Requests.LIMSRejectionCode`:

| Code | Description |
|------|-------------|
| `REPIT` | Repeated sample |
| `SPUN2` | Specimen spun/centrifuged |
| `INS` | Insufficient sample |
| `UNS` | Unsuitable sample |
| `RSA` | Rejected — sample age |
| `NSRP` | No sample received |
| `SDBSA` | Specimen damaged |
| `ERRTC` | Error in test code |
| `ACC` | Acceptance issue |
| `PROBT` | Problem with transport |
| `SASOB` | Sample already submitted |
| `DUPRG` | Duplicate registration |
| `NAME` | Name mismatch |
| `AM30D` | Older than 30 days |

---

## 14. Key Metrics and Indicators

### HIV Viral Load
- **Suppression**: `FinalViralLoadResult` < 1000 copies/mL = "Suppressed"
- **Suppression Rate**: Percentage of tested patients with suppressed viral load
- **TAT**: Time from specimen collection to result authorization
- **FinalViralLoadResult** is computed: `ViralLoadFinalResult(HIVVD, COALESCE(HIVVR, HIVVC, HIVVF))`

### HIV EID (Early Infant Diagnosis)
- **Positivity**: `PCR_Result` = Positivo/Negativo
- **PCR vs POC**: Conventional lab PCR vs Point-of-Care testing
- **POC Detection**: Based on `LIMSAnalyzerCode` = 'MPIMA' or presence of HIV2/HIVMN/HIVO observation codes

### TB GeneXpert
- **MTB Detection**: `PcrResult` = detected/not detected
- **Rifampicin Resistance**: `Rifampicin` = Resistance Detected/Not Detected/Indeterminate
- **MTB Trace**: Low-level MTB detection (`GXTRA` observation code)

### Advanced Diseases
- **CD4 Count**: `CD4FinalResult` = COALESCE(CD4, NCD4, VCD4) — conventional CD4, POC CD4, or VCD4
- **CrAg**: Cryptococcal antigen detection for meningitis screening
- **TB-LAM**: Urine-based TB detection for HIV-positive patients

---

## 15. The Flexible Data Model (Pivot Pattern)

OpenLDR's most important design concept is its **hybrid horizontal-vertical data model**. Instead of creating fixed columns for every possible data element, supplementary information is stored as rows in the LabResults table.

### How It Works

A single specimen (`RequestID`) can have multiple panels (`OBRSetID`), and each panel can have multiple observation results. The `LIMSObservationCode` in LabResults identifies what each row represents.

**Example: HIV Viral Load request** has two panels:

| RequestID | OBRSetID | LIMSPanelCode | Purpose |
|-----------|----------|---------------|---------|
| REQ001 | 1 | HIVVL | Viral load test results |
| REQ001 | 2 | VIRAL | Registration/clinical metadata |

The **HIVVL** panel contains result observations:

| RequestID | OBRSetID | LIMSObservationCode | LIMSRptResult |
|-----------|----------|---------------------|---------------|
| REQ001 | 1 | HIVVD | 1500 |
| REQ001 | 1 | HIVVR | 1500 |
| REQ001 | 1 | HIVRL | 3.17 |

The **VIRAL** panel contains registration metadata:

| RequestID | OBRSetID | LIMSObservationCode | LIMSRptResult |
|-----------|----------|---------------------|---------------|
| REQ001 | 2 | ENCON | Yes |
| REQ001 | 2 | AMAME | No |
| REQ001 | 2 | LABDA | 2024-01-15 |
| REQ001 | 2 | ESCOL | Routine |

### Data Extraction: The Pivot Pattern

Views transform row-based data into columnar format using LEFT JOINs with filtered subqueries:

```sql
SELECT req.RequestID,
    preg.LIMSRptResult AS Pregnant,      -- From LIMSObservationCode = 'ENCON'
    bf.LIMSRptResult AS BreastFeeding,   -- From LIMSObservationCode = 'AMAME'
    cday.LIMSRptResult AS CollectedDate  -- From LIMSObservationCode = 'LABDA'
FROM Requests AS req
LEFT JOIN (
    SELECT * FROM LabResults WHERE LIMSObservationCode = 'ENCON'
) AS preg ON req.RequestID = preg.RequestID AND req.OBRSetID = preg.OBRSetID
LEFT JOIN (
    SELECT * FROM LabResults WHERE LIMSObservationCode = 'AMAME'
) AS bf ON req.RequestID = bf.RequestID AND req.OBRSetID = bf.OBRSetID
-- ... repeat for each observation code needed ...
```

---

## 16. Data Import

### XML Import File

Data enters OpenLDR via a **Standardized XML Import File**. The XML structure maps to HL7 segments:

```xml
<LDRImport>
    <Request>
        <!-- OBR segment fields -->
        <RequestID>...</RequestID>
        <OBRSetID>1</OBRSetID>
        <LIMSPanelCode>HIVVL</LIMSPanelCode>
        <!-- PID segment fields -->
        <HL7SexCode>F</HL7SexCode>
        <AgeInYears>34</AgeInYears>
        <!-- Facility fields -->
        <RequestingFacilityCode>0110</RequestingFacilityCode>
        <TestingFacilityCode>HPM</TestingFacilityCode>
    </Request>
    <LabResult>
        <!-- OBX segment fields -->
        <RequestID>...</RequestID>
        <OBRSetID>1</OBRSetID>
        <OBXSetID>1</OBXSetID>
        <LIMSObservationCode>HIVVD</LIMSObservationCode>
        <LIMSRptResult>1500</LIMSRptResult>
    </LabResult>
</LDRImport>
```

### MirthConnect Integration

**MirthConnect** middleware supports electronic data integration from LIMS systems, transforming proprietary formats into the OpenLDR XML import format.

---

## 17. WHONET Integration

Three views export data in WHONET-compatible format for antimicrobial resistance surveillance:

- **WHONET_AST**: Antimicrobial susceptibility test results
- **WHONET_LabResults**: General lab results for immunology, microbiology, mycology, parasitology, virology sections
- **WHONET_MONITORING**: Monitoring data with organism identifications

These views join `LabResults` with `Requests` and `OpenLDRDict.Facilities`, filtering by `HL7SectionCode` values: `IMM`, `MB`, `MCB`, `MYC`, `PAR`, `TX`, `SP`, `VR`.

---

## 18. OpenLDRDict — Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    OpenLDRDict Database                          │
│                                                                  │
│  ┌──────────────────┐     ┌──────────────────────┐              │
│  │   Facilities      │     │   HealthcareAreas     │              │
│  │──────────────────│     │──────────────────────│              │
│  │ FacilityCode (PK)│     │ HealthcareAreaCode(PK)│              │
│  │ Description       │     │ HealthcareAreaDesc    │              │
│  │ FacilityType      │────>│ LattLong              │              │
│  │ CountryCode       │  *  └──────────────────────┘              │
│  │ ProvinceCode      │  * joined via code concatenation          │
│  │ DistrictCode      │     (CountryCode+ProvinceCode+            │
│  │ SubDistrictCode   │      DistrictCode = HealthcareAreaCode)   │
│  │ LattLong          │                                           │
│  │ HFStatus          │                                           │
│  └──────┬───────────┘                                           │
│         │ FacilityCode                                           │
│    ┌────┴────┐                                                   │
│    │         │                                                   │
│    ▼         ▼                                                   │
│  ┌────────────┐  ┌──────────────┐                               │
│  │ HFLattLong  │  │ Laboratories  │                               │
│  │────────────│  │──────────────│                               │
│  │FacilityCode│  │ LabCode (PK) │                               │
│  │  (PK, FK)  │  │ FacilityCode │                               │
│  │Latt        │  │   (FK)       │                               │
│  │Long        │  │ LabName      │                               │
│  │LattLong    │  │ LabType      │                               │
│  └────────────┘  │ LIMSVendor   │                               │
│                   │ StaffingLevel│                               │
│                   └──────────────┘                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              viewFacilities (SQL VIEW)                    │    │
│  │  = Facilities + HealthcareAreas + HFLattLong             │    │
│  │  Pre-joined with resolved names at all geographic levels │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌──────────┐  ┌──────────┐                                     │
│  │ DisaPoc   │  │ Disalink  │    (Mozambique-specific tables)    │
│  │──────────│  │──────────│                                     │
│  │DisaPocCode│  │DlinkCode │                                     │
│  │DisaPocName│  │DlinkName │                                     │
│  │Province   │  │Province  │                                     │
│  │District   │  │District  │                                     │
│  └──────────┘  └──────────┘                                     │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Reference/Lookup Tables                      │    │
│  │  LOINC | HL7* (9 tables) | MDRCodes | Surveillance      │    │
│  │  Analyzers | VersionControl                              │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### How OpenLDRDict Connects to Data Databases

```
┌─────────────────────────────────────────────────────────────┐
│                     OpenLDRDict                              │
│  viewFacilities | Laboratories | HL7* | LOINC               │
└──────────┬──────────────┬──────────────┬────────────────────┘
           │              │              │
     ┌─────┴─────┐  ┌────┴────┐  ┌─────┴─────┐
     │ TB Data    │  │ VL Data  │  │ EID Data   │
     │ (tb bind)  │  │ (vl bind)│  │ (dpi bind) │
     │ TBMaster   │  │ VlData   │  │ EIDMaster  │
     │.Testing    │  │.Testing  │  │.Requesting │
     │ FacilityCode─┼──────────┼──┼──►viewFac  │
     │.LOINCCode ──┼──────────┼──┼──► LOINC    │
     │.HL7SexCode──┼──────────┼──┼──► HL7Sex   │
     └────────────┘  └─────────┘  └────────────┘
```

---

## 19. Common Terminology (Glossary)

| Term | Definition |
|------|-----------|
| **OpenLDR** | Open Laboratory Data Repository — centralized electronic data storage for country-wide laboratory requests and results |
| **OpenLDRData** | The operational database containing all test requests and results (Requests, LabResults, Monitoring, ASTResults, Patients tables) |
| **OpenLDRDict** | The dictionary/reference database containing facilities, geographic hierarchy, HL7 codes, and LOINC data |
| **LIMS** | Laboratory Information Management System — the source system (e.g., DISA, Meditech) that sends data to OpenLDR |
| **HL7** | Health Level 7 — international standard for exchange of electronic health information. OpenLDR column names follow HL7 v2.5 segment naming conventions |
| **OBR** | Observation Request — HL7 segment representing a test order/request. Maps to the Requests table |
| **OBX** | Observation Result — HL7 segment representing an individual result. Maps to the LabResults table |
| **PID** | Patient Identification — HL7 segment with patient demographics. Maps to parts of the Requests table and the Patients table |
| **PV1** | Patient Visit — HL7 segment with visit/encounter info. Maps to parts of the Requests table |
| **LOINC** | Logical Observation Identifiers Names and Codes — international standard for identifying laboratory tests. Used in `LOINCCode` and `LOINCPanelCode` fields |
| **LIMSPanelCode** | LIMS vendor-specific code identifying the type of test/panel (e.g., HIVVL, VIRAL, PCRGX, FSR) |
| **LIMSObservationCode** | LIMS vendor-specific code identifying a specific observation within a panel (e.g., HIVVD for viral load value, ENCON for pregnancy status) |
| **RequestID** | Unique specimen/request identifier (varchar 26) — the primary key for all test data |
| **OBRSetID** | Panel sequence number within a request — distinguishes multiple test panels for the same specimen |
| **OBXSetID** | Result sequence number within a panel — distinguishes multiple result rows for the same panel |
| **Pivot** | The technique of converting vertical row-based data (one LIMSObservationCode per row) into horizontal columnar data (one column per observation code) |
| **TAT** | Turnaround Time — the time elapsed between key events (collection → registration → analysis → authorization) |
| **POC** | Point of Care — testing performed at the health facility rather than a central laboratory |
| **DISA** | Laboratory Information System used in Mozambique. Gives rise to DISA POC (point-of-care sites) and DISA Link (transport hubs) |
| **ART** | Antiretroviral Therapy — treatment for HIV. ART start date and regimen are tracked in VIRAL panel metadata |
| **PMTCT** | Prevention of Mother-to-Child Transmission — HIV prevention program. EID testing is part of PMTCT |
| **EID** | Early Infant Diagnosis — PCR testing of infants for HIV infection |
| **VL** | Viral Load — quantitative measurement of HIV RNA copies/mL in blood |
| **GeneXpert** | Cepheid's molecular diagnostic platform for TB detection (PCRGX/POCGT panels) |
| **MTB** | Mycobacterium tuberculosis — the bacterium causing TB |
| **MDR** | Multi-Drug Resistant — TB resistant to at least rifampicin and isoniazid |
| **XDR** | Extensively Drug Resistant — TB resistant to rifampicin, isoniazid, and at least one second-line drug |
| **CD4** | CD4+ T-lymphocyte count — measure of immune system health in HIV patients |
| **CrAg** | Cryptococcal Antigen — test for Cryptococcus meningitis screening |
| **TB-LAM** | TB Lipoarabinomannan — urine-based TB antigen test for HIV-positive patients |
| **FacilityCode** | Primary key for health facilities in OpenLDRDict.Facilities — used to join across all data and dictionary tables |
| **HealthcareAreaCode** | Concatenated geographic code (Country+Province+District) used to join Facilities with HealthcareAreas |
| **Bind Key** | SQLAlchemy database binding key used in Flask API to route queries to the correct database (`vl`, `tb`, `dpi`, `ad`, `dict`) |
| **viewFacilities** | The primary facility view in OpenLDRDict that pre-joins Facilities + HealthcareAreas + HFLattLong with resolved province/district names |
| **VlData** | The HIV Viral Load analytics dataset table in the `ViralLoadData` database |
| **EIDMaster** | The HIV EID analytics dataset table in the DPI database |
| **TBMaster** | The TB GeneXpert analytics dataset table in the TB database |
| **DBS** | Dried Blood Spot — a specimen collection method for HIV EID testing in infants |
| **MirthConnect** | Open-source integration engine used to transform LIMS data formats into OpenLDR XML import format |
| **WHONET** | WHO antimicrobial resistance database software — OpenLDR exports data in WHONET-compatible format via WHONET_AST, WHONET_LabResults, WHONET_MONITORING views |

---

*This reference guide is extracted from OpenLDR documentation (May 2018 schema) and implementation files as of 2026-04-02. For live database queries, use the openldr-explore skill's database connectivity tools.*
