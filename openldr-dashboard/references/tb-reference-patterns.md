# TB Dashboard Reference Patterns

> Comprehensive reference of conventions extracted from the TB dashboard.
> All code snippets use generic placeholders (`{APP_TITLE}`, `{APP_ID}`, `{module}`, etc.) so they can be adapted for any new dashboard.

---

## 1. Root Layout Pattern

**File:** `app/layout.tsx`

```tsx
import "./globals.css";
import type { Metadata } from "next";
import { Open_Sans } from "next/font/google";
import { AuthProvider } from "@repo/auth";
import { ThemeProvider } from "../context/theme-provider";
import { ClerkProvider } from "@clerk/nextjs";

const openSans = Open_Sans({
  variable: "--font-open-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "{APP_TITLE}",
  description: "{APP_DESCRIPTION}",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={` ${openSans.variable} antialiased`}
        suppressHydrationWarning
      >
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
              baseTheme: undefined,
              elements: {
                formButtonPrimary: 'bg-primary hover:bg-primary/90',
              }
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
```

**Key points:**
- Provider nesting order: `ThemeProvider` (outermost) then `ClerkProvider` then `children`.
- `suppressHydrationWarning` on both `<html>` and `<body>` to prevent theme-related hydration mismatches.
- Font: Open Sans loaded via `next/font/google` with CSS variable `--font-open-sans`.
- `AuthProvider` from `@repo/auth` is available but currently commented out in favor of Clerk.

---

## 2. Dashboard Layout Pattern

**File:** `app/(dashboard)/layout.tsx`

```tsx
"use client"
import { useEffect, useState } from "react"
import { DashboardLayout } from "@repo/design_system/app/templates/DashboardLayout"
import { IconlyGrid } from "@repo/design_system/app/atoms/icons/Grid"
import { IconlyLocation } from "@repo/design_system/app/atoms/icons/Location"
import { IconlyPatients } from "@repo/design_system/app/atoms/icons/Patients"
import { SettingsProps } from "@repo/design_system/app/molecules/headers/SettingsDrawer"
import { useLayoutSettings } from "../../hooks/useLayoutSettings"
import { AIChatProvider } from "@repo/ai/src/context/ai-chat-provider"
import { AppProvider } from "@repo/design_system/contexts"
import { darkMode } from "../../themes/dark"
import { lightMode } from "../../themes/light"
import { useUser, useAuth, SignedOut, SignedIn, RedirectToSignIn } from "@clerk/nextjs"
import { useTheme } from "next-themes"
import { usePathname } from "next/navigation";

const SMALL_SCREEN_BREAKPOINT = 1280; // xl breakpoint

export default function Layout({children}: {children: React.ReactNode}) {
  const { settings, setSettings } = useLayoutSettings();
  const [mounted, setMounted] = useState(false);
  const { isLoaded, isSignedIn, user } = useUser();
  const { signOut } = useAuth();
  const { theme, setTheme } = useTheme();
  const pathname = usePathname();

  // Force compact to "large" on small screens
  useEffect(() => {
    setMounted(true);

    const handleResize = () => {
      const isSmallScreen = window.innerWidth < SMALL_SCREEN_BREAKPOINT;
      if (isSmallScreen && settings.compact !== "large") {
        setSettings({ ...settings, compact: "large" });
      }
    };

    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, [settings, setSettings]);

  // Map pathnames to display labels
  const pathToLabel: Record<string, string> = {
    "/": "{NAV_LABEL_HOME}",
    "/{section_a}": "{NAV_LABEL_A}",
    "/{section_b}": "{NAV_LABEL_B}",
  };

  // Navbar options with active state computed from pathname
  const navbarOptions = [
    { label: "{NAV_LABEL_HOME}", icon: <IconlyGrid style="two-tone" size={18}/>, href: "/", active: false },
    { label: "{NAV_LABEL_A}", icon: <IconlyLocation style="two-tone" size={19}/>, href: "/{section_a}", active: false },
    { label: "{NAV_LABEL_B}", icon: <IconlyPatients style="two-tone" size={19}/>, href: "/{section_b}", active: false },
  ].map(option => ({
    ...option,
    active: option.href === pathname
  }));

  const handleSetAppSettings = (settings: SettingsProps) => {
    setTheme(settings.mode);
    setSettings(settings);
  };

  if (!mounted) {
    return null;
  }

  return (
    <AppProvider
      lightTheme={lightMode}
      darkTheme={darkMode}
      themeMode={settings?.mode}
    >
      <AIChatProvider
        dashboard="{APP_ID}"
        panelSizes={{ left: settings.leftPanelWidth, right: settings.rightPanelWidth }}
        onPanelResize={(sizes) => {
          setSettings({
            ...settings,
            leftPanelWidth: sizes.left,
            rightPanelWidth: sizes.right
          })
        }}
      >
        <DashboardLayout
          pagename={pathToLabel[pathname]}
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
```

**Key points:**
- Must be a `"use client"` component.
- Provider nesting order: `AppProvider` (themes) then `AIChatProvider` (AI panel) then `DashboardLayout` (shell).
- `mounted` state prevents hydration mismatches -- returns `null` until client-side mount.
- Responsive breakpoint at 1280px forces compact layout on smaller screens.
- `navbarOptions` array drives sidebar navigation; `active` is computed from `usePathname()`.
- `AIChatProvider` receives the `dashboard` identifier (e.g. `"tb"`) and panel size state.
- `DashboardLayout` receives user info from Clerk's `useUser()`.

---

