# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/controllers/admin", under: "controllers/admin"
pin_all_from "app/javascript/controllers/public", under: "controllers/public"
pin_all_from "app/javascript/controllers/shared", under: "controllers/shared"

# OpenLayers — loaded via CDN ESM build
pin "ol", to: "https://cdn.jsdelivr.net/npm/ol@10.5.0/dist/ol.js", preload: false

# Apache ECharts — loaded via CDN ESM build
pin "echarts", to: "https://cdn.jsdelivr.net/npm/echarts@5.6.0/dist/echarts.esm.min.js", preload: false
