require "test_helper"
require_relative "../support/test_helpers"

class WhereTest < ActiveSupport::TestCase
  ############################################################
  test "SimpleWhereIDCondition" do
    # In this test we'll fetch each model type and compare it to the JSON variation
    # We'll use #{attr_name}_before_type_cast to minimize effects of casting mismatches
    TestHelpers.fetch_models.each do |model|
      id = model.last.id
      ar_instance = model.where(id: id).take
      nativeson_json = Nativeson.fetch_json_by_query_hash({klass: model.to_s, where: "id = #{id}"})
      nativeson_array = Oj.load(nativeson_json[:json])
      nativeson_hash = nativeson_array.first
      assert_equal 1, nativeson_array.size
      assert(TestHelpers.compare_ar_instance_to_nativeson_hash(ar_instance, nativeson_hash),
        "Model '#{model}' failed during test '#{__method__}'")
    end
  end
  ############################################################
  test "WhereGt" do
    TestHelpers.fetch_models.each do |model|
      id = model.last.id - 10
      ar_instances = model.where("id > ?", id)
      nativeson_json = Nativeson.fetch_json_by_query_hash({klass: model.to_s, where: "id > #{id}"})
      nativeson_array = Oj.load(nativeson_json[:json])
      nativeson_full_hash = TestHelpers.map_nativeson_by_prop(nativeson_array)
      assert_equal ar_instances.size, nativeson_array.size
      ar_instances.each do |ar_instance|
        assert(nativeson_full_hash.key?(ar_instance.id),
          "Model '#{model}' id = #{ar_instance.id} didn't find matching element in nativeson_full_hash")
        nativeson_hash = nativeson_full_hash[ar_instance.id]
        assert(TestHelpers.compare_ar_instance_to_nativeson_hash(ar_instance, nativeson_hash),
          "Model '#{model}' failed during test '#{__method__}'")
      end
    end
  end
  ############################################################
end
