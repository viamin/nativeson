require 'test_helper'

class NativesonTest < ActiveSupport::TestCase
  test "fetch_json_by_query_hash" do
    query_hash = {
      klass: "User",
      columns: ["id", "name"],
      associations: {
        items: {
          klass: "Item",
          columns: ["id", "name"]
        }
      }
    }
    expected_json = <<~JSON
      {
        "id": 1,
        "name": "User 1",
      }
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json, actual_json
  end

  test "fetch_json_by_rails_query" do 

  end

  test "fetch_json_by_string" do 

  end
end
