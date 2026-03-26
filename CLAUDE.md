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
- Key spatial query: `SensorStation#nearby_river_basin_ids` uses `ST_DWithin`.

### Risk Model

Five risk levels used across `RiverBasin` and `Neighborhood`: `normal` (0), `attention` (1), `alert` (2), `high_alert` (3), `emergency` (4). Composite risk score 0.0–1.0 from weighted factors (precipitation, river level, forecast, soil moisture, historical).

### Sensor Data

`SensorReading` table uses raw SQL migration for PostgreSQL `PARTITION BY RANGE` (monthly partitions). This is intentional — Rails DSL doesn't support table partitioning.

### Frontend Stack (no build step)

- **Importmap-rails** for ES modules. No node_modules, no bundler.
- **OpenLayers 10** and **ECharts 5** loaded via CDN ESM pins in `config/importmap.rb`.
- **Stimulus controllers** in `app/javascript/controllers/{admin,public,shared}/`. Auto-discovered by `eagerLoadControllersFrom`. Naming convention: `admin--map` maps to `admin/map_controller.js`.
- **Tailwind CSS 4** with `@theme` directive in `app/assets/tailwind/application.css`. Custom design tokens: `naila-*` (dark theme), `risk-*` (risk level colors), `sensor-*` (status colors), `public-*` (light theme). Compiled by `tailwindcss:watch` process in `Procfile.dev`.

### Key data flow

```
External sources → [Solid Queue jobs] → SensorReading/WeatherObservation
  → RiskEngine (services/) → RiskAssessment → AlertThreshold evaluation
  → Alert creation → AlertNotification dispatch (WebSocket/SMS/Push)
  → ActionCable broadcast → Turbo Stream UI updates
```

## Conventions

- **TDD workflow**: write failing tests first, then implement the code to make them pass. Run tests before and after implementation to confirm the red-green cycle. Use Minitest (not RSpec).
- All UI text in **pt-BR** (Portuguese). Variable names and code in English.
- Git messages use **conventional commits** format: `feat(scope):`, `fix(scope):`, `chore(scope):`.
- Commit after each completed task, not batched.
- CSS: dark admin theme uses `bg-naila-bg`, `text-naila-text`, etc. Risk colors: `text-risk-normal`, `bg-risk-emergency`, glow classes: `.glow-high`, `.glow-emergency`.

## Database

- Development: `naila_development`, Test: `naila_test`
- Production uses multi-database: primary + separate cache/queue/cable databases (Solid Trifecta).
- Login credentials (seed): `admin@naila.curitiba.pr.gov.br` / `naila2026`

## CI

GitHub Actions (`.github/workflows/ci.yml`): Brakeman + bundler-audit scan, importmap audit, RuboCop lint.
