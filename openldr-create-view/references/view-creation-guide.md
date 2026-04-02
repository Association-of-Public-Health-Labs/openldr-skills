# OpenLDR View Creation Reference Guide

## Purpose

OpenLDR stores laboratory data in a **vertical (row-based) format** where each observation is a separate row in the `LabResults` table, identified by a `LIMSObservationCode`. SQL Views transform this vertical data into a **horizontal (column-based) format** where each observation becomes a named column, making the data suitable for reporting, analytics, and dashboards.

This document is the authoritative knowledge base for creating any OpenLDR view.

---

## 1. Panel-to-Observation-Code Mappings

Each panel has a defined set of `LIMSObservationCode` values. These codes are pivoted into columns using the Sub-Select Join Pattern described in Section 2.

> **Note**: A NULL Default of `'Unreported'` means the column should use `ISNULL(alias.LIMSRptResult, 'Unreported')`. A NULL Default of `NULL` means no ISNULL wrapper is needed — let the value be NULL when absent.

---

### Panel: VIRAL (HIV Viral Load Registration / Info)

View: `viewVL_Info` — Panel filter: `WHERE req.LIMSPanelCode = 'VIRAL'`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `ENCON` | Pregnant | Patient Clinical Status | Is patient pregnant? | `'Unreported'` |
| `AMAME` | BreastFeeding | Patient Clinical Status | Is patient breastfeeding? | `'Unreported'` |
| `VIRAP` | FirstTime | Patient Clinical Status | Is this the first VL test? | `'Unreported'` |
| `LABDA` | CollectedDate | Specimen Collection | Date of specimen collection | `'Unreported'` |
| `LABHO` | CollectedTime | Specimen Collection | Time of specimen collection | `NULL` |
| `TARVD` | DataDeInicioDoTARV | ART Treatment | ART (antiretroviral therapy) start date | `NULL` |
| `TARVP` | PrimeiraLinha | ART Treatment | First-line ART regimen | `NULL` |
| `TARVS` | SegundaLinha | ART Treatment | Second-line ART regimen | `NULL` |
| `TARVQ` | ARTRegimen | ART Treatment | Current ART regimen code | `NULL` |
| `ESCOL` | ReasonForTest | Previous Results & Clinical Context | Reason for the VL test (often resolved via `GetReasonForTest` function) | `'Reason Not Specified'` |
| `LABTI` | TypeOfSampleCollection | Specimen Collection | How was the sample collected (DBS, venepuncture, etc.)? | `NULL` |
| `VIRAD` | LastViralLoadDate | Previous Results & Clinical Context | Date of the patient's last viral load test | `NULL` |
| `VIRR1` | LastViralLoadResult | Previous Results & Clinical Context | Result of the patient's last viral load test | `NULL` |
| `LABNO` | RequestingClinician | Contact & Consent | Name of the requesting clinician | `NULL` |
| `CONSE` | ConsentimentoParaContacto | Contact & Consent | Patient consent for follow-up contact | `NULL` |
| `LABLO` | LocalDeColheita | Specimen Collection | Collection location / point of care description | `NULL` |

---

### Panel: HIVVL (HIV Viral Load Results)

View: `viewVL_Result` — Panel filter: `WHERE req.LIMSPanelCode = 'HIVVL'`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `HIVVD` | HIVVL_ViralLoadResult | VL Results | Viral load numeric result (copies/mL); often merged with LIMSCodedValue via `ViralLoadResultMerge` function | `NULL` |
| `HIVVR` | HIVVL_ViralLoadResultCategory | VL Results | Viral load category (e.g., Suppressed, Unsuppressed) | `NULL` |
| `HIVVC` | HIVVL_ViralLoadCopies | VL Results | Viral load copies value from coded field | `NULL` |
| `HIVVF` | HIVVL_ViralLoadFlag | VL Results | Viral load result flag (e.g., detectable, undetectable) | `NULL` |
| `HIVRL` | HIVVL_RejectReason | VL Results | Rejection reason for the VL result | `NULL` |

---

### Panel: PCRGX / POCGT (TB GeneXpert — Conventional and Point-of-Care)

