# OpenLDR Dashboard Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `openldr-dashboard` subskill that handles the full lifecycle of dashboards in the OpenLDR turborepo monorepo — scaffolding, reports, and maintenance.

**Architecture:** A single skill entry point (`SKILL.md`) acts as a router, detecting user intent (scaffold/report/maintain) and loading the appropriate reference guide. Reference guides contain the detailed workflows. A shell script handles bootstrapping new apps. The API endpoint catalog is symlinked from `openldr-query-api`.

**Tech Stack:** Markdown skill files, Bash shell script, symlinks. The skill generates code using Next.js 15, React 18, Clerk, Zustand, Axios, Recharts/ApexCharts, next-intl, Tailwind CSS 4, MUI + Shadcn design system.

**Monorepo path:** `/home/vagner/Documents/Projects/APHL/openldr/openldr-monorepo/`
**Skills repo path:** `/home/vagner/Documents/Projects/APHL/openldr-skills/`

---

### Task 1: Create directory structure and SKILL.md

**Files:**
- Create: `openldr-dashboard/SKILL.md`
- Create: `openldr-dashboard/references/` (directory)
- Create: `openldr-dashboard/scripts/` (directory)

- [ ] **Step 1: Create the skill directories**

```bash
mkdir -p openldr-dashboard/references openldr-dashboard/scripts
```

Run from: `/home/vagner/Documents/Projects/APHL/openldr-skills/`

- [ ] **Step 2: Write SKILL.md**

Create `openldr-dashboard/SKILL.md` with this content:

```markdown
---
name: openldr-dashboard
description: >
  Use when building, maintaining, or improving dashboards in the OpenLDR
  turborepo monorepo. Scaffolds new dashboard apps, adds reports/visualizations,
  fixes bugs, and improves UX. Works across apps/ and packages/ (design_system,
  auth, ai, utilities).
  TRIGGER: user mentions dashboard, create dashboard, new dashboard, add report,
  fix dashboard, improve dashboard, dashboard component, dashboard page,
  turborepo app, monorepo app.
metadata:
  author: openldr
  version: "1.0"
---

# Build & Maintain OpenLDR Dashboards

Build, maintain, and improve dashboards in the OpenLDR turborepo monorepo. Dashboards are Next.js 15 apps that visualize OpenLDR analytics API data with interactive charts, facility drill-down, export capabilities, and AI-assisted analysis.

**Announce:** "I'm using the openldr:dashboard skill to [scaffold/add report/improve] the dashboard."

## Process

` ``dot
digraph dashboard {
  "Detect Intent" [shape=box];
  "Scaffold?" [shape=diamond];
  "Report?" [shape=diamond];
  "Maintain?" [shape=diamond];
  "Load scaffold-guide.md" [shape=box];
  "Load report-guide.md" [shape=box];
  "Load maintenance-guide.md" [shape=box];
  "Resolve Monorepo" [shape=box];
  "Read Existing Patterns" [shape=box];
  "Execute Guide Workflow" [shape=box];
  "Verify" [shape=doublecircle];

  "Detect Intent" -> "Scaffold?" ;
  "Scaffold?" -> "Load scaffold-guide.md" [label="yes"];
  "Scaffold?" -> "Report?";
  "Report?" -> "Load report-guide.md" [label="yes"];
  "Report?" -> "Maintain?";
  "Maintain?" -> "Load maintenance-guide.md" [label="yes"];
  "Load scaffold-guide.md" -> "Resolve Monorepo";
  "Load report-guide.md" -> "Resolve Monorepo";
  "Load maintenance-guide.md" -> "Resolve Monorepo";
  "Resolve Monorepo" -> "Read Existing Patterns";
  "Read Existing Patterns" -> "Execute Guide Workflow";
  "Execute Guide Workflow" -> "Verify";
}
` ``

## Phase 1: Resolve Monorepo

The monorepo lives at `../openldr/openldr-monorepo/` relative to this skills repo (sibling directory). Resolve the absolute path from the skills repo location. If not found, ask the user for the monorepo location.

Key paths:
- **Apps:** `{monorepo}/apps/` — each dashboard is a Next.js app here
- **Design System:** `{monorepo}/packages/design_system/` — MUI + Shadcn UI components
- **Auth:** `{monorepo}/packages/auth/` — Clerk-based SSO authentication
- **AI:** `{monorepo}/packages/ai/` — AI chat agents for dashboards
- **Utilities:** `{monorepo}/packages/utilities/` — shared helper functions

## Phase 2: Detect Intent

Match the user's request to one of three modes:

| Keywords | Mode | Guide |
|---|---|---|
| "create dashboard", "new dashboard", "build dashboard for", "scaffold" | Scaffold | `references/scaffold-guide.md` |
| "add report", "new report", "new chart", "add page", "new visualization", "add section" | Report | `references/report-guide.md` |
| "fix", "improve", "update", "refactor", "optimize", "change", "modify", "bug" | Maintain | `references/maintenance-guide.md` |

If the intent is ambiguous, ask the user: "Are you looking to (a) create a new dashboard, (b) add a report to an existing dashboard, or (c) fix/improve an existing dashboard?"

Load the matched reference guide and follow its workflow.

## Phase 3: Context Gathering

Before executing any mode:

1. **For Scaffold:** Read `{monorepo}/turbo.json`, `{monorepo}/pnpm-workspace.yaml`, and `{monorepo}/package.json` to understand workspace configuration. Check existing apps in `{monorepo}/apps/`.
2. **For Report:** Read the target dashboard's existing reports to detect the established file structure. Read `references/tb-reference-patterns.md` for the default pattern. Load `references/api-endpoint-catalog.md` to identify the correct API endpoint.
3. **For Maintain:** Read the files that will be affected. Check `{monorepo}/packages/` for downstream impact if touching shared packages.

## Phase 4: Execute

Follow the loaded guide's workflow step by step.

## Phase 5: Verify

After any change:
- Confirm the dev server boots: `cd {monorepo} && pnpm dev --filter=<app-name>`
- Check for TypeScript errors: `cd {monorepo} && pnpm check-types --filter=<app-name>`

## Scope

This skill can create and modify files across:

| Target | When |
|---|---|
| `apps/<dashboard>/` | Always — this is the primary scope |
| `packages/design_system/` | When dashboard work requires a new or modified UI component |
| `packages/ai/` | When dashboard work requires AI agent changes |
| `packages/auth/` | When dashboard work requires auth flow changes |
| `packages/utilities/` | When dashboard work requires shared utilities |

<HARD-GATE>
When modifying any `packages/` directory, first check which apps import the affected code. Never break other apps.
</HARD-GATE>

## Anti-Rationalization

| Temptation | Reality |
|---|---|
| "I'll just write the code without reading existing patterns" | Always read existing reports/components first. Context-driven. |
| "I don't need the scaffold script for a new app" | Use the scaffold. Manual setup misses configuration. |
| "This change is small, no need to check downstream impact" | If touching packages/, always check which apps are affected. |
| "I'll skip i18n for now" | All UI text goes through i18n from day one. Portuguese default. |
| "I'll use a different chart library" | Follow what the target dashboard already uses. |
| "I can just copy the TB dashboard" | Read and adapt patterns — don't copy domain-specific TB code. |
```

**Note:** Fix the dot code block — remove the space in the opening triple backticks (added to avoid markdown parsing issues in this plan).

- [ ] **Step 3: Verify the file**

```bash
cat openldr-dashboard/SKILL.md | head -5
```

Expected: The YAML frontmatter starting with `---` and `name: openldr-dashboard`.

- [ ] **Step 4: Commit**

```bash
git add openldr-dashboard/SKILL.md
git commit -m "feat(openldr-dashboard): add SKILL.md entry point with routing logic"
```

---

### Task 2: Create `tb-reference-patterns.md`

This is the most content-heavy reference file. It distills the TB dashboard's conventions into reusable patterns.

**Files:**
- Create: `openldr-dashboard/references/tb-reference-patterns.md`

- [ ] **Step 1: Write the reference file**

Create `openldr-dashboard/references/tb-reference-patterns.md` with the following content. This file documents every pattern the skill needs to generate dashboard code. All code snippets are abstracted from the TB dashboard — domain-specific TB references are replaced with generic placeholders.

```markdown
# TB Dashboard Reference Patterns

This guide contains the conventions and code patterns extracted from the TB (Tuberculosis) dashboard — the reference implementation for all OpenLDR dashboards. When generating code for new dashboards, follow these patterns unless the target dashboard has established its own conventions.

**Source:** `apps/tb/` in the openldr-monorepo

---

## 1. Root Layout Pattern

File: `app/layout.tsx`

The root layout wraps the entire app with theme and auth providers.

` ``tsx
import "./globals.css";
import type { Metadata } from "next";
import { Open_Sans } from "next/font/google";
import { ThemeProvider } from "../context/theme-provider";
import { ClerkProvider } from "@clerk/nextjs";

