# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Naila** is a real-time flood risk monitoring system for Curitiba, Brazil. It serves government officials (Defesa Civil) via a dark-themed command-center dashboard and citizens via a light-themed public website. Built with Rails 8, PostgreSQL + PostGIS, and Hotwire.

## Commands

```bash
bin/dev                          # Start app (Puma + Tailwind watcher via foreman)
bin/rails db:setup               # Create DB, run migrations, seed
bin/rails db:seed                # Seed Curitiba data (regions, neighborhoods, rivers, sensors, alerts)
bin/rails test                   # Run full test suite
bin/rails test test/models/      # Run model tests only
bin/rails test test/models/user_test.rb:15  # Run single test at line
bin/rubocop                      # Lint Ruby code (omakase style)
bin/brakeman --no-pager          # Security scan
bin/bundler-audit                # Gem vulnerability audit
bin/importmap audit              # JS dependency audit
```

## Architecture

### Two interfaces, one app

- **Admin** (`/admin`) — dark command-center dashboard. `Admin::BaseController` requires authentication + Pundit authorization. Layout: `app/views/layouts/admin.html.erb`.
- **Public** (`/`, `/mapa`, `/alertas`, `/bairros`, `/seguranca`) — light mobile-first citizen site. `Public::BaseController` with public layout. Portuguese URLs.
- **API** (`/api/v1`) — sensor data ingestion endpoint (planned).

### Authentication & Authorization

- Cookie-based sessions using signed tokens (`app/controllers/concerns/authentication.rb`). Session records stored in DB with IP/user agent.
- Three roles: `admin` (full access), `coordinator` (can manage alerts), `operator` (read-only).
- Pundit policies in `app/policies/`. Default: index/show open, create/update requires coordinator+, destroy requires admin.
- Routes use `login_path`/`logout_path` (not resourceful `new_session_path`).

### PostGIS & Geospatial

- All geographic models use PostGIS spatial types (`st_polygon`, `st_point`, `st_line_string`) with SRID 4326 and GiST indexes.
- Adapter: `activerecord-postgis` gem (seuros fork, Rails 8 native). RGeo for geometry operations, `rgeo-geojson` for serialization.
- Key spatial query: `MonitoringStation#nearby_river_basin_ids` uses `ST_DWithin` (used by background jobs). Risk/alert service queries go through `Sensor.joins(:monitoring_station).where("ST_DWithin(monitoring_stations.location::geography, ...)")`.

### Risk Model

Five risk levels used across `RiverBasin` and `Neighborhood`: `normal` (0), `attention` (1), `alert` (2), `high_alert` (3), `emergency` (4). Composite risk score 0.0–1.0 from weighted factors (precipitation, river level, forecast, soil moisture, historical).

### Sensor Data

Model hierarchy: `RiverBasin (1:1) → MonitoringStation → Sensor (1:many) → SensorReading`

- Each river basin has one monitoring station; each station has multiple sensors (pluviometer, river_gauge, weather_station).
- `sensor_readings.sensor_id` is the FK — not `monitoring_station_id`. Traverse readings via `station.sensor_readings` (through association) or `sensor.sensor_readings`.
- `SensorReading` table uses raw SQL migration for PostgreSQL `PARTITION BY RANGE` (monthly partitions). This is intentional — Rails DSL doesn't support table partitioning. Any schema changes to `sensor_readings` must use `execute "ALTER TABLE ..."` raw SQL, not Rails column helpers.
- The 1:1 RiverBasin↔MonitoringStation relationship is a design convention (enforced in seeds + admin UI), not a DB unique constraint — test fixtures may have multiple stations per basin for job testing.

### Frontend Stack (no build step)

- **Importmap-rails** for ES modules. No node_modules, no bundler.
- **OpenLayers 10** and **ECharts 5** loaded via CDN ESM pins in `config/importmap.rb`.
- **Stimulus controllers** in `app/javascript/controllers/{admin,public,shared}/`. Auto-discovered by `eagerLoadControllersFrom`. Naming convention: `admin--map` maps to `admin/map_controller.js`.
  - Key admin controllers: `admin--map` (OpenLayers sensor map), `admin--reading-chart` / `admin--timeseries` / `admin--sparkline` / `admin--heatmap` (ECharts wrappers), `admin--polygon-editor` / `admin--polygon-viewer` (basin geometry), `admin--side-sheet` (slide-over panel), `admin--realtime-counter` (live stats).
  - Shared: `shared--notification` (ActionCable subscription), `shared--dialog` (native `<dialog>`), `shared--dropdown` (Popover API), `shared--combobox` (autocomplete).
- **Tailwind CSS 4** with `@theme` directive in `app/assets/tailwind/application.css`. Uses Catalyst's standard zinc palette with `dark:` variants for UI components. Custom domain tokens: `risk-*` (risk level colors), `sensor-*` (status colors). Compiled by `tailwindcss:watch` process in `Procfile.dev`.

### Catalyst Design System

The UI layer is built on **Catalyst** (by Tailwind Labs), ported from React/JSX to Rails helpers and a custom FormBuilder. Source reference: `/Users/eduardonakanishi/Developer/catalyst-ui-kit/javascript/`.

