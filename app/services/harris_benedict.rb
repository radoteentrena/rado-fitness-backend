class HarrisBenedict
  ACTIVITY_FACTORS = {
    "Sedentario"  => 1.2,
    "Ligero"      => 1.375,
    "Moderado"    => 1.55,
    "Intenso"     => 1.725,
    "Muy intenso" => 1.9
  }.freeze

  # Maps the activity_level values captured by the onboarding form
  # ("Tipo de trabajo diario") to TDEE activity multipliers.
  ONBOARDING_ACTIVITY_FACTORS = {
    "Sentado"          => 1.2,
    "Levemente activo" => 1.375,
    "Activo"           => 1.55,
    "Muy activo"       => 1.725
  }.freeze

  DEFAULT_ACTIVITY_FACTOR = 1.375

  def self.bmr(user)
    new(user).bmr
  end

  def self.tdee(user)
    new(user).tdee
  end

  def initialize(user)
    @user = user
    @profile = user.onboarding_profile
  end

  def bmr
    return nil unless @profile && sex && age && weight_kg && height_cm

    base =
      if sex == :male
        88.362 + (13.397 * weight_kg) + (4.799 * height_cm) - (5.677 * age)
      else
        447.593 + (9.247 * weight_kg) + (3.098 * height_cm) - (4.330 * age)
      end
    base.round
  end

  # Total Daily Energy Expenditure: maintenance calories.
  def tdee
    base = bmr
    return nil unless base

    (base * activity_factor).round
  end

  private

  def activity_factor
    ONBOARDING_ACTIVITY_FACTORS[@profile&.activity_level] || DEFAULT_ACTIVITY_FACTOR
  end

  def sex
    case @profile.gender.to_s
    when /\Am/i then :male
    when /\Af/i then :female
    end
  end

  def age
    @profile.age
  end

  def weight_kg
    @weight_kg ||= parse_number(@profile.weight) || latest_logged_weight
  end

  def latest_logged_weight
    @user.daily_metrics.where.not(weight: nil).order(date_logged: :desc).pick(:weight)
  end

  def height_cm
    value = parse_number(@profile.height)
    return nil unless value

    value < 3 ? value * 100 : value
  end

  def parse_number(raw)
    match = raw.to_s[/\d+(?:[.,]\d+)?/]
    match&.tr(",", ".")&.to_f
  end
end
