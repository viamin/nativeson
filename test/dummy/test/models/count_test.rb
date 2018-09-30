require 'test_helper'

def fetch_models
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
  models
end

class CountTest < ActiveSupport::TestCase
  test "Count models" do
    fetch_models.each do |model|
      ar_model_count = model.count
      nativeson_json = Nativeson.fetch_json_by_query_hash({klass: model.to_s})
      nativeson_array = Oj.load(nativeson_json[:json])
      assert_equal ar_model_count, nativeson_array.size
    end
  end

  test "Simple where = id condition" do
    # In this test we'll fetch each model type and compare it to the JSON variation
    # We'll use #{attr_name}_before_type_cast to minimize effects of casting mismatches
    fetch_models.each do |model|
      id = model.last.id
      ar_instance     = model.where(id: id).take
      nativeson_json  = Nativeson.fetch_json_by_query_hash({klass: model.to_s, where: "id = #{id}"})
      nativeson_array = Oj.load(nativeson_json[:json])
      nativeson_hash  = nativeson_array.first
      assert_equal 1, nativeson_array.size
      ar_instance.attributes.each_key do |name|
        next if ['updated_at', 'created_at'].include?(name) ; # Skiping due to minor casting on each side
        assert_equal ar_instance.send("#{name}_before_type_cast").to_s, nativeson_hash[name].to_s
      end
    end
  end
end

