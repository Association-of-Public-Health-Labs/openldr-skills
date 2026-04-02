# OpenLDR Analytics API — Complete Endpoint Catalog

This catalog lists all 126 API endpoints across 5 modules. Load this file when you need to look up an endpoint path, its parameters, or response structure.

---

## Connection Details

| Property | Value |
|----------|-------|
| **Base URL (Dev)** | `https://dev.openldr.org.mz` |
| **Base URL (Prod)** | `https://api.openldr.org.mz` |
| **Base URL (Local)** | `http://localhost:5000` |
| **Swagger UI** | `{base_url}/apidocs/` |
| **Auth Method** | JWT Bearer Token |
| **Token Expiry** | 60 minutes |
| **Content-Type** | `application/json` |
| **CORS** | Enabled for all origins |

---

## Authentication

### Obtain JWT Token

```
POST /auth/login
Content-Type: application/json

{
  "username": "string",
  "password": "string"
}
```

**Success Response (200):**
```json
{
  "status": 200,
  "message": "Login successful",
  "data": {
    "user_id": "uuid-string",
    "user_name": "string",
    "first_name": "string",
    "last_name": "string",
    "email_address": "string",
    "role": "Admin|user"
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Error Response (401):**
```json
{
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid credentials"
}
```

### Use Token in All Subsequent Requests

```
GET /hiv/vl/summary/header_indicators/?interval_dates=2024-01-01&interval_dates=2024-12-31
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

> All reporting endpoints require the `Authorization: Bearer {token}` header. Dictionary endpoints (`/dict/*`) do NOT require authentication.

---

## Module 1: Auth (`/auth`) — 6 endpoints

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | `/auth/login` | No | Authenticate and get JWT token |
| POST | `/auth/create` | JWT (Admin) | Create a new user |
| PUT | `/auth/update` | JWT (Admin) | Update an existing user |
| DELETE | `/auth/delete` | JWT (Admin) | Delete a user |
| GET | `/auth/users` | JWT (Admin) | List all users |
| POST | `/auth/clerk` | No (Webhook) | Clerk social auth webhook |

---

## Module 2: Dictionary (`/dict`) — 6 endpoints

These endpoints do NOT require authentication.

| # | Method | Endpoint | Parameters | Description |
|---|--------|----------|------------|-------------|
| 1 | GET | `/dict/laboratories/` | None | Get all laboratories |
| 2 | GET | `/dict/laboratories/provinces/` | `province` (multi) | Get laboratories filtered by province(s) |
| 3 | GET | `/dict/laboratories/province/districts/` | `district` (multi) | Get laboratories filtered by district(s) |
| 4 | GET | `/dict/facilities/` | None | Get all health facilities |
| 5 | GET | `/dict/facilities/provinces/` | `province` (multi) | Get facilities filtered by province(s) |
| 6 | GET | `/dict/facilities/province/districts/` | `district` (multi) | Get facilities filtered by district(s) |

**Facilities Response Format:**
```json
[
  {
    "FacilityName": "string",
    "FacilityCode": "string",
    "FacilityType": "string",
    "FacilityNationalCode": "string",
    "ProvinceName": "string",
    "DistrictName": "string",
    "HFStatus": 1,
    "Latitude": "string",
    "Longitude": "string"
  }
]
```

---

## Module 3: HIV Viral Load (`/hiv/vl`) — 35 endpoints

All endpoints require JWT authentication. All accept the **standard parameters**: `interval_dates`, `province`, `district`, `health_facility`, `facility_type`, `disaggregation`.

### Laboratory Endpoints (15)

| # | Endpoint | Description | Key Metrics |
|---|----------|-------------|-------------|
| 1 | `/hiv/vl/laboratories/registered_samples/` | Registered samples by lab | total per lab |
| 2 | `/hiv/vl/laboratories/registered_samples_by_month/` | Registered samples by month | total per month per lab |
| 3 | `/hiv/vl/laboratories/tested_samples/` | Tested samples by lab | total per lab |
| 4 | `/hiv/vl/laboratories/tested_samples_by_month/` | Tested samples by month | total per month per lab |
| 5 | `/hiv/vl/laboratories/tested_samples_by_gender/` | Tested by gender | male, female per lab |
| 6 | `/hiv/vl/laboratories/tested_samples_by_gender_by_lab/` | Gender breakdown per lab | male, female per lab detail |
| 7 | `/hiv/vl/laboratories/tested_samples_by_age/` | Tested by age group | age groups per lab |
| 8 | `/hiv/vl/laboratories/tested_samples_by_test_reason/` | Tested by reason | routine, targeted, etc. |
| 9 | `/hiv/vl/laboratories/tested_samples_pregnant/` | Pregnant patients tested | total pregnant per lab |
| 10 | `/hiv/vl/laboratories/tested_samples_breastfeeding/` | Breastfeeding patients | total breastfeeding per lab |
| 11 | `/hiv/vl/laboratories/rejected_samples/` | Rejected samples by lab | total rejected per lab |
| 12 | `/hiv/vl/laboratories/rejected_samples_by_month/` | Rejected by month | total rejected per month |
| 13 | `/hiv/vl/laboratories/tat_by_lab/` | TAT averages by lab | avg days per TAT segment |
| 14 | `/hiv/vl/laboratories/tat_by_month/` | TAT averages by month | avg days per month |
| 15 | `/hiv/vl/laboratories/suppression/` | Viral suppression by lab | suppressed, not_suppressed per lab |

