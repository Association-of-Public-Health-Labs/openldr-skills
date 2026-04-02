# Dataset Generation Reference Guide

## 1. Existing Datasets

| Dataset | Table Name | Database | Bind Key | Views Used | Includes Patients | Approx. Column Count |
|---------|-----------|----------|----------|-----------|-------------------|----------------------|
| **VlData** (HIV Viral Load) | `VlData` | `ViralLoadData` | `vlSMS` or `vl` | `viewVL_Result` + `viewVL_Info` | Yes | ~150 |
| **EIDMaster** (HIV EID) | `EIDMaster` | DPI database | `dpi` | `viewEID_Result` + `viewEID_Info` | Yes | ~73 |
| **TBMaster** (TB GeneXpert) | `TBMaster` | TB database | `tb` | `viewTbGenexpert` | Yes | ~100 |
| CD4 (planned) | `CD4Data` | AD database | `ad` | `viewCD4` | Yes | — |
| CrAg (planned) | `CragData` | AD database | `ad` | `viewCryptococcus` | Yes | — |
| TB-LAM (planned) | `TbLamData` | AD database | `ad` | `viewTBLAM` | Yes | — |

### VlData Column Categories

| Category | Count | Source | Examples |
|----------|-------|--------|----------|
| Patient data | ~22 | `Patients` table | SURNAME, FIRSTNAME, DOB, NATIONALID, MOBILE |
| Demographics | 3 | `viewVL_Result` | AgeInDays, AgeInYears, HL7SexCode |
| Pre-registration | 3 | `viewVL_Info` | LIMSPreReg_RegistrationDateTime, etc. |
| Timeline | 7 | `viewVL_Result` | SpecimenDatetime through AuthorisedDateTime |
| VL Info (pivoted) | 16 | `viewVL_Info` | Pregnant, BreastFeeding, ARTRegimen, ReasonForTest |
| VL Results (pivoted) | 7 | `viewVL_Result` | FinalViralLoadResult, HIVVL_ViralLoadCAPCTM, etc. |
| Facilities | 16 | Views + Dict | 4 facility types x (Code, Name, Province, District) |
| GPS | 2 | `HFLattLong` | Latitude, Longitude |
| Request metadata | ~30 | `viewVL_Result` | HL7 codes, specimen info, staff, etc. |
| Derived | 6 | Computed | AgeGroup, ViralLoadResultCategory, RegisteredYearAndMonth |
| Operational | ~10 | Added later | EPTS, SMS_NOTIFICATION, PatientNotification, etc. |

### Existing SQL Source Files

- VlData function: `openldr-skills-notes/getVL_Vendor1_WithPatients_DateTimeStamp.sql`
- VlData table DDL: `openldr-skills-notes/VlData.sql`
- EIDMaster ORM model: `api_openldr_python/hiv/eid/models/eid_master_model.py`
- TBMaster ORM model: `api_openldr_python/tb/gxpert/models/tb_gx_model.py`
- VlData ORM model: `api_openldr_python/hiv/vl/models/vl.py`

---

## 2. Table-Valued Function Template

The table-valued function is the SQL bridge between raw OpenLDR data and the analytics dataset. It accepts a date range and returns a flat result set combining views, patients, and dictionary lookups.

