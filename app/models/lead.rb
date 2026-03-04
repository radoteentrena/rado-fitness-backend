class Lead < ApplicationRecord
  validates :name, :last_name, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
