# frozen_string_literal: true

require 'test_helper'
require_relative '../support/test_helpers'

class AssociationsTest < ActiveSupport::TestCase
  test 'UsersItemAssociation' do
    ar_instance = User.find(User.pluck(:id).sample(1).first)
    nativeson_output = Nativeson.fetch_json_by_query_hash({
                                                            klass: 'User',
                                                            where: "id = #{ar_instance.id}",
                                                            associations: {
                                                              items: {
                                                                klass: 'Item'
                                                              }
                                                            }
                                                          })
    nativeson_array = Oj.load(nativeson_output[:json])
    assert_equal 1, nativeson_array.size
    nativeson_hash = nativeson_array.first
    assert(TestHelpers.compare_ar_instance_to_nativeson_hash(ar_instance, nativeson_hash.reject { |i| i == 'items' }),
           "Model 'User' failed during test '#{__method__}'")
    nativeson_items = TestHelpers.map_nativeson_by_prop(nativeson_hash['items'])
    ar_instance.items.each do |item|
      nativeson_item = nativeson_items[item.id]
      assert(TestHelpers.compare_ar_instance_to_nativeson_hash(item, nativeson_item),
             "Model 'Item' failed during test '#{__method__}'")
    end
  end
end
