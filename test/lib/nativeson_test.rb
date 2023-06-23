require 'test_helper'

class NativesonTest < ActiveSupport::TestCase
  test "fetch_json_by_query_hash" do
    query_hash = {
      klass: "User",
      columns: ["name"],
      associations: {
        items: {
          klass: "Item",
          columns: ["name"]
        },
        widgets: {
          klass: "Widget",
          columns: ["name"]
        }
      }
    }
    expected_json = <<~JSON
    [{"name":"Homer Simpson","items":null,"widgets":[{"name":"Green Glowy Thing"}]}, 
     {"name":"Bart Simpson","items":[{"name":"Huffy"}],"widgets":null}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  test "fetch_json_by_rails_query" do 
    rails_query = User.select(:name, :email)
    expected_json = <<~JSON
    [{"name":"Homer Simpson","email":"homer.simpson@springfield.gov"}, 
     {"name":"Bart Simpson","email":"bart@geocities.com"}]
    JSON
    actual_json = Nativeson.fetch_json_by_rails_query(rails_query)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  test "fetch_json_by_string" do 
    sql_string = "select name, email from users order by name"
    expected_json = <<~JSON
    [{"name":"Bart Simpson","email":"bart@geocities.com"}, 
     {"name":"Homer Simpson","email":"homer.simpson@springfield.gov"}]
    JSON
    actual_json = Nativeson.fetch_json_by_string(sql_string)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end
end