View: `viewTbGenexpert` — Panel filter: `WHERE req.LIMSPanelCode IN ('PCRGX', 'POCGT')`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `GEND` | GeneXpertDevice | Metadata | GeneXpert device or instrument identifier | `NULL` |
| `!GX` | GeneXpertBarcode | Metadata | GeneXpert cartridge barcode / sample identifier | `NULL` |
| `GXRIF` | RifampicinResistance | Drug Resistance | Rifampicin resistance result (DET = detected, NDET = not detected, Indeterminate) | `NULL` |
| `GXTB` | TBDetected | TB Detection | TB detected result (e.g., DETECTED, NOT DETECTED, INVALID) | `NULL` |
| `GXTBR` | TBResult | TB Detection | TB result description / categorization | `NULL` |
| `GXTRA` | TraceResult | TB Detection | Trace-level TB detection result | `NULL` |
| `HCOM` | HighRiskComment | Metadata | High-risk comment or clinical note | `NULL` |
| `RJREA` | RejectionReason | Metadata | Reason for specimen rejection | `NULL` |
| `RJREM` | RejectionRemarks | Metadata | Additional rejection remarks | `NULL` |
| `TBTXT` | TBTextResult | TB Detection | Free-text TB result or comments | `NULL` |

---

### Panel: FSR / POFSR (HIV EID Registration / Info — Conventional and POC)

View: `viewEID_Info` — Panel filter: `WHERE req.LIMSPanelCode IN ('FSR', 'POFSR')`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `AGE` | PatientAge | Patient Info | Patient age (in appropriate units) | `NULL` |
| `ALEIC` | ALEICCode | Clinical | Clinical classification code (ALEIC = Algoritmo Local EID Code) | `NULL` |
| `ALEIT` | ALEITCode | Clinical | Clinical text description for ALEIC code | `NULL` |
| `CONSE` | ConsentimentoParaContacto | Patient Info | Patient consent for follow-up contact | `NULL` |
| `EIDCM` | EIDClinicalManagement | Clinical | EID clinical management notes | `NULL` |
| `EIDCN` | EIDClinicalNotes | Clinical | Additional EID clinical notes | `NULL` |
| `EIDCP` | EIDClinicalProfile | Clinical | EID clinical profile / patient status | `NULL` |
| `EIDDT` | EIDDispatchDate | Patient Info | Date the EID sample was dispatched | `NULL` |
| `EIDID` | EIDID | Patient Info | EID identifier / reference number | `NULL` |
| `EIDRS` | EIDResultStatus | Clinical | EID result status code | `NULL` |
| `PCRAN` | PCRAnalysisNote | Qualifications | PCR analysis note | `NULL` |
| `PCRF` | PCRFlag | Qualifications | PCR quality flag | `NULL` |
| `PORS` | POCResultStatus | Qualifications | Point-of-care result status | `NULL` |
| `PTVC` | PTVCCode | Clinical | PTVC clinical code (Prevention of Transmission Vertical) | `NULL` |
| `PTVM` | PTVMCode | Clinical | PTVM clinical management code | `NULL` |
| `QUALF` | Qualification | Qualifications | Test qualification or accreditation flag | `NULL` |

---

### Panel: PCR / POCED (HIV EID PCR Results — Conventional and POC)

View: `viewEID_Result` / `viewPCR` — Panel filter: `WHERE req.LIMSPanelCode IN ('PCR', 'POCED')`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `HIVPC` | HIVPCRResult | PCR Results | HIV PCR result (e.g., DETECTED, NOT DETECTED) | `NULL` |
| `HIVVR` | HIVViralLoadResult | PCR Results | HIV viral load result associated with EID PCR | `NULL` |
| `HIVVD` | HIVViralLoadDetailed | PCR Results | Detailed HIV viral load value | `NULL` |
| `HIVRL` | HIVRejectReason | PCR Results | Rejection reason for HIV test | `NULL` |
| `PII1` | PCRInhibition1 | PCR Results | PCR inhibition indicator (first run) | `NULL` |
| `HIV2` | HIV2Result | Additional Markers | HIV-2 specific result | `NULL` |
| `HIVMN` | HIVMutationNote | Additional Markers | HIV mutation or variant note | `NULL` |
| `HIVO` | HIVOtherResult | Additional Markers | Other HIV-related observation | `NULL` |
| `TXT` | TextResult | Additional Markers | Free-text result or comment | `NULL` |
| `HIVVC` / `HIVVF` | HIVCopies / HIVFlag | PCR Results | HIV copies value / viral load flag (may appear as separate codes depending on vendor) | `NULL` |

