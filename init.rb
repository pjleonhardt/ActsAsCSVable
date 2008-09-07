require 'acts_as_csvable'
# add the csv MimeType
Mime::Type.register 'text/csv', :csv, %w('text/comma-separated-values')


