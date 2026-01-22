class Program < ApplicationRecord
  belongs_to :user, optional: true # Optional if it's a template
  has_many :routines, dependent: :nullify
end
