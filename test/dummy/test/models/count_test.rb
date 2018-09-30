require 'test_helper'

class CountTest < ActiveSupport::TestCase
  test "Count models" do
    models = []
    Dir.foreach("test/dummy/app/models").each do |model_file|
      next if model_file.match(/^\.+$|application_record|concerns/)
      model_name = model_file.gsub(/\.rb$/,'').camelize
      begin
        models << Object.const_get(model_name)
      rescue NameError => e
        puts "#{__method__} model_name = '#{model_name}' couldn't be fetched via const_get, exception: #{e}"
      end
    end
    models.each do |model|
      ar_model_count = model.count
      nativeson_json = Nativeson.fetch_json_by_query_hash({klass: model.to_s})
      nativeson_hash = Oj.load(nativeson_json[:json])
      assert_equal ar_model_count, nativeson_hash.size
    end
  end
end