const openSans = Open_Sans({
  variable: "--font-open-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "{APP_TITLE}",           // e.g., "Portal de TB"
  description: "{APP_DESCRIPTION}", // e.g., "Portal de Tuberculose"
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt" suppressHydrationWarning>
      <body className={`${openSans.variable} antialiased`} suppressHydrationWarning>
        <ThemeProvider
          attribute="class"
          defaultTheme="light"
          enableSystem
          disableTransitionOnChange
        >
          <ClerkProvider
            signInUrl="/sign-in"
            signUpUrl="/sign-up"
            afterSignInUrl="/"
            afterSignUpUrl="/"
            appearance={{
              elements: {
                formButtonPrimary: "bg-primary hover:bg-primary/90",
              },
            }}
            publishableKey={process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY}
          >
            {children}
          </ClerkProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
` ``

**Key points:**
- Font: Open Sans loaded via `next/font/google`
- Provider order: `ThemeProvider` → `ClerkProvider` → children
- `suppressHydrationWarning` on `<html>` and `<body>` to avoid theme flash
- Clerk's `publishableKey` from env var `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`

---

## 2. Dashboard Layout Pattern

File: `app/(dashboard)/layout.tsx`

The dashboard layout wraps authenticated pages with the design system's DashboardLayout, AI chat, and theme context.

` ``tsx
"use client";
import { useEffect, useState, useMemo } from "react";
import { DashboardLayout } from "@repo/design_system/app/templates/DashboardLayout";
import { SettingsProps } from "@repo/design_system/app/molecules/headers/SettingsDrawer";
import { useLayoutSettings } from "../../hooks/useLayoutSettings";
import { AIChatProvider } from "@repo/ai/src/context/ai-chat-provider";
import { AppProvider } from "@repo/design_system/contexts";
import { darkMode } from "../../themes/dark";
import { lightMode } from "../../themes/light";
import { useUser, useAuth } from "@clerk/nextjs";
import { useTheme } from "next-themes";
import { usePathname } from "next/navigation";
// Import icons from design system:
// import { IconlyGrid } from "@repo/design_system/app/atoms/icons/Grid";

const SMALL_SCREEN_BREAKPOINT = 1280;

export default function Layout({ children }: { children: React.ReactNode }) {
  const { settings, setSettings } = useLayoutSettings();
  const [mounted, setMounted] = useState(false);
  const { isLoaded, isSignedIn, user } = useUser();
  const { signOut } = useAuth();
  const { theme, setTheme } = useTheme();
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
    const handleResize = () => {
      if (window.innerWidth < SMALL_SCREEN_BREAKPOINT && settings.compact !== "large") {
        setSettings({ ...settings, compact: "large" });
      }
    };
    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, [settings, setSettings]);

  // Define navigation options — customize per dashboard
  const navbarOptions = [
    { label: "Sumário", icon: /* icon component */, href: "/", active: false },
    // Add more sections...
  ].map(option => ({ ...option, active: option.href === pathname }));

  const handleSetAppSettings = (settings: SettingsProps) => {
    setTheme(settings.mode);
    setSettings(settings);
  };

  if (!mounted) return null;

  return (
    <AppProvider lightTheme={lightMode} darkTheme={darkMode} themeMode={settings?.mode}>
      <AIChatProvider
        dashboard="{APP_ID}"  // e.g., "tb", "hivvl"
        panelSizes={{ left: settings.leftPanelWidth, right: settings.rightPanelWidth }}
        onPanelResize={(sizes) =>
          setSettings({ ...settings, leftPanelWidth: sizes.left, rightPanelWidth: sizes.right })
        }
      >
        <DashboardLayout
          pagename={/* derive from pathname */}
          options={navbarOptions}
          user={{
            name: user?.fullName || "",
            avatar: user?.imageUrl || "",
            email: user?.emailAddresses[0].emailAddress || "",
            signOut: () => signOut(),
          }}
          settings={settings}
          handleSetAppSettings={handleSetAppSettings}
        >
          {children}
        </DashboardLayout>
      </AIChatProvider>
    </AppProvider>
  );
}
` ``

**Key points:**
- Provider nesting: `AppProvider` → `AIChatProvider` → `DashboardLayout`
- `AIChatProvider` takes a `dashboard` string prop to identify the app
- `DashboardLayout` receives user info, navbar options, settings
- Responsive: compact mode forced on screens < 1280px
- `mounted` state prevents hydration mismatch

---

## 3. Theme Provider Pattern

File: `context/theme-provider.tsx`

` ``tsx
"use client";
import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => { setMounted(true); }, []);
  if (!mounted) return null;
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
` ``

---

## 4. Theme Objects Pattern

Files: `themes/dark.ts`, `themes/light.ts`

MUI theme objects. Customize `primary.main` per dashboard — TB uses green (#00B000).

` ``ts
// themes/dark.ts
export const darkMode = {
  palette: {
    mode: "dark",
    primary: { main: "#00B000" },      // Customize per dashboard
    secondary: { main: "#F8A200" },
    error: { main: "#EF5350" },
    success: { main: "#00B000" },
    warning: { main: "#F8A200" },
    info: { main: "#6B52DC" },
    background: { paper: "#1d232a", default: "#141a21" },
    text: {
      primary: "#fff",
      secondary: "#8996a0",
      disabled: "rgba(255, 255, 255, 0.6)",
    },
    divider: "rgba(145, 158, 171, 0.24)",
  },
  typography: {
    fontFamily: '"Open Sans", "Nunito Sans", sans-serif',
    button: { textTransform: "none" },
  },
  shape: { borderRadius: 4 },
};
` ``

` ``ts
// themes/light.ts
export const lightMode = {
  palette: {
    mode: "light",
    primary: { main: "#00B000" },      // Customize per dashboard
    secondary: { main: "#F8A200" },
    error: { main: "#EF5350" },
    success: { main: "#00B000" },
    warning: { main: "#F8A200" },
    info: { main: "#6B52DC" },
    background: { paper: "#fff", default: "#f4f4f4" },
    text: {
      primary: "#333333",
      secondary: "#8996a0",
      disabled: "rgba(51, 51, 51, 0.4)",
    },
    divider: "#e5e5e5",
  },
  typography: {
    fontFamily: '"Open Sans", "Nunito Sans", sans-serif',
    button: { textTransform: "none" },
  },
  shape: { borderRadius: 4 },
};
` ``

---

## 5. Zustand Settings Store Pattern

File: `hooks/useLayoutSettings.ts`

` ``ts
import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { SettingsProps } from "@repo/design_system/app/molecules/headers/SettingsDrawer";

interface LayoutSettingsState {
  settings: SettingsProps;
  setSettings: (settings: SettingsProps) => void;
}

export const useLayoutSettings = create<LayoutSettingsState>()(
  persist(
    (set) => ({
      settings: {
        mode: "light",
        contrast: "positive",
        layout: "compact",
        compact: "large",
        color: "apparent",
        rightPanelWidth: 25,
        leftPanelWidth: 75,
      },
      setSettings: (settings) => set({ settings }),
    }),
    { name: "layout-settings" }
  )
);
` ``

**Key points:**
- Persisted to localStorage under key `"layout-settings"`
- Controls theme mode, layout density, AI panel sizes
- Used by dashboard layout to pass settings to `DashboardLayout`

---

## 6. Auth Middleware Pattern

File: `middleware.ts`

` ``ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";

