require "test_helper"

class NativesonContainerTest < ActiveSupport::TestCase
  def query_defaults
    {order: "name ASC", limit: 10}
  end

  test "generate_base_sql" do
    @query = query_defaults.merge(klass: "User", columns: ["id", "name"])
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)
    expected_sql = <<~SQL
    SELECT JSON_AGG(t)
      FROM (
        SELECT id , name
        FROM users
        AS base_table
        ORDER BY name ASC
        LIMIT 10
      ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_base_sql.strip.squeeze("\n")
  end

  test "generate_association_sql" do 
    @association_query = query_defaults.merge({klass: 'Item', columns: ['id', 'name']})
    @container = NativesonContainer.new(container_type: :association, query: @association_query, parent: nil, name: 'items')
    expected_sql = <<~SQL
    ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT id , name
            FROM items
            WHERE  = items
            ORDER BY name ASC
            LIMIT 10
        ) tmp_items
      ) AS items
    SQL

    association_sql = @container.generate_association_sql("items", "  ", "")
    assert_equal expected_sql.strip, association_sql.strip.squeeze("\n")
  end

  test "generate_sql with associations" do
    @query = query_defaults.merge(
      klass: "User",
      columns: ["id", "name"],
      associations: {
        items: {
          klass: "Item",
          columns: ["id", "name"]
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)

    expected_sql = <<~SQL
        SELECT JSON_AGG(t)
          FROM (
            SELECT id , name
             ,     ( SELECT JSON_AGG(tmp_items)
              FROM (
                SELECT id , name
                  FROM items
                  WHERE user_id = base_table.id
              ) tmp_items
            ) AS items
            FROM users
            AS base_table
            ORDER BY name ASC
            LIMIT 10
          ) t;
        SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end
end
