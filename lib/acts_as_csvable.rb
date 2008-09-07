module ActsAsCSVable
  class ActsAsCSVableException < Exception; end
  class UnknownExportTemplateException < ActsAsCSVableException; end
  class UnknownImportTemplateException < ActsAsCSVableException; end
  class MissingGemException < ActsAsCSVableException; end
  class MissingImportTemplateException < ActsAsCSVableException; end
end #end ActsAsCSVable

begin
  require 'fastercsv'
rescue Exception
  require 'csv'
  rescue Exception
    raise ActsAsCSVable::MissingGemException.new("ActsAsCSVable requires either the FasterCSV or CSV gem")
  end
end
  
require 'acts_as_csv_exportable'
require 'acts_as_csv_importable'
  
  
class Array
  alias :to_csv, :fastercsv_to_csv
  def to_csv(options = {})
    
    if all? { |e| e.respond_to?(:to_row) } and not empty?
      columns = options.delete(:columns)
      template = options.delete(:template)
      
      if columns.blank?
        columns = first.class.get_export_template(template)
      end
      
      columns = first.class.convert_all_elements_to_hash(columns)
      column_names = columns.map { |c| c.keys.first.to_s }
      methods = columns.map { |c| c.values.first.to_s }
      
      header_row = column_names.map { |c| c.gsub('_', ' ').titleize}.to_csv
      content_rows = map { |e| e.to_row(:columns => columns) }.map(&:to_csv)
      ([header_row] + content_rows).join
    else 
      if defined? FasterCSV
        FasterCSV.generate_line(self)
      else
        buffer = ''
        CSV.generate_row(self, self.size, buffer)
        buffer
      end
    end
  end
end # end Array

ActiveRecord::Base.class_eval do
  include ActsAsCSVable::ActiveRecord::Exporting
  include ActsAsCSVable::ActiveRecord::Importing
end