```sql
CREATE FUNCTION [dbo].[get{Test}_WithPatients_DateTimeStamp] (
    @startDate DATETIME,
    @endDate DATETIME
)
RETURNS TABLE
AS RETURN (
SELECT
    -- ═══════════════════════════════════════════════════════
    -- BLOCK A: Patient columns (OPTIONAL - only if including patients)
    -- Source: Patients table
    -- ═══════════════════════════════════════════════════════
    patients.RequestID,
    patients.Versionstamp,
    patients.[REFNO],
    patients.[REGISTEREDDATE],
    patients.[LOCATION],
    patients.[WARD],
    patients.[HOSPID],
    patients.[NATIONALITY],
    patients.[NATIONALID],
    patients.[UNIQUEID],
    patients.SURNAME,
    patients.FIRSTNAME,
    patients.[INITIALS],
    patients.[REFDRCODE],
    patients.[REFDR],
    patients.[MEDAID],
    patients.[MEDAIDNO],
    patients.[BILLACCNO],
    patients.[TELHOME],
    patients.[TELWORK],
    patients.[MOBILE],
    patients.[EMAIL],
    patients.DOB,
    patients.DOBType,
    patients.HealthcareNo,

    -- ═══════════════════════════════════════════════════════
    -- BLOCK B: Demographics from Result view
    -- Source: view{Test}_Result or view{Test}
    -- ═══════════════════════════════════════════════════════
    result.AgeInDays,
    result.AgeInYears,
    result.HL7SexCode,

    -- ═══════════════════════════════════════════════════════
    -- BLOCK C: Pre-registration timeline (if applicable)
    -- Source: view{Test}_Info
    -- ═══════════════════════════════════════════════════════
    info.LIMSPreReg_RegistrationDateTime,
    info.LIMSPreReg_ReceivedDateTime,
    info.LIMSPreReg_RegistrationFacilityCode,

    -- ═══════════════════════════════════════════════════════
    -- BLOCK D: Core timeline dates
    -- Source: view{Test}_Result
    -- ═══════════════════════════════════════════════════════
    result.SpecimenDatetime,
    result.ReceivedDateTime,
    result.RegisteredDateTime,
    result.AnalysisDateTime,
    result.AuthorisedDateTime,
    result.LIMSRejectionCode,
    result.LIMSRejectionDesc,
    result.LIMSDateTimeStamp,
    result.Newborn,

    -- ═══════════════════════════════════════════════════════
    -- BLOCK E: Pivoted info columns (from Info view)
    -- Source: view{Test}_Info - NULL-handled
    -- ═══════════════════════════════════════════════════════
    ISNULL(info.{InfoColumn1}, 'Unreported') AS {InfoColumn1},
    ISNULL(info.{InfoColumn2}, 'Unreported') AS {InfoColumn2},
    -- ... repeat for all info columns ...

    -- ═══════════════════════════════════════════════════════
    -- BLOCK F: Pivoted result columns (from Result view)
    -- Source: view{Test}_Result
    -- ═══════════════════════════════════════════════════════
    result.{ResultColumn1},
    result.{ResultColumn2},
    -- ... repeat for all result columns ...

    -- ═══════════════════════════════════════════════════════
    -- BLOCK G: Request metadata passthrough
    -- Source: view{Test}_Result
    -- ═══════════════════════════════════════════════════════
    result.LIMSVersionstamp,
    result.LOINCPanelCode,
    result.HL7PriorityCode,
    result.AdmitAttendDateTime,
    result.CollectionVolume,

    -- ═══════════════════════════════════════════════════════
    -- BLOCK H: Facility columns (4 facility types)
    -- Source: view{Test}_Result + Dictionary lookups
    -- ═══════════════════════════════════════════════════════
    result.LIMSFacilityCode,
    result.LIMSFacilityName,
    result.LIMSProvinceName,
    result.LIMSDistrictName,
    -- GPS coordinates from HFLattLong
    latlong.Latt AS Latitude,
    latlong.Long AS Longitude,
    -- National facility code
    info.RequestingFacilityNationalCode,
    ISNULL(fac.[FacilityNationalCode], result.RequestingFacilityCode) AS RequestingFacilityCode,
    result.RequestingFacilityName,
    result.RequestingProvinceName,
    result.RequestingDistrictName,
    result.ReceivingFacilityCode,
    result.ReceivingFacilityName,
    result.ReceivingProvinceName,
    result.ReceivingDistrictName,
    result.TestingFacilityCode,
    result.TestingFacilityName,
    result.TestingProvinceName,
    result.TestingDistrictName,

    -- ═══════════════════════════════════════════════════════
    -- BLOCK I: Remaining request metadata
    -- Source: view{Test}_Result
    -- ═══════════════════════════════════════════════════════
    result.LIMSPointOfCareDesc,
    result.RequestTypeCode,
    result.ICD10ClinicalInfoCodes,
    result.ClinicalInfo,
    result.HL7SpecimenSourceCode,
    result.LIMSSpecimenSourceCode,
    result.LIMSSpecimenSourceDesc,
    result.HL7SpecimenSiteCode,
    result.LIMSSpecimenSiteCode,
    result.LIMSSpecimenSiteDesc,
    result.WorkUnits,
    result.CostUnits,
    result.HL7SectionCode,
    result.HL7ResultStatusCode,
    result.RegisteredBy,
    result.TestedBy,
    result.AuthorisedBy,
    result.OrderingNotes,
    result.EncryptedPatientID,
    result.HL7EthnicGroupCode,
    result.Deceased,
    result.HL7PatientClassCode,
    result.AttendingDoctor,
    result.ReferringRequestID,
    result.Therapy,
    result.LIMSAnalyzerCode,
    result.TargetTimeDays,
    result.TargetTimeMins,
    result.Repeated,

    -- ═══════════════════════════════════════════════════════
    -- BLOCK J: Derived/computed columns
    -- ═══════════════════════════════════════════════════════
    -- Age group classification
    [dbo].[GetAgeGroup](result.AgeInYears) AS AgeGroup,
    -- Date parts for grouping
    CONCAT(YEAR(result.RegisteredDateTime), '-',
           DATEPART(QUARTER, result.RegisteredDateTime)) AS RegisteredYearAndQuarter,
    CONCAT(YEAR(result.RegisteredDateTime), '-',
           MONTH(result.RegisteredDateTime)) AS RegisteredYearAndMonth,
    -- DISA flags from Info view
    info.IsDisaLink,
    info.IsDisaPoc,
    -- DateTimeStamp: earliest of info or result timestamps
    IIF(info.DateTimeStamp IS NULL OR result.DateTimeStamp IS NULL,
        ISNULL(info.DateTimeStamp, result.DateTimeStamp),
        IIF(info.DateTimeStamp < result.DateTimeStamp,
            info.DateTimeStamp, result.DateTimeStamp)
    ) AS DateTimeStamp,
    -- Patient creation timestamp
    patients.DatetimeStamp AS CreatedAt

-- ═══════════════════════════════════════════════════════════
-- FROM: Date-filtered RequestID subquery
-- ═══════════════════════════════════════════════════════════
FROM (
    SELECT DISTINCT Requests.RequestID
    FROM Requests
    LEFT JOIN LabResults
        ON Requests.RequestID = LabResults.RequestID
        AND Requests.OBRSetID = LabResults.OBRSetID
    WHERE (
        Requests.LIMSPanelCode = '{PANEL_CODE_1}'
        OR Requests.LIMSPanelCode = '{PANEL_CODE_2}'
    )
    AND (
        (Requests.DateTimeStamp >= @startDate
         AND Requests.DateTimeStamp < @endDate)
        OR
        (LabResults.DateTimeStamp IS NOT NULL
         AND LabResults.DateTimeStamp >= @startDate
         AND LabResults.DateTimeStamp < @endDate)
    )
) AS mainRequests

-- ═══════════════════════════════════════════════════════════
-- JOINs: Views + Patients + Dictionary
-- ═══════════════════════════════════════════════════════════
-- Patient data (LEFT JOIN = optional, INNER JOIN = required)
LEFT JOIN Patients AS patients
    ON patients.RequestID = mainRequests.RequestID
-- Result view (INNER JOIN ensures we only get requests with results)
INNER JOIN [dbo].[view{Test}_Result] AS result
    ON mainRequests.RequestID = result.RequestID
-- Info view (LEFT JOIN because info may be missing)
LEFT JOIN [dbo].[view{Test}_Info] AS info
    ON result.RequestID = info.RequestID
-- Dictionary: Facility national code lookup
LEFT JOIN OpenLDRDict.dbo.viewFacilities AS fac
    ON info.RequestingFacilityCode = fac.FacilityCode
    OR result.RequestingFacilityCode = fac.FacilityCode
-- Dictionary: GPS coordinates
LEFT JOIN OpenLDRDict.[dbo].[HFLattLong] AS latlong
    ON info.RequestingFacilityCode = latlong.FacilityCode
    OR result.RequestingFacilityCode = latlong.FacilityCode
)
```

