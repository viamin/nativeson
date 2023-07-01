# frozen_string_literal: true

require 'test_helper'

class NativesonTest < ActiveSupport::TestCase
  #   ####  #    # ###### #####  #   #    #    #   ##    ####  #    #
  #  #    # #    # #      #    #  # #     #    #  #  #  #      #    #
  #  #    # #    # #####  #    #   #      ###### #    #  ####  ######
  #  #  # # #    # #      #####    #      #    # ######      # #    #
  #  #   #  #    # #      #   #    #      #    # #    # #    # #    #
  #   ### #  ####  ###### #    #   #      #    # #    #  ####  #    #

  def query_defaults
    { order: 'users.name ASC', limit: 10 }
  end

  test 'fetch_json_by_query_hash' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name'],
        associations: {
          items: {
            klass: 'Item',
            columns: ['name']
          },
          widgets: {
            klass: 'Widget',
            columns: ['name']
          }
        }
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","items":[{"name":"Skateboard"}],"widgets":null},#{' '}
       {"name":"Homer Simpson","items":[{"name":"Nuclear Tongs"}],"widgets":[{"name":"Green Glowy Thing"}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with column hash' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: [{ as: 'full_name', name: 'name' }],
        associations: {
          items: {
            klass: 'Item',
            key: 'possessions',
            columns: [{ name: 'name', as: 'item_name' }]
          },
          widgets: {
            klass: 'Widget',
            columns: [{ name: 'name', as: 'widget_name' }]
          }
        }
      }
    )
    expected_json = <<~JSON
      [{"full_name":"Bart Simpson","possessions":[{"item_name":"Skateboard"}],"widgets":null},#{' '}
       {"full_name":"Homer Simpson","possessions":[{"item_name":"Nuclear Tongs"}],"widgets":[{"widget_name":"Green Glowy Thing"}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with top-level key' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: [{ as: 'full_name', name: 'name' }],
        key: 'users',
        associations: {
          items: {
            klass: 'Item',
            key: 'possessions',
            columns: [{ as: 'item_name', name: 'name' }]
          },
          widgets: {
            klass: 'Widget',
            columns: [{ name: 'name', as: 'widget_name' }]
          }
        }
      }
    )
    expected_json = <<~JSON
      {"users" : [{"full_name":"Bart Simpson","possessions":[{"item_name":"Skateboard"}],"widgets":null},#{' '}
       {"full_name":"Homer Simpson","possessions":[{"item_name":"Nuclear Tongs"}],"widgets":[{"widget_name":"Green Glowy Thing"}]}]}
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with datetime column' do
    query_hash = {
      klass: 'User',
      columns: %i[name created_at]
    }
    expected_json = <<~JSON
      [{"name":"Homer Simpson","created_at":"#{DateTime.parse('Monday 5:00pm').iso8601}"},#{' '}
       {"name":"Bart Simpson","created_at":"#{DateTime.parse('Tuesday 5:00pm').iso8601}"}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with columns from joined table' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', 'email', { name: 'user_profiles.name', as: 'profile_name' }],
        joins: [{ klass: 'UserProfile', on: 'users.id',
                  foreign_on: 'user_profiles.user_id' }],
        key: 'users'
      }
    )
    expected_json = <<~JSON
      {"users" : [{"name":"Bart Simpson","email":"bart@geocities.com","profile_name":"Bart's Profile"},#{' '}
       {"name":"Homer Simpson","email":"homer.simpson@springfield.gov","profile_name":"Homer's Profile"}]}
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with columns from coalesced columns' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', 'email',
                  { coalesce: ['col_string', 'user_profiles.name'], as: 'string' }],
        joins: [{ klass: 'UserProfile', on: 'users.id',
                  foreign_on: 'user_profiles.user_id' }],
        key: 'users'
      }
    )
    expected_json = <<~JSON
      {"users" : [{"name":"Bart Simpson","email":"bart@geocities.com","string":"Bart's String"},#{' '}
       {"name":"Homer Simpson","email":"homer.simpson@springfield.gov","string":"Homer's Profile"}]}
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with deeply nested associations' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', 'email', { name: 'items.name', as: 'item' },
                  { name: 'item_descriptions.description', as: 'description' }],
        joins: [
          { klass: 'Item', on: 'users.id', foreign_on: 'items.user_id' },
          { klass: 'ItemDescription', on: 'items.id',
            foreign_on: 'item_descriptions.item_id' }
        ],
        key: 'users'
      }
    )
    expected_json = <<~JSON
      {"users" : [{"name":"Bart Simpson","email":"bart@geocities.com","item":"Skateboard","description":"Green with a red stripe"},#{' '}
       {"name":"Homer Simpson","email":"homer.simpson@springfield.gov","item":"Nuclear Tongs","description":"Two handled, to grip a carbon rod"}]}
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with conditional and aliased joins' do
    query_hash = {
      klass: 'Item',
      columns: ['name', 'cheap_prices.current_price'],
      joins: [{ klass: 'ItemPrice', foreign_on: 'cheap_prices.item_id', on: 'items.id',
                where: 'cheap_prices.current_price < 15.0', as: 'cheap_prices' }],
      key: 'inexpensive_items'
    }
    expected_json = '{"inexpensive_items" : [{"name":"Nuclear Tongs","current_price":10}]}'
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  #  #####    ##   # #       ####      ####  #    # ###### #####  #   #
  #  #    #  #  #  # #      #         #    # #    # #      #    #  # #
  #  #    # #    # # #       ####     #    # #    # #####  #    #   #
  #  #####  ###### # #           #    #  # # #    # #      #####    #
  #  #   #  #    # # #      #    #    #   #  #    # #      #   #    #
  #  #    # #    # # ######  ####      ### #  ####  ###### #    #   #

  test 'fetch_json_by_rails_query' do
    rails_query = User.select(:name, :email)
    expected_json = <<~JSON
      [{"name":"Homer Simpson","email":"homer.simpson@springfield.gov"},#{' '}
       {"name":"Bart Simpson","email":"bart@geocities.com"}]
    JSON
    actual_json = Nativeson.fetch_json_by_rails_query(rails_query)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  #   ####  ##### #####  # #    #  ####
  #  #        #   #    # # ##   # #    #
  #   ####    #   #    # # # #  # #
  #       #   #   #####  # #  # # #  ###
  #  #    #   #   #   #  # #   ## #    #
  #   ####    #   #    # # #    #  ####

  test 'fetch_json_by_string' do
    sql_string = 'select name, email from users order by name'
    expected_json = <<~JSON
      [{"name":"Bart Simpson","email":"bart@geocities.com"},#{' '}
       {"name":"Homer Simpson","email":"homer.simpson@springfield.gov"}]
    JSON
    actual_json = Nativeson.fetch_json_by_string(sql_string)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  
  #  ###### #    # ######  ####  #    # ##### ######
  #  #       #  #  #      #    # #    #   #   #
  #  #####    ##   #####  #      #    #   #   #####
  #  #        ##   #      #      #    #   #   #
  #  #       #  #  #      #    # #    #   #   #
  #  ###### #    # ######  ####   ####    #   ######

  test 'execute' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name'],
        associations: {
          items: {
            klass: 'Item',
            columns: ['name']
          },
          widgets: {
            klass: 'Widget',
            columns: ['name']
          }
        }
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","items":[{"name":"Skateboard"}],"widgets":null},#{' '}
       {"name":"Homer Simpson","items":[{"name":"Nuclear Tongs"}],"widgets":[{"name":"Green Glowy Thing"}]}]
    JSON
    nativeson_hash = Nativeson.fetch_json_by_query_hash(query_hash, false)

    assert_nil nativeson_hash[:json]
    executed_sql = Nativeson.execute(nativeson_hash)
    assert_equal expected_json.strip, executed_sql[:json].strip
  end
end