const isPublicRoute = createRouteMatcher(["/sign-in(.*)", "/sign-up(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (!isPublicRoute(req)) {
    try {
      await auth.protect();
    } catch (err) {
      const signInUrl = new URL("/sign-in", req.url);
      return NextResponse.redirect(signInUrl);
    }
  }
  return NextResponse.next();
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
` ``

---

## 7. API Client Pattern

File: `config/api.ts`

` ``ts
import axios from "axios";

export const api = (token: string) =>
  axios.create({
    baseURL: process.env.NEXT_PUBLIC_OPENLDR_API,
    timeout: 60000,
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
` ``

**Usage in reports:**
```ts
import { api } from "@/config/api";
const token = await getToken(); // from @clerk/nextjs useAuth()
const response = await api(token).get(API_CONFIG.BASE_URL, { params });
```

---

## 8. Report File Structure (6-File Pattern)

Each report lives in its own directory under a section's `reports/` folder:

```
app/(dashboard)/<section>/reports/<report-name>/
├── index.tsx              # Main React component
├── actions.ts             # API functions, types, data transformation
├── constants.ts           # Config: API_CONFIG, DEFAULTS, CHART_CONFIG, UI_CONFIG
├── excel-export-utils.ts  # Excel export with xlsx library
├── chart-export-utils.ts  # PNG export via html2canvas + ApexCharts
└── docs.tsx               # In-app documentation (MUI components, Portuguese)
```

### 8.1 `constants.ts` Pattern

` ``ts
import { FacilityType, getLastTwelveMonths } from "./actions";

export const API_CONFIG = {
  BASE_URL: `${process.env.NEXT_PUBLIC_OPENLDR_API}/{module}/{view}/{endpoint}/`,
  TIMEOUT: 60000,
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 1000,
} as const;

export const DEFAULTS = {
  TIME_INTERVAL: getLastTwelveMonths(),
  FACILITY_TYPE: "province" as FacilityType,
  ACTIVE_TAB: "ultra" as const,        // Customize per domain
  DISAGGREGATION: false,
  REPORT_NAME: "Nome do Relatório",     // Portuguese
} as const;

export const CHART_CONFIG = {
  HEIGHT: 350,
  CHART_ID: "unique-chart-id",         // Unique per report for export
  SERIES_NAME: "Nome da Série",        // Portuguese
  COLORS: {
    PRIMARY: ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd"],
    SECONDARY: ["#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"],
  },
} as const;

export const UI_CONFIG = {
  TAB_OPTIONS: [
    { value: "tab1", label: "Tab 1" },
    { value: "tab2", label: "Tab 2" },
  ] as const,
  MAIN_CARD_OPTIONS: {
    HEIGHT: "auto",
    LAB_TYPE: "poc",
    REPORT_TYPE: "facility",
  } as const,
} as const;
` ``

### 8.2 `actions.ts` Pattern

` ``ts
import { AxiosError } from "axios";
import { API_CONFIG } from "./constants";
import { api } from "@/config/api";

// ── Types ──
export type Data = {
  // Fields matching the API response shape
  Start_Date: string;
  End_Date: string;
  Testing_Facility: string;
  // ... domain-specific fields
};

export interface FacilityOptions {
  value: string;
  label: string;
  district: string;
  province: string;
}

export interface TimeInterval {
  startDate: string;
  endDate: string;
}

export interface ChartData {
  labels: string[];
  series: Array<{ name: string; data: number[]; group: string }>;
}

export type FacilityType = "province" | "district" | "clinic" | "patients";
export type ActiveTab = string; // Customize per domain

// ── Utilities ──
export const getLastTwelveMonths = (): TimeInterval => {
  const endDate = new Date();
  const startDate = new Date();
  startDate.setMonth(endDate.getMonth() - 11);
  startDate.setDate(1);
  return {
    startDate: startDate.toISOString().split("T")[0],
    endDate: endDate.toISOString().split("T")[0],
  };
};

export const getNextFacilityType = (current: FacilityType): FacilityType => {
  const hierarchy: Record<FacilityType, FacilityType> = {
    province: "district",
    district: "clinic",
    clinic: "province",
    patients: "province",
  };
  return hierarchy[current];
};

// ── API Functions ──
export const buildApiParams = (
  timeInterval: TimeInterval,
  activeTab: ActiveTab,
  facilities: FacilityOptions[],
  facilityType: FacilityType,
  disaggregation: boolean
): Record<string, any> => {
  const baseParams: Record<string, any> = {
    interval_dates: `${timeInterval.startDate},${timeInterval.endDate}`,
    disaggregation: disaggregation ? "True" : "False",
    // Add domain-specific params (e.g., genexpert_result_type for TB)
  };

  const districts = [...new Set(facilities.map((f) => f.district).filter(Boolean))];
  const provinces = [...new Set(facilities.map((f) => f.province).filter(Boolean))];

  return {
    ...baseParams,
    ...(districts.length > 0 && { district: districts }),
    ...(provinces.length > 0 && { province: provinces }),
  };
};

export const fetchFacilityData = async (
  params: Record<string, any>,
  token: string
): Promise<Data[]> => {
  try {
    const response = await api(token).get(API_CONFIG.BASE_URL, {
      params,
      paramsSerializer: { indexes: null },
      timeout: API_CONFIG.TIMEOUT,
    });
    return response.data?.length ? response.data : [];
  } catch (error) {
    const msg =
      error instanceof AxiosError
        ? error.response?.data?.message || error.message
        : error instanceof Error
          ? error.message
          : "An error occurred";
    throw new Error(msg);
  }
};

// ── Data Transformation ──
export const prepareChartData = (data: Data[]): ChartData => {
  if (!data?.length) return { labels: [], series: [] };
  // Transform API response into chart labels + series
  // Customize per report
  return { labels: [], series: [] };
};

export const createFacilityOptions = (
  label: string,
  currentType: FacilityType,
  currentFacilities: FacilityOptions[]
): FacilityOptions => {
  const current = currentFacilities[0];
  return {
    value: label,
    label,
    district: currentType === "district" ? label : current?.district || "",
    province: currentType === "province" ? label : current?.province || "",
  };
};
` ``

### 8.3 `index.tsx` Pattern (Report Component)

` ``tsx
"use client";
import { useEffect, useState, useCallback, useMemo } from "react";
import { Stacked } from "@repo/design_system/app/atoms/charts/apex/Stacked";
import { PiMicrosoftExcelLogoFill } from "react-icons/pi";
import { IoImageOutline } from "react-icons/io5";
import { VscDebugRestart } from "react-icons/vsc";
import { MainCard } from "@repo/design_system/app/organisms/cards/MainCard";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DEFAULTS, CHART_CONFIG, UI_CONFIG } from "./constants";
import {
  FacilityType, FacilityOptions, ActiveTab, Data, TimeInterval,
  buildApiParams, prepareChartData, fetchFacilityData,
  getNextFacilityType, createFacilityOptions, getReportName,
} from "./actions";
import { exportChartToExcel } from "./excel-export-utils";
import { exportChart } from "./chart-export-utils";
import Docs from "./docs";
import { useAuth, useUser } from "@clerk/nextjs";

interface ReportState {
  data: Data[];
  loading: boolean;
  error: string | null;
  activeTab: ActiveTab;
  timeInterval: TimeInterval;
  facilities: FacilityOptions[];
  facilityType: FacilityType;
  disaggregation: boolean;
}

export default function ReportComponent() {
  const { user } = useUser();
  const { getToken } = useAuth();

  const [reportState, setReportState] = useState<ReportState>({
    data: [],
    loading: true,
    error: null,
    activeTab: DEFAULTS.ACTIVE_TAB,
    timeInterval: DEFAULTS.TIME_INTERVAL,
    facilities: [],
    facilityType: DEFAULTS.FACILITY_TYPE,
    disaggregation: DEFAULTS.DISAGGREGATION,
  });

  const chartData = useMemo(() => prepareChartData(reportState.data), [reportState.data]);

  const fetchDataFromApi = useCallback(async (
    startDate: string, endDate: string,
    disaggregation: boolean, facilities: FacilityOptions[],
    facilityType?: FacilityType
  ) => {
    try {
      setReportState((prev) => ({ ...prev, loading: true, error: null }));
      const token = await getToken();
      const params = buildApiParams(
        { startDate, endDate }, reportState.activeTab,
        facilities, facilityType || reportState.facilityType, disaggregation
      );
      const data = await fetchFacilityData(params, token);
      setReportState((prev) => ({ ...prev, data, loading: false }));
    } catch (error) {
      const msg = error instanceof Error ? error.message : "Ocorreu um erro";
      setReportState((prev) => ({ ...prev, loading: false, error: msg }));
    }
  }, [reportState.activeTab, reportState.facilityType, getToken]);

  // Chart click handler — drill down through facility hierarchy
  const handleChartClick = useCallback(async (label: string) => {
    if (!label) return;
    const newType = getNextFacilityType(reportState.facilityType);
    const newFacility = createFacilityOptions(label, reportState.facilityType, reportState.facilities);
    setReportState((prev) => ({
      ...prev, facilityType: newType, facilities: [newFacility], disaggregation: true,
    }));
    await fetchDataFromApi(
      reportState.timeInterval.startDate, reportState.timeInterval.endDate,
      true, [newFacility], newType
    );
  }, [reportState, fetchDataFromApi]);

  const handleRestart = useCallback(() => {
    setReportState((prev) => ({
      ...prev,
      disaggregation: DEFAULTS.DISAGGREGATION,
      facilities: [],
      facilityType: DEFAULTS.FACILITY_TYPE,
      timeInterval: DEFAULTS.TIME_INTERVAL,
      activeTab: DEFAULTS.ACTIVE_TAB,
    }));
  }, []);

  useEffect(() => {
    fetchDataFromApi(
      reportState.timeInterval.startDate, reportState.timeInterval.endDate,
      reportState.disaggregation, reportState.facilities, reportState.facilityType
    );
  }, [reportState.timeInterval, reportState.disaggregation, reportState.facilities,
      reportState.facilityType, reportState.activeTab, fetchDataFromApi]);

  const mainCardOptions = useMemo(() => [
    { action: () => exportChartToExcel(chartData, reportState, DEFAULTS.REPORT_NAME, () => ({})),
      icon: <PiMicrosoftExcelLogoFill size={20} />, label: "Exportar para Excel", type: "primary" as const },
    { action: () => exportChart(CHART_CONFIG.CHART_ID, DEFAULTS.REPORT_NAME),
      icon: <IoImageOutline size={20} />, label: "Exportar imagem", type: "primary" as const },
    { action: handleRestart,
      icon: <VscDebugRestart size={20} />, label: "Reiniciar o relatorio", type: "primary" as const },
  ], [chartData, reportState, handleRestart]);

  return (
    <MainCard
      additionalOptions={mainCardOptions}
      chartId={CHART_CONFIG.CHART_ID}
      documentation={<Docs />}
      headerProps={{ sx: { padding: 2 } }}
      height={UI_CONFIG.MAIN_CARD_OPTIONS.HEIGHT}
      loading={reportState.loading}
      reportType="lab"
      title={DEFAULTS.REPORT_NAME}
      user={{ email: user?.emailAddresses[0].emailAddress, name: user?.fullName || "" }}
      width="100%"
      handleSubmit={(dates, facilities, facilityType) => {
        setReportState((prev) => ({
          ...prev, facilities, facilityType: "district",
          timeInterval: { startDate: dates[0], endDate: dates[1] },
          disaggregation: true,
        }));
      }}
    >
      <Tabs defaultValue={DEFAULTS.ACTIVE_TAB} className="w-full">
        <TabsList className="mx-4 ml-auto">
          {UI_CONFIG.TAB_OPTIONS.map((opt) => (
            <TabsTrigger key={opt.value} value={opt.value}
              className="dark:data-[state=active]:border-gray-950 dark:data-[state=active]:bg-gray-950 text-xs">
              {opt.label}
            </TabsTrigger>
          ))}
        </TabsList>
        {UI_CONFIG.TAB_OPTIONS.map((opt) => (
          <TabsContent key={opt.value} value={opt.value} className="px-4 pb-4">
            <Stacked
              id={CHART_CONFIG.CHART_ID}
              height={CHART_CONFIG.HEIGHT}
              labels={chartData.labels}
              onClick={handleChartClick}
              series={chartData.series}
            />
          </TabsContent>
        ))}
      </Tabs>
    </MainCard>
  );
}
` ``

### 8.4 `excel-export-utils.ts` Pattern

Uses the `xlsx` library. Key functions:
- `validateExportData(data)` — checks array is non-empty
- `prepareChartDataForExcel(labels, series, reportState, getFacilityProperty)` — maps report data to export rows with Portuguese column headers
- `createFormattedWorksheet(options)` — creates worksheet with title row, headers, column widths
- `createAndSaveWorkbook(worksheet, options)` — saves as `.xlsx` with timestamp in filename
- `exportChartToExcel(chartData, reportState, reportName, getFacilityProperty)` — main export function

### 8.5 `chart-export-utils.ts` Pattern

Uses `html2canvas` with fallback strategies:
1. Try ApexCharts native export (`chart.dataURI`)
2. Try html2canvas with OKLCH color fix
3. Try direct canvas with SVG serialization
4. Try SVG-to-canvas conversion

Main function: `exportChart(chartId: string, reportName: string)`

### 8.6 `docs.tsx` Pattern

MUI-based documentation component in Portuguese. Structure:
- Header with icon + report title
- "Visão Geral" section
- Test/data types section
- Chart visualization explanation
- Usage instructions (numbered steps)
- Key indicators
- Data quality notes
- Technical notes (API endpoint, data structure, timeout)

---

## 9. Section Page Pattern

File: `app/(dashboard)/<section>/page.tsx`

` ``tsx
export default function SectionPage() {
  return (
    <div className="w-full">
      <div className="grid grid-cols-1 @container gap-8">
        <div className="@[900px]:grid-cols-2 grid gap-8">
          {/* Import and render report components */}
          <ReportA />
          <ReportB />
        </div>
      </div>
    </div>
  );
}
` ``

**Key points:**
- Responsive grid using `@container` queries
- 1 column on small screens, 2 columns at 900px+
- Each report component is self-contained (handles its own data fetching)

---

## 10. Auth Pages Pattern

Files: `app/(auth)/layout.tsx`, `app/(auth)/sign-in/page.tsx`, `app/(auth)/sign-in/client.tsx`

` ``tsx
// (auth)/layout.tsx
export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen items-center justify-center">
      {children}
    </div>
  );
}
` ``

` ``tsx
// (auth)/sign-in/page.tsx
import SignInClient from "./client";
export default function SignInPage() {
  return <SignInClient />;
}
` ``

` ``tsx
// (auth)/sign-in/client.tsx
"use client";
import { SignIn } from "@clerk/nextjs";
export default function SignInClient() {
  return <SignIn routing="path" path="/sign-in" signUpUrl="/sign-up" />;
}
` ``

---

## 11. Next.js Config Pattern

File: `next.config.ts`

` ``ts
import type { NextConfig } from "next";
import createMDX from "@next/mdx";