### Key Rules for the Function

| Rule | Details |
|------|---------|
| **Date filter uses OR** | Checks BOTH `Requests.DateTimeStamp` AND `LabResults.DateTimeStamp` to catch updates |
| **DISTINCT RequestID** | The inner subquery deduplicates to avoid repeated rows from multiple panels |
| **INNER JOIN on Result view** | Ensures only requests with actual test results are returned |
| **LEFT JOIN on Info view** | Info panels may be missing (common for some data sources) |
| **LEFT JOIN on Patients** | Include if patient data requested; some requests may lack patient records |
| **ISNULL for info columns** | Default to `'Unreported'` for missing info values |
| **Computed columns last** | Derived fields (AgeGroup, date parts, categories) come after raw data |

---

## 3. Function Without Patients

When the user does NOT want patient-identifying data, apply the following modifications to the template:

1. **Remove Block A** — delete all `patients.*` columns from the SELECT list.
2. **Remove the Patient JOIN** — delete the `LEFT JOIN Patients AS patients` clause.
3. **Replace `patients.RequestID`** as the first SELECT column with `result.RequestID`.
4. **Remove `patients.DatetimeStamp AS CreatedAt`** from Block J.

The date-filtered subquery (FROM clause), all view JOINs, and dictionary JOINs remain unchanged. The resulting function will still carry demographics, timeline, info/result columns, facility data, and derived columns — just without the 22 patient-identifying fields.

