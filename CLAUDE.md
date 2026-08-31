# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Naila** is a real-time flood risk monitoring system for Curitiba, Brazil. It serves government officials (Defesa Civil) via a dark-themed command-center dashboard. Citizens are notified about emergencies via SMS. Built with Rails 8, PostgreSQL + PostGIS, and Hotwire.

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

### Admin-only app

- **Admin** (`/admin`, also `/` root) — dark command-center dashboard. `Admin::BaseController` requires authentication + Pundit authorization. Layout: `app/views/layouts/admin.html.erb`.
- **API** (`/api/v1`) — sensor data ingestion endpoint (planned).
- Root path redirects to admin dashboard (login required).

### Authentication & Authorization

- Cookie-based sessions using signed tokens (`app/controllers/concerns/authentication.rb`). Session records stored in DB with IP/user agent.
- Three roles: `admin` (full access), `coordinator` (can manage alerts), `operator` (read-only).
- Pundit policies in `app/policies/`. Default: index/show open, create/update requires coordinator+, destroy requires admin.
- Routes use `login_path`/`logout_path` (not resourceful `new_session_path`).

### PostGIS & Geospatial

- All geographic models use PostGIS spatial types (`st_polygon`, `st_point`, `st_line_string`) with SRID 4326 and GiST indexes.
- Adapter: `activerecord-postgis` gem (seuros fork, Rails 8 native). RGeo for geometry operations, `rgeo-geojson` for serialization.
- Key spatial query: `MonitoringStation#nearby_river_basin_ids` uses `ST_DWithin` (used by background jobs). Alarm-evaluation queries go through `Sensor.joins(:monitoring_station).where("ST_DWithin(monitoring_stations.location::geography, ...)")`.

### Alarm-driven status model

Basin and dashboard status are **derived from alarm state**, not from a separately computed risk score. The five-level severity scale `1..4` (`attention`, `alert`, `high_alert`, `emergency`) lives on `Alarm#current_severity`; `0` is the implicit "no firing alarm" baseline.

- `RiverBasin#alarm_severity` returns the maximum `current_severity` of any firing alarm on the basin (0..4).
- `RiverBasin#monitored?` returns `true` when at least one alarm is configured for the basin. Untracked basins render gray on the map so coverage gaps are visible.
- `Alarm.max_severity_by_basin` (Hash of `basin_id → severity`) is the bulk variant — the dashboard precomputes it once and embeds it in the page; it's also re-broadcast over the `basin_alarms` Turbo Stream when any alarm transitions, so polygons recolor live.
- The map's color buckets map severity 1→attention, 2→alert, 3→high_alert, 4→emergency. Severity 0 + monitored = green ("normal"); not monitored = gray.

### Sensor Data

Model hierarchy: `RiverBasin (1:1 home) → MonitoringStation → Sensor (1:many) → SensorReading`

- Each river basin has one *home* monitoring station (`monitoring_stations.river_basin_id`, ownership/cascade-delete, admin display); each station has multiple sensors (pluviometer, weather_station). This home relationship is a design convention (enforced in seeds + admin UI), not a DB unique constraint — test fixtures may have multiple stations per basin for job testing.
- Separately, `RiverBasin#configured_monitoring_stations` (through `RiverBasinMonitoringStation`) is what actually feeds a basin's metrics/alarms — `MetricDataCollector` reads `river_basin.configured_sensors`, not the home station. A station auto-configures for its own home basin on create, but can also be explicitly configured for additional basins (shared station), managed via the basin edit form's "Estações Configuradas" checklist. Don't confuse the two: `river_basin.monitoring_station` (ownership) can silently diverge from `river_basin.configured_monitoring_stations` (what alarms actually read) if someone reassigns a station's home basin without updating its configuration.
- An individual `Alarm` can further narrow *which* of its basin's configured stations it reads, via `Alarm#monitoring_stations` (through `AlarmMonitoringStation`) — managed by the alarm form's "Estações" checklist. `Alarm#effective_monitoring_stations` is what evaluation actually uses: the explicit scope if any station is checked, otherwise every station configured for the basin. A scoped station must already be one of the basin's configured stations — validated on the alarm, not just enforced by the UI.
- `sensor_readings.sensor_id` is the FK — not `monitoring_station_id`. Traverse readings via `station.sensor_readings` (through association) or `sensor.sensor_readings`.
- `SensorReading` table uses raw SQL migration for PostgreSQL `PARTITION BY RANGE` (monthly partitions). This is intentional — Rails DSL doesn't support table partitioning. Any schema changes to `sensor_readings` must use `execute "ALTER TABLE ..."` raw SQL, not Rails column helpers.

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
External sources (CEMADEN, Open-Meteo, OpenWeatherMap)
  → FetchCemadenJob / FetchOpenMeteoJob / FetchOpenWeatherMapJob
  → SensorReading (via Sensor) / WeatherObservation / WeatherForecast
  → AlarmEvaluationJob → AlarmEvaluationEngine → MetricDataCollector
  → Alarm transitions (state, current_severity) + AlarmStateHistory
  → AlarmActionExecutor → SendAlarmEmail / SendAlarmSms via NotificationRule
  → after_update_commit broadcasts Alarm.max_severity_by_basin to "basin_alarms"
  → Turbo Stream replaces the severities partial → maps recolor live
```

`WeatherIngestionCycleJob` orchestrates the weather fetch jobs on a schedule. Each fetch job enqueues `AlarmEvaluationJob.perform_later("all")` once after writing fresh data, so alarms re-evaluate against the latest readings without waiting for the 5-minute scheduled tick.

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