## 3. Theme Provider Pattern

**File:** `context/theme-provider.tsx`

```tsx
"use client"

import * as React from "react"
import { ThemeProvider as NextThemesProvider } from "next-themes"

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}
```

**Key points:**
- Wraps `next-themes` provider with a mounted guard to prevent hydration mismatch.
- Returns `null` during SSR; renders only after client mount.
- Accepts all props from `NextThemesProvider` via spread.

---

## 4. Theme Objects Pattern

### Dark Theme -- `themes/dark.ts`

```ts
export const darkMode = {
  palette: {
    mode: 'dark',
    primary: {
      main: "{PRIMARY_COLOR}",     // default: "#00B000"
    },
    secondary: {
      main: "{SECONDARY_COLOR}",   // default: "#F8A200"
    },
    error: {
      main: "#EF5350"
    },
    success: {
      main: "{PRIMARY_COLOR}",     // typically matches primary
    },
    warning: {
      main: "#F8A200"
    },
    info: {
      main: "#6B52DC"
    },
    background: {
      paper: "#1d232a",
      default: "#141a21"
    },
    text: {
      primary: "#fff",
      secondary: "#8996a0",
      disabled: "rgba(255, 255, 255, 0.6)",
    },
    common: {
      black: "#000",
      white: "#fff"
    },
    contrastThreshold: 3,
    divider: "rgba(145, 158, 171, 0.24)",
  },
  typography: {
    fontFamily: '"Open Sans", "Nunito Sans", sans-serif',
    button: {
      textTransform: "none"
    }
  },
  shape: {
    borderRadius: 4
  },
}
```

### Light Theme -- `themes/light.ts`

```ts
export const lightMode = {
  palette: {
    mode: "light",
    primary: {
      main: "{PRIMARY_COLOR}",     // default: "#00B000"
    },
    secondary: {
      main: "{SECONDARY_COLOR}",   // default: "#F8A200"
    },
    error: {
      main: "#EF5350"
    },
    success: {
      main: "{PRIMARY_COLOR}",
    },
    warning: {
      main: "#F8A200"
    },
    info: {
      main: "#6B52DC"
    },
    background: {
      paper: "#fff",
      default: "#f4f4f4",
    },
    common: {
      black: "#000",
      white: "#fff"
    },
    text: {
      primary: "#333333",
      secondary: "#8996a0",
      disabled: "rgba(51, 51, 51, 0.4)",
    },
    contrastThreshold: 3,
    divider: "#e5e5e5"
  },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          border: "1px solid",
          borderColor: "hsl(240 4.8% 95.9%)",
          borderRadius: "16px",
        },
      },
    },
    MuiDivider: {
      styleOverrides: {
        root: {
          borderColor: "hsl(240 4.8% 95.9%)",
          borderWidth: "1px",
        },
      },
    },
  },
  shadows: [
    "none",
    "rgb(145 158 171 / 20%) 0px 0px 2px 0px, rgb(145 158 171 / 12%) 0px 12px 24px -4px",
    "rgb(145 158 171 / 24%) 0px 0px 2px 0px, rgb(145 158 171 / 24%) -20px 20px 40px -4px",
    ...Array(23).fill("none")
  ],
  typography: {
    fontFamily: '"Open Sans", "Nunito Sans", sans-serif',
    button: {
      textTransform: "none"
    }
  },
  shape: {
    borderRadius: 4,
  },
}
```

**Key points:**
- These are MUI-compatible theme objects consumed by `AppProvider`.
- `primary.main` is the brand color -- defaults to `#00B000` (green). Replace with `{PRIMARY_COLOR}`.
- Light theme includes `components` overrides for `MuiCard` and `MuiDivider`; dark theme does not.
- Light theme provides a custom `shadows` array (only indices 0-2 defined, rest `"none"`).
- Typography uses Open Sans as the primary font family.
- Export names are `darkMode` and `lightMode` (not `dark`/`light`).

---

## 5. Zustand Settings Store Pattern

**File:** `hooks/useLayoutSettings.ts`

```ts
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
    {
      name: "layout-settings", // key in localStorage
    }
  )
);
```

**Key points:**
- Uses Zustand with `persist` middleware for localStorage persistence.
- `SettingsProps` type comes from the design system's `SettingsDrawer`.
- Default layout: light mode, compact "large", 75/25 panel split.
- localStorage key is `"layout-settings"` -- same across all dashboards (the key could be made app-specific if needed).
- The store is a single `settings` object with a single `setSettings` setter (full replacement, not partial merge).

---

## 6. Auth Middleware Pattern

**File:** `middleware.ts`

```ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server'
import { NextResponse } from 'next/server'

const isPublicRoute = createRouteMatcher(['/sign-in(.*)', '/sign-up(.*)'])

export default clerkMiddleware(async (auth, req) => {
  if (!isPublicRoute(req)) {
    try {
      await auth.protect()
    } catch (err) {
      const signInUrl = new URL('/sign-in', req.url)
      return NextResponse.redirect(signInUrl)
    }
  }
  return NextResponse.next()
})

export const config = {
  matcher: [
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    '/(api|trpc)(.*)',
  ],
}
```

