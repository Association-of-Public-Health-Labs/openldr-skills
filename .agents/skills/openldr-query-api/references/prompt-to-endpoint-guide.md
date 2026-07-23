# Prompt-to-Endpoint Reference Guide

This guide is loaded on demand to help match natural-language user prompts to the correct OpenLDR Analytics API endpoints. Use the 4-step decision tree first, then look up the specific pattern in the quick reference tables.

---

## 4-Step Decision Tree

### Step 1: Identify the Disease/Test Type

| User Mentions | Module Path |
|---------------|-------------|
| viral load, VL, HIV suppression, ART | `/hiv/vl/` |
| EID, early infant diagnosis, PCR, infant HIV, PMTCT | `/hiv/eid/` |
| TB, tuberculosis, GeneXpert, MTB, rifampicin | `/tb/gx/` |
| facilities, clinics, health facilities, laboratories | `/dict/` |
| login, token, user, password | `/auth/` |

---

### Step 2: Identify the View Perspective

| User Mentions | Perspective | Path Segment |
|---------------|-------------|--------------|
| by lab, by laboratory, lab performance | Laboratory | `/laboratories/` |
| by facility, by clinic, by health facility, by province, by district | Facility | `/facilities/` |
| dashboard, summary, overview, indicators, map | Summary | `/summary/` |
| patient, patient list, search patient | Patients | `/patients/` (TB only) |

---

### Step 3: Identify the Metric Type

| User Mentions | Metric | Endpoint Suffix |
|---------------|--------|-----------------|
| registered, received | Registration | `registered_samples` |
| tested, processed, completed | Testing | `tested_samples` |
| rejected, rejection | Rejection | `rejected_samples` |
| TAT, turnaround, time | Turnaround Time | `tat` / `trl_samples` |
| suppression, suppressed | Viral Suppression | `suppression` (VL only) |
| positivity, positive, negative | Positivity | `positivity` (EID/TB) |
| gender, male, female | Gender | `by_gender` |
| age, age group | Age | `by_age` |
| equipment, instrument, analyzer | Equipment | `by_equipment` (EID only) |
| drug, resistance, rifampicin | Drug Resistance | `by_drug_type` (TB only) |
| specimen, sample type, sputum | Specimen Type | `by_sample_types` (TB only) |
| month, monthly, trend | Monthly Trend | `_by_month` suffix |
| reason | Rejection Reason | `by_reason` (TB only) |

---

### Step 4: Determine Time Granularity

| User Mentions | Granularity | Action |
|---------------|-------------|--------|
| by month, monthly, trend, over time | Monthly | Use `_by_month` variant of the endpoint |
| totals, overall, aggregated | Aggregated | Use base variant (no `_by_month`) |
| last year, 2024, date range | Date-filtered | Set `interval_dates` parameter |

---

## Prompt-to-Endpoint Quick Reference

### HIV Viral Load (17 patterns)

| User Prompt Pattern | Endpoint |
|---------------------|----------|
| "How many VL samples were tested?" | `/hiv/vl/summary/header_indicators/` |
| "Show VL tested samples by lab" | `/hiv/vl/laboratories/tested_samples/` |
| "VL tested by month" | `/hiv/vl/laboratories/tested_samples_by_month/` |
| "VL suppression rate" | `/hiv/vl/summary/viral_suppression/` |
| "VL suppression by province" | `/hiv/vl/summary/suppression_by_province/` |
| "VL suppression by lab" | `/hiv/vl/laboratories/suppression/` |
| "VL rejected samples" | `/hiv/vl/laboratories/rejected_samples/` |
| "VL turnaround time" | `/hiv/vl/summary/tat/` |
| "VL TAT by lab" | `/hiv/vl/laboratories/tat_by_lab/` |
| "VL tested by gender" | `/hiv/vl/laboratories/tested_samples_by_gender/` |
| "VL tested by age" | `/hiv/vl/laboratories/tested_samples_by_age/` |
| "VL pregnant women" | `/hiv/vl/laboratories/tested_samples_pregnant/` |
| "VL breastfeeding" | `/hiv/vl/laboratories/tested_samples_breastfeeding/` |
| "VL by test reason" | `/hiv/vl/laboratories/tested_samples_by_test_reason/` |
| "VL samples history" | `/hiv/vl/summary/samples_history/` |
| "VL clinic performance" | `/hiv/vl/facilities/tested_samples_by_facility/` |
| "VL clinic rejections" | `/hiv/vl/facilities/rejected_samples_by_facility/` |

---

### HIV EID (11 patterns)

