# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@alpinejs/persist", to: "@alpinejs--persist.js" # @3.15.5
pin "alpinejs" # @3.15.5
pin "apexcharts" # @5.3.6
pin "flowbite", to: "https://cdnjs.cloudflare.com/ajax/libs/flowbite/2.3.0/flowbite.turbo.min.js"
# pin "@popperjs/core", to: "https://unpkg.com/@popperjs/core@2.11.8/dist/esm/index.js" # Optional if Flowbite bundles it
