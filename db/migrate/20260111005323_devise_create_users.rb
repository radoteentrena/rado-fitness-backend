# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      # --- CAMPOS PERSONALIZADOS ---
      t.string :first_name
      t.string :last_name
      t.string :phone

      # Status del Funnel: 0=lead (registrado sin pagar), 1=active (pagó), 2=churned (se fue), 3=archived
      t.integer :status, default: 0

      # Tipo de Plan: 0=basic, 1=medium, 2=high_ticket
      t.integer :plan_tier

      # Soft Delete
      t.datetime :discarded_at
      t.index :discarded_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
