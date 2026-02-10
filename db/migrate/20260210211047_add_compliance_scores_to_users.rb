class AddComplianceScoresToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :workout_compliance_score, :integer
    add_column :users, :diet_adherence_score, :integer
  end
end
