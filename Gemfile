source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "mission_control-jobs"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Geospatial — PostGIS adapter and geometry operations [https://github.com/seuros/activerecord-postgis]
gem "activerecord-postgis", "~> 0.4"
gem "rgeo", "~> 3.0"
gem "rgeo-geojson", "~> 2.0"

# Authorization — policy-based access control [https://github.com/varvet/pundit]
gem "pundit", "~> 2.4"

# HTTP clients for external API data ingestion [https://github.com/lostisland/faraday]
gem "faraday", "~> 2.0"
gem "faraday-retry", "~> 2.0"

# Notifications — polymorphic notification system [https://github.com/excid3/noticed]
gem "noticed", "~> 2.0"
# Web Push API for browser notifications [https://github.com/pushpad/web-push]
gem "web-push", "~> 3.0"
# SMS via Twilio [https://github.com/twilio/twilio-ruby]
gem "twilio-ruby", "~> 7.0"

# MQTT client for IoT sensor data ingestion [https://github.com/njh/ruby-mqtt]
gem "mqtt", "~> 0.6"

# Pagination [https://github.com/ddnexus/pagy]
gem "pagy", "~> 9.0"
# Charts [https://github.com/ankane/chartkick]
gem "chartkick", "~> 5.0"
# Time-series grouping [https://github.com/ankane/groupdate]
gem "groupdate", "~> 6.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Fake data generator [https://github.com/faker-ruby/faker]
  gem "faker", "~> 3.8"
end

group :test do
  # System testing [https://github.com/teamcapybara/capybara]
  gem "capybara", "~> 3.0"
  gem "selenium-webdriver", "~> 4.0"
  # HTTP request stubbing [https://github.com/bblimke/webmock]
  gem "webmock", "~> 3.0"
  # Record HTTP interactions [https://github.com/vcr/vcr]
  gem "vcr", "~> 6.0"
  # Code coverage [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false
  # Database cleaning between tests [https://github.com/DatabaseCleaner/database_cleaner]
  gem "database_cleaner-active_record", "~> 2.0"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  # N+1 query detection [https://github.com/flyerhzm/bullet]
  gem "bullet", "~> 8.0"
end
