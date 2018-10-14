require 'test_helper'
require_relative '../support/test_helpers'

class LimitTest < ActiveSupport::TestCase
  ############################################################
  test 'CountLimitAllModels' do
    TestHelpers.fetch_models.each do |model|
      limit            = rand(model.count) + 1
      ar_model_count   = model.limit(limit).count
      nativeson_output = Nativeson.fetch_json_by_query_hash({klass: model.to_s, limit: limit})
      nativeson_array  = Oj.load(nativeson_output[:json])
      assert_equal ar_model_count, nativeson_array.size
    end
  end
  ############################################################
end