- **CatalystFormBuilder** (`app/form_builders/catalyst_form_builder.rb`) — registered as `default_form_builder` in `ApplicationController`. Wraps all inputs in Catalyst's `<span data-slot="control">` pattern with pseudo-element focus rings. Overrides: `text_field`, `email_field`, `password_field`, `select`, `text_area`, `check_box`, `label`, `submit`. Adds: `field`, `field_group`, `description`, `error_message`, `error_summary`.
- **Helpers** in `app/helpers/catalyst/` — each module is included via `ApplicationHelper`:
  - `ButtonHelper` — `catalyst_button`, `catalyst_button_link` (solid/outline/plain variants, 20+ colors)
  - `BadgeHelper` — `catalyst_badge` (18 colors)
  - `TypographyHelper` — `catalyst_heading`, `catalyst_subheading`, `catalyst_text`, `catalyst_strong`, `catalyst_code`, `catalyst_text_link`
  - `TableHelper` — `catalyst_table` (bleed/dense/grid/striped), `catalyst_table_head`, `catalyst_table_body`, `catalyst_table_row`, `catalyst_th`, `catalyst_td`
  - `DescriptionListHelper` — `catalyst_dl`, `catalyst_dt`, `catalyst_dd`
  - `DialogHelper` — `catalyst_dialog`, `catalyst_alert` (uses native `<dialog>` + `shared--dialog` Stimulus controller)
  - `DropdownHelper` — `catalyst_dropdown`, `catalyst_dropdown_menu`, `catalyst_dropdown_item` (uses Popover API + `shared--dropdown` Stimulus controller)
  - `ComboboxHelper` — `catalyst_combobox` (uses `shared--combobox` Stimulus controller)
  - `SidebarHelper` — `catalyst_sidebar`, `catalyst_sidebar_item` (with `aria-current` active indicator)
  - `NavbarHelper` — `catalyst_navbar`, `catalyst_navbar_item`
  - `PaginationHelper` — `catalyst_pagination`
  - `DividerHelper`, `AvatarHelper`
- **Color strategy**: standard Tailwind zinc + `dark:` variants for all components. Admin layout has `<html class="dark">` so dark-mode classes apply automatically. Domain tokens (`risk-*`, `sensor-*`) are kept separately in `@theme`.
- **Interactive components** use native browser APIs (no React, no Headless UI): `<dialog>` for modals, Popover API for dropdowns, CSS `peer-checked:` for checkboxes/radios/switches.

### Key data flow

```
External sources (CEMADEN, INMET, Open-Meteo, OpenWeatherMap)
  → FetchCemadenJob / FetchInmetJob / FetchOpenMeteoJob / FetchOpenWeatherMapJob
  → SensorReading (via Sensor) / WeatherObservation
  → RiskAssessmentJob → RiskEngine (services/) → RiskAssessment
  → EscalationCheckJob → AlertThreshold evaluation → Alert creation
  → SendAlertNotificationJob → AlertNotification dispatch (WebSocket/SMS/Push)
  → ActionCable broadcast → Turbo Stream UI updates
```

`WeatherIngestionCycleJob` orchestrates the weather fetch jobs on a schedule.

## Conventions

- **TDD workflow**: write failing tests first, then implement the code to make them pass. Run tests before and after implementation to confirm the red-green cycle. Use Minitest (not RSpec).
- All UI text in **pt-BR** (Portuguese). Variable names and code in English.
- Git messages use **conventional commits** format: `feat(scope):`, `fix(scope):`, `chore(scope):`.
- Commit after each completed task, not batched.
- CSS: uses Catalyst's zinc palette with `dark:` variants. Admin is always `<html class="dark">`. Use `catalyst_*` helpers for UI components instead of hand-writing Tailwind classes. Risk colors: `text-risk-normal`, `bg-risk-emergency`, glow classes: `.glow-high`, `.glow-emergency`. Primary action color is `sky` (sky-500).
- **Test fixtures bypass model validations** — the DB receives values directly. A fixture that would fail a `validates :uniqueness` check still loads fine. Rely on model tests (not fixtures) to verify validation behaviour.

## Gotchas

- **Partitioned table migrations**: `sensor_readings` is `PARTITION BY RANGE (recorded_at)`. All schema changes to this table must use `execute "ALTER TABLE sensor_readings ..."` raw SQL — ActiveRecord column helpers (`add_column`, `change_column_null`, etc.) silently fail or error on partitioned tables.
- **`destroy_all` vs `delete_all` on associated records**: models with `dependent: :destroy` chains (e.g. `RiverBasin → MonitoringStation → Sensor → SensorReading`) require `destroy_all` to fire callbacks and respect FK constraints. `delete_all` bypasses Rails and will hit FK violations.
- **Stimulus controller naming**: the directory separator becomes `--` in the identifier. `admin/map_controller.js` → `data-controller="admin--map"`. Values/targets follow the same prefix: `data-admin--map-sensors-value`.
- **CatalystFormBuilder is the default**: all `form_with` calls use it automatically. Don't pass raw Tailwind class strings to form fields — the builder handles styling. If you need to customize, pass extra classes via the `class:` option (they're appended, not replaced).
- **Catalyst data-slot attributes**: the FormBuilder emits `data-slot="control"`, `data-slot="label"`, etc. These are used by Catalyst's CSS spacing rules (e.g., `[&>[data-slot=label]+[data-slot=control]]:mt-3`). Don't remove them.

## Database

- Development: `naila_development`, Test: `naila_test`
- Production uses multi-database: primary + separate cache/queue/cable databases (Solid Trifecta).
- Login credentials (seed): `admin@naila.curitiba.pr.gov.br` / `naila2026`

## CI

GitHub Actions (`.github/workflows/ci.yml`): Brakeman + bundler-audit scan, importmap audit, RuboCop lint. **Tests are not run in CI** — run `bin/rails test` locally before pushing.