### Facility Endpoints (14)

| # | Endpoint | Description | Key Metrics |
|---|----------|-------------|-------------|
| 1 | `/hiv/vl/facilities/registered_samples/` | Registered by facility | total per facility |
| 2 | `/hiv/vl/facilities/tested_samples_by_month/` | Tested by month | total per month |
| 3 | `/hiv/vl/facilities/tested_samples_by_facility/` | Tested by facility | total per facility |
| 4 | `/hiv/vl/facilities/tested_samples_by_gender/` | Tested by gender | male, female |
| 5 | `/hiv/vl/facilities/tested_samples_by_gender_by_facility/` | Gender per facility | male, female per facility |
| 6 | `/hiv/vl/facilities/tested_samples_by_age/` | Tested by age group | age groups |
| 7 | `/hiv/vl/facilities/tested_samples_by_age_by_facility/` | Age per facility | age groups per facility |
| 8 | `/hiv/vl/facilities/tested_samples_by_test_reason/` | Tested by reason | routine, targeted |
| 9 | `/hiv/vl/facilities/tested_samples_pregnant/` | Pregnant tested | total pregnant |
| 10 | `/hiv/vl/facilities/tested_samples_breastfeeding/` | Breastfeeding tested | total breastfeeding |
| 11 | `/hiv/vl/facilities/rejected_samples_by_month/` | Rejected by month | rejected per month |
| 12 | `/hiv/vl/facilities/rejected_samples_by_facility/` | Rejected by facility | rejected per facility |
| 13 | `/hiv/vl/facilities/tat_by_month/` | TAT by month | avg TAT per month |
| 14 | `/hiv/vl/facilities/tat_by_facility/` | TAT by facility | avg TAT per facility |

### Summary/Dashboard Endpoints (6)

| # | Endpoint | Description | Response Structure |
|---|----------|-------------|--------------------|
| 1 | `/hiv/vl/summary/header_indicators/` | Key indicator counts | `{registered, tested, suppressed, not_suppressed, rejected}` |
| 2 | `/hiv/vl/summary/number_of_samples/` | Monthly sample trend | `[{year, month, total}]` |
| 3 | `/hiv/vl/summary/viral_suppression/` | Monthly suppression trend | `[{year, month, suppressed, not_suppressed}]` |
| 4 | `/hiv/vl/summary/tat/` | Monthly TAT averages | `[{year, month, collection_reception, reception_registration, registration_analysis, analysis_validation}]` |
| 5 | `/hiv/vl/summary/suppression_by_province/` | Suppression by province (map) | `[{province, suppressed, not_suppressed, total}]` |
| 6 | `/hiv/vl/summary/samples_history/` | Historical sample trend | `[{year, month, total}]` |

---

## Module 4: HIV Early Infant Diagnosis (`/hiv/eid`) — 35 endpoints

All endpoints require JWT authentication. All accept the **standard parameters** PLUS `lab_type`, `category`, `viewport`.

### Laboratory Endpoints (11)

| # | Endpoint | Description |
|---|----------|-------------|
| 1 | `/hiv/eid/laboratories/tested_samples_by_month/` | Tested samples by month per lab |
| 2 | `/hiv/eid/laboratories/registered_samples_by_month/` | Registered samples by month |
| 3 | `/hiv/eid/laboratories/tested_samples/` | Tested samples by lab |
| 4 | `/hiv/eid/laboratories/tat/` | TAT averages by lab |
| 5 | `/hiv/eid/laboratories/tat_samples/` | TAT sample distribution |
| 6 | `/hiv/eid/laboratories/rejected_samples/` | Rejected samples by lab |
| 7 | `/hiv/eid/laboratories/rejected_samples_by_month/` | Rejected by month |
| 8 | `/hiv/eid/laboratories/samples_by_equipment/` | Samples by analyzer/equipment |
| 9 | `/hiv/eid/laboratories/samples_by_equipment_by_month/` | Equipment samples by month |
| 10 | `/hiv/eid/laboratories/sample_routes/` | Sample transport routes (mapping) |
| 11 | `/hiv/eid/laboratories/sample_routes_viewport/` | Routes within map viewport |