---

## 4. Table DDL Template

The table schema mirrors the function output column-by-column, with one addition: an auto-increment `id` primary key. Column types follow the mapping rules in Section 5.

```sql
CREATE TABLE [dbo].[{Test}Data](
    -- Auto-increment primary key (NOT in the function output)
    [id] [bigint] IDENTITY(1,1) NOT NULL,

    -- All columns from the function, in the same order
    -- Map function output types to SQL Server column types per Section 5 rules

    [RequestID] [varchar](26) NULL,
    -- ... all columns matching function output, in function order ...

    -- Optional: Additional operational columns not in the function
    [EPTS] [varchar](255) NULL,               -- External Patient Tracking System link
    [EPTS_DATETIME] [datetime] NULL,           -- EPTS sync timestamp
    [SMS_NOTIFICATION] [varchar](100) NULL,    -- SMS notification status
    [SMS_NOTIFICATION_DATETIME] [datetime] NULL,

    -- Primary key constraint
    CONSTRAINT [PK_{test}data] PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
```

---

## 5. Column Type Mapping Rules

| Function Output | Table Column Type | Notes |
|----------------|-------------------|-------|
| `patients.RequestID` (varchar(26)) | `[varchar](26) NULL` | Direct mapping |
| `patients.SURNAME` (varchar(31)) | `[varchar](31) NULL` | Direct mapping |
| `ISNULL(info.Pregnant, 'Unreported')` | `[varchar](80) NOT NULL` | NOT NULL because ISNULL guarantees a value |
| `result.SpecimenDatetime` (datetime) | `[datetime] NULL` | Direct mapping |
| `result.AgeInYears` (int) | `[int] NULL` | Direct mapping |
| `result.Deceased` (bit) | `[bit] NULL` | Direct mapping |
| `[dbo].[GetAgeGroup](...)` (nvarchar(64)) | `[nvarchar](64) NULL` | Match the function's return type |
| `[dbo].[ViralLoadResultRange](...)` (nvarchar(1024)) | `[nvarchar](max) NULL` | Use max for variable-length computed strings |
| `CONCAT(YEAR(...), '-', ...)` | `[varchar](25) NOT NULL` | CONCAT never returns NULL |
| `latlong.Latt` (varchar(255)) | `[varchar](100) NULL` | Size may be reduced for coordinates |