const withMDX = createMDX({
  extension: /\.mdx?$/,
  options: { remarkPlugins: [], rehypePlugins: [] },
});

const nextConfig: NextConfig = {
  experimental: {
    serverActions: { bodySizeLimit: "10mb" },
  },
  env: {
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  },
  turbopack: {
    rules: { "*.mdx": { loaders: ["@mdx-js/loader"], as: "*.js" } },
  },
};

export default withMDX(nextConfig);
` ``

---

## 12. Package.json Dependencies

Standard workspace dependencies for a dashboard app:

` ``json
{
  "dependencies": {
    "@clerk/nextjs": "^6.18.5",
    "@mdx-js/loader": "^3.0.0",
    "@mdx-js/react": "^3.1.0",
    "@next/mdx": "^14.0.4",
    "@radix-ui/react-dialog": "^1.1.14",
    "@radix-ui/react-dropdown-menu": "^2.1.14",
    "@radix-ui/react-label": "^2.1.3",
    "@radix-ui/react-scroll-area": "^1.2.3",
    "@radix-ui/react-select": "^2.2.5",
    "@radix-ui/react-separator": "^1.1.4",
    "@radix-ui/react-slot": "^1.1.2",
    "@radix-ui/react-tabs": "^1.1.12",
    "@radix-ui/react-toggle": "^1.1.3",
    "@radix-ui/react-toggle-group": "^1.1.3",
    "@react-google-maps/api": "^2.20.7",
    "@repo/ai": "workspace:*",
    "@repo/auth": "workspace:*",
    "@repo/design_system": "workspace:*",
    "@repo/utilities": "workspace:*",
    "@tailwindcss/typography": "^0.5.10",
    "@tanstack/react-table": "^8.21.3",
    "apexcharts": "^5.3.4",
    "axios": "^1.8.3",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "html2canvas": "^1.4.1",
    "lucide-react": "^0.482.0",
    "next": "15.3.2",
    "next-themes": "^0.2.1",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-icons": "^5.4.0",
    "react-resizable-panels": "^3.0.2",
    "react-spinners": "^0.15.0",
    "recharts": "2.15.4",
    "tailwind-merge": "^3.3.0",
    "xlsx": "^0.18.5",
    "zustand": "^5.0.4"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3",
    "@tailwindcss/postcss": "^4",
    "@types/html2canvas": "^1.0.0",
    "@types/node": "^20",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "eslint": "^9",
    "eslint-config-next": "15.3.2",
    "tailwindcss": "^4",
    "tw-animate-css": "^1.2.5",
    "typescript": "^5"
  }
}
` ``

---

## 13. Design System Imports Reference

Key imports from `@repo/design_system`:

| Import | Purpose |
|---|---|
| `@repo/design_system/app/templates/DashboardLayout` | Main dashboard shell (sidebar, navbar, content area) |
| `@repo/design_system/app/organisms/cards/MainCard` | Report card wrapper (title, subtitle, filters, actions) |
| `@repo/design_system/app/atoms/charts/apex/Stacked` | Stacked bar chart (ApexCharts) |
| `@repo/design_system/app/atoms/icons/*` | Icon components (Grid, Location, Patients, etc.) |
| `@repo/design_system/app/molecules/headers/SettingsDrawer` | Settings type (`SettingsProps`) |
| `@repo/design_system/contexts` | `AppProvider` for MUI theme injection |

Key imports from `@repo/ai`:
| Import | Purpose |
|---|---|
| `@repo/ai/src/context/ai-chat-provider` | `AIChatProvider` wraps dashboard for AI chat |

Key imports from `@repo/auth`:
| Import | Purpose |
|---|---|
| `@repo/auth` | `AuthProvider` (alternative to Clerk, currently unused) |
```

**Note:** Fix all triple-backtick code blocks in the file — remove the space in the opening backticks (added to avoid markdown parsing issues in this plan).

- [ ] **Step 2: Verify the file was created**

```bash
wc -l openldr-dashboard/references/tb-reference-patterns.md
```

Expected: approximately 400-500 lines.

- [ ] **Step 3: Commit**

```bash
git add openldr-dashboard/references/tb-reference-patterns.md
git commit -m "feat(openldr-dashboard): add TB reference patterns guide"
```

---

### Task 3: Create `scaffold-guide.md`

**Files:**
- Create: `openldr-dashboard/references/scaffold-guide.md`

- [ ] **Step 1: Write the scaffold guide**

Create `openldr-dashboard/references/scaffold-guide.md` with the following content:

```markdown
# Scaffold Guide — Create a New Dashboard App

This guide walks through creating a new dashboard app in the OpenLDR turborepo monorepo. The result is a working Next.js 15 app with authentication, theming, AI chat, and navigation — ready for reports to be added.

---

## Prerequisites

- The monorepo path has been resolved (Phase 1 of SKILL.md)
- User has provided: dashboard name, navigation sections

## Process

` ``dot
digraph scaffold {
  "Gather Requirements" [shape=box];
  "Validate App Name" [shape=box];
  "Run scaffold-dashboard.sh" [shape=box];
  "Customize Navigation" [shape=box];
  "Set Up i18n" [shape=box];
  "Install Dependencies" [shape=box];
  "Verify Dev Server" [shape=doublecircle];

  "Gather Requirements" -> "Validate App Name";
  "Validate App Name" -> "Run scaffold-dashboard.sh";
  "Run scaffold-dashboard.sh" -> "Customize Navigation";
  "Customize Navigation" -> "Set Up i18n";
  "Set Up i18n" -> "Install Dependencies";
  "Install Dependencies" -> "Verify Dev Server";
}
` ``

## Step 1: Gather Requirements

Ask the user for:

1. **Dashboard name** (lowercase, kebab-case) — e.g., `hivvl`, `eid`, `cd4`
2. **Display title** (Portuguese) — e.g., "Portal de HIV Carga Viral"
3. **Navigation sections** — e.g., "Sumário, Laboratório, Província, Pacientes"
4. **Primary color** (hex) — for the MUI theme. Default: `#00B000` (green)
5. **API module path** — e.g., `/hiv/vl/`, `/hiv/eid/`, `/tb/gx/`. Can be multiple.

## Step 2: Validate

- Check that `{monorepo}/apps/{name}` does not already exist
- Check that the name is lowercase and contains only letters, numbers, and hyphens

## Step 3: Run Scaffold Script

```bash
cd {skills_repo}
scripts/scaffold-dashboard.sh {app-name} --sections "{section1},{section2},{section3}" --monorepo {monorepo_path}
```

The script creates the full directory structure and template files. See `tb-reference-patterns.md` for the code patterns used in each generated file.

## Step 4: Customize After Scaffold

After the script runs, customize these files:

### 4a. Dashboard Layout Navigation

Edit `app/(dashboard)/layout.tsx`:
- Update `navbarOptions` with the sections from Step 1
- Set the `dashboard` prop on `AIChatProvider` to the app name
- Update `pathToLabel` mapping for Portuguese labels

### 4b. Theme Colors

Edit `themes/dark.ts` and `themes/light.ts`:
- Set `primary.main` to the chosen color

### 4c. Root Layout Metadata

Edit `app/layout.tsx`:
- Set `title` and `description` in Portuguese

### 4d. Environment Variables

Create `.env.local` from `.env.local.template`:
```
NEXT_PUBLIC_OPENLDR_API=https://dev.openldr.org.mz
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
```

### 4e. i18n Setup

Create `messages/pt.json` with navigation labels and common UI strings:
```json
{
  "navigation": {
    "summary": "Sumário",
    "laboratory": "Laboratório",
    "clinic": "Província",
    "patients": "Pacientes"
  },
  "common": {
    "export_excel": "Exportar para Excel",
    "export_image": "Exportar imagem",
    "restart": "Reiniciar o relatório",
    "loading": "A carregar...",
    "error": "Ocorreu um erro",
    "no_data": "Sem dados disponíveis"
  }
}
```

Create `messages/en.json` with the same keys in English (skeleton for future use).

## Step 5: Install and Verify

```bash
cd {monorepo}
pnpm install
pnpm dev --filter={app-name}
```

The app should boot at `http://localhost:300X` with:
- Clerk sign-in page on protected routes
- Empty dashboard shell with navigation sidebar
- Theme toggle working (light/dark)
- AI chat panel available

## What's Next

Use the **report guide** (`references/report-guide.md`) to add reports to the newly created dashboard.
```

**Note:** Fix the dot code block backticks.

- [ ] **Step 2: Commit**

```bash
git add openldr-dashboard/references/scaffold-guide.md
git commit -m "feat(openldr-dashboard): add scaffold guide for new dashboard apps"
```

---

### Task 4: Create `scaffold-dashboard.sh`

**Files:**
- Create: `openldr-dashboard/scripts/scaffold-dashboard.sh`

- [ ] **Step 1: Write the scaffold script**

Create `openldr-dashboard/scripts/scaffold-dashboard.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# scaffold-dashboard.sh — Bootstrap a new dashboard app in the OpenLDR monorepo
# ============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") <app-name> [OPTIONS]

Create a new dashboard app in the OpenLDR turborepo monorepo.

Arguments:
  app-name              Lowercase name for the app (e.g., hivvl, eid, cd4)

Options:
  --sections "a,b,c"    Comma-separated navigation sections (default: "summary")
  --monorepo PATH       Path to the monorepo root (default: auto-detect)
  --help                Show this help

Examples:
  $(basename "$0") hivvl --sections "summary,lab,clinic,patients"
  $(basename "$0") eid --monorepo /path/to/openldr-monorepo
EOF
  exit 0
}

# ── Parse arguments ──
APP_NAME=""
SECTIONS="summary"
MONOREPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sections) SECTIONS="$2"; shift 2 ;;
    --monorepo) MONOREPO="$2"; shift 2 ;;
    --help) usage ;;
    -*) echo "Error: Unknown option $1" >&2; exit 1 ;;
    *) APP_NAME="$1"; shift ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Error: app-name is required" >&2
  usage
fi

# Validate app name
if [[ ! "$APP_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: app-name must be lowercase, start with a letter, and contain only letters, numbers, hyphens" >&2
  exit 1
fi

# ── Resolve monorepo path ──
if [[ -z "$MONOREPO" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SKILLS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  # Try sibling directory pattern
  MONOREPO="$(cd "$SKILLS_ROOT/../../openldr/openldr-monorepo" 2>/dev/null && pwd)" || true
  if [[ -z "$MONOREPO" || ! -f "$MONOREPO/turbo.json" ]]; then
    echo "Error: Could not find monorepo. Use --monorepo to specify the path." >&2
    exit 1
  fi
fi

if [[ ! -f "$MONOREPO/turbo.json" ]]; then
  echo "Error: $MONOREPO does not look like a turborepo (no turbo.json)" >&2
  exit 1
fi

APP_DIR="$MONOREPO/apps/$APP_NAME"

if [[ -d "$APP_DIR" ]]; then
  echo "Error: $APP_DIR already exists" >&2
  exit 1
fi

echo "Creating dashboard app: $APP_NAME"
echo "Monorepo: $MONOREPO"
echo "Sections: $SECTIONS"
echo ""

# ── Create directory structure ──
IFS=',' read -ra SECTION_ARRAY <<< "$SECTIONS"

mkdir -p "$APP_DIR"/{app/{api,"(auth)"/{sign-in,sign-up},"(dashboard)"},components/ui,config,context,hooks,themes,public,messages,lib}

# Create section directories under (dashboard)
for section in "${SECTION_ARRAY[@]}"; do
  section=$(echo "$section" | xargs) # trim whitespace
  if [[ "$section" == "summary" || "$section" == "${SECTION_ARRAY[0]}" ]]; then
    mkdir -p "$APP_DIR/app/(dashboard)/(index)/reports"
  else
    mkdir -p "$APP_DIR/app/(dashboard)/$section/reports"
  fi
done

# ── Generate package.json ──
cat > "$APP_DIR/package.json" << 'PKGJSON'
{
  "name": "APP_NAME_PLACEHOLDER",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@clerk/nextjs": "^6.18.5",
    "@mdx-js/loader": "^3.0.0",
    "@mdx-js/react": "^3.1.0",
    "@next/mdx": "^14.0.4",
    "@radix-ui/react-dialog": "^1.1.14",
    "@radix-ui/react-dropdown-menu": "^2.1.14",
    "@radix-ui/react-label": "^2.1.3",
    "@radix-ui/react-scroll-area": "^1.2.3",
    "@radix-ui/react-select": "^2.2.5",
    "@radix-ui/react-separator": "^1.1.4",
    "@radix-ui/react-slot": "^1.1.2",
    "@radix-ui/react-tabs": "^1.1.12",
    "@radix-ui/react-toggle": "^1.1.3",
    "@radix-ui/react-toggle-group": "^1.1.3",
    "@react-google-maps/api": "^2.20.7",
    "@repo/ai": "workspace:*",
    "@repo/auth": "workspace:*",
    "@repo/design_system": "workspace:*",
    "@repo/utilities": "workspace:*",
    "@tailwindcss/typography": "^0.5.10",
    "@tanstack/react-table": "^8.21.3",
    "apexcharts": "^5.3.4",
    "axios": "^1.8.3",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "html2canvas": "^1.4.1",
    "lucide-react": "^0.482.0",
    "next": "15.3.2",
    "next-intl": "^3.0.0",
    "next-themes": "^0.2.1",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-icons": "^5.4.0",
    "react-resizable-panels": "^3.0.2",
    "react-spinners": "^0.15.0",
    "recharts": "2.15.4",
    "tailwind-merge": "^3.3.0",
    "xlsx": "^0.18.5",
    "zustand": "^5.0.4"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3",
    "@tailwindcss/postcss": "^4",
    "@types/html2canvas": "^1.0.0",
    "@types/node": "^20",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "eslint": "^9",
    "eslint-config-next": "15.3.2",
    "tailwindcss": "^4",
    "tw-animate-css": "^1.2.5",
    "typescript": "^5"
  }
}
PKGJSON
sed -i "s/APP_NAME_PLACEHOLDER/$APP_NAME/g" "$APP_DIR/package.json"

# ── Generate config files ──

# next.config.ts
cat > "$APP_DIR/next.config.ts" << 'EOF'
import type { NextConfig } from "next";
import createMDX from "@next/mdx";

const withMDX = createMDX({
  extension: /\.mdx?$/,
  options: { remarkPlugins: [], rehypePlugins: [] },
});

const nextConfig: NextConfig = {
  experimental: {
    serverActions: { bodySizeLimit: "10mb" },
  },
  env: {
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  },
  turbopack: {
    rules: { "*.mdx": { loaders: ["@mdx-js/loader"], as: "*.js" } },
  },
};

export default withMDX(nextConfig);
EOF

# tsconfig.json
cat > "$APP_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# tailwind.config.ts
cat > "$APP_DIR/tailwind.config.ts" << 'EOF'
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "../../packages/design_system/**/*.{ts,tsx}",
  ],
  theme: { extend: {} },
  plugins: [],
};