---

### Panel: MTXDR (TB Molecular Drug Resistance)

View: `viewTbMTXDR` — Panel filter: `WHERE req.LIMSPanelCode = 'MTXDR'`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `GEND` | GeneXpertDevice | Metadata | GeneXpert / MTXDR device identifier | `NULL` |
| `GXFLQ` | FluoroquinoloneResistance | Drug Resistance | Fluoroquinolone resistance result | `NULL` |
| `GXISO` / `GXINH` | IsoniazidResistance | Drug Resistance | Isoniazid resistance result (code varies by vendor: GXISO or GXINH) | `NULL` |
| `GXKAN` | KanamycinResistance | Drug Resistance | Kanamycin resistance result | `NULL` |
| `GXAMI` | AmikacinResistance | Drug Resistance | Amikacin resistance result | `NULL` |
| `GXCAP` | CapreomycinResistance | Drug Resistance | Capreomycin resistance result | `NULL` |
| `GXETH` | EthambutolResistance | Drug Resistance | Ethambutol resistance result | `NULL` |
| `GXRIF` | RifampicinResistance | Drug Resistance | Rifampicin resistance result | `NULL` |
| `GXTBR` | TBResult | TB Detection | TB result description / categorization | `NULL` |
| `GXTB` | TBDetected | TB Detection | TB detected flag | `NULL` |

---

### Panel: TBLAM (TB LAM — Lipoarabinomannan Antigen Test)

View: `viewTBLAM` — Panel filter: `WHERE req.LIMSPanelCode = 'TBLAM'`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `TBLAM` | TBLAMResult | TB LAM Results | TB LAM antigen test result (e.g., POSITIVE, NEGATIVE) | `NULL` |
| `CD4TX` | CD4TextResult | TB LAM Results | CD4 count text descriptor accompanying LAM result | `NULL` |
| `NCD4` | CD4AbsoluteCount | TB LAM Results | Absolute CD4 cell count (cells/µL) | `NULL` |
| `NCD4P` | CD4Percentage | TB LAM Results | CD4 percentage of total lymphocytes | `NULL` |
| `CRYP` | CryptococcalResult | TB LAM Results | Cryptococcal antigen (CrAg) result | `NULL` |
| `THSR` | THSRCode | TB LAM Results | THSR (test/health system result) classification code | `NULL` |
| `TBTXT` / `REM` | TBTextResult / Remarks | TB LAM Results | Free-text TB result or general remarks (code varies by implementation) | `NULL` |

---

### Panel: CRAG (Cryptococcal Antigen)

View: `viewCryptococcus` — Panel filter: `WHERE req.LIMSPanelCode = 'CRAG'`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `CRYP` | CryptococcalResult | Cryptococcal Results | Cryptococcal antigen (CrAg) test result (e.g., POSITIVE, NEGATIVE) | `NULL` |
| `REM` | Remarks | Cryptococcal Results | General remarks or additional notes for the CrAg result | `NULL` |

---

### Panel: CD4 (CD4 Cell Count)

View: `viewCD4` — Panel filter: `WHERE req.LIMSPanelCode = 'CD4'`

| LIMSObservationCode | Column Alias | Group | Description | NULL Default |
|---------------------|-------------|-------|-------------|-------------|
| `CBAC` | CD4BaselineCount | Cell Counts | Baseline CD4 count (cells/µL) | `NULL` |
| `CD3` | CD3AbsoluteCount | Cell Counts | Absolute CD3 T-cell count | `NULL` |
| `CD3L` | CD3Lymphocytes | Cell Counts | CD3 lymphocyte count | `NULL` |
| `CD4` | CD4AbsoluteCount | Cell Counts | Absolute CD4 T-cell count (cells/µL) | `NULL` |
| `VCD4` | VCD4Count | Cell Counts | Variant CD4 count (vendor-specific) | `NULL` |
| `CD4L` | CD4Lymphocytes | Cell Counts | CD4 lymphocyte count | `NULL` |
| `THSR` | THSRCode | Percentages | THSR (test/health system result) classification code | `NULL` |
| `NCD4` | CD4CountNumeric | Percentages | Numeric CD4 count (may differ from CD4 in format) | `NULL` |
| `NCD4L` | CD4LymphocytesNumeric | Percentages | Numeric CD4 lymphocyte value | `NULL` |
| `NCD4P` | CD4Percentage | Percentages | CD4 percentage of total lymphocytes | `NULL` |
| `CD4TX` | CD4TextResult | Text | CD4 count text descriptor or interpretation | `NULL` |
| `TXT` | TextResult | Text | Free-text result or clinical comment | `NULL` |

