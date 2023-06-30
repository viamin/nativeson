# frozen_string_literal: true

require 'test_helper'
require_relative '../support/test_helpers'

class CountTest < ActiveSupport::TestCase
  ############################################################
  test 'CountAllModels' do
    TestHelpers.fetch_models.each do |model|
      ar_model_count = model.count
      nativeson_output = Nativeson.fetch_json_by_query_hash({ klass: model.to_s })
      nativeson_array = Oj.load(nativeson_output[:json])
      assert_equal ar_model_count, nativeson_array.size
    end
  end
  ############################################################
end