---

## 6. Table Naming Convention

| Test Type | Table Name | Database |
|-----------|-----------|----------|
| HIV Viral Load | `VlData` | `ViralLoadData` |
| HIV EID | `EIDMaster` | DPI database |
| TB GeneXpert | `TBMaster` | TB database |
| CD4 | `CD4Data` (planned) | AD database |
| CrAg | `CragData` (planned) | AD database |
| TB-LAM | `TbLamData` (planned) | AD database |

---

## 7. Population Scripts

### Initial Population (Full Load)

Run once to backfill all historical data. Use `'2016-01-01'` as the start date (or the earliest known data date) and `GETDATE()` as the end date.

```sql
INSERT INTO [{DatabaseName}].[dbo].[{Test}Data] (
    [RequestID], [Versionstamp], [REFNO], ...
    -- List ALL columns except [id] (auto-generated by IDENTITY)
)
SELECT *
FROM [OpenLDRData].[dbo].[get{Test}_WithPatients_DateTimeStamp](
    '2016-01-01',  -- Start date (beginning of data)
    GETDATE()      -- End date (current date)
)
```

> For very large datasets, consider batching by year to avoid timeouts:
> run one INSERT per year range (e.g., `'2016-01-01'` to `'2017-01-01'`, then `'2017-01-01'` to `'2018-01-01'`, etc.).

### Incremental Updates

Use for ongoing synchronization. Detects new and updated records by comparing against the current maximum `DateTimeStamp` in the analytics table.

```sql
-- Get the latest DateTimeStamp already loaded
DECLARE @lastSync DATETIME = (
    SELECT MAX(DateTimeStamp) FROM [{DatabaseName}].[dbo].[{Test}Data]
)

-- Delete records that the function will re-fetch (they may have been updated)
DELETE FROM [{DatabaseName}].[dbo].[{Test}Data]
WHERE RequestID IN (
    SELECT RequestID
    FROM [OpenLDRData].[dbo].[get{Test}_WithPatients_DateTimeStamp](
        @lastSync, GETDATE()
    )
)

-- Re-insert those records with current data
INSERT INTO [{DatabaseName}].[dbo].[{Test}Data] (
    [RequestID], [Versionstamp], ...
    -- List ALL columns except [id]
)
SELECT *
FROM [OpenLDRData].[dbo].[get{Test}_WithPatients_DateTimeStamp](
    @lastSync, GETDATE()
)
```

---

## 8. Python ORM Model Template

Place the model file at `api_openldr_python/{module}/models/{test}_model.py`.