### Facility Endpoints (14)

| # | Endpoint | Description |
|---|----------|-------------|
| 1 | `/hiv/eid/facilities/registered_samples/` | Registered by facility |
| 2 | `/hiv/eid/facilities/registered_samples_by_month/` | Registered by month |
| 3 | `/hiv/eid/facilities/tested_samples/` | Tested by facility |
| 4 | `/hiv/eid/facilities/tested_samples_by_month/` | Tested by month |
| 5 | `/hiv/eid/facilities/tested_samples_by_gender/` | Tested by gender |
| 6 | `/hiv/eid/facilities/tested_samples_by_gender_by_month/` | Gender by month |
| 7 | `/hiv/eid/facilities/tat_avg_by_month/` | Average TAT by month |
| 8 | `/hiv/eid/facilities/tat_avg/` | Average TAT by facility |
| 9 | `/hiv/eid/facilities/tat_days_by_month/` | TAT days distribution by month |
| 10 | `/hiv/eid/facilities/tat_days/` | TAT days distribution by facility |
| 11 | `/hiv/eid/facilities/tested_samples_by_age/` | Tested by age group |
| 12 | `/hiv/eid/facilities/rejected_samples_by_month/` | Rejected by month |
| 13 | `/hiv/eid/facilities/rejected_samples/` | Rejected by facility |
| 14 | `/hiv/eid/facilities/key_indicators/` | Key indicators per facility |

### Summary/Dashboard Endpoints (10)

| # | Endpoint | Description |
|---|----------|-------------|
| 1 | `/hiv/eid/summary/indicators/` | Key indicators (registered, tested, rejected, pending, positive, negative) |
| 2 | `/hiv/eid/summary/tat/` | TAT averages by month (6 hub segments) |
| 3 | `/hiv/eid/summary/tat_samples/` | TAT sample distribution by time brackets |
| 4 | `/hiv/eid/summary/positivity/` | Monthly positivity (total, positive, negative) |
| 5 | `/hiv/eid/summary/number_of_samples/` | Monthly sample counts |
| 6 | `/hiv/eid/summary/indicators_by_province/` | Indicators by province (map) |
| 7 | `/hiv/eid/summary/samples_positivity/` | Positivity breakdown |
| 8 | `/hiv/eid/summary/rejected_samples_by_month/` | Monthly rejections |
| 9 | `/hiv/eid/summary/samples_by_equipment/` | Equipment summary |
| 10 | `/hiv/eid/summary/samples_by_equipment_by_month/` | Equipment by month |

---

## Module 5: TB GeneXpert (`/tb/gx`) — 44 endpoints

All endpoints require JWT authentication (extracted via `get_token(request)`). Endpoints accept **standard parameters** PLUS `genexpert_result_type` and `type_of_laboratory`.

### Facility Endpoints (19)

> Note: The source lists 18 in the heading but enumerates 19 entries including `trl_samples_avg_by_days_by_month`.

| # | Endpoint | Description |
|---|----------|-------------|
| 1 | `/tb/gx/facilities/registered_samples/` | Registered samples by facility |
| 2 | `/tb/gx/facilities/registered_samples_by_month/` | Registered by month |
| 3 | `/tb/gx/facilities/tested_samples/` | Tested by facility |
| 4 | `/tb/gx/facilities/tested_samples_by_month/` | Tested by month |
| 5 | `/tb/gx/facilities/tested_samples_disaggregated/` | Tested with result disaggregation |
| 6 | `/tb/gx/facilities/tested_samples_disaggregated_by_gender/` | Disaggregated by gender |
| 7 | `/tb/gx/facilities/tested_samples_disaggregated_by_age/` | Disaggregated by age |
| 8 | `/tb/gx/facilities/tested_samples_by_sample_types/` | By specimen type (sputum, feces, etc.) |
| 9 | `/tb/gx/facilities/tested_samples_types_disaggregated_by_age/` | Specimen types by age |
| 10 | `/tb/gx/facilities/tested_samples_disaggregated_by_drug_type/` | By drug resistance type |
| 11 | `/tb/gx/facilities/tested_samples_disaggregated_by_drug_type_by_age/` | Drug type by age |
| 12 | `/tb/gx/facilities/rejected_samples/` | Rejected by facility |
| 13 | `/tb/gx/facilities/rejected_samples_by_month/` | Rejected by month |
| 14 | `/tb/gx/facilities/rejected_samples_by_reason/` | Rejected by reason |
| 15 | `/tb/gx/facilities/rejected_samples_by_reason_by_month/` | Rejection reasons by month |
| 16 | `/tb/gx/facilities/trl_samples_by_days/` | Turnaround time distribution |
| 17 | `/tb/gx/facilities/trl_samples_by_days_by_month/` | TAT distribution by month |
| 18 | `/tb/gx/facilities/trl_samples_avg_by_days/` | Average TAT by facility |
| 19 | `/tb/gx/facilities/trl_samples_avg_by_days_by_month/` | Average TAT by month |