---

## 2. View Template

Every OpenLDR view follows this exact structure. Replace `{Name}`, `{alias}`, `{ColumnName}`, `{CODE}`, and `{PANEL_CODE}` with real values.

```sql
CREATE VIEW [dbo].[view{Name}]
AS
SELECT
    -- ========================================================
    -- SECTION 1: Request identification
    -- ========================================================
    req.RequestID,
    req.OBRSetID,
    req.LIMSPanelCode,
    req.LIMSPanelDesc,

    -- ========================================================
    -- SECTION 2: Pivoted observation columns (THE CORE)
    -- One column per LIMSObservationCode
    -- ========================================================
    {alias}.LIMSRptResult AS {ColumnName},
    -- ... repeat for each observation code ...

    -- ========================================================
    -- SECTION 3: Demographics and dates from Requests
    -- ========================================================
    req.AgeInYears,
    req.AgeInDays,
    req.HL7SexCode,
    req.SpecimenDatetime,
    req.RegisteredDateTime,
    req.ReceivedDateTime,
    req.AnalysisDateTime,
    req.AuthorisedDateTime,
    req.LIMSRejectionCode,
    req.LIMSRejectionDesc,

    -- ========================================================
    -- SECTION 4: Timestamps and versioning
    -- ========================================================
    req.DateTimeStamp,
    req.Versionstamp,
    req.LIMSDateTimeStamp,
    req.LIMSVersionstamp,

    -- ========================================================
    -- SECTION 5: Additional request metadata
    -- ========================================================
    req.LOINCPanelCode,
    req.HL7PriorityCode,
    req.AdmitAttendDateTime,
    req.CollectionVolume,

    -- ========================================================
    -- SECTION 6: Facility resolution (4 facility types)
    -- ========================================================
    -- LIMS Facility
    req.LIMSFacilityCode,
    limsFacility.[Description] AS LIMSFacilityName,
    limsFacility.ProvinceName AS LIMSProvinceName,
    limsFacility.DistrictName AS LIMSDistrictName,
    -- Requesting Facility
    req.RequestingFacilityCode,
    requestingFacility.[Description] AS RequestingFacilityName,
    requestingFacility.ProvinceName AS RequestingProvinceName,
    requestingFacility.DistrictName AS RequestingDistrictName,
    -- Receiving Facility (with DisaPoc fallback)
    req.ReceivingFacilityCode,
    ISNULL(receivingFacility.[Description], disapocReceivingFacility.DisaPocName)
        AS ReceivingFacilityName,
    ISNULL(receivingFacility.ProvinceName, disapocReceivingFacility.DisaPocProvinceName)
        AS ReceivingProvinceName,
    ISNULL(receivingFacility.DistrictName, disapocReceivingFacility.DisapocDistrictName)
        AS ReceivingDistrictName,
    -- Testing Facility (with DisaPoc and Laboratories fallback)
    req.TestingFacilityCode,
    CASE WHEN testingFacility.[Description] IS NOT NULL THEN testingFacility.[Description]
         WHEN testingDisapoc.DisaPocName IS NOT NULL THEN testingDisapoc.DisaPocName
         ELSE testingLab.LabName
    END AS TestingFacilityName,
    ISNULL(testingFacility.ProvinceName, testingDisapoc.DisaPocProvinceName)
        AS TestingProvinceName,
    ISNULL(testingFacility.DistrictName, testingDisapoc.DisapocDistrictName)
        AS TestingDistrictName,

    -- ========================================================
    -- SECTION 7: Remaining request fields
    -- ========================================================
    req.LIMSPointOfCareDesc,
    req.RequestTypeCode,
    req.ICD10ClinicalInfoCodes,
    req.ClinicalInfo,
    req.HL7SpecimenSourceCode,
    req.LIMSSpecimenSourceCode,
    req.LIMSSpecimenSourceDesc,
    req.HL7SpecimenSiteCode,
    req.LIMSSpecimenSiteCode,
    req.LIMSSpecimenSiteDesc,
    req.WorkUnits,
    req.CostUnits,
    req.HL7SectionCode,
    req.HL7ResultStatusCode,
    req.RegisteredBy,
    req.TestedBy,
    req.AuthorisedBy,
    req.OrderingNotes,
    req.EncryptedPatientID,
    req.HL7EthnicGroupCode,
    req.Deceased,
    req.Newborn,
    req.HL7PatientClassCode,
    req.AttendingDoctor,
    req.ReferringRequestID,
    req.Therapy,
    req.LIMSAnalyzerCode,
    req.TargetTimeDays,
    req.TargetTimeMins,
    req.Repeated

-- ========================================================
-- SECTION 8: FROM — Base table is always Requests
-- ========================================================
FROM Requests AS req

-- ========================================================
-- SECTION 9: OBSERVATION CODE JOINS — One per pivoted column
-- ========================================================
LEFT JOIN (
    SELECT RequestID, OBRSetID, LIMSRptResult
    FROM LabResults WHERE LIMSObservationCode = '{CODE1}'
) AS {alias1} ON req.RequestID = {alias1}.RequestID
             AND req.OBRSetID   = {alias1}.OBRSetID
-- ... repeat for each observation code ...

-- ========================================================
-- SECTION 10: DICTIONARY JOINS — Facility resolution
-- ========================================================
-- LIMS Facility
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS limsFacility
    ON req.LIMSFacilityCode = limsFacility.FacilityCode
-- Requesting Facility
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS requestingFacility
    ON req.RequestingFacilityCode = requestingFacility.FacilityCode
-- Receiving Facility
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS receivingFacility
    ON req.ReceivingFacilityCode = receivingFacility.FacilityCode
-- Testing Facility
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS testingFacility
    ON req.TestingFacilityCode = testingFacility.FacilityCode
-- Testing Lab
LEFT JOIN OpenLDRDict.dbo.Laboratories AS testingLab
    ON req.TestingFacilityCode = testingLab.LabCode
-- Testing DisaPoc
LEFT JOIN OpenLDRDict.dbo.DisaPoc AS testingDisapoc
    ON LEFT(testingDisapoc.DisaPocLabNo, 3) = req.TestingFacilityCode
    AND testingDisapoc.DisapocState = 1
-- Receiving DisaPoc
LEFT JOIN OpenLDRDict.dbo.DisaPoc AS disapocReceivingFacility
    ON req.ReceivingFacilityCode = LEFT(disapocReceivingFacility.DisaPocLabNo, 3)
    AND disapocReceivingFacility.DisapocState = 1

-- ========================================================
-- WHERE: Filter by panel code(s)
-- ========================================================
WHERE req.LIMSPanelCode = '{PANEL_CODE}'
-- For multiple panels: WHERE req.LIMSPanelCode IN ('{CODE1}', '{CODE2}')
```