```python
from db.database import db


class {Test}Data(db.Model):
    __bind_key__ = "{bind_key}"
    __tablename__ = "{TableName}"
    __table_args__ = {"extend_existing": True}

    # Primary key (auto-increment, not in function output)
    id = db.Column(db.Integer, primary_key=True)

    # ── Patient columns (include only if dataset has patient data) ──
    RequestID = db.Column(db.String(26))
    Versionstamp = db.Column(db.String(30))
    REFNO = db.Column(db.String(56))
    REGISTEREDDATE = db.Column(db.DateTime)
    LOCATION = db.Column(db.String(5))
    WARD = db.Column(db.String(5))
    HOSPID = db.Column(db.String(26))
    NATIONALITY = db.Column(db.String(5))
    NATIONALID = db.Column(db.String(26))
    UNIQUEID = db.Column(db.String(31))
    SURNAME = db.Column(db.String(31))
    FIRSTNAME = db.Column(db.String(31))
    INITIALS = db.Column(db.String(16))
    REFDRCODE = db.Column(db.String(10))
    REFDR = db.Column(db.String(51))
    MEDAID = db.Column(db.String(26))
    MEDAIDNO = db.Column(db.String(26))
    BILLACCNO = db.Column(db.String(26))
    TELHOME = db.Column(db.String(26))
    TELWORK = db.Column(db.String(26))
    MOBILE = db.Column(db.String(26))
    EMAIL = db.Column(db.String(51))
    DOB = db.Column(db.Date)
    DOBType = db.Column(db.String(25))
    HealthcareNo = db.Column(db.String(255))

    # ── Demographics ──
    AgeInDays = db.Column(db.Integer)
    AgeInYears = db.Column(db.Integer)
    HL7SexCode = db.Column(db.String(1))

    # ── Pre-registration timeline (if applicable) ──
    LIMSPreReg_RegistrationDateTime = db.Column(db.DateTime)
    LIMSPreReg_ReceivedDateTime = db.Column(db.DateTime)
    LIMSPreReg_RegistrationFacilityCode = db.Column(db.String(15))

    # ── Core timeline ──
    SpecimenDatetime = db.Column(db.DateTime)
    ReceivedDateTime = db.Column(db.DateTime)
    RegisteredDateTime = db.Column(db.DateTime)
    AnalysisDateTime = db.Column(db.DateTime)
    AuthorisedDateTime = db.Column(db.DateTime)
    LIMSRejectionCode = db.Column(db.String(10))
    LIMSRejectionDesc = db.Column(db.String(250))
    LIMSDateTimeStamp = db.Column(db.DateTime)

    # ── Info columns (test-specific, NOT NULL with 'Unreported' default) ──
    # Add columns matching the Info view output, e.g.:
    # Pregnant = db.Column(db.String(80), nullable=False)
    # ARTRegimen = db.Column(db.String(80), nullable=False)

    # ── Result columns (test-specific) ──
    # Add columns matching the Result view output, e.g.:
    # FinalViralLoadResult = db.Column(db.String(255))

    # ── Request metadata passthrough ──
    LIMSVersionstamp = db.Column(db.String(30))
    LOINCPanelCode = db.Column(db.String(20))
    HL7PriorityCode = db.Column(db.String(2))
    AdmitAttendDateTime = db.Column(db.DateTime)
    CollectionVolume = db.Column(db.String(20))

    # ── Facility columns ──
    LIMSFacilityCode = db.Column(db.String(15))
    LIMSFacilityName = db.Column(db.String(50))
    LIMSProvinceName = db.Column(db.String(50))
    LIMSDistrictName = db.Column(db.String(50))
    Latitude = db.Column(db.String(100))
    Longitude = db.Column(db.String(100))
    RequestingFacilityCode = db.Column(db.String(15))
    RequestingFacilityName = db.Column(db.String(50))
    RequestingProvinceName = db.Column(db.String(50))
    RequestingDistrictName = db.Column(db.String(50))
    ReceivingFacilityCode = db.Column(db.String(10))
    ReceivingFacilityName = db.Column(db.String(50))
    ReceivingProvinceName = db.Column(db.String(50))
    ReceivingDistrictName = db.Column(db.String(50))
    TestingFacilityCode = db.Column(db.String(10))
    TestingFacilityName = db.Column(db.String(50))
    TestingProvinceName = db.Column(db.String(50))
    TestingDistrictName = db.Column(db.String(50))

    # ── Remaining request metadata ──
    LIMSPointOfCareDesc = db.Column(db.String(50))
    RequestTypeCode = db.Column(db.String(10))
    ICD10ClinicalInfoCodes = db.Column(db.String(255))
    ClinicalInfo = db.Column(db.String(500))
    HL7SpecimenSourceCode = db.Column(db.String(10))
    LIMSSpecimenSourceCode = db.Column(db.String(10))
    LIMSSpecimenSourceDesc = db.Column(db.String(50))
    HL7SpecimenSiteCode = db.Column(db.String(10))
    LIMSSpecimenSiteCode = db.Column(db.String(10))
    LIMSSpecimenSiteDesc = db.Column(db.String(50))
    WorkUnits = db.Column(db.String(10))
    CostUnits = db.Column(db.String(10))
    HL7SectionCode = db.Column(db.String(10))
    HL7ResultStatusCode = db.Column(db.String(2))
    RegisteredBy = db.Column(db.String(15))
    TestedBy = db.Column(db.String(15))
    AuthorisedBy = db.Column(db.String(15))
    OrderingNotes = db.Column(db.String(255))
    EncryptedPatientID = db.Column(db.String(255))
    HL7EthnicGroupCode = db.Column(db.String(10))
    Deceased = db.Column(db.Boolean)
    HL7PatientClassCode = db.Column(db.String(5))
    AttendingDoctor = db.Column(db.String(30))
    ReferringRequestID = db.Column(db.String(26))
    Therapy = db.Column(db.String(255))
    LIMSAnalyzerCode = db.Column(db.String(10))
    TargetTimeDays = db.Column(db.Integer)
    TargetTimeMins = db.Column(db.Integer)
    Repeated = db.Column(db.SmallInteger)

    # ── Derived/computed columns ──
    AgeGroup = db.Column(db.String(64))
    RegisteredYearAndQuarter = db.Column(db.String(25))
    RegisteredYearAndMonth = db.Column(db.String(25))
    DateTimeStamp = db.Column(db.DateTime)

    # ── Operational columns (added to table but not in function output) ──
    EPTS = db.Column(db.String(255))
    EPTS_DATETIME = db.Column(db.DateTime)
    CreatedAt = db.Column(db.DateTime)
```

