# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/controllers/admin", under: "controllers/admin"
pin_all_from "app/javascript/controllers/public", under: "controllers/public"
pin_all_from "app/javascript/controllers/shared", under: "controllers/shared"

# OpenLayers — loaded as classic <script> in admin layout (UMD build, not ESM)

# Apache ECharts — loaded via CDN ESM build
pin "echarts", to: "https://cdn.jsdelivr.net/npm/echarts@5.6.0/dist/echarts.esm.min.js", preload: false