### Laboratory Endpoints (16)

| # | Endpoint | Description |
|---|----------|-------------|
| 1 | `/tb/gx/laboratories/registered_samples/` | Registered by lab |
| 2 | `/tb/gx/laboratories/tested_samples/` | Tested by lab |
| 3 | `/tb/gx/laboratories/registered_samples_by_month/` | Registered by month |
| 4 | `/tb/gx/laboratories/tested_samples_by_month/` | Tested by month |
| 5 | `/tb/gx/laboratories/tested_samples_by_sample_types/` | By specimen type |
| 6 | `/tb/gx/laboratories/tested_samples_by_sample_types_by_month/` | Specimen types by month |
| 7 | `/tb/gx/laboratories/rejected_samples/` | Rejected by lab |
| 8 | `/tb/gx/laboratories/rejected_samples_by_month/` | Rejected by month |
| 9 | `/tb/gx/laboratories/rejected_samples_by_reason/` | Rejected by reason |
| 10 | `/tb/gx/laboratories/rejected_samples_by_reason_by_month/` | Rejection reasons by month |
| 11 | `/tb/gx/laboratories/tested_samples_by_drug_type/` | By drug resistance type |
| 12 | `/tb/gx/laboratories/tested_samples_by_drug_type_by_month/` | Drug type by month |
| 13 | `/tb/gx/laboratories/trl_samples_by_lab_in_days/` | TAT distribution by lab |
| 14 | `/tb/gx/laboratories/trl_samples_by_lab_in_days_by_month/` | TAT distribution by month |
| 15 | `/tb/gx/laboratories/trl_samples_avg_by_days/` | Average TAT by lab |
| 16 | `/tb/gx/laboratories/trl_samples_avg_by_days_by_month/` | Average TAT by month |

### Summary/Dashboard Endpoints (6)

| # | Endpoint | Description |
|---|----------|-------------|
| 1 | `/tb/gx/summary/summary_header_component/` | Header indicators (only needs `interval_dates`) |
| 2 | `/tb/gx/summary/positivity_by_month/` | Positivity trend by month |
| 3 | `/tb/gx/summary/positivity_by_lab/` | Positivity by lab |
| 4 | `/tb/gx/summary/positivity_by_lab_by_age/` | Positivity by lab by age |
| 5 | `/tb/gx/summary/sample_types_by_month/` | Specimen types by month |
| 6 | `/tb/gx/summary/sample_types_by_facility_by_age/` | Specimen types by facility and age |

### Patient Endpoints (4)

These endpoints support pagination and name search in addition to standard parameters.

| # | Endpoint | Extra Parameters | Description |
|---|----------|-----------------|-------------|
| 1 | `/tb/gx/patients/by_name/` | `first_name`, `surname`, `page`, `per_page` | Search patients by name |
| 2 | `/tb/gx/patients/by_facility/` | `health_facility`, `page`, `per_page` | Patients by facility |
| 3 | `/tb/gx/patients/by_sample_type/` | `page`, `per_page` | Patients by specimen type |
| 4 | `/tb/gx/patients/by_result_type/` | `page`, `per_page` | Patients by result type |

---

## Standard Query Parameters

Most reporting endpoints accept the same set of query parameters.

| Parameter | Type | Format | Required | Default | Multi-Value | Description |
|-----------|------|--------|----------|---------|-------------|-------------|
| `interval_dates` | string[] | `YYYY-MM-DD` | YES (recommended) | Last 12 months | Yes (`action=append`) | Date range as two values: start and end |
| `province` | string[] | Province name | No | All provinces | Yes (`action=append`) | Filter by province name(s) |
| `district` | string[] | District name | No | All districts | Yes (`action=append`) | Filter by district name(s) |
| `health_facility` | string | Facility name | No | All facilities | No | Filter by specific facility |
| `facility_type` | string | enum | No | None | No | Aggregation level: `"province"`, `"district"`, `"health_facility"` |
| `disaggregation` | string | enum | No | `"False"` | No | Enable disaggregation: `"True"` or `"False"` |