### Column Type Mapping: SQL Server → SQLAlchemy

| SQL Server Type | SQLAlchemy Type |
|----------------|-----------------|
| `varchar(N)` / `nvarchar(N)` | `db.Column(db.String(N))` |
| `datetime` | `db.Column(db.DateTime)` |
| `date` | `db.Column(db.Date)` |
| `int` | `db.Column(db.Integer)` |
| `bigint` | `db.Column(db.BigInteger)` |
| `smallint` | `db.Column(db.SmallInteger)` |
| `float` | `db.Column(db.Float)` |
| `bit` | `db.Column(db.Boolean)` |
| `NOT NULL` column | Add `nullable=False` |

---

## 9. Bind Key Assignments

| Test Type | Bind Key | Database |
|-----------|----------|----------|
| HIV Viral Load | `vlSMS` or `vl` | `ViralLoadData` or VL database |
| HIV EID | `dpi` | DPI database |
| TB GeneXpert | `tb` | TB database |
| HIV AD (CD4 / CrAg / TB-LAM) | `ad` | AD database |

Bind keys are configured in `api_openldr_python/configs/paths.py`. When creating a dataset for a new database, register the bind key and connection string there before creating the ORM model.

---

## 10. Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Function column count != table column count | The table must have exactly the same columns as the function output (plus `id`). Count columns carefully in both. |
| NOT NULL columns with no default | Columns that use `ISNULL(..., 'Unreported')` in the function always produce a value — mark them `NOT NULL` in the DDL and `nullable=False` in the ORM model. |
| Patient data privacy | Always confirm with the user before including patient columns. Restrict database access appropriately for tables containing patient-identifying data. |
| Date range too large on first population | For initial loads spanning many years, batch by year to avoid SQL Server timeouts and tempdb pressure. |
| Duplicate RequestIDs | The function uses `DISTINCT` in the inner subquery, but verify after population that the table has no duplicate RequestIDs for the same result. |
| Missing operational columns | The analytics table may need extra columns (EPTS, SMS notifications, etc.) that are not in the function. Add these to the DDL and ORM model after the function columns. |
| ORM bind key mismatch | Ensure the Python model `__bind_key__` exactly matches the key registered in `configs/paths.py`. A mismatch silently uses the default database. |
| Single-view test types | Some tests (e.g., TB GeneXpert) use a single combined view instead of separate Info + Result views. Omit Block C (pre-registration) and adjust the JOINs accordingly. |