export default config;
EOF

# postcss.config.mjs
cat > "$APP_DIR/postcss.config.mjs" << 'EOF'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
export default config;
EOF

# eslint.config.mjs
cat > "$APP_DIR/eslint.config.mjs" << 'EOF'
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({ baseDirectory: __dirname });

const eslintConfig = [...compat.extends("next/core-web-vitals", "next/typescript")];
export default eslintConfig;
EOF

# components.json (Shadcn UI config)
cat > "$APP_DIR/components.json" << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
EOF

# .gitignore
cat > "$APP_DIR/.gitignore" << 'EOF'
# dependencies
node_modules
.pnp
.pnp.js

# testing
coverage

# next.js
.next/
out/

# production
build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*

# local env files
.env*.local

# turbo
.turbo

# typescript
*.tsbuildinfo
EOF

# .env.local.template
cat > "$APP_DIR/.env.local.template" << 'EOF'
NEXT_PUBLIC_OPENLDR_API=https://dev.openldr.org.mz
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
EOF

# next-env.d.ts
cat > "$APP_DIR/next-env.d.ts" << 'EOF'
/// <reference types="next" />
/// <reference types="next/image-types/global" />
// NOTE: This file should not be edited
EOF

# ── Generate source files ──

# config/api.ts
cat > "$APP_DIR/config/api.ts" << 'EOF'
import axios from "axios";

