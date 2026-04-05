#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# scaffold-dashboard.sh — Bootstrap a new dashboard app in the
# OpenLDR turborepo monorepo.
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ────────────────────────────────────────────────
APP_NAME=""
SECTIONS="summary"
MONOREPO=""

# ── Usage ───────────────────────────────────────────────────
usage() {
  cat <<USAGE
Usage: scaffold-dashboard.sh <app-name> [OPTIONS]

Bootstrap a new Next.js 15 dashboard app inside the OpenLDR turborepo monorepo.

Arguments:
  app-name              Lowercase app identifier (e.g. hivvl, eid, cd4)

Options:
  --sections "a,b,c"    Comma-separated navigation sections (default: "summary")
  --monorepo PATH       Path to monorepo root (default: auto-detect)
  --help                Show this help message

Examples:
  scaffold-dashboard.sh hivvl
  scaffold-dashboard.sh eid --sections "summary,laboratory,province"
  scaffold-dashboard.sh cd4 --sections "summary,patients" --monorepo /path/to/monorepo
USAGE
  exit 0
}

# ── Argument parsing ────────────────────────────────────────
if [[ $# -eq 0 ]]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      ;;
    --sections)
      SECTIONS="$2"
      shift 2
      ;;
    --monorepo)
      MONOREPO="$2"
      shift 2
      ;;
    -*)
      echo "ERROR: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$APP_NAME" ]]; then
        APP_NAME="$1"
      else
        echo "ERROR: Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# ── Validation ──────────────────────────────────────────────
if [[ -z "$APP_NAME" ]]; then
  echo "ERROR: App name is required." >&2
  exit 1
fi

if [[ ! "$APP_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "ERROR: App name must match ^[a-z][a-z0-9-]*$ (lowercase, letters/numbers/hyphens, start with letter)." >&2
  exit 1
fi

# ── Auto-detect monorepo ────────────────────────────────────
if [[ -z "$MONOREPO" ]]; then
  # From script location: scripts/ -> openldr-dashboard/ -> openldr-skills/ -> ../../openldr/openldr-monorepo/
  SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  CANDIDATE="$SKILLS_ROOT/../../openldr/openldr-monorepo"
  if [[ -d "$CANDIDATE" ]]; then
    MONOREPO="$(cd "$CANDIDATE" && pwd)"
  else
    echo "ERROR: Could not auto-detect monorepo. Use --monorepo PATH." >&2
    exit 1
  fi
fi

if [[ ! -f "$MONOREPO/turbo.json" ]]; then
  echo "ERROR: $MONOREPO does not contain turbo.json — not a valid turborepo." >&2
  exit 1
fi

APP_DIR="$MONOREPO/apps/$APP_NAME"

if [[ -d "$APP_DIR" ]]; then
  echo "ERROR: App '$APP_NAME' already exists at $APP_DIR" >&2
  exit 1
fi

# ── Prepare section list ────────────────────────────────────
IFS=',' read -ra SECTION_LIST <<< "$SECTIONS"
# Trim whitespace from each section
for i in "${!SECTION_LIST[@]}"; do
  SECTION_LIST[$i]="$(echo "${SECTION_LIST[$i]}" | xargs)"
done

# Capitalize app name for display
APP_TITLE="$(echo "$APP_NAME" | sed 's/\b\(.\)/\u\1/g')"

echo "Scaffolding dashboard app: $APP_NAME"
echo "  Monorepo: $MONOREPO"
echo "  App dir:  $APP_DIR"
echo "  Sections: ${SECTION_LIST[*]}"
echo ""

# ── Create directory structure ──────────────────────────────
mkdir -p "$APP_DIR/app/(auth)/sign-in"
mkdir -p "$APP_DIR/app/(auth)/sign-up"
mkdir -p "$APP_DIR/app/(dashboard)/(index)/reports"
for section in "${SECTION_LIST[@]}"; do
  if [[ "$section" != "${SECTION_LIST[0]}" ]]; then
    mkdir -p "$APP_DIR/app/(dashboard)/$section/reports"
  fi
done
mkdir -p "$APP_DIR/app/api"
mkdir -p "$APP_DIR/components/ui"
mkdir -p "$APP_DIR/config"
mkdir -p "$APP_DIR/context"
mkdir -p "$APP_DIR/hooks"
mkdir -p "$APP_DIR/themes"
mkdir -p "$APP_DIR/public"
mkdir -p "$APP_DIR/messages"
mkdir -p "$APP_DIR/lib"

# ── package.json ────────────────────────────────────────────
cat > "$APP_DIR/package.json" << 'EOF'
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
    "@clerk/nextjs": "^6.12.0",
    "@mdx-js/loader": "^3.1.0",
    "@mdx-js/react": "^3.1.0",
    "@next/mdx": "^15.1.7",
    "@radix-ui/react-tabs": "^1.1.3",
    "@repo/ai": "*",
    "@repo/auth": "*",
    "@repo/design_system": "*",
    "@repo/utilities": "*",
    "@tanstack/react-table": "^8.21.2",
    "apexcharts": "^4.4.0",
    "axios": "^1.7.9",
    "clsx": "^2.1.1",
    "html2canvas": "^1.4.1",
    "lucide-react": "^0.474.0",
    "next": "^15.1.7",
    "next-intl": "^3.26.3",
    "next-themes": "^0.4.4",
    "react": "^18.3.1",
    "react-apexcharts": "^1.7.0",
    "react-dom": "^18.3.1",
    "recharts": "^2.15.1",
    "tailwind-merge": "^3.0.2",
    "xlsx": "^0.18.5",
    "zustand": "^5.0.3"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4.0.9",
    "@types/mdx": "^2.0.13",
    "@types/node": "^22.13.5",
    "@types/react": "^18.3.18",
    "@types/react-dom": "^18.3.5",
    "eslint": "^9.20.0",
    "eslint-config-next": "^15.1.7",
    "tailwindcss": "^4.0.9",
    "typescript": "^5.7.3"
  }
}
EOF
sed -i "s/APP_NAME_PLACEHOLDER/$APP_NAME/g" "$APP_DIR/package.json"