### How to Pass Multi-Value Parameters

Multi-value parameters use repeated query string keys (NOT comma-separated):

```
# Correct: Two separate province parameters
?province=Maputo&province=Gaza

# Correct: Date range as two separate values
?interval_dates=2024-01-01&interval_dates=2024-12-31

# WRONG: Comma-separated (will not work)
?province=Maputo,Gaza
```

### Province Names (Mozambique)

Valid values for the `province` parameter:

| Province Name |
|---------------|
| Cabo Delgado |
| Gaza |
| Inhambane |
| Manica |
| Maputo |
| Maputo Cidade |
| Nampula |
| Niassa |
| Sofala |
| Tete |
| Zambezia |

---

## Module-Specific Parameters

### HIV EID Only

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lab_type` | string | `"all"` | Filter by lab type: `"conventional"`, `"poc"`, `"all"` |
| `category` | integer | None | TAT segment index (0-5) |
| `viewport` | string | None | Map viewport bounds: `{lat: {low, high}, lng: {low, high}}` |

### TB GeneXpert Only

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `genexpert_result_type` | string | None | Filter by GeneXpert cartridge type: `"Ultra 6 Cores"`, `"XDR 10 Cores"` |
| `type_of_laboratory` | string | None | Filter by lab classification: `"Conventional"`, `"Point_Of_Care"`, `"All"` |

### TB GeneXpert Patient Endpoints Only

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `first_name` | string | None | Patient first name (partial match) |
| `surname` | string | None | Patient surname (partial match) |
| `page` | integer | 1 | Page number (1-indexed) |
| `per_page` | integer | 50 | Records per page |

---

## Error Handling

### Standard Error Responses

| Status Code | Meaning | Response Format |
|-------------|---------|-----------------|
| 200 | Success | `{"status": 200, "data": {...}}` |
| 400 | Bad Request | `{"status": 400, "error": "Bad Request", "message": "..."}` |
| 401 | Unauthorized | `{"msg": "Missing Authorization Header"}` or `{"msg": "Token has expired"}` |
| 403 | Forbidden | `{"status": "error", "code": 403, "message": "Forbidden - User ... is not authorized"}` |
| 500 | Server Error | `{"status": "error", "code": 500, "message": "An Error Occurred", "error": "..."}` |

### Common Error Scenarios

| Scenario | Cause | Fix |
|----------|-------|-----|
| `Missing Authorization Header` | No Bearer token provided | Call `/auth/login` first |
| `Token has expired` | Token older than 60 minutes | Re-authenticate with `/auth/login` |
| `Invalid credentials` | Wrong username or password | Verify credentials |
| `Forbidden` | Non-admin user accessing admin endpoint | Use admin account |
| Empty data response | No data for given date range/filters | Widen date range or remove filters |

---

## User Management Endpoints

### Create User

```
POST /auth/create
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "username": "string (3-50 chars)",
  "first_name": "string (1-50 chars)",
  "last_name": "string (1-50 chars)",
  "password": "string (6-100 chars)",
  "confirm_password": "string (must match password)",
  "email": "string (valid email)",
  "role": "admin|user"
}
```

### Update User

```
PUT /auth/update
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "user_id": "string (required)",
  "username": "string",
  "first_name": "string",
  "last_name": "string",
  "email": "string",
  "role": "admin|user",
  "password": "string (optional)",
  "confirm_password": "string (optional, must match password)"
}
```

### Delete User

```
DELETE /auth/delete
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "user_id": "string"
}
```

### List All Users

```
GET /auth/users
Authorization: Bearer {admin_token}
```

---

## Endpoint Count Summary

| Module | Laboratory | Facility | Summary | Patients | Other | Total |
|--------|-----------|----------|---------|----------|-------|-------|
| Auth | - | - | - | - | 6 | **6** |
| Dictionary | - | - | - | - | 6 | **6** |
| HIV VL | 15 | 14 | 6 | - | - | **35** |
| HIV EID | 11 | 14 | 10 | - | - | **35** |
| TB GeneXpert | 16 | 19 | 6 | 4 | - | **45** |
| **Total** | **42** | **47** | **22** | **4** | **12** | **127** |

> Note: The TB GeneXpert Facility section lists 19 endpoints in the source (the header says 18 but 19 are enumerated, including `trl_samples_avg_by_days_by_month`). The source document's summary table lists 126 total; the actual enumerated count is 127.
