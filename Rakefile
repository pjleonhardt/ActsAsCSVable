require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
    test_files = []
    test_files << "acts_as_csv_exportable_test.rb"
    test_files << "acts_as_csv_importablt_test.rb"
  t.test_files = test_files
  t.verbose = true
end