**Key points:**
- Public routes: `/sign-in` and `/sign-up` (with any subpaths).
- All other routes call `auth.protect()` which redirects unauthenticated users to `/sign-in`.
- The `matcher` excludes static assets and includes API/tRPC routes.
- Uses `NextResponse.redirect` for custom redirect behavior (not Clerk's built-in redirect).

---

## 7. API Client Pattern

**File:** `config/api.ts`

```ts
import axios from "axios";

export const api = (token: string) => axios.create({
  baseURL: process.env.NEXT_PUBLIC_OPENLDR_API,
  timeout: 60000, // 60 seconds timeout
  headers: {
    "Authorization": `Bearer ${token}`,
  },
});
```

**Key points:**
- Factory function: returns a new Axios instance per call, parameterized by auth token.
- Base URL comes from `NEXT_PUBLIC_OPENLDR_API` environment variable.
- 60-second default timeout.
- Token is passed as a `Bearer` authorization header.
- Each API call site obtains a token via Clerk's `getToken()` and passes it to `api(token)`.

---

## 8. Report File Structure (6-File Pattern)

Every report in the dashboard follows a consistent 6-file directory structure:

```
app/(dashboard)/{section}/reports/{report-name}/
  constants.ts          # Configuration constants
  actions.ts            # Types, API functions, data transformations
  index.tsx             # Main report component
  excel-export-utils.ts # Excel export logic
  chart-export-utils.ts # Chart image export logic (or uses shared)
  docs.tsx              # Documentation component
```

Additionally, shared utilities live at:
```
app/(dashboard)/{section}/reports/shared/
  chart-export-utils.ts # Shared chart export (ApexCharts)
```

---

### 8.1 Constants -- `constants.ts`

```ts
import { FacilityType } from "./actions";
import { getLastTwelveMonths } from "./actions";

// API Configuration
export const API_CONFIG = {
  BASE_URL: `${process.env.NEXT_PUBLIC_OPENLDR_API}/{module}/gx/facilities/{endpoint}/`,
  TIMEOUT: 30000,
} as const;

// Default Values
export const DEFAULTS = {
  TIME_INTERVAL: getLastTwelveMonths(),
  FACILITY_TYPE: "province" as FacilityType,
  ACTIVE_TAB: "{default_tab}" as const,
  DISAGGREGATION: false,
  REPORT_NAME: "{Report Display Name}",
} as const;

// Chart Configuration
export const CHART_CONFIG = {
  HEIGHT: 350,
  CHART_ID: "{section}_{report_slug}_chart",
  SERIES_NAME: "{Series Display Name}",
} as const;

// UI Configuration
export const UI_CONFIG = {
  TAB_OPTIONS: [
    { value: "{tab_1}", label: "{Tab 1 Label}" },
    { value: "{tab_2}", label: "{Tab 2 Label}" },
  ] as const,
  MAIN_CARD_OPTIONS: {
    HEIGHT: "auto",
    LAB_TYPE: "poc",
    REPORT_TYPE: "facility",
    SUBTITLE: "{Default Subtitle}",
  } as const,
} as const;
```

**Key points:**
- Four configuration groups: `API_CONFIG`, `DEFAULTS`, `CHART_CONFIG`, `UI_CONFIG`.
- All use `as const` for type safety and immutability.
- `CHART_ID` must be unique across the dashboard (used by ApexCharts for export).
- `DEFAULTS.TIME_INTERVAL` calls `getLastTwelveMonths()` at module level.
- `TAB_OPTIONS` array drives the tab UI; can have any number of tabs.
- `MAIN_CARD_OPTIONS` configures the wrapper card's appearance.

---

### 8.2 Actions -- `actions.ts`

```ts
import axios, { AxiosError } from "axios";
import { API_CONFIG } from "./constants";
import { api } from "../../../../../config/api";

// ============================================================================
// TYPES
// ============================================================================
export type Data = {
    Facility: string;
    {metric_field_1}: number;
    {metric_field_2}: number;
    {metric_field_3}: number;
    Start_Date: string;
    End_Date: string;
    Disaggregation: boolean;
    Facility_Type: string;
}

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
    series: Array<{
        name: string;
        data: number[];
        group: string;
    }>;
}

export type FacilityType = "province" | "district" | "clinic" | "patients";
export type ActiveTab = "{tab_1}" | "{tab_2}";

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Get the last 12 months date range
 */
export const getLastTwelveMonths = (): TimeInterval => {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setFullYear(endDate.getFullYear() - 1);

    const formatDate = (date: Date): string => {
        return date.toISOString().split('T')[0];
    };

    return {
        startDate: formatDate(startDate),
        endDate: formatDate(endDate)
    };
};

/**
 * Get next facility type in the drill-down hierarchy
 */
export const getNextFacilityType = (currentType: FacilityType): FacilityType => {
    const facilityTypeHierarchy: Record<FacilityType, FacilityType> = {
        province: "district",
        district: "clinic",
        clinic: "province",   // resets at the bottom
        patients: "province"
    };

    return facilityTypeHierarchy[currentType];
};

// ============================================================================
// API FUNCTIONS
// ============================================================================

/**
 * Build API parameters for facility data request
 */
export const buildApiParams = (
    timeInterval: TimeInterval,
    activeTab: ActiveTab,
    facilities: FacilityOptions[],
    facilityType: FacilityType,
    disaggregation: boolean
): Record<string, any> => {
    const baseParams = {
        interval_dates: `${timeInterval.startDate},${timeInterval.endDate}`,
        disaggregation: disaggregation ? "True" : "False"
    };

    const facilityParams = {
        ...(facilityType === "province" || facilityType === "district") && {
            province: facilities.map(facility => facility.province)
        },
        ...(facilityType === "district" && {
            province: facilities.map(facility => facility.province),
        }),
        ...(facilityType === "clinic" && {
            province: facilities.map(facility => facility.province),
            district: facilities.map(facility => facility.district),
            facility_type: "health_facility"
        }),
    };

    return { ...baseParams, ...facilityParams };
};

/**
 * Fetch facility data from API
 */
export const fetchFacilityData = async (
    params: Record<string, any>,
    token: string
): Promise<Data[]> => {
    try {
        const response = await api(token).get(API_CONFIG.BASE_URL, {
            params,
            paramsSerializer: { indexes: null },
            timeout: API_CONFIG.TIMEOUT
        });

        if (!response.data?.length) {
            return [];
        }

        return response.data;
    } catch (error) {
        const errorMessage = error instanceof AxiosError
            ? error.response?.data?.message || error.message
            : error instanceof Error ? error.message : "An error occurred";

        console.error("Error fetching facility data:", errorMessage);
        throw new Error(errorMessage);
    }
};

// ============================================================================
// DATA TRANSFORMATION FUNCTIONS
// ============================================================================

export const prepareChartData = (data: Data[]) => {
    if (data.length === 0) {
        return { labels: [], series: [] };
    }

    const labels = data.map(item => item.Facility);
    const series = [{
        name: '{Series 1 Name}',
        data: data.map(item => item.{metric_field_1}),
        group: 'apexcharts-axis-0'
    },
    {
        name: '{Series 2 Name}',
        data: data.map(item => item.{metric_field_2}),
        group: 'apexcharts-axis-0'
    }];

    return { labels, series };
};

/**
 * Create new facility options from clicked label (drill-down)
 */
export const createFacilityOptions = (
    label: string,
    currentFacilityType: FacilityType,
    currentFacilities: FacilityOptions[]
): FacilityOptions => {
    const currentFacility = currentFacilities[0];

    return {
        value: label,
        label,
        district: currentFacilityType === "district" ? label : currentFacility?.district || "",
        province: currentFacilityType === "province" ? label : currentFacility?.province || ""
    };
};
```

**Key points:**
- `Data` type mirrors the API response fields; adjust fields per report.
- `FacilityOptions` is reused across all drill-down reports (province/district/clinic hierarchy).
- `TimeInterval` uses ISO date strings (`YYYY-MM-DD`).
- `ChartData.series[].group` must be `'apexcharts-axis-0'` for stacked charts.
- `buildApiParams` constructs query params based on the current drill-down level.
- `paramsSerializer: { indexes: null }` is required for Axios to serialize array params correctly.
- `fetchFacilityData` handles errors with `AxiosError` type narrowing.
- `prepareChartData` transforms API response into labels + series arrays for ApexCharts.
- `createFacilityOptions` builds the next drill-down context from the clicked bar label.

---

### 8.3 Report Component -- `index.tsx`

```tsx
"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { Stacked } from "@repo/design_system/app/atoms/charts/apex/Stacked";
import { PiMicrosoftExcelLogoFill } from "react-icons/pi";
import { IoImageOutline } from "react-icons/io5";
import { VscDebugRestart } from "react-icons/vsc";
import { MainCard } from "@repo/design_system/app/organisms/cards/MainCard";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../../../../../components/ui/tabs";
import {
    DEFAULTS,
    CHART_CONFIG,
    UI_CONFIG
} from "./constants";
import {
    FacilityType,
    FacilityOptions,
    ActiveTab,
    Data,
    buildApiParams,
    prepareChartData,
    fetchFacilityData,
    getNextFacilityType,
    createFacilityOptions,
    TimeInterval,
} from "./actions";
import { useAuth, useUser } from "@clerk/nextjs";
import { exportChartToExcel } from "./excel-export-utils";
import { exportChart } from "../shared/chart-export-utils";
import Docs from "./docs";

// ============================================================================
// TYPES
// ============================================================================

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

// ============================================================================
// COMPONENT
// ============================================================================

export default function {ReportComponentName}() {
    const { user } = useUser();
    const { getToken } = useAuth();

    // ============================================================================
    // STATE
    // ============================================================================

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

    const [clickedLabels, setClickedLabels] = useState<string[]>([]);

    // ============================================================================
    // MEMOIZED VALUES
    // ============================================================================

    const dynamicSubtitle = useMemo(() => {
        const { startDate, endDate } = reportState.timeInterval;
        const formatDate = (dateString: string) => {
            const date = new Date(dateString);
            const day = date.getDate().toString().padStart(2, '0');
            const month = date.toLocaleDateString('pt-BR', { month: 'long' });
            const year = date.getFullYear();
            return `${day} de ${month} de ${year}`;
        };

        const dateRange = `${formatDate(startDate)} a ${formatDate(endDate)}`;

        if (clickedLabels.length === 0) {
            return dateRange;
        }

        return `${dateRange} | ${clickedLabels.join(' > ')}`;
    }, [reportState, clickedLabels]);

    const chartData = useMemo(() =>
        prepareChartData(reportState.data),
        [reportState.data]
    );

    // ============================================================================
    // API FUNCTIONS
    // ============================================================================

    const fetchDataFromApi = useCallback(async (
        startDate: string,
        endDate: string,
        disaggregation: boolean,
        facilities: FacilityOptions[],
        facilityType?: FacilityType
    ) => {
        try {
            setReportState(prev => ({ ...prev, loading: true, error: null }));
            const token = await getToken();
            const params = buildApiParams(
                { startDate, endDate },
                reportState.activeTab,
                facilities,
                facilityType || reportState.facilityType,
                disaggregation
            );

            const data = await fetchFacilityData(params, token);

            setReportState(prev => ({
                ...prev,
                data,
                loading: false,
                error: null
            }));

        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : "An error occurred";
            setReportState(prev => ({
                ...prev,
                loading: false,
                error: errorMessage
            }));
        }
    }, [reportState.activeTab, reportState.facilityType, getToken]);

    // ============================================================================
    // EVENT HANDLERS
    // ============================================================================

    const handleRestart = useCallback(() => {
        setClickedLabels([]);
        setReportState(prev => ({
            ...prev,
            disaggregation: DEFAULTS.DISAGGREGATION,
            facilities: [],
            facilityType: DEFAULTS.FACILITY_TYPE,
            timeInterval: DEFAULTS.TIME_INTERVAL,
            activeTab: DEFAULTS.ACTIVE_TAB
        }));
    }, []);

    const handleTabChange = useCallback((newTab: ActiveTab) => {
        setReportState(prev => ({
            ...prev,
            activeTab: newTab
        }));
    }, []);

    const handleChartClick = useCallback(async (label: string) => {
        if (!label) return;

        setReportState(prev => ({ ...prev, loading: true }));
        setClickedLabels(prev => [...prev, label]);

        const newFacilityType = getNextFacilityType(reportState.facilityType);
        const newFacility = createFacilityOptions(
            label,
            reportState.facilityType,
            reportState.facilities
        );

        const newFacilities = [newFacility];
        const newDisaggregation = true;

        setReportState(prev => ({
            ...prev,
            facilityType: newFacilityType,
            facilities: newFacilities,
            disaggregation: newDisaggregation,
        }));

        await fetchDataFromApi(
            reportState.timeInterval.startDate,
            reportState.timeInterval.endDate,
            newDisaggregation,
            newFacilities,
            newFacilityType
        );

        setReportState(prev => ({ ...prev, loading: false }));
    }, [reportState.facilityType, reportState.facilities, reportState.timeInterval, fetchDataFromApi]);

    const handleExportToExcel = useCallback(async () => {
        try {
            await exportChartToExcel(chartData, reportState, DEFAULTS.REPORT_NAME, () => ({}));
        } catch (error) {
            console.error("Failed to export to Excel:", error);
        }
    }, [chartData, reportState]);

    const handleExportToImage = useCallback(async () => {
        try {
            await exportChart({
                chartId: CHART_CONFIG.CHART_ID,
                fileName: DEFAULTS.REPORT_NAME
            });
        } catch (error) {
            console.error("Failed to export chart:", error);
        }
    }, []);

    // ============================================================================
    // MEMOIZED OPTIONS
    // ============================================================================

    const mainCardOptions = useMemo(() => [
        {
            action: handleExportToExcel,
            icon: <PiMicrosoftExcelLogoFill size={20} />,
            label: "Exportar para Excel",
            type: "primary" as const
        },
        {
            action: handleExportToImage,
            icon: <IoImageOutline size={20} />,
            label: "Exportar imagem",
            type: "primary" as const
        },
        {
            action: handleRestart,
            icon: <VscDebugRestart size={20} />,
            label: "Reiniciar o relatorio",
            type: "primary" as const
        },
    ], [handleRestart, handleExportToExcel, handleExportToImage]);

    // ============================================================================
    // EFFECTS
    // ============================================================================

    useEffect(() => {
        fetchDataFromApi(
            reportState.timeInterval.startDate,
            reportState.timeInterval.endDate,
            reportState.disaggregation,
            reportState.facilities,
            reportState.facilityType
        );
    }, [
        reportState.timeInterval,
        reportState.disaggregation,
        reportState.facilities,
        reportState.facilityType,
        fetchDataFromApi
    ]);

    // ============================================================================
    // RENDER
    // ============================================================================

    return (
        <MainCard
            additionalOptions={mainCardOptions}
            chartId={CHART_CONFIG.CHART_ID}
            documentation={<Docs />}
            headerProps={{ sx: { padding: 2 } }}
            height={UI_CONFIG.MAIN_CARD_OPTIONS.HEIGHT}
            id="{APP_ID}-main-card"
            labType={UI_CONFIG.MAIN_CARD_OPTIONS.LAB_TYPE}
            loading={reportState.loading}
            reportType={UI_CONFIG.MAIN_CARD_OPTIONS.REPORT_TYPE}
            subtitle={dynamicSubtitle || UI_CONFIG.MAIN_CARD_OPTIONS.SUBTITLE}
            title={DEFAULTS.REPORT_NAME}
            user={{
                email: user?.emailAddresses[0].emailAddress,
                name: user?.fullName || ""
            }}
            width="100%"
        >
            <Tabs
                defaultValue={DEFAULTS.ACTIVE_TAB}
                className="w-full"
                onValueChange={handleTabChange}
            >
                <TabsList className="mx-4 ml-auto">
                    {UI_CONFIG.TAB_OPTIONS.map(option => (
                        <TabsTrigger
                            key={option.value}
                            value={option.value}
                            className="dark:data-[state=active]:border-gray-950 dark:data-[state=active]:bg-gray-950 text-xs"
                        >
                            {option.label}
                        </TabsTrigger>
                    ))}
                </TabsList>

                {UI_CONFIG.TAB_OPTIONS.map(option => (
                    <TabsContent key={option.value} value={option.value} className="px-4 pb-4">
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
```

**Key points:**
- Must be `"use client"` -- uses hooks extensively.
- `ReportState` interface holds all report state in a single `useState` object.
- `clickedLabels` tracks the drill-down breadcrumb trail.
- `dynamicSubtitle` is memoized and shows date range + drill-down path.
- `fetchDataFromApi` is wrapped in `useCallback` with proper dependencies.
- `handleChartClick` implements drill-down: province -> district -> clinic.
- `useEffect` triggers initial data fetch and re-fetches on state changes.
- `MainCard` is the standard wrapper from the design system; it receives `documentation`, `additionalOptions`, `user`, and handles the card header/loading state.
- `Tabs` + `TabsContent` render the chart inside each tab (same `Stacked` chart, data changes via tab state).
- Three standard action buttons: Excel export, image export, restart.
- Icons: `PiMicrosoftExcelLogoFill` (react-icons/pi), `IoImageOutline` (react-icons/io5), `VscDebugRestart` (react-icons/vsc).

---

### 8.4 Excel Export Utils -- `excel-export-utils.ts`

Pattern description (not full code -- this file is mostly copy-paste with field name changes):

The file exports the following functions:

1. **`validateExportData(data: any[])`** -- validates data is non-empty array. Returns `{ isValid, message? }`.

2. **`prepareChartDataForExcel(chartLabels, chartSeries, reportState, getFacilityProperty)`** -- maps `reportState.data` to flat objects with display-friendly column names (e.g., `"Provincia"`, `"Amostras Testadas"`). Uses a facility type label map to create dynamic column keys.

3. **`createFormattedWorksheet(options: ExcelExportOptions)`** -- creates an XLSX worksheet with:
   - Title row (merged across all columns)
   - Empty spacer row
   - Header row (auto-detected from data keys)
   - Data rows
   - Column width formatting

4. **`createAndSaveWorkbook(worksheet, options)`** -- creates workbook, appends the worksheet (sheet name truncated to 31 chars), generates timestamped filename, saves via `XLSX.writeFile`.

5. **`exportChartToExcel(chartData, reportState, reportName, getFacilityProperty)`** -- orchestrates the full export: prepare data, create worksheet, save workbook.

**Dependencies:** `xlsx` package only.

**Key convention:** Export file names follow the pattern `{ReportName}_{ActiveTab}_{YYYY-MM-DD}.xlsx`.

---

### 8.5 Chart Export Utils -- `chart-export-utils.ts`

Pattern description:

The shared chart export utility lives at `reports/shared/chart-export-utils.ts` and exports a single function:

```ts
interface ExportChartOptions {
  chartId: string;
  fileName?: string;
  type?: "png" | "svg";
}

export async function exportChart({ chartId, fileName, type }: ExportChartOptions)
```

**Strategy:** Uses ApexCharts native export via `ApexCharts.getChartByID(chartId)`:
1. Finds the chart DOM element by ID.
2. Gets the ApexCharts instance via `ApexCharts.getChartByID()`.
3. Calls `chart.dataURI({ scale: 3 })` to generate a high-resolution PNG data URI.
4. Creates a temporary `<a>` element, sets `href` to the data URI, triggers a click to download.

**Fallback strategies** (in some per-report `chart-export-utils.ts` files):
- `html2canvas` with OKLCH color fix (replaces unsupported OKLCH colors before capture).
- Direct canvas capture from SVG.
- SVG-to-canvas rendering.

**Key convention:** The `chartId` must match the `id` prop passed to the `<Stacked>` component and the `CHART_CONFIG.CHART_ID` constant.

---

### 8.6 Documentation Component -- `docs.tsx`

Pattern description:

The docs component is an MUI-based documentation page written in Portuguese. It is passed to the `MainCard` via the `documentation` prop and rendered in a slide-out panel.

**Standard sections:**

1. **Header** -- `Paper` with icon + report title + subtitle. Uses `Science` MUI icon. Title color: `#009689`.
2. **Visao Geral (Overview)** -- describes what the report shows and why it matters.
3. **Visualizacao de Dados (Chart Visualization)** -- `Alert` explaining the chart type, `List` items describing the chart, navigation hierarchy, and tab switching.
4. **Funcionalidades Principais (Features)** -- `List` with `Timeline`, `Assessment`, `Info` MUI icons.
5. **Como Utilizar (Usage)** -- step-by-step instructions: date selection, hierarchical navigation, tab switching, data export.
6. **Utilidade Operacional (Indicators/Utility)** -- describes operational value with `ListItem` cards.
7. **Notas Tecnicas (Technical Notes)** -- `Alert` components with severity info/warning/success for: data source endpoint, data structure, timeout, auto-update behavior.
8. **Footer** -- centered `Paper` with system name and support contact.

**Key convention:**
- Component name: `{ReportName}Docs`, default exported.
- All text in Portuguese.
- Uses MUI components: `Typography`, `Box`, `Paper`, `Divider`, `List`, `ListItem`, `ListItemText`, `Alert`.
- MUI icons: `Science`, `Timeline`, `Assessment`, `Info` from `@mui/icons-material`.

---

## 9. Section Page Pattern

**File:** `app/(dashboard)/{section}/page.tsx`

```tsx
"use client"

import ReportA from "./reports/{report-a}";
import ReportB from "./reports/{report-b}";
import ReportC from "./reports/{report-c}";

export default function {Section}Page() {
  return (
    <div className="w-full @container">
      <div className="grid grid-cols-1 gap-3 sm:gap-4 @[1536px]:gap-8">
        <div className="grid grid-cols-1 @[640px]:grid-cols-2 gap-3 sm:gap-4 @[1536px]:gap-8">
          <ReportA />
          <ReportB />
          <ReportC />
        </div>
      </div>
    </div>
  );
}
```

**Key points:**
- Must be `"use client"` since child report components are client components.
- Uses CSS `@container` queries (not media queries) for responsive layout.
- Outer `@container` wrapper enables container query breakpoints.
- 2-column layout kicks in at `@[640px]` (640px container width).
- Gap increases at `@[1536px]` for ultra-wide screens.
- Each report is imported from its `index.tsx` and rendered as a self-contained component.
- Reports are siblings in the grid; no props needed (they manage their own state and data fetching).

---

## 10. Auth Pages Pattern

### Auth Layout -- `app/(auth)/layout.tsx`

```tsx
import Image from "next/image";

export default function AuthLayout({children}: {children: React.ReactNode}) {
  return (
    <div className="relative min-h-screen w-full flex">
      {/* Background Image */}
      <div className="absolute inset-0 z-0">
        <Image
          src="/login-bg.jpg"
          alt="Sign up illustration"
          fill
          style={{ objectFit: "cover" }}
          className="w-full h-full"
          priority
        />
      </div>

      {/* Form Container -- right-aligned */}
      <div className="absolute right-0 bottom-0 top-0 z-10 flex items-center justify-center px-10">
        {children}
      </div>
    </div>
  );
}
```

### Sign-In Page -- `app/(auth)/sign-in/page.tsx`

```tsx
import SignInClientPage from "./client";

export default function SignInPage() {
  return <SignInClientPage />;
}
```

### Sign-In Client -- `app/(auth)/sign-in/client.tsx`

```tsx
"use client";

import { useSignIn, useAuth } from "@clerk/nextjs";
import { useRef, useState } from "react";
import { FcGoogle } from "react-icons/fc";
import { SyncLoader } from "react-spinners";
import { Card, CardContent, CardHeader, CardTitle } from "../../../components/ui/card";
import { Input } from "../../../components/ui/input";
import { Button } from "../../../components/ui/button";
import { Logo } from "@repo/design_system/app/atoms/images/Logo";
import { Separator } from "../../../components/ui/separator";

export default function SignInPage() {
  const { signIn, isLoaded } = useSignIn();
  const { isSignedIn } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSignInLoading, setIsSignInLoading] = useState(false);
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);

  // Redirect if already signed in
  if (isSignedIn) {
    window.location.href = "/";
    return null;
  }

  // Google OAuth
  function handleGoogleSignIn() {
    if (!isLoaded) return;
    setIsGoogleLoading(true);
    signIn.authenticateWithRedirect({
      strategy: "oauth_google",
      redirectUrl: "/",
      redirectUrlComplete: "/",
    });
  }

  // Email/password sign in
  async function handleSignIn() {
    if (!isLoaded) return;
    setError(null);
    setIsSignInLoading(true);
    try {
      const result = await signIn.create({ identifier: email, password });
      if (result.status === "complete") {
        window.location.href = "/";
      } else {
        setError("Sign in failed");
      }
    } catch (err: any) {
      if (err.errors?.[0]?.message?.includes("Session already exists")) {
        window.location.href = "/";
      } else {
        setError(err.errors?.[0]?.message || "Sign in failed");
      }
    } finally {
      setIsSignInLoading(false);
    }
  }

  return (
    <Card className="w-full h-auto min-h-[70%] max-w-md min-w-[300px] rounded-4xl shadow-lg border-0 py-8 px-4 lg:px-6">
      <CardHeader className="space-y-1">
        <div className="flex items-center justify-center mb-2">
          <Logo width={75} />
        </div>
        <CardTitle className="text-center text-2xl font-extrabold text-[{PRIMARY_COLOR}]">
          {SIGN_IN_TITLE}
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-5">
        {/* Email/password form + Google OAuth button + links */}
      </CardContent>
    </Card>
  );
}
```

**Key points:**
- Auth layout uses a full-screen background image with form right-aligned.
- Sign-in/sign-up pages split into `page.tsx` (server) + `client.tsx` (client component).
- Uses Clerk's `useSignIn` / `useSignUp` hooks for authentication.
- Google OAuth via `authenticateWithRedirect` with `strategy: "oauth_google"`.
- Loading states use `SyncLoader` from `react-spinners`.
- Session-already-exists errors trigger a redirect rather than showing an error.
- UI components: local `components/ui/` Radix-based components (Card, Input, Button, Separator).
- Logo from `@repo/design_system/app/atoms/images/Logo`.

---

## 11. Next.js Config Pattern

**File:** `next.config.ts`

```ts
import type { NextConfig } from "next";
import createMDX from '@next/mdx';

const withMDX = createMDX({
  extension: /\.mdx?$/,
  options: {
    remarkPlugins: [],
    rehypePlugins: [],
  },
})

const nextConfig: NextConfig = {
  experimental: {
    serverActions: {
      bodySizeLimit: "10mb"
    }
  },
  env: {
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  },
  turbopack: {
    rules: {
      '*.mdx': {
        loaders: ['@mdx-js/loader'],
        as: '*.js',
      },
    },
  },
};

export default withMDX(nextConfig);
```

**Key points:**
- MDX support via `@next/mdx` with Turbopack-specific rules.
- Server actions enabled with 10MB body size limit.
- Clerk publishable key explicitly forwarded via `env` config.
- Turbopack MDX loader configured separately from webpack MDX (both needed for dev and build).
- Config is TypeScript (`next.config.ts`, not `.js` or `.mjs`).

---

## 12. Package.json Dependencies

### Workspace Dependencies

| Package | Purpose |
|---------|---------|
| `@repo/design_system` | Shared UI: DashboardLayout, MainCard, Stacked charts, icons, AppProvider |
| `@repo/ai` | AI chat panel: AIChatProvider |
| `@repo/auth` | Auth provider (alternative to Clerk) |
| `@repo/utilities` | Shared helpers, formatters, constants |

### Runtime Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `next` | `15.3.2` | Framework |
| `react` / `react-dom` | `^18.3.1` | UI library |
| `@clerk/nextjs` | `^6.18.5` | Authentication |
| `axios` | `^1.8.3` | HTTP client |
| `zustand` | `^5.0.4` | State management |
| `apexcharts` | `^5.3.4` | Charting (stacked bars) |
| `recharts` | `2.15.4` | Charting (alternative) |
| `next-themes` | `^0.2.1` | Theme switching |
| `xlsx` | `^0.18.5` | Excel export |
| `html2canvas` | `^1.4.1` | Chart image export fallback |
| `@tanstack/react-table` | `^8.21.3` | Data tables |
| `react-icons` | `^5.4.0` | Icon library |
| `react-spinners` | `^0.15.0` | Loading spinners |
| `react-resizable-panels` | `^3.0.2` | Resizable panels (AI chat) |
| `lucide-react` | `^0.482.0` | Icons (auth pages) |
| `@react-google-maps/api` | `^2.20.7` | Google Maps |
| `@mui/icons-material` | `^7.3.2` | MUI icons (docs components) |
| `@mdx-js/loader` / `@mdx-js/react` | `^3.x` | MDX support |
| `@next/mdx` | `^14.0.4` | Next.js MDX plugin |
| `next-mdx-remote` | `^5.0.0` | Remote MDX rendering |
| `next-auth` | `5.0.0-beta.29` | Auth (alternative) |
| `resend` | `^4.8.0` | Email sending |
| `class-variance-authority` | `^0.7.1` | Variant styling |
| `clsx` | `^2.1.1` | Classname utility |
| `tailwind-merge` | `^3.3.0` | Tailwind class merging |
| `@tailwindcss/typography` | `^0.5.10` | Prose styling |
| Radix UI packages | various | Primitive UI components |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `typescript` | `^5` | Type checking |
| `tailwindcss` | `^4` | Utility-first CSS |
| `@tailwindcss/postcss` | `^4` | PostCSS plugin |
| `eslint` / `eslint-config-next` | `^9` / `15.3.2` | Linting |
| `tw-animate-css` | `^1.2.5` | Animation utilities |
| `@types/node` / `@types/react` / `@types/react-dom` | various | Type definitions |
| `@types/html2canvas` | `^1.0.0` | html2canvas types |
| `@eslint/eslintrc` | `^3` | ESLint config |

---

## 13. Design System Imports Reference

### From `@repo/design_system`

| Import Path | Export | Purpose |
|-------------|--------|---------|
| `@repo/design_system/app/templates/DashboardLayout` | `DashboardLayout` | Main dashboard shell with sidebar, header, content area |
| `@repo/design_system/app/organisms/cards/MainCard` | `MainCard` | Report wrapper card with title, subtitle, loading state, documentation panel, export actions |
| `@repo/design_system/app/atoms/charts/apex/Stacked` | `Stacked` | ApexCharts stacked bar chart with click handler |
| `@repo/design_system/app/atoms/icons/Grid` | `IconlyGrid` | Grid/dashboard icon for navigation |
| `@repo/design_system/app/atoms/icons/Location` | `IconlyLocation` | Location/map icon for navigation |
| `@repo/design_system/app/atoms/icons/Patients` | `IconlyPatients` | Patients icon for navigation |
| `@repo/design_system/app/atoms/images/Logo` | `Logo` | Application logo component |
| `@repo/design_system/app/molecules/headers/SettingsDrawer` | `SettingsProps` (type) | Settings type used by layout and Zustand store |
| `@repo/design_system/contexts` | `AppProvider` | MUI theme provider accepting light/dark theme objects |

### From `@repo/ai`

| Import Path | Export | Purpose |
|-------------|--------|---------|
| `@repo/ai/src/context/ai-chat-provider` | `AIChatProvider` | AI chat panel with resizable split view |

### From `@repo/auth`

| Import Path | Export | Purpose |
|-------------|--------|---------|
| `@repo/auth` | `AuthProvider` | Alternative auth provider (not used when Clerk is active) |

### From Clerk (`@clerk/nextjs`)

| Import | Purpose |
|--------|---------|
| `ClerkProvider` | Root auth provider (in root layout) |
| `useUser` | Get current user info (name, email, avatar) |
| `useAuth` | Get auth functions (signOut, getToken) |
| `useSignIn` | Sign-in flow hooks |
| `useSignUp` | Sign-up flow hooks |
| `clerkMiddleware` | Middleware auth protection |
| `createRouteMatcher` | Route matching for public routes |

### React Icons Used

| Import | Package | Purpose |
|--------|---------|---------|
| `PiMicrosoftExcelLogoFill` | `react-icons/pi` | Excel export button |
| `IoImageOutline` | `react-icons/io5` | Image export button |
| `VscDebugRestart` | `react-icons/vsc` | Restart/reset button |
| `FcGoogle` | `react-icons/fc` | Google OAuth button |

### MUI Icons (Documentation Components)

| Import | Purpose |
|--------|---------|
| `Science` | Report header icon |
| `Timeline` | Feature list icon |
| `Assessment` | Feature list icon |
| `Info` | Feature list icon |
