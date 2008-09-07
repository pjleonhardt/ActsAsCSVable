module ActsAsCSVExportable
  module ActiveRecord
      
    # == CSV Exporting
    # Allows for the easy exportation of ActiveRecord Models.
    # ==== Usage Examples
    # 
    module Exporting
      
      def self.included(base)#:nodoc:
        base.extend(ClassMethods)
        base.class_eval { include InstanceMethods }
      end
        
      module ClassMethods
        @@csv_export_templates = {}

        # Call this method in the model of which you would like to override default export functionallity. The 
        # default template returns all content columns (+content_columns+)
        # 
        # Arrays are used to maintain order.
        # 
        #     #proposal.rb
        #     class Proposal < ActiveRecord::Base
        #       acts_as_csv_exportable :default, [:id, :name, :description, { :client => "client.name"}]
        #       acts_as_csv_exportable :detailed, [:id, :name. :description, { :client => "client.name}, :projected_cost, :projected_profit, :formatted_proposed_completion_date]
        #      #...
        #  You can define an unlimited number of csv export templates
        # ==== Specifying Columns
        # You can specify your column in multiple ways:
        # * As a symbol: The symbol will be used as both a column header and a method to call
        # * As a string: Same as symbol, but this allows you to do method chaining ("client.name")
        # * As a hash: Allows you to specify both a column header and a method ( {:a_name => :a_method})
        #
        def acts_as_csv_exportable(template, column_array)
          column_hashes = convert_all_elements_to_hash(column_array)
          add_csv_export_template(template.to_sym, column_hashes)
        end
        
        def to_csv(*args)
          find(:all).to_csv(*args)   
        end
          
        def get_export_template(template = :default)
          template ||= :default
          if all_csv_export_templates.keys.include?(template.to_sym)
            all_csv_export_templates[template.to_sym]  
          elsif template == :default
            convert_all_elements_to_hash(content_columns.map(&:name))
          else
            raise UnknownExportTemplate.new("Unknown Export Template: #{template}")  
          end  
        end
        
        # converts all elements of the template array to key => val pairs for name/method for the use
        # of the +to_row+ method. Converts arrays of hashes, arrays of strings/symbols and mixed arrays
        #
        def convert_all_elements_to_hash(column_array)
          column_array.map do |element|
            if element.is_a? Hash
              element
            elsif element.is_a? String or element.is_a? Symbol
              {element => element}  
            end
          end
        end
        
        private

        # Adds an export template to the model that you can use when calling +to_csv+
        #
        def add_csv_export_template(template, column_hashes)
          @@csv_export_templates[self.to_s] ||= {}
          @@csv_export_templates[self.to_s][template] = column_hashes
        end
        
        def all_csv_export_templates
          @@csv_export_templates[self.to_s] || {}
        end
        
        # Get the hash pairs for a specific template. If nil is passed, returns default template.
        # Default template +can+ be overwriten in your model!
        #

      end # end ClassMethods
    
      module InstanceMethods
        # This returns a CSV row of an item's data. Used by Array.to_csv
        # if columns are specified, they take priority over a template
        def to_row(options = {})
          template = options.delete(:template) || :default
          columns = options.delete(:columns)
          
          # columns take precedence over a template
          columns_to_export = columns.blank? ? self.class.get_export_template(template) : self.class.convert_all_elements_to_hash(columns)
          
          columns_to_export.map! do |hash_pair|
            method = hash_pair.values.first
            get_column_value(method)              
          end
          columns_to_export
        end
        
        private
        # Used by to_row to determine values to used to fill an item's row. Simply sends the method
        # to the item, breaking apart chained methods and sending those individually.
        #
        def get_column_value(method)
          parts = method.to_s.split
          
          response = self
          parts.each do |part|
            response = response.send(part) if response.respond_to?(part)
          end
          response = nil if response == self
          
          return response
        end
      end # end InstanceMethods
    end # end Exporting
  end # end ActiveRecord
end #end ActsAsCSVExportable