| User Prompt Pattern | Endpoint |
|---------------------|----------|
| "EID indicators" | `/hiv/eid/summary/indicators/` |
| "EID positivity" | `/hiv/eid/summary/positivity/` |
| "EID positivity by province" | `/hiv/eid/summary/indicators_by_province/` |
| "EID tested by lab" | `/hiv/eid/laboratories/tested_samples/` |
| "EID tested by month" | `/hiv/eid/laboratories/tested_samples_by_month/` |
| "EID POC tested" | `/hiv/eid/laboratories/tested_samples/` + `lab_type=poc` |
| "EID turnaround time" | `/hiv/eid/summary/tat/` |
| "EID rejected" | `/hiv/eid/laboratories/rejected_samples/` |
| "EID by equipment" | `/hiv/eid/laboratories/samples_by_equipment/` |
| "EID sample routes" | `/hiv/eid/laboratories/sample_routes/` |
| "EID clinic indicators" | `/hiv/eid/facilities/key_indicators/` |

---

### TB GeneXpert (13 patterns)

| User Prompt Pattern | Endpoint |
|---------------------|----------|
| "TB summary" | `/tb/gx/summary/summary_header_component/` |
| "TB positivity by month" | `/tb/gx/summary/positivity_by_month/` |
| "TB positivity by lab" | `/tb/gx/summary/positivity_by_lab/` |
| "TB tested by lab" | `/tb/gx/laboratories/tested_samples/` |
| "TB tested by month" | `/tb/gx/laboratories/tested_samples_by_month/` |
| "TB tested by specimen type" | `/tb/gx/laboratories/tested_samples_by_sample_types/` |
| "TB drug resistance" | `/tb/gx/laboratories/tested_samples_by_drug_type/` |
| "TB rejected by reason" | `/tb/gx/laboratories/rejected_samples_by_reason/` |
| "TB turnaround time by lab" | `/tb/gx/laboratories/trl_samples_by_lab_in_days/` |
| "TB average TAT" | `/tb/gx/laboratories/trl_samples_avg_by_days/` |
| "TB clinic performance" | `/tb/gx/facilities/tested_samples/` |
| "Search TB patient Maria" | `/tb/gx/patients/by_name/` + `first_name=Maria` |
| "TB patients at HG Machava" | `/tb/gx/patients/by_facility/` + `health_facility=HG Machava` |

---

## Parameter Assembly Example

**User prompt**: "Show me the viral load suppression by province for Gaza and Inhambane in 2024"

**Decision tree walkthrough**:

- Step 1 — Disease: "viral load" → `/hiv/vl/`
- Step 2 — Perspective: "by province" → `/summary/`
- Step 3 — Metric: "suppression" → `suppression_by_province`
- Step 4 — Time: "2024" → set `interval_dates=2024-01-01,2024-12-31`
- Geographic filter: "Gaza and Inhambane" → `province=Gaza&province=Inhambane`

**Assembled API call**:

```
GET /hiv/vl/summary/suppression_by_province/?interval_dates=2024-01-01,2024-12-31&province=Gaza&province=Inhambane
Authorization: Bearer {token}
```

---

## cURL Examples

### Login

```bash
curl -X POST https://api.openldr.org.mz/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "myuser", "password": "mypass"}'
```

### Get VL Summary Indicators

```bash
curl -X GET "https://api.openldr.org.mz/hiv/vl/summary/header_indicators/?interval_dates=2024-01-01,2024-12-31" \
  -H "Authorization: Bearer eyJhbGciOi..."
```

### Get TB Positivity by Province

```bash
curl -X GET "https://api.openldr.org.mz/tb/gx/summary/positivity_by_month/?interval_dates=2024-01-01,2024-12-31&province=Maputo" \
  -H "Authorization: Bearer eyJhbGciOi..."
```

### Get EID Data for POC Labs

```bash
curl -X GET "https://api.openldr.org.mz/hiv/eid/laboratories/tested_samples/?interval_dates=2024-01-01,2024-12-31&lab_type=poc" \
  -H "Authorization: Bearer eyJhbGciOi..."
```

### Get All Facilities in Maputo

```bash
curl -X GET "https://api.openldr.org.mz/dict/facilities/provinces/?province=Maputo"
```

### Search TB Patients by Name

```bash
curl -X GET "https://api.openldr.org.mz/tb/gx/patients/by_name/?interval_dates=2024-01-01,2024-12-31&first_name=Maria&page=1&per_page=20" \
  -H "Authorization: Bearer eyJhbGciOi..."
```
