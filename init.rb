require 'acts_as_csvable.rb'
require 'acts_as_csv_exportable'
require 'acts_as_csv_importable'

ActsAsCSVable.allow_dynamic_import_template_generation = false

begin
  require 'csv'
  rescue Exception
    raise ActsAsCSVable::MissingGemException.new("ActsAsCSVable requires the Ruby 1.9 CSV gem")
end
  
require 'array'

ActiveRecord::Base.class_eval do
  include ActsAsCSVExportable::ActiveRecord::Exporting
  include ActsAsCSVImportable::ActiveRecord::Importing
end
