# frozen_string_literal: true

require 'test_helper'

class NativesonContainerTest < ActiveSupport::TestCase
  def query_defaults
    { order: 'users.name ASC', limit: 10 }
  end

  def teardown
    # ensure that the query used actually generates valid SQL
    assert_nothing_raised { Nativeson.fetch_json_by_query_hash(@query) }
  end

  test 'generate_sql' do
    @query = query_defaults.merge(klass: 'User', columns: %w[id name])
    @container = NativesonContainer.new(container_type: :base, query: @query)
    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.id ,
            users.name
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with where clause' do
    @query = query_defaults.merge(
      klass: 'User',
      columns: %w[id name],
      where: "users.name = 'Homer Simpson'"
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)
    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.id ,
            users.name
          FROM users
          WHERE users.name = 'Homer Simpson'
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with offset' do
    @query = query_defaults.merge(klass: 'User', columns: %w[id name], offset: 10)
    @container = NativesonContainer.new(container_type: :base, query: @query)
    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.id ,
            users.name
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
          OFFSET 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with associations' do
    @query = query_defaults.merge(
      klass: 'User',
      columns: %w[id name],
      associations: {
        items: {
          klass: 'Item',
          columns: %w[id name]
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.id ,
            users.name
            , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT
            items.id ,
            items.name
          FROM items
          WHERE items.user_id = users.id
          ORDER BY items.id
        ) tmp_items
      ) AS items
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with nested associations' do
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name'],
        associations: {
          items: {
            klass: 'Item',
            columns: ['name'],
            associations: {
              item_prices: {
                klass: 'ItemPrice',
                columns: %w[previous_price current_price]
              }
            }
          }
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name
            , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT
            items.name
            ,   ( SELECT JSON_AGG(tmp_item_prices)
          FROM (
            SELECT
              item_prices.previous_price ,
              item_prices.current_price
            FROM item_prices
            WHERE item_prices.item_id = items.id
            ORDER BY item_prices.id
          ) tmp_item_prices
        ) AS item_prices
          FROM items
          WHERE items.user_id = users.id
          ORDER BY items.id
        ) tmp_items
      ) AS items
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with inverted belongs_to association' do
    # In this query, item_prices is a has_many,:through association
    # and item is the through association. This is a weird case
    # here to support alternative output structures
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name'],
        associations: {
          item_prices: {
            klass: 'ItemPrice',
            columns: %w[previous_price current_price],
            associations: {
              item: {
                klass: 'Item',
                columns: ['name']
              }
            }
          }
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name
            , ( SELECT JSON_AGG(tmp_item_prices)
        FROM (
          SELECT
            item_prices.previous_price ,
            item_prices.current_price
            ,   ( SELECT JSON_BUILD_OBJECT('name' , name)
          FROM (
            SELECT
              items.name
            FROM items
            WHERE item_prices.item_id = items.id
            ORDER BY items.id
          ) tmp_items
        ) AS item
          FROM item_prices
          INNER JOIN items
            ON items.user_id = users.id
          WHERE item_prices.item_id = items.id
          ORDER BY item_prices.id
        ) tmp_item_prices
      ) AS item_prices
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with deeply nested mixed associations' do
    # In this query, item_prices is a has_many,:through association
    # and item is the through association. This is a weird case
    # here to support alternative output structures
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name'],
        associations: {
          item_prices: {
            klass: 'ItemPrice',
            columns: %w[previous_price current_price],
            associations: {
              item: {
                klass: 'Item',
                columns: ['name'],
                associations: {
                  item_description: {
                    klass: 'ItemDescription',
                    columns: ['description']
                  }
                }
              }
            }
          }
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name
            , ( SELECT JSON_AGG(tmp_item_prices)
        FROM (
          SELECT
            item_prices.previous_price ,
            item_prices.current_price
            ,   ( SELECT JSON_BUILD_OBJECT('name' , name , 'item_description' , item_description)
          FROM (
            SELECT
              items.name
              ,     ( SELECT JSON_BUILD_OBJECT('description' , description)
            FROM (
              SELECT
                item_descriptions.description
              FROM item_descriptions
              WHERE item_descriptions.item_id = items.id
              ORDER BY item_descriptions.id
            ) tmp_item_descriptions
          ) AS item_description
            FROM items
            WHERE item_prices.item_id = items.id
            ORDER BY items.id
          ) tmp_items
        ) AS item
          FROM item_prices
          INNER JOIN items
            ON items.user_id = users.id
          WHERE item_prices.item_id = items.id
          ORDER BY item_prices.id
        ) tmp_item_prices
      ) AS item_prices
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with column aliases' do
    @query = query_defaults.merge(
      klass: 'User',
      columns: [{ as: 'full_name', name: 'name' }],
      associations: {
        items: {
          klass: 'Item',
          key: 'possessions',
          columns: [{ as: 'item_name', name: 'name' }]
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name AS full_name
            , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT
            items.name AS item_name
          FROM items
          WHERE items.user_id = users.id
          ORDER BY items.id
        ) tmp_items
      ) AS possessions
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with mixed column aliases and string names' do
    @query = query_defaults.merge(
      klass: 'User',
      columns: ['name', :email, { name: :id, as: 'user_id' }],
      associations: {
        items: {
          klass: 'Item',
          key: 'possessions',
          columns: [{ name: 'name', as: 'item_name' }]
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name ,
            users.email ,
            users.id AS user_id
            , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT
            items.name AS item_name
          FROM items
          WHERE items.user_id = users.id
          ORDER BY items.id
        ) tmp_items
      ) AS possessions
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with a top-level key' do
    @query = query_defaults.merge(
      klass: 'User',
      columns: [{ as: 'full_name', name: 'name' }],
      key: 'users',
      associations: {
        items: {
          klass: 'Item',
          key: 'possessions',
          columns: [{ as: 'item_name', name: 'name' }]
        }
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_BUILD_OBJECT('users', JSON_AGG(t))
        FROM (
          SELECT
            users.name AS full_name
            , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT
            items.name AS item_name
          FROM items
          WHERE items.user_id = users.id
          ORDER BY items.id
        ) tmp_items
      ) AS possessions
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL
    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with joins and coalesced data' do
    @query = query_defaults.merge(
      klass: 'User',
      columns: ['id', { coalesce: ['name', 'user_profiles.name'], as: 'name' }],
      joins: [
        { klass: 'UserProfile', foreign_on: 'user_profiles.user_id', on: 'users.id' }
      ]
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.id ,
            COALESCE( users.name , user_profiles.name ) AS name
          FROM users
          LEFT OUTER JOIN user_profiles
            ON users.id = user_profiles.user_id
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with joins with an alias and conditional clause' do
    @query = {
      klass: 'Item',
      columns: ['id', 'name', 'cheap_prices.current_price'],
      joins: [{
        klass: 'ItemPrice',
        foreign_on: 'cheap_prices.item_id',
        on: 'items.id',
        where: 'cheap_prices.current_price < 15.0',
        as: 'cheap_prices'
      }]
    }
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            items.id ,
            items.name ,
            cheap_prices.current_price
          FROM items
          LEFT OUTER JOIN item_prices
            AS cheap_prices
            ON items.id = cheap_prices.item_id
            AND cheap_prices.current_price < 15.0
          ORDER BY items.id
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with json column' do
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', { json: "permissions->>'items'", as: 'item_permissions' }]
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name ,
            users.permissions->>'items' AS item_permissions
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with json column on a joined table' do
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: [
          'name',
          { name: 'items.name', as: 'item_name' },
          { json: "items.product_codes->>'united_states'", as: 'us_product_code' }
        ],
        joins: [{ klass: 'Item', foreign_on: 'items.user_id', on: 'users.id' }]
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name ,
            items.name AS item_name ,
            items.product_codes->>'united_states' AS us_product_code
          FROM users
          LEFT OUTER JOIN items
            ON users.id = items.user_id
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with left joined table' do
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: [
          'name',
          { name: 'user_profile_pics.image_url', as: 'profile_pic_url' }
        ],
        joins: [
          { klass: 'UserProfile', on: 'user_profiles.user_id', foreign_on: 'users.id' },
          { klass: 'UserProfilePic', on: 'user_profile_pics.user_profile_id', foreign_on: 'user_profiles.id',
            type: 'LEFT JOIN' }
        ]
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name ,
            user_profile_pics.image_url AS profile_pic_url
          FROM users
          LEFT OUTER JOIN user_profiles
            ON user_profiles.user_id = users.id
          LEFT JOIN user_profile_pics
            ON user_profile_pics.user_profile_id = user_profiles.id
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with formatted string' do
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', { format: ['https://imgur.com/%s', 'user_profile_pics.image_url'], as: 'profile_pic_url' }],
        joins: [
          { klass: 'UserProfile', on: 'user_profiles.user_id', foreign_on: 'users.id' },
          { klass: 'UserProfilePic', on: 'user_profile_pics.user_profile_id', foreign_on: 'user_profiles.id',
            type: 'INNER JOIN' }
        ]
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name ,
            FORMAT( 'https://imgur.com/%s' , user_profile_pics.image_url ) AS profile_pic_url
          FROM users
          LEFT OUTER JOIN user_profiles
            ON user_profiles.user_id = users.id
          INNER JOIN user_profile_pics
            ON user_profile_pics.user_profile_id = user_profiles.id
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with struct' do
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name',
                  { struct: { name: 'items.name', description: 'item_descriptions.description', price: 'item_prices.current_price' },
                    as: 'item' }],
        joins: [
          { klass: 'Item', on: 'items.user_id', foreign_on: 'users.id' },
          { klass: 'ItemPrice', on: 'item_prices.item_id', foreign_on: 'items.id' },
          { klass: 'ItemDescription', on: 'item_descriptions.item_id', foreign_on: 'items.id' }
        ]
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name ,
            JSON_BUILD_OBJECT( 'name' , items.name , 'description' , item_descriptions.description , 'price' , item_prices.current_price ) AS item
          FROM users
          LEFT OUTER JOIN items
            ON items.user_id = users.id
          LEFT OUTER JOIN item_prices
            ON item_prices.item_id = items.id
          LEFT OUTER JOIN item_descriptions
            ON item_descriptions.item_id = items.id
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end

  test 'generate_sql with struct and if condition' do
    @query = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name',
                  { struct: { name: 'items.name', description: 'item_descriptions.description', price: 'item_prices.current_price' },
                    as: 'item', if: 'item_prices.current_price > 20' }],
        joins: [
          { klass: 'Item', on: 'items.user_id', foreign_on: 'users.id' },
          { klass: 'ItemPrice', on: 'item_prices.item_id', foreign_on: 'items.id' },
          { klass: 'ItemDescription', on: 'item_descriptions.item_id', foreign_on: 'items.id' }
        ]
      }
    )
    @container = NativesonContainer.new(container_type: :base, query: @query)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT
            users.name ,
            CASE
              WHEN item_prices.current_price > 20
              THEN JSON_BUILD_OBJECT( 'name' , items.name , 'description' , item_descriptions.description , 'price' , item_prices.current_price )
            END AS item
          FROM users
          LEFT OUTER JOIN items
            ON items.user_id = users.id
          LEFT OUTER JOIN item_prices
            ON item_prices.item_id = items.id
          LEFT OUTER JOIN item_descriptions
            ON item_descriptions.item_id = items.id
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL
    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end
end