### Observation JOIN Pattern (Detail)

Each observation code becomes exactly one LEFT JOIN:

```sql
LEFT JOIN (
    SELECT RequestID, OBRSetID, LIMSRptResult
    FROM LabResults
    WHERE LIMSObservationCode = '{OBSERVATION_CODE}'
) AS {alias} ON req.RequestID = {alias}.RequestID
             AND req.OBRSetID   = {alias}.OBRSetID
```

**Rules:**

| Rule | Details |
|------|---------|
| Always use LEFT JOIN | Never INNER JOIN — observations may be absent for some requests |
| Always join on both keys | `RequestID` AND `OBRSetID` — both are required for correct matching |
| Filter inside the subquery | `WHERE LIMSObservationCode = '...'` goes INSIDE the subquery, not in the outer WHERE |
| Use descriptive aliases | e.g., `preg` for pregnancy, `bf` for breastfeeding, `rifRes` for rifampicin resistance |
| Select specific columns | Prefer `SELECT RequestID, OBRSetID, LIMSRptResult` over `SELECT *` for performance |

**SELECT clause patterns:**

```sql
-- Simple: direct column reference
{alias}.LIMSRptResult AS {ColumnName}

-- With NULL handling
ISNULL({alias}.LIMSRptResult, 'Unreported') AS {ColumnName}

-- With CASE default
CASE WHEN {alias}.LIMSRptResult IS NULL THEN 'Unreported'
     ELSE {alias}.LIMSRptResult
END AS {ColumnName}

-- With value transformation (e.g., drug resistance codes)
CASE WHEN {alias}.LIMSRptResult IN ('DET')           THEN 'Resistance Detected'
     WHEN {alias}.LIMSRptResult IN ('NDET')          THEN 'Resistance Not Detected'
     WHEN {alias}.LIMSRptResult IN ('Indeterminate') THEN 'Resistance Indeterminate'
     ELSE {alias}.LIMSRptResult
END AS {ColumnName}

-- When you also need LIMSCodedValue from the same observation
LEFT JOIN (
    SELECT RequestID, OBRSetID, LIMSRptResult, LIMSCodedValue
    FROM LabResults WHERE LIMSObservationCode = '{CODE}'
) AS {alias} ON req.RequestID = {alias}.RequestID
             AND req.OBRSetID   = {alias}.OBRSetID
-- Then in SELECT:
{alias}.LIMSRptResult  AS {ResultColumnName},
{alias}.LIMSCodedValue AS {CodedColumnName}
```

