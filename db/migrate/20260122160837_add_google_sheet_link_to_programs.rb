class AddGoogleSheetLinkToPrograms < ActiveRecord::Migration[8.0]
  def change
    add_column :programs, :google_sheet_link, :string
  end
end
