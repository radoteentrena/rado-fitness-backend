class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  include Discard::Model

  enum :status, { lead: 0, active: 1, churned: 2, archived: 3 }, default: :lead
  enum :plan_tier, { basic: 0, medium: 1, high_ticket: 2 }
  enum :category, { pelele: 0, civil: 1, soldado: 2 }

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Callbacks
  before_validation :set_temporary_password, on: :create
  after_create :send_welcome_email

  # Associations
  has_many :routines, dependent: :destroy
  has_many :programs, dependent: :destroy
  has_many :user_dietary_plans, dependent: :destroy
  has_many :daily_metrics, dependent: :destroy

  def name
    "#{first_name} #{last_name}"
  end

  private

  def set_temporary_password
    self.password = SecureRandom.hex(8) if password.blank?
  end

  def send_welcome_email
    # TODO: Configure mailer properly for all environments
    # send_reset_password_instructions
  end
end