export const api = (token: string) =>
  axios.create({
    baseURL: process.env.NEXT_PUBLIC_OPENLDR_API,
    timeout: 60000,
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
EOF

# context/theme-provider.tsx
cat > "$APP_DIR/context/theme-provider.tsx" << 'EOF'
"use client";
import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => { setMounted(true); }, []);
  if (!mounted) return null;
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
EOF

# hooks/useLayoutSettings.ts
cat > "$APP_DIR/hooks/useLayoutSettings.ts" << 'EOF'
import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { SettingsProps } from "@repo/design_system/app/molecules/headers/SettingsDrawer";

interface LayoutSettingsState {
  settings: SettingsProps;
  setSettings: (settings: SettingsProps) => void;
}

export const useLayoutSettings = create<LayoutSettingsState>()(
  persist(
    (set) => ({
      settings: {
        mode: "light",
        contrast: "positive",
        layout: "compact",
        compact: "large",
        color: "apparent",
        rightPanelWidth: 25,
        leftPanelWidth: 75,
      },
      setSettings: (settings) => set({ settings }),
    }),
    { name: "layout-settings" }
  )
);
EOF

# themes/dark.ts
cat > "$APP_DIR/themes/dark.ts" << 'EOF'
export const darkMode = {
  palette: {
    mode: "dark",
    primary: { main: "#00B000" },
    secondary: { main: "#F8A200" },
    error: { main: "#EF5350" },
    success: { main: "#00B000" },
    warning: { main: "#F8A200" },
    info: { main: "#6B52DC" },
    background: { paper: "#1d232a", default: "#141a21" },
    text: {
      primary: "#fff",
      secondary: "#8996a0",
      disabled: "rgba(255, 255, 255, 0.6)",
    },
    divider: "rgba(145, 158, 171, 0.24)",
  },
  typography: {
    fontFamily: '"Open Sans", "Nunito Sans", sans-serif',
    button: { textTransform: "none" },
  },
  shape: { borderRadius: 4 },
};
EOF

# themes/light.ts
cat > "$APP_DIR/themes/light.ts" << 'EOF'
export const lightMode = {
  palette: {
    mode: "light",
    primary: { main: "#00B000" },
    secondary: { main: "#F8A200" },
    error: { main: "#EF5350" },
    success: { main: "#00B000" },
    warning: { main: "#F8A200" },
    info: { main: "#6B52DC" },
    background: { paper: "#fff", default: "#f4f4f4" },
    text: {
      primary: "#333333",
      secondary: "#8996a0",
      disabled: "rgba(51, 51, 51, 0.4)",
    },
    divider: "#e5e5e5",
  },
  typography: {
    fontFamily: '"Open Sans", "Nunito Sans", sans-serif',
    button: { textTransform: "none" },
  },
  shape: { borderRadius: 4 },
};
EOF

# middleware.ts
cat > "$APP_DIR/middleware.ts" << 'EOF'
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";

const isPublicRoute = createRouteMatcher(["/sign-in(.*)", "/sign-up(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (!isPublicRoute(req)) {
    try {
      await auth.protect();
    } catch (err) {
      const signInUrl = new URL("/sign-in", req.url);
      return NextResponse.redirect(signInUrl);
    }
  }
  return NextResponse.next();
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
EOF

# app/globals.css
cat > "$APP_DIR/app/globals.css" << 'EOF'
@import "tailwindcss";
@import "tw-animate-css";
EOF

# app/layout.tsx (root)
cat > "$APP_DIR/app/layout.tsx" << ROOTLAYOUT
import "./globals.css";
import type { Metadata } from "next";
import { Open_Sans } from "next/font/google";
import { ThemeProvider } from "../context/theme-provider";
import { ClerkProvider } from "@clerk/nextjs";

const openSans = Open_Sans({
  variable: "--font-open-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Portal de ${APP_NAME^}",
  description: "Portal de ${APP_NAME^}",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt" suppressHydrationWarning>
      <body className={\`\${openSans.variable} antialiased\`} suppressHydrationWarning>
        <ThemeProvider
          attribute="class"
          defaultTheme="light"
          enableSystem
          disableTransitionOnChange
        >
          <ClerkProvider
            signInUrl="/sign-in"
            signUpUrl="/sign-up"
            afterSignInUrl="/"
            afterSignUpUrl="/"
            appearance={{
              elements: {
                formButtonPrimary: "bg-primary hover:bg-primary/90",
              },
            }}
            publishableKey={process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY}
          >
            {children}
          </ClerkProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
ROOTLAYOUT

# app/page.tsx (redirect to dashboard)
cat > "$APP_DIR/app/page.tsx" << 'EOF'
import { redirect } from "next/navigation";

export default function Home() {
  redirect("/");
}
EOF

# Auth pages
cat > "$APP_DIR/app/(auth)/layout.tsx" << 'EOF'
export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen items-center justify-center">
      {children}
    </div>
  );
}
EOF

cat > "$APP_DIR/app/(auth)/sign-in/page.tsx" << 'EOF'
import SignInClient from "./client";
export default function SignInPage() {
  return <SignInClient />;
}
EOF

cat > "$APP_DIR/app/(auth)/sign-in/client.tsx" << 'EOF'
"use client";
import { SignIn } from "@clerk/nextjs";
export default function SignInClient() {
  return <SignIn routing="path" path="/sign-in" signUpUrl="/sign-up" />;
}
EOF

cat > "$APP_DIR/app/(auth)/sign-up/page.tsx" << 'EOF'
import SignUpClient from "./client";
export default function SignUpPage() {
  return <SignUpClient />;
}
EOF

cat > "$APP_DIR/app/(auth)/sign-up/client.tsx" << 'EOF'
"use client";
import { SignUp } from "@clerk/nextjs";
export default function SignUpClient() {
  return <SignUp routing="path" path="/sign-up" signInUrl="/sign-in" />;
}
EOF

# Dashboard layout — placeholder (skill will customize after scaffold)
cat > "$APP_DIR/app/(dashboard)/layout.tsx" << 'DASHLAYOUT'
"use client";
import { useEffect, useState } from "react";
import { DashboardLayout } from "@repo/design_system/app/templates/DashboardLayout";
import { SettingsProps } from "@repo/design_system/app/molecules/headers/SettingsDrawer";
import { useLayoutSettings } from "../../hooks/useLayoutSettings";
import { AIChatProvider } from "@repo/ai/src/context/ai-chat-provider";
import { AppProvider } from "@repo/design_system/contexts";
import { darkMode } from "../../themes/dark";
import { lightMode } from "../../themes/light";
import { useUser, useAuth } from "@clerk/nextjs";
import { useTheme } from "next-themes";
import { usePathname } from "next/navigation";

const SMALL_SCREEN_BREAKPOINT = 1280;

export default function Layout({ children }: { children: React.ReactNode }) {
  const { settings, setSettings } = useLayoutSettings();
  const [mounted, setMounted] = useState(false);
  const { user } = useUser();
  const { signOut } = useAuth();
  const { setTheme } = useTheme();
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
    const handleResize = () => {
      if (window.innerWidth < SMALL_SCREEN_BREAKPOINT && settings.compact !== "large") {
        setSettings({ ...settings, compact: "large" });
      }
    };
    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, [settings, setSettings]);

  // TODO: Customize navigation options for this dashboard
  const navbarOptions = [
    { label: "Sumário", href: "/", active: pathname === "/" },
  ];

  const handleSetAppSettings = (newSettings: SettingsProps) => {
    setTheme(newSettings.mode);
    setSettings(newSettings);
  };

  if (!mounted) return null;

  return (
    <AppProvider lightTheme={lightMode} darkTheme={darkMode} themeMode={settings?.mode}>
      <AIChatProvider
        dashboard="APP_NAME_PLACEHOLDER"
        panelSizes={{ left: settings.leftPanelWidth, right: settings.rightPanelWidth }}
        onPanelResize={(sizes) =>
          setSettings({ ...settings, leftPanelWidth: sizes.left, rightPanelWidth: sizes.right })
        }
      >
        <DashboardLayout
          pagename={pathname === "/" ? "Sumário" : pathname.slice(1)}
          options={navbarOptions}
          user={{
            name: user?.fullName || "",
            avatar: user?.imageUrl || "",
            email: user?.emailAddresses[0]?.emailAddress || "",
            signOut: () => signOut(),
          }}
          settings={settings}
          handleSetAppSettings={handleSetAppSettings}
        >
          {children}
        </DashboardLayout>
      </AIChatProvider>
    </AppProvider>
  );
}
DASHLAYOUT
sed -i "s/APP_NAME_PLACEHOLDER/$APP_NAME/g" "$APP_DIR/app/(dashboard)/layout.tsx"

# Dashboard index page
cat > "$APP_DIR/app/(dashboard)/(index)/page.tsx" << 'EOF'
export default function SummaryPage() {
  return (
    <div className="w-full p-4">
      <h1 className="text-2xl font-bold">Sumário</h1>
      <p className="text-muted-foreground mt-2">Adicione relatórios a esta página.</p>
    </div>
  );
}
EOF

# Section pages
for section in "${SECTION_ARRAY[@]}"; do
  section=$(echo "$section" | xargs)
  if [[ "$section" != "summary" && "$section" != "${SECTION_ARRAY[0]}" ]]; then
    SECTION_TITLE="${section^}"
    cat > "$APP_DIR/app/(dashboard)/$section/page.tsx" << SECTIONPAGE
export default function ${SECTION_TITLE}Page() {
  return (
    <div className="w-full p-4">
      <h1 className="text-2xl font-bold">${SECTION_TITLE}</h1>
      <p className="text-muted-foreground mt-2">Adicione relatórios a esta página.</p>
    </div>
  );
}
SECTIONPAGE
  fi
done

# Tabs component (from Shadcn)
cat > "$APP_DIR/components/ui/tabs.tsx" << 'EOF'
"use client";
import * as React from "react";
import * as TabsPrimitive from "@radix-ui/react-tabs";
import { cn } from "@/lib/utils";

const Tabs = TabsPrimitive.Root;

const TabsList = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.List>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={cn(
      "inline-flex h-9 items-center justify-center rounded-lg bg-muted p-1 text-muted-foreground",
      className
    )}
    {...props}
  />
));
TabsList.displayName = TabsPrimitive.List.displayName;

const TabsTrigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.Trigger
    ref={ref}
    className={cn(
      "inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow",
      className
    )}
    {...props}
  />
));
TabsTrigger.displayName = TabsPrimitive.Trigger.displayName;

const TabsContent = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Content>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.Content
    ref={ref}
    className={cn(
      "mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
      className
    )}
    {...props}
  />
));
TabsContent.displayName = TabsPrimitive.Content.displayName;

export { Tabs, TabsList, TabsTrigger, TabsContent };
EOF

# lib/utils.ts
cat > "$APP_DIR/lib/utils.ts" << 'EOF'
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

# i18n skeleton files
cat > "$APP_DIR/messages/pt.json" << 'EOF'
{
  "navigation": {
    "summary": "Sumário"
  },
  "common": {
    "export_excel": "Exportar para Excel",
    "export_image": "Exportar imagem",
    "restart": "Reiniciar o relatório",
    "loading": "A carregar...",
    "error": "Ocorreu um erro",
    "no_data": "Sem dados disponíveis"
  }
}
EOF

cat > "$APP_DIR/messages/en.json" << 'EOF'
{
  "navigation": {
    "summary": "Summary"
  },
  "common": {
    "export_excel": "Export to Excel",
    "export_image": "Export image",
    "restart": "Restart report",
    "loading": "Loading...",
    "error": "An error occurred",
    "no_data": "No data available"
  }
}
EOF

echo ""
echo "✓ Dashboard app '$APP_NAME' created at $APP_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $MONOREPO"
echo "  2. cp $APP_DIR/.env.local.template $APP_DIR/.env.local"
echo "  3. Edit $APP_DIR/.env.local with your credentials"
echo "  4. pnpm install"
echo "  5. pnpm dev --filter=$APP_NAME"
echo ""
echo "Then use the report guide to add reports to the dashboard."
```

- [ ] **Step 2: Make the script executable**

```bash
chmod +x openldr-dashboard/scripts/scaffold-dashboard.sh
```

- [ ] **Step 3: Verify the script parses correctly**

```bash
bash -n openldr-dashboard/scripts/scaffold-dashboard.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add openldr-dashboard/scripts/scaffold-dashboard.sh
git commit -m "feat(openldr-dashboard): add scaffold-dashboard.sh bootstrap script"
```

---

### Task 5: Create `report-guide.md`

**Files:**
- Create: `openldr-dashboard/references/report-guide.md`

- [ ] **Step 1: Write the report guide**

Create `openldr-dashboard/references/report-guide.md`:

```markdown
# Report Guide — Add or Modify Dashboard Reports

This guide walks through adding new reports to an existing dashboard or modifying existing reports. Reports are self-contained visualization components that fetch data from the OpenLDR Analytics API and display charts, tables, and export capabilities.

---

## Adding a New Report

### Step 1: Read Existing Patterns

Before creating a new report, scan the target dashboard's existing reports:

```bash
ls {monorepo}/apps/{dashboard}/app/(dashboard)/*/reports/
```

If reports exist, examine the file structure of one to detect the established pattern:

```bash
ls {monorepo}/apps/{dashboard}/app/(dashboard)/{section}/reports/{any-report}/
```

If no reports exist yet, use the default 6-file pattern from `tb-reference-patterns.md`.

### Step 2: Identify the API Endpoint

Load `references/api-endpoint-catalog.md` and find the endpoint matching the user's request.

Key fields to identify:
- **Module path:** `/hiv/vl/`, `/hiv/eid/`, `/tb/gx/`, etc.
- **View perspective:** `/laboratories/`, `/facilities/`, `/summary/`
- **Metric:** `tested_samples`, `rejected_samples`, `suppression`, `tat`, etc.
- **Time variant:** base (aggregated) or `_by_month` (time series)

Extract from the catalog:
- Full endpoint path
- Available parameters
- Response field names and types

### Step 3: Determine Placement

Identify which dashboard section the report belongs to:

| Report Type | Section | Route |
|---|---|---|
| Laboratory-level data | lab | `(dashboard)/lab/reports/` |
| Facility/clinic-level data | clinic | `(dashboard)/clinic/reports/` |
| Summary/overview indicators | (index) | `(dashboard)/(index)/reports/` |
| Patient-level data | patients | `(dashboard)/patients/reports/` |

Create the report directory:

```bash
mkdir -p {monorepo}/apps/{dashboard}/app/(dashboard)/{section}/reports/{report-name}/
```

Use kebab-case for the directory name, prefixed with a short identifier. Examples:
- `mtb-registered-by-lab` (TB)
- `vl-suppression-by-province` (HIV VL)
- `eid-positivity-by-month` (HIV EID)

### Step 4: Generate Report Files

Create the 6 files following the patterns in `tb-reference-patterns.md`. Customize:

| File | What to Customize |
|---|---|
| `constants.ts` | `API_CONFIG.BASE_URL` with the correct endpoint, `DEFAULTS.REPORT_NAME` in Portuguese, `CHART_CONFIG` with unique chart ID and series name, `UI_CONFIG.TAB_OPTIONS` if the domain has multiple result types |
| `actions.ts` | `Data` type matching the API response fields, `buildApiParams` with domain-specific parameters (e.g., `genexpert_result_type` for TB, `lab_type` for EID), `prepareChartData` mapping response fields to labels and series |
| `index.tsx` | Component name matching the report, chart component selection (Stacked, Line, etc.), tab labels if applicable |
| `excel-export-utils.ts` | Column headers in Portuguese matching the data fields, `prepareChartDataForExcel` mapping |
| `chart-export-utils.ts` | Usually identical to the TB pattern — copy as-is |
| `docs.tsx` | Full Portuguese documentation: report title, overview, test types (if applicable), chart explanation, usage steps, key indicators, data quality notes, technical notes with API endpoint |

### Step 5: Wire the Report

Import the report component in the parent section's `page.tsx`:

```tsx
import ReportName from "./reports/report-name";

export default function SectionPage() {
  return (
    <div className="w-full">
      <div className="grid grid-cols-1 @container gap-8">
        <div className="@[900px]:grid-cols-2 grid gap-8">
          <ReportName />
          {/* Other reports */}
        </div>
      </div>
    </div>
  );
}
```

### Step 6: Verify

```bash
cd {monorepo}
pnpm dev --filter={dashboard}
```

Navigate to the section page and confirm:
- Report renders without errors
- Loading state shows correctly
- Data loads from the API
- Chart displays with correct labels and series
- Drill-down navigation works
- Excel export downloads a formatted file
- PNG export downloads the chart image
- Documentation popup shows correct content

---

## Modifying Existing Reports

### Read First

Always read the report's current files before making changes:

```bash
cat {monorepo}/apps/{dashboard}/app/(dashboard)/{section}/reports/{report}/index.tsx
cat {monorepo}/apps/{dashboard}/app/(dashboard)/{section}/reports/{report}/constants.ts
cat {monorepo}/apps/{dashboard}/app/(dashboard)/{section}/reports/{report}/actions.ts
```

### Change Size Decision

| Change | Size | Approach |
|---|---|---|
| Update a label or color | Small | Make the change directly |
| Add a filter parameter | Small | Update `buildApiParams` and `constants.ts` |
| Change chart type | Large | Propose the change, show what will differ, get approval |
| Add a new data series | Large | Propose, as it affects actions.ts, index.tsx, and constants.ts |
| Restructure drill-down logic | Large | Propose — touches handleChartClick and state management |

---

## Chart Types Available

From the design system (`@repo/design_system/app/atoms/charts/apex/`):

| Component | Use Case |
|---|---|
| `Stacked` | Stacked bar chart — comparing categories with breakdowns |
| `Bar` | Simple bar chart — single series comparison |
| `Line` | Line chart — time series data |
| `Pie` | Pie/doughnut — part-of-whole (≤8 slices) |
| `Area` | Area chart — cumulative time series |

From Recharts (also available in the TB dashboard):
- `BarChart`, `LineChart`, `PieChart`, `AreaChart`, `ComposedChart`

Prefer ApexCharts (design system) for consistency unless the dashboard already uses Recharts.

---

## Report Capabilities Checklist

Every report should have:

- [ ] Date range filtering (default: last 12 months)
- [ ] Facility hierarchy drill-down (province → district → clinic → patients)
- [ ] Tab switching (if domain has multiple result types)
- [ ] Excel export with Portuguese column headers
- [ ] PNG export of the chart
- [ ] In-app documentation popup (Portuguese)
- [ ] Suggestion/feedback submission via MainCard
- [ ] Reset to defaults button
- [ ] Loading and error states
- [ ] Empty state ("Sem dados disponíveis")
```

- [ ] **Step 2: Commit**

```bash
git add openldr-dashboard/references/report-guide.md
git commit -m "feat(openldr-dashboard): add report guide for creating/modifying reports"
```

---

### Task 6: Create `maintenance-guide.md`

**Files:**
- Create: `openldr-dashboard/references/maintenance-guide.md`

- [ ] **Step 1: Write the maintenance guide**

Create `openldr-dashboard/references/maintenance-guide.md`:

```markdown
# Maintenance Guide — Improve & Fix Existing Dashboards

This guide handles improvements, bug fixes, refactoring, and optimization of existing dashboards and shared packages.

---

## Process

1. **Identify scope** — What dashboard and which files are affected? Read them.
2. **Detect change size** — Small or large?
3. **Execute** — Apply directly (small) or propose first (large).
4. **Verify** — Dev server boots, no type errors.

## Change Size Decision

| Size | Criteria | Action |
|---|---|---|
| **Small** | Single file, isolated change, no cross-cutting impact | Read the file, make the change, verify |
| **Large** | Multiple files, architectural change, affects shared packages, restructures navigation or state | Read all affected files, present a proposal with before/after, get user approval, then implement |

### Examples of Small Changes

- Fix a bug in a report's data transformation
- Update a label or translation string
- Change chart colors or dimensions
- Add a filter parameter to an existing report
- Fix a CSS/styling issue
- Update an API endpoint URL

### Examples of Large Changes

- Add a new navigation section to a dashboard
- Restructure report file organization
- Change state management approach
- Add a new shared component to the design system
- Modify authentication flow
- Refactor drill-down navigation logic
- Add a new AI agent capability

## Working with Shared Packages

<HARD-GATE>
Before modifying any file in `packages/`, check downstream impact.
</HARD-GATE>

### Check Downstream Impact

```bash
# Find which apps import from a package
grep -r "from \"@repo/design_system" {monorepo}/apps/*/app --include="*.tsx" --include="*.ts" -l
grep -r "from \"@repo/ai" {monorepo}/apps/*/app --include="*.tsx" --include="*.ts" -l
grep -r "from \"@repo/auth" {monorepo}/apps/*/app --include="*.tsx" --include="*.ts" -l
grep -r "from \"@repo/utilities" {monorepo}/apps/*/app --include="*.tsx" --include="*.ts" -l
```

### Package-Specific Rules

| Package | Rules |
|---|---|
| `packages/design_system/` | Never change component props without checking all consumers. Test in all apps that use the component. Prefer adding optional props over changing existing ones. |
| `packages/ai/` | Changes to `AIChatProvider` affect all dashboards. Test AI chat in each dashboard after changes. |
| `packages/auth/` | Auth changes affect login/logout across all apps. Test sign-in/sign-out flow in each dashboard. Never break the SSO experience. |
| `packages/utilities/` | Utility changes are low-risk but verify type signatures. Run `pnpm check-types` across the monorepo. |

### Verification After Package Changes

```bash
cd {monorepo}

# Check types across all packages and apps
pnpm check-types

# Build all to catch issues
pnpm build

# Or test specific app
pnpm dev --filter={affected-app}
```

## i18n Maintenance

When editing UI text:

1. Check if the text is already in a translation file (`messages/pt.json`, `messages/en.json`)
2. If yes, update the translation file — never hardcode the new string
3. If no translation file exists yet, consider whether this is the right time to add one
4. Always update both `pt.json` and `en.json` when changing translation keys
5. Portuguese is the primary language — ensure Portuguese translations are complete

## Common Maintenance Tasks

### Updating API Endpoints

1. Read the report's `constants.ts` to find `API_CONFIG.BASE_URL`
2. Update the endpoint path
3. If the response shape changed, update the `Data` type in `actions.ts`
4. If new fields were added, update `prepareChartData` and `excel-export-utils.ts`
5. Verify the report loads correctly

### Adding a Filter

1. Add the parameter to `buildApiParams` in `actions.ts`
2. Add the state variable to `ReportState` in `index.tsx`
3. Add the UI control (dropdown, checkbox) to the component's render
4. Verify the filter affects the API call and chart updates

### Fixing Chart Display Issues

1. Read `index.tsx` to understand which chart component is used
2. Read `actions.ts` → `prepareChartData` to see how data maps to labels/series
3. Check if the issue is in data transformation or chart configuration
4. If chart component issue: check design system source at `packages/design_system/`

### Improving Performance

1. Check for unnecessary re-renders (missing `useMemo`/`useCallback` deps)
2. Check API call patterns (avoid duplicate fetches)
3. Check data transformation — move expensive operations to `useMemo`
4. Consider pagination for large datasets (patient tables)
```

- [ ] **Step 2: Commit**

```bash
git add openldr-dashboard/references/maintenance-guide.md
git commit -m "feat(openldr-dashboard): add maintenance guide for dashboard improvements"
```

---

### Task 7: Symlink API endpoint catalog

**Files:**
- Create: `openldr-dashboard/references/api-endpoint-catalog.md` (symlink)

- [ ] **Step 1: Create the symlink**

```bash
cd /home/vagner/Documents/Projects/APHL/openldr-skills
ln -s ../../openldr-query-api/references/api-endpoint-catalog.md openldr-dashboard/references/api-endpoint-catalog.md
```

- [ ] **Step 2: Verify the symlink works**

```bash
head -5 openldr-dashboard/references/api-endpoint-catalog.md
```

Expected: First 5 lines of the API endpoint catalog (starting with `# OpenLDR Analytics API — Complete Endpoint Catalog`).

- [ ] **Step 3: Commit**

```bash
git add openldr-dashboard/references/api-endpoint-catalog.md
git commit -m "feat(openldr-dashboard): symlink API endpoint catalog from openldr-query-api"
```

---

### Task 8: Update `openldr/SKILL.md` routing table

**Files:**
- Modify: `openldr/SKILL.md`

- [ ] **Step 1: Add the routing entry**

In `openldr/SKILL.md`, add a new row to the Routing Table:

```markdown
| Build, create, modify, or improve dashboards in the turborepo monorepo | `openldr:dashboard` |
```

Add after the existing `openldr:report` row.

- [ ] **Step 2: Add the "When to Use" section**

After the existing `**openldr:report**` paragraph, add:

```markdown
**`openldr:dashboard`** — User mentions: create dashboard, new dashboard, build dashboard for, add report, add chart, add page, fix dashboard, improve dashboard, update dashboard, dashboard component, monorepo app, turborepo app.
```

- [ ] **Step 3: Add the invocation entry**

In the "How to Invoke" section, add:

```
Skill: openldr:dashboard
```

- [ ] **Step 4: Verify the file is valid**

```bash
head -30 openldr/SKILL.md
```

Confirm the routing table has 6 rows (create-view, create-dataset, query-api, explore, report, dashboard).

- [ ] **Step 5: Commit**

```bash
git add openldr/SKILL.md
git commit -m "feat(openldr): add openldr:dashboard to routing table"
```

---

### Task 9: Final verification

- [ ] **Step 1: Verify complete file structure**

```bash
find openldr-dashboard -type f -o -type l | sort
```

Expected:
```
openldr-dashboard/references/api-endpoint-catalog.md
openldr-dashboard/references/maintenance-guide.md
openldr-dashboard/references/report-guide.md
openldr-dashboard/references/scaffold-guide.md
openldr-dashboard/references/tb-reference-patterns.md
openldr-dashboard/scripts/scaffold-dashboard.sh
openldr-dashboard/SKILL.md
```

- [ ] **Step 2: Verify symlink resolves**

```bash
file openldr-dashboard/references/api-endpoint-catalog.md
```

Expected: `symbolic link to ../../openldr-query-api/references/api-endpoint-catalog.md`

- [ ] **Step 3: Verify routing table**

```bash
grep "openldr:dashboard" openldr/SKILL.md
```

Expected: At least 2 matches (routing table entry and invocation entry).

- [ ] **Step 4: Verify scaffold script is executable**

```bash
test -x openldr-dashboard/scripts/scaffold-dashboard.sh && echo "Executable"
```

Expected: `Executable`

- [ ] **Step 5: Commit any remaining changes**

If any uncommitted changes remain:

```bash
git status
git add -A
git commit -m "chore(openldr-dashboard): finalize skill structure"
```
