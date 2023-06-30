# frozen_string_literal: true

require 'test_helper'

class NativesonContainerTest < ActiveSupport::TestCase
  def query_defaults
    { order: 'name ASC', limit: 10 }
  end

  test 'generate_base_sql' do
    @query = query_defaults.merge(klass: 'User', columns: %w[id name])
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)
    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT users.id , users.name
          FROM users
          ORDER BY name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_base_sql.strip.squeeze("\n")
  end

  test 'generate_association_sql' do
    @association_query = query_defaults.merge({ klass: 'Item', columns: %w[id name] })
    @container = NativesonContainer.new(container_type: :association, query: @association_query, parent: nil,
                                        name: 'items')
    expected_sql = <<~SQL
      ( SELECT JSON_AGG(tmp_items)
          FROM (
            SELECT items.id , items.name
              FROM items
              WHERE  = items
              ORDER BY name ASC
              LIMIT 10
          ) tmp_items
        ) AS items
    SQL

    association_sql = @container.generate_association_sql('items', '  ', '')
    assert_equal expected_sql.strip, association_sql.strip.squeeze("\n")
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
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT users.id , users.name
           , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT items.id , items.name
            FROM items
            WHERE user_id = users.id
        ) tmp_items
      ) AS items
          FROM users
          ORDER BY name ASC
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
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT users.name AS full_name
           , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT items.name AS item_name
            FROM items
            WHERE user_id = users.id
        ) tmp_items
      ) AS possessions
          FROM users
          ORDER BY name ASC
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
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT users.name , users.email , users.id AS user_id
           , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT items.name AS item_name
            FROM items
            WHERE user_id = users.id
        ) tmp_items
      ) AS possessions
          FROM users
          ORDER BY name ASC
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
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)

    expected_sql = <<~SQL
      SELECT JSON_BUILD_OBJECT('users', JSON_AGG(t))
        FROM (
          SELECT users.name AS full_name
           , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT items.name AS item_name
            FROM items
            WHERE user_id = users.id
        ) tmp_items
      ) AS possessions
          FROM users
          ORDER BY name ASC
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
    @container = NativesonContainer.new(container_type: :base, query: @query, parent: nil)

    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT users.id , COALESCE( users.name , user_profiles.name ) AS name
          FROM users
          JOIN user_profiles ON users.id = user_profiles.user_id
          ORDER BY name ASC
          LIMIT 10
        ) t;
    SQL

    assert_equal expected_sql.strip, @container.generate_sql.strip.squeeze("\n")
  end
end
