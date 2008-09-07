module ActsAsCSVImportable
  module ActiveRecord
    module Importing
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        @@csv_import_templates = {}
        
        def add_csv_import_template(template, column_hashes)
            @@csv_import_templates[self.class.to_sym] ||= {}
            @@csv_import_templates[self.class.to_sym][template.to_sym] = column_hashes                                                                                       
        end
        
        def get_csv_import_columns(template = :default)
          if all_csv_import_templates.keys.include?(template.to_s)
            all_import_templates[template.to_s]
          elsif template == :default
            convert_all_elements_to_hash(content_columns.map(&:name) - ['created_at', 'update_at'])
          else
            raise UnknownImportTemplate.new("Could not find import template '#{template}'")
          end
        end
        
        def all_csv_import_templates
          @@csv_import_templates[self.class.to_sym]
        end
        
        
        def acts_as_csv_importable(template, column_hash_or_array)
          column_hashes = convert_all_elements_to_hash(column_hash_or_array)
          add_csv_import_template(template.to_sym, column_hashes)
        end
        
        def from_csv(file, template = nil)
          raise MissingGem.new("Need FasterCSV gem to use ActsAsCSVImportable") unless defined? FasterCSV
          
          methods = get_csv_import_columns(template).map { |c| c.values.first.to_s } unless template.blank?
          
          count = 0
          objects = []
          
          FasterCSV.parse(csv_file.read) do |row|
            if count > 0 #past header row
              objects << from_csv_row(methods, row)
            else
              #if template not passed, try to find from the header row 
              methods ||= find_methods_from_header_row(row)
            end
            count += 1
          end
          return objects          
        end
        
        def find_methods_from_header_row(row)
          all_csv_import_templates.each do |template, hash_array|
            method_names = column_definitions_to_header_row(hash_array)
            if method_names == row
              return method_names
            end
          end
          # if here, no import template exists for this csv
          raise MissingImportTemplateException.new("Could not find an import template for this file")
        end
        
        def csv_import_template(template = :default)
          columns = get_csv_import_columns(template)
          column_definitions_to_header_row(columns).to_csv
        end
        
        def column_definitions_to_header_row(columns)
          columns.map { |c| c.keys.first.to_s.gsub('_', ' ').titleize }
        end
      
        def from_csv_row(methods, data_array)
          data_array.each { |c| c.strip! unless c.blank? }
          
          pk_placement = 0
          if methods.include?(self.primary_key.to_s)
            methods.each_with_index do |method, i|
              if method.to_s == self.primary_key.to_s
                pk_placement == i
                break
              end
            end
          end
          #find obj in db or instantiate new
          new_obj = self.find(data_array[pk_placement]) if self.exists?(data_array[pk_placement])
          new_obj ||= new
          
          methods.each_with_index do |method, j|
            new_obj.send("#{method}=", data_array[j])
          end
          new_obj
        end
      end #end ClassMethods
    end #end Importing
  end #end ActiveRecord
end #end ActsAsCSVImportable
          