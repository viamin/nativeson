require "test_helper"
require_relative "../support/test_helpers"

class OrderTest < ActiveSupport::TestCase
  ############################################################
  test "CheckOrder" do
    TestHelpers.fetch_models.each do |model|
      ar_instance = model.take
      column = TestHelpers.random_attributes(ar_instance, mandatory_attributes: %w[], size_limit: 1).first
      %w[desc asc].each do |direction|
        ar_instances = model.order("#{column} #{direction}")
        nativeson_output = Nativeson.fetch_json_by_query_hash({klass: model.to_s, order: "#{column} #{direction}"})
        nativeson_array = Oj.load(nativeson_output[:json])
        assert_equal ar_instances.size, nativeson_array.size
        ar_instances.each_with_index do |ar_instance, idx|
          nativeson_hash = nativeson_array[idx]
          assert(TestHelpers.compare_ar_instance_to_nativeson_hash(ar_instance, nativeson_hash),
            "Model '#{model}' failed during test '#{__method__}'")
        end
      end
    end
  end
  ############################################################
end