# ── next.config.ts ──────────────────────────────────────────
cat > "$APP_DIR/next.config.ts" << 'EOF'
import createMDX from "@next/mdx";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  pageExtensions: ["js", "jsx", "md", "mdx", "ts", "tsx"],
  transpilePackages: [
    "@repo/ai",
    "@repo/auth",
    "@repo/design_system",
    "@repo/utilities",
  ],
  experimental: {
    mdxRs: true,
    turbo: {
      rules: {
        "*.mdx": {
          loaders: ["@mdx-js/loader"],
          as: "*.js",
        },
      },
    },
    serverActions: {
      bodySizeLimit: "5mb",
    },
  },
};

const withMDX = createMDX({});

export default withMDX(nextConfig);
EOF

# ── tsconfig.json ───────────────────────────────────────────
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
    "module": "bundler",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", "**/*.mdx"],
  "exclude": ["node_modules"]
}
EOF

# ── tailwind.config.ts ──────────────────────────────────────
cat > "$APP_DIR/tailwind.config.ts" << 'EOF'
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./node_modules/@repo/design_system/src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};

export default config;
EOF

# ── postcss.config.mjs ─────────────────────────────────────
cat > "$APP_DIR/postcss.config.mjs" << 'EOF'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
EOF

# ── eslint.config.mjs ──────────────────────────────────────
cat > "$APP_DIR/eslint.config.mjs" << 'EOF'
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [...compat.extends("next/core-web-vitals")];

export default eslintConfig;
EOF

# ── components.json (Shadcn UI) ─────────────────────────────
cat > "$APP_DIR/components.json" << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
EOF

# ── .gitignore ──────────────────────────────────────────────
cat > "$APP_DIR/.gitignore" << 'EOF'
# dependencies
node_modules
.pnp
.pnp.js

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
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts
EOF

# ── .env.local.template ────────────────────────────────────
cat > "$APP_DIR/.env.local.template" << 'EOF'
# OpenLDR API
OPENLDR_API=https://api.openldr.org

# Clerk Authentication
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/
EOF

# ── next-env.d.ts ───────────────────────────────────────────
cat > "$APP_DIR/next-env.d.ts" << 'EOF'
/// <reference types="next" />
/// <reference types="next/image-types/global" />

// NOTE: This file should not be edited
// see https://nextjs.org/docs/app/api-reference/config/typescript for more information.
EOF

# ── config/api.ts ───────────────────────────────────────────
cat > "$APP_DIR/config/api.ts" << 'EOF'
import axios from "axios";

const createApiClient = (token?: string) => {
  const client = axios.create({
    baseURL: process.env.OPENLDR_API || "https://api.openldr.org",
    timeout: 60000,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  return client;
};

export default createApiClient;
EOF

# ── context/theme-provider.tsx ──────────────────────────────
cat > "$APP_DIR/context/theme-provider.tsx" << 'EOF'
"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";
import { type ThemeProviderProps } from "next-themes";
import { useEffect, useState } from "react";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
EOF

# ── hooks/useLayoutSettings.ts ──────────────────────────────
cat > "$APP_DIR/hooks/useLayoutSettings.ts" << 'EOF'
import { create } from "zustand";
import { persist } from "zustand/middleware";

interface LayoutSettings {
  sidebarOpen: boolean;
  compactMode: boolean;
  toggleSidebar: () => void;
  setCompactMode: (compact: boolean) => void;
}

export const useLayoutSettings = create<LayoutSettings>()(
  persist(
    (set) => ({
      sidebarOpen: true,
      compactMode: false,
      toggleSidebar: () =>
        set((state) => ({ sidebarOpen: !state.sidebarOpen })),
      setCompactMode: (compact: boolean) => set({ compactMode: compact }),
    }),
    {
      name: "layout-settings",
    }
  )
);
EOF

# ── themes/dark.ts ──────────────────────────────────────────
cat > "$APP_DIR/themes/dark.ts" << 'EOF'
const darkTheme = {
  palette: {
    mode: "dark" as const,
    primary: {
      main: "#00B000",
    },
    background: {
      default: "#0a0a0a",
      paper: "#1a1a1a",
    },
    text: {
      primary: "#ffffff",
      secondary: "#a0a0a0",
    },
  },
};

export default darkTheme;
EOF

# ── themes/light.ts ─────────────────────────────────────────
cat > "$APP_DIR/themes/light.ts" << 'EOF'
const lightTheme = {
  palette: {
    mode: "light" as const,
    primary: {
      main: "#00B000",
    },
    background: {
      default: "#ffffff",
      paper: "#f5f5f5",
    },
    text: {
      primary: "#0a0a0a",
      secondary: "#606060",
    },
  },
};

export default lightTheme;
EOF

# ── middleware.ts ────────────────────────────────────────────
cat > "$APP_DIR/middleware.ts" << 'EOF'
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher(["/sign-in(.*)", "/sign-up(.*)"]);

export default clerkMiddleware(async (auth, request) => {
  if (!isPublicRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
EOF

# ── app/globals.css ─────────────────────────────────────────
cat > "$APP_DIR/app/globals.css" << 'EOF'
@import "tailwindcss";
EOF

# ── app/layout.tsx ──────────────────────────────────────────
cat > "$APP_DIR/app/layout.tsx" << EOF
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { ThemeProvider } from "@/context/theme-provider";
import "./globals.css";

export const metadata: Metadata = {
  title: "$APP_TITLE",
  description: "$APP_TITLE Dashboard — OpenLDR",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt" suppressHydrationWarning>
      <body>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <ClerkProvider>
            {children}
          </ClerkProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
EOF

# ── app/page.tsx ────────────────────────────────────────────
cat > "$APP_DIR/app/page.tsx" << 'EOF'
import { redirect } from "next/navigation";

export default function Home() {
  redirect("/");
}
EOF

# ── app/(auth)/layout.tsx ───────────────────────────────────
cat > "$APP_DIR/app/(auth)/layout.tsx" << 'EOF'
export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen items-center justify-center">
      {children}
    </div>
  );
}
EOF

# ── app/(auth)/sign-in/page.tsx ─────────────────────────────
cat > "$APP_DIR/app/(auth)/sign-in/page.tsx" << 'EOF'
import { SignInClient } from "./client";

export default function SignInPage() {
  return <SignInClient />;
}
EOF

# ── app/(auth)/sign-in/client.tsx ───────────────────────────
cat > "$APP_DIR/app/(auth)/sign-in/client.tsx" << 'EOF'
"use client";

import { SignIn } from "@clerk/nextjs";

export function SignInClient() {
  return <SignIn />;
}
EOF

# ── app/(auth)/sign-up/page.tsx ─────────────────────────────
cat > "$APP_DIR/app/(auth)/sign-up/page.tsx" << 'EOF'
import { SignUpClient } from "./client";

export default function SignUpPage() {
  return <SignUpClient />;
}
EOF

# ── app/(auth)/sign-up/client.tsx ───────────────────────────
cat > "$APP_DIR/app/(auth)/sign-up/client.tsx" << 'EOF'
"use client";

import { SignUp } from "@clerk/nextjs";

export function SignUpClient() {
  return <SignUp />;
}
EOF

# ── app/(dashboard)/layout.tsx ──────────────────────────────
cat > "$APP_DIR/app/(dashboard)/layout.tsx" << 'DASHEOF'
"use client";

import { AppProvider, DashboardLayout } from "@repo/design_system";
import { AIChatProvider } from "@repo/ai";

export default function DashLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AppProvider>
      <AIChatProvider dashboard="APP_NAME_PLACEHOLDER">
        <DashboardLayout>{children}</DashboardLayout>
      </AIChatProvider>
    </AppProvider>
  );
}
DASHEOF
sed -i "s/APP_NAME_PLACEHOLDER/$APP_NAME/g" "$APP_DIR/app/(dashboard)/layout.tsx"

# ── app/(dashboard)/(index)/page.tsx ────────────────────────
FIRST_SECTION="${SECTION_LIST[0]}"
FIRST_SECTION_TITLE="$(echo "$FIRST_SECTION" | sed 's/\b\(.\)/\u\1/g')"

cat > "$APP_DIR/app/(dashboard)/(index)/page.tsx" << EOF
export default function ${FIRST_SECTION_TITLE}Page() {
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold">$FIRST_SECTION_TITLE</h1>
      <p className="mt-2 text-muted-foreground">
        This is the $FIRST_SECTION section. Add your reports and visualizations here.
      </p>
    </div>
  );
}
EOF

# ── Additional section pages ────────────────────────────────
for section in "${SECTION_LIST[@]}"; do
  if [[ "$section" != "${SECTION_LIST[0]}" ]]; then
    SECTION_TITLE="$(echo "$section" | sed 's/\b\(.\)/\u\1/g')"
    cat > "$APP_DIR/app/(dashboard)/$section/page.tsx" << EOF
export default function ${SECTION_TITLE}Page() {
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold">$SECTION_TITLE</h1>
      <p className="mt-2 text-muted-foreground">
        This is the $section section. Add your reports and visualizations here.
      </p>
    </div>
  );
}
EOF
  fi
done

# ── components/ui/tabs.tsx ──────────────────────────────────
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
      "inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground",
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
      "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm",
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

# ── lib/utils.ts ────────────────────────────────────────────
cat > "$APP_DIR/lib/utils.ts" << 'EOF'
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

# ── messages/pt.json ────────────────────────────────────────
# Build navigation keys dynamically
NAV_PT="{"
for i in "${!SECTION_LIST[@]}"; do
  section="${SECTION_LIST[$i]}"
  section_title="$(echo "$section" | sed 's/\b\(.\)/\u\1/g')"
  if [[ $i -gt 0 ]]; then
    NAV_PT+=","
  fi
  NAV_PT+="
    \"$section\": \"$section_title\""
done
NAV_PT+="
  }"

cat > "$APP_DIR/messages/pt.json" << EOF
{
  "navigation": $NAV_PT,
  "common": {
    "loading": "Carregando...",
    "error": "Erro ao carregar dados",
    "noData": "Sem dados disponíveis",
    "search": "Pesquisar",
    "filter": "Filtrar",
    "export": "Exportar",
    "refresh": "Atualizar",
    "save": "Salvar",
    "cancel": "Cancelar",
    "confirm": "Confirmar",
    "back": "Voltar",
    "next": "Próximo",
    "previous": "Anterior",
    "close": "Fechar",
    "yes": "Sim",
    "no": "Não",
    "total": "Total",
    "period": "Período",
    "from": "De",
    "to": "Até"
  }
}
EOF

# ── messages/en.json ────────────────────────────────────────
NAV_EN="{"
for i in "${!SECTION_LIST[@]}"; do
  section="${SECTION_LIST[$i]}"
  section_title="$(echo "$section" | sed 's/\b\(.\)/\u\1/g')"
  if [[ $i -gt 0 ]]; then
    NAV_EN+=","
  fi
  NAV_EN+="
    \"$section\": \"$section_title\""
done
NAV_EN+="
  }"

cat > "$APP_DIR/messages/en.json" << EOF
{
  "navigation": $NAV_EN,
  "common": {
    "loading": "Loading...",
    "error": "Error loading data",
    "noData": "No data available",
    "search": "Search",
    "filter": "Filter",
    "export": "Export",
    "refresh": "Refresh",
    "save": "Save",
    "cancel": "Cancel",
    "confirm": "Confirm",
    "back": "Back",
    "next": "Next",
    "previous": "Previous",
    "close": "Close",
    "yes": "Yes",
    "no": "No",
    "total": "Total",
    "period": "Period",
    "from": "From",
    "to": "To"
  }
}
EOF

# ── Success message ─────────────────────────────────────────
echo ""
echo "=========================================="
echo " Dashboard '$APP_NAME' scaffolded!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "  cd $APP_DIR"
echo "  cp .env.local.template .env.local"
echo "  # Edit .env.local with your Clerk keys"
echo ""
echo "  cd $MONOREPO"
echo "  pnpm install"
echo "  pnpm dev --filter=$APP_NAME"
echo ""