---

## 3. Facility Resolution Patterns

Every view must resolve four facility types. Each type has a different resolution pattern depending on whether fallback sources are needed.

### Pattern A — Simple (LIMS Facility and Requesting Facility)

Use when the facility code is a standard health facility code that will always resolve against `viewFacilities`.

```sql
-- JOIN:
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS {alias}
    ON req.{FacilityCodeField} = {alias}.FacilityCode

-- SELECT:
req.{FacilityCodeField},
{alias}.[Description] AS {Prefix}FacilityName,
{alias}.ProvinceName  AS {Prefix}ProvinceName,
{alias}.DistrictName  AS {Prefix}DistrictName
```

### Pattern B — With DisaPoc Fallback (Receiving Facility)

The receiving facility code may be a DISA POC lab number prefix (3 characters) rather than a standard facility code. Use `ISNULL` to fall back to `DisaPoc` when `viewFacilities` returns nothing.

```sql
-- JOIN:
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS receivingFacility
    ON req.ReceivingFacilityCode = receivingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.DisaPoc AS disapocReceivingFacility
    ON req.ReceivingFacilityCode = LEFT(disapocReceivingFacility.DisaPocLabNo, 3)
    AND disapocReceivingFacility.DisapocState = 1

-- SELECT:
req.ReceivingFacilityCode,
ISNULL(receivingFacility.[Description], disapocReceivingFacility.DisaPocName)
    AS ReceivingFacilityName,
ISNULL(receivingFacility.ProvinceName, disapocReceivingFacility.DisaPocProvinceName)
    AS ReceivingProvinceName,
ISNULL(receivingFacility.DistrictName, disapocReceivingFacility.DisapocDistrictName)
    AS ReceivingDistrictName
```

### Pattern C — 3-Level Cascade: viewFacilities > DisaPoc > Laboratories (Testing Facility)

The testing facility code may be a health facility code, a DISA POC code, or a laboratory code. Use a CASE cascade for the name, and ISNULL for province/district.

**Priority order: `viewFacilities` first, then `DisaPoc`, then `Laboratories`.**

```sql
-- JOIN:
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS testingFacility
    ON req.TestingFacilityCode = testingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.Laboratories AS testingLab
    ON req.TestingFacilityCode = testingLab.LabCode
LEFT JOIN OpenLDRDict.dbo.DisaPoc AS testingDisapoc
    ON LEFT(testingDisapoc.DisaPocLabNo, 3) = req.TestingFacilityCode
    AND testingDisapoc.DisapocState = 1

-- SELECT:
req.TestingFacilityCode,
CASE WHEN testingFacility.[Description] IS NOT NULL THEN testingFacility.[Description]
     WHEN testingDisapoc.DisaPocName IS NOT NULL    THEN testingDisapoc.DisaPocName
     ELSE testingLab.LabName
END AS TestingFacilityName,
ISNULL(testingFacility.ProvinceName, testingDisapoc.DisaPocProvinceName)
    AS TestingProvinceName,
ISNULL(testingFacility.DistrictName, testingDisapoc.DisapocDistrictName)
    AS TestingDistrictName
```

### Complete Facility Joins Block (Copy-Paste Ready)

