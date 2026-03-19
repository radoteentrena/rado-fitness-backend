module Admin
  class SubscriptionsController < Admin::ApplicationController
    # Read-only — Administrate index + show only
    # Subscriptions are created/modified via webhooks, not manually
  end
end
