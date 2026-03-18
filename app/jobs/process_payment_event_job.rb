class ProcessPaymentEventJob < ApplicationJob
  queue_as :default

  def perform(processor:, event_type:, payload:)
    # TODO: implement payment event processing
    Rails.logger.info "[ProcessPaymentEventJob] processor=#{processor} event_type=#{event_type}"
  end
end