```sql
-- == LIMS Facility ==
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS limsFacility
    ON req.LIMSFacilityCode = limsFacility.FacilityCode
-- == Requesting Facility ==
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS requestingFacility
    ON req.RequestingFacilityCode = requestingFacility.FacilityCode
-- == Receiving Facility (with DisaPoc fallback) ==
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS receivingFacility
    ON req.ReceivingFacilityCode = receivingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.DisaPoc AS disapocReceivingFacility
    ON req.ReceivingFacilityCode = LEFT(disapocReceivingFacility.DisaPocLabNo, 3)
    AND disapocReceivingFacility.DisapocState = 1
-- == Testing Facility (with DisaPoc + Lab fallback) ==
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS testingFacility
    ON req.TestingFacilityCode = testingFacility.FacilityCode
LEFT JOIN OpenLDRDict.dbo.Laboratories AS testingLab
    ON req.TestingFacilityCode = testingLab.LabCode
LEFT JOIN OpenLDRDict.dbo.DisaPoc AS testingDisapoc
    ON LEFT(testingDisapoc.DisaPocLabNo, 3) = req.TestingFacilityCode
    AND testingDisapoc.DisapocState = 1
```

### Complete Facility SELECT Block (Copy-Paste Ready)

```sql
-- LIMS Facility
req.LIMSFacilityCode,
limsFacility.[Description] AS LIMSFacilityName,
limsFacility.ProvinceName  AS LIMSProvinceName,
limsFacility.DistrictName  AS LIMSDistrictName,
-- Requesting Facility
req.RequestingFacilityCode,
requestingFacility.[Description] AS RequestingFacilityName,
requestingFacility.ProvinceName  AS RequestingProvinceName,
requestingFacility.DistrictName  AS RequestingDistrictName,
-- Receiving Facility (with DisaPoc fallback)
req.ReceivingFacilityCode,
ISNULL(receivingFacility.[Description], disapocReceivingFacility.DisaPocName)
    AS ReceivingFacilityName,
ISNULL(receivingFacility.ProvinceName, disapocReceivingFacility.DisaPocProvinceName)
    AS ReceivingProvinceName,
ISNULL(receivingFacility.DistrictName, disapocReceivingFacility.DisapocDistrictName)
    AS ReceivingDistrictName,
-- Testing Facility (with DisaPoc + Lab fallback)
req.TestingFacilityCode,
CASE WHEN testingFacility.[Description] IS NOT NULL THEN testingFacility.[Description]
     WHEN testingDisapoc.DisaPocName IS NOT NULL    THEN testingDisapoc.DisaPocName
     ELSE testingLab.LabName
END AS TestingFacilityName,
ISNULL(testingFacility.ProvinceName, testingDisapoc.DisaPocProvinceName)
    AS TestingProvinceName,
ISNULL(testingFacility.DistrictName, testingDisapoc.DisapocDistrictName)
    AS TestingDistrictName,
```

---

## 4. Optional Features

### GPS Coordinates (HFLattLong Joins)

For views that need mapping support, add `HFLattLong` joins:

```sql
-- In FROM clause:
LEFT JOIN OpenLDRDict.dbo.HFLattLong AS geoRequestingFacility
    ON geoRequestingFacility.FacilityCode = req.RequestingFacilityCode
LEFT JOIN OpenLDRDict.dbo.HFLattLong AS geoTestingFacility
    ON geoTestingFacility.FacilityCode = req.TestingFacilityCode
LEFT JOIN OpenLDRDict.dbo.HFLattLong AS geoReceivingFacility
    ON geoReceivingFacility.FacilityCode = req.ReceivingFacilityCode
LEFT JOIN OpenLDRDict.dbo.HFLattLong AS geoHubFacility
    ON geoHubFacility.FacilityCode = req.LIMSPreReg_RegistrationFacilityCode

-- In SELECT clause:
geoRequestingFacility.Latt AS RequestingLatitude,
geoRequestingFacility.Long AS RequestingLongitude,
geoTestingFacility.Latt    AS TestingLatitude,
geoTestingFacility.Long    AS TestingLongitude,
geoReceivingFacility.Latt  AS ReceivingLatitude,
geoReceivingFacility.Long  AS ReceivingLongitude,
geoHubFacility.Latt        AS HubLatitude,
geoHubFacility.Long        AS HubLongitude
```

