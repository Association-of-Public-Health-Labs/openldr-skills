# OpenLDR Skills

AI agent skills for working with [OpenLDR](https://openldr.org) (Open Laboratory Data Repository) — a centralized electronic data storage system for country-wide laboratory requests and results.

## Skills

| Skill | Description |
|-------|-------------|
| **openldr** | Meta-skill that routes to the correct sub-skill based on user intent |
| **openldr-explore** | Answer questions about the OpenLDR data model, schema, panel codes, and relationships. Knowledge-first with live DB and LOINC enrichment |
| **openldr-create-view** | Create SQL views that pivot LabResults observation codes into columns. Guided workflow with column selection |
| **openldr-create-dataset** | Generate analytics dataset tables, functions, DDL, population scripts, and Python ORM models |
| **openldr-query-api** | Query the OpenLDR Analytics API — 126+ endpoints for HIV VL, HIV EID, TB GeneXpert, and more |
| **openldr-report** | Generate self-contained HTML report pages with dark dashboard theme, Chart.js charts, and sortable data tables |

## Installation

```bash
npx skills add Association-of-Public-Health-Labs/openldr-skills
```

Or install manually by cloning and symlinking into your Claude Code skills directory:

```bash
git clone https://github.com/Association-of-Public-Health-Labs/openldr-skills.git
cd openldr-skills

# Global install (all projects)
for skill in openldr openldr-explore openldr-create-view openldr-create-dataset openldr-query-api openldr-report; do
  ln -s "$(pwd)/$skill" ~/.claude/skills/$skill
done

# Or project-specific install
mkdir -p /path/to/your/project/.claude/skills
for skill in openldr openldr-explore openldr-create-view openldr-create-dataset openldr-query-api openldr-report; do
  ln -s "$(pwd)/$skill" /path/to/your/project/.claude/skills/$skill
done
```

## Setup

### Database Connectivity (optional, recommended)

The skills work **offline-first** using built-in knowledge, but connecting to the live database unlocks full capabilities.

Create `~/.openldr.env` for global access from any directory:

```env
# Database (used by openldr-explore and openldr-create-view)
OPENLDR_DB_HOST=localhost
OPENLDR_DB_USER=your_username
OPENLDR_DB_PASSWORD=your_password
OPENLDR_DB_DICT=OpenLDRDict
OPENLDR_DB_DATA=OpenLDRData

# API (used by openldr-query-api)
OPENLDR_API_URL=https://dev.openldr.org.mz
OPENLDR_API_USER=your_api_username
OPENLDR_API_PASSWORD=your_api_password
```

Or create a `.env` in your project directory to override specific values per project.

**Priority order:** project `.env` > `~/.openldr.env` > shell environment variables.

### Test Connectivity

```bash
# Database
openldr-create-view/scripts/query-db.sh test

# API
openldr-query-api/scripts/query-api.sh test
```

## HTML Report Generation

The `openldr-report` skill generates self-contained HTML report pages with a dark dashboard theme, Chart.js charts, and sortable data tables. Reports open directly in your browser — no server needed.

### How to Use

Request an HTML report in two ways:

**Upfront** — include it in your request:
```
Show me VL suppression by province as an HTML report
```

**After results** — ask for HTML after seeing terminal output:
```
Generate an HTML report for this
```

### What Gets Generated

- **KPI summary cards** — auto-extracted from aggregate metrics (totals, rates, TAT)
- **Charts** — auto-selected based on data shape (bar, line, doughnut, or grouped bar)
- **Sortable data table** — always included, click column headers to sort
- **Dark dashboard theme** — elegant, print-friendly design

The report is a single `.html` file saved to your working directory (customizable) and opened in your default browser automatically.

### Trigger Keywords

`generate HTML report`, `show in browser`, `visualize this`, `as HTML`, `open in browser`, `export as HTML report`

## Supported Test Types

| Test | Panel Codes | LOINC |
|------|-------------|-------|
| HIV Viral Load | HIVVL, VIRAL | 25836-8 |
| HIV Early Infant Diagnosis | PCR, FSR, POCED, POFSR | 9836-8 |
| TB GeneXpert | PCRGX, POCGT | 38376-3 |
| TB MDR/XDR | MTXDR | - |
| CD4 Count | CD4 | 24467-3 |
| Cryptococcal Antigen | CRAG | 31795-8 |
| TB LAM | TBLAM | 94053-5 |

## Requirements

- **Claude Code** (CLI, desktop, or web)
- **SQL Server access** (optional): `sqlcmd` (mssql-tools18) or `python3` + `pyodbc`
- **API access** (optional): `curl`

## License

MIT
