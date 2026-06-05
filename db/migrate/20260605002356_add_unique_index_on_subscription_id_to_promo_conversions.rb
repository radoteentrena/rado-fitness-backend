class AddUniqueIndexOnSubscriptionIdToPromoConversions < ActiveRecord::Migration[8.0]
  def change
    # Webhook idempotency guard: ensures no duplicate PromoConversion row if MercadoPago webhook fires twice
    remove_index :promo_conversions, :subscription_id
    add_index :promo_conversions, :subscription_id, unique: true
  end
end