The `HFLattLong` table stores string-based coordinates (`Latt`, `Long`, `LattLong`) as an alternative to the SQL Server GEOGRAPHY type in the `Facilities` table. String format ensures compatibility with reporting tools that do not support the GEOGRAPHY type.

### DISA Link / POC Flags

To flag whether a requesting facility is a DISA Link hub or a DISA POC site:

```sql
-- In FROM clause:
LEFT JOIN OpenLDRDict.dbo.DisaLink AS disalink
    ON disalink.DlinkCode = req.RequestingFacilityCode
LEFT JOIN OpenLDRDict.dbo.DisaPoc AS disapoc
    ON disapoc.DisaPocCode = req.RequestingFacilityCode

-- In SELECT clause:
CASE WHEN disalink.DlinkCode IS NOT NULL AND LEN(disalink.DlinkCode) > 0
     THEN 1 ELSE 0
END AS IsDisaLink,
CASE WHEN disapoc.DisaPocCode IS NOT NULL AND LEN(disapoc.DisaPocCode) > 0
     THEN 1 ELSE 0
END AS IsDisaPoc
```

### National Facility Code

To include the national MoH facility registration code:

```sql
-- In FROM clause:
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS facilityNationalCode
    ON req.RequestingFacilityNationalCode = facilityNationalCode.FacilityNationalCode

-- In SELECT clause:
facilityNationalCode.FacilityNationalCode
```

The `FacilityNationalCode` column lives on `HFLattLong` (as an `INT`) and is surfaced through `viewFacilities`. It maps to the official Ministry of Health facility registration code (`MoHFacilityCode` on the `Facilities` table).

---

## 5. Naming Conventions

| View Type | Pattern | Examples |
|-----------|---------|---------|
| Info view (registration/metadata) | `view{Test}_Info` | `viewVL_Info`, `viewEID_Info`, `viewCovid19_Info` |
| Result view (test results) | `view{Test}_Result` or `view{Test}` | `viewVL_Result`, `viewTbGenexpert`, `viewCD4` |
| Combined view (info + result + patients) | `viewFull{Test}` | `viewFullPCR` |
| Date-filtered function | `get{Test}_WithPatients_DateTimeStamp` | `getVL_Vendor1_WithPatients_DateTimeStamp` |
| Panel-specific result view | `view{Panel}` | `viewTBLAM`, `viewCryptococcus` |

---

## 6. Common Pitfalls

| Pitfall | Symptom | Solution |
|---------|---------|---------|
| INNER JOIN on observation codes | Requests without all observations are silently dropped | Always use **LEFT JOIN** for observation code subqueries |
| Joining only on `RequestID` | Duplicate or incorrect rows when a request has multiple OBRSets | Always join on **both** `RequestID` AND `OBRSetID` |
| Duplicate rows per observation | Multiple `LabResults` rows for same observation code on same request | Ensure the data model guarantees one row per code per request; add `SELECT DISTINCT` in the view if needed |
| DisaPoc join returns wrong facility | Facilities from wrong POC sites bleed in | Add `AND disapocReceivingFacility.DisapocState = 1` (active POC sites only) in the join condition |
| DisaPoc code key mismatch | POC facilities never resolve | Use `LEFT(DisaPocLabNo, 3)` to extract the 3-character facility prefix from `DisaPocLabNo` |
| `SELECT *` in observation subqueries | Unnecessary columns fetched; performance degrades | Select only `RequestID, OBRSetID, LIMSRptResult` (add `LIMSCodedValue` only when needed) |
| NULL values in info views | Reports show blank instead of meaningful label | Wrap with `ISNULL(..., 'Unreported')` for clinical/metadata observation columns |
| Multi-vendor observation code descriptions | Same code has different `LIMSObservationDesc` values from different LIMS vendors | Use the **code** (e.g., `GXRIF`) as the filter, not the description; use `SELECT DISTINCT LIMSObservationCode` when querying `LIMSPanelCodes` |
| Missing `WHERE LIMSPanelCode` filter | View includes data from unrelated panels | Always filter on `LIMSPanelCode` in the outer `WHERE` clause |
| Observation filter in outer WHERE | Filtering on observation code outside the subquery causes cross-joins | The `WHERE LIMSObservationCode = '...'` clause **must** be inside the subquery, never in the outer query |
