# frozen_string_literal: true

require 'test_helper'
require_relative '../support/test_helpers'

class ColumnsTest < ActiveSupport::TestCase
  ############################################################
  test 'SelectOnlyID' do
    TestHelpers.fetch_models.each do |model|
      id = model.last.id
      columns = ['id']
      ar_instance = model.select(columns).find(id)
      nativeson_json = Nativeson.fetch_json_by_query_hash({
                                                            klass: model.to_s,
                                                            where: "id = #{id}",
                                                            columns: columns
                                                          })
      nativeson_array = Oj.load(nativeson_json[:json])
      assert_equal 1, nativeson_array.size
      nativeson_hash = nativeson_array.first
      assert(TestHelpers.compare_ar_instance_to_nativeson_hash(ar_instance, nativeson_hash),
             "Model '#{model}' failed during test '#{__method__}'")
    end
  end
  ############################################################
  test 'SelectRandomAttributes' do
    TestHelpers.fetch_models.each do |model|
      id = model.last.id
      ar_instance = model.last
      columns = TestHelpers.random_attributes(ar_instance)
      ar_instance = model.select(columns).find(ar_instance.id)
      nativeson_json = Nativeson.fetch_json_by_query_hash({
                                                            klass: model.to_s,
                                                            where: "id = #{id}",
                                                            columns: columns
                                                          })
      nativeson_array = Oj.load(nativeson_json[:json])
      assert_equal 1, nativeson_array.size
      nativeson_hash = nativeson_array.first
      assert(TestHelpers.compare_ar_instance_to_nativeson_hash(ar_instance, nativeson_hash),
             "Model '#{model}' failed during test '#{__method__}'")
    end
  end
  ############################################################
end
