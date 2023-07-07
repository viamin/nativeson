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
       {"name":"Homer Simpson","items":[{"name":"Nuclear Tongs"}],"widgets":[{"name":"Widget"}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with nested association' do
    query_hash = query_defaults.merge(
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
    expected_json = <<~JSON
      [{"name":"Bart Simpson","items":[{"name":"Skateboard","item_prices":[{"previous_price":90,"current_price":100}]}]},#{' '}
       {"name":"Homer Simpson","items":[{"name":"Nuclear Tongs","item_prices":[{"previous_price":9,"current_price":10}]}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with belongs_to association' do
    query_hash = query_defaults.merge(
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
    expected_json = <<~JSON
      [{"name":"Bart Simpson","item_prices":[{"previous_price":90,"current_price":100,"item":{"name" : "Skateboard"}}]},#{' '}
       {"name":"Homer Simpson","item_prices":[{"previous_price":9,"current_price":10,"item":{"name" : "Nuclear Tongs"}}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]

    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with deep nested mixed associations' do
    query_hash = query_defaults.merge(
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
                    key: 'description',
                    columns: ['description']
                  }
                }
              }
            }
          }
        }
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","item_prices":[{"previous_price":90,"current_price":100,"item":{"name" : "Skateboard", "description" : {"description" : "Green with a red stripe"}}}]},#{' '}
       {"name":"Homer Simpson","item_prices":[{"previous_price":9,"current_price":10,"item":{"name" : "Nuclear Tongs", "description" : {"description" : "Two handled, to grip a carbon rod"}}}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    # binding.pry
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with has_one association' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name'],
        associations: {
          items: {
            klass: 'Item',
            columns: %w[name],
            associations: {
              item_description: {
                klass: 'ItemDescription',
                key: 'description',
                columns: ['description']
              }
            }
          }
        }
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","items":[{"name":"Skateboard","description":{"description" : "Green with a red stripe"}}]},#{' '}
       {"name":"Homer Simpson","items":[{"name":"Nuclear Tongs","description":{"description" : "Two handled, to grip a carbon rod"}}]}]
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
       {"full_name":"Homer Simpson","possessions":[{"item_name":"Nuclear Tongs"}],"widgets":[{"widget_name":"Widget"}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with offset' do
    query_hash = {
      klass: 'User',
      columns: [{ as: 'full_name', name: 'name' }],
      order: 'users.name ASC',
      limit: 1,
      offset: 1
    }
    expected_json = <<~JSON
      [{"full_name":"Homer Simpson"}]
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
       {"full_name":"Homer Simpson","possessions":[{"item_name":"Nuclear Tongs"}],"widgets":[{"widget_name":"Widget"}]}]}
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

  test 'fetch_json_by_query_hash with datetime column with an alias' do
    query_hash = {
      klass: 'User',
      columns: [:name, { name: 'created_at', as: 'created' }]
    }
    expected_json = <<~JSON
      [{"name":"Homer Simpson","created":"#{DateTime.parse('Monday 5:00pm').iso8601}"},#{' '}
       {"name":"Bart Simpson","created":"#{DateTime.parse('Tuesday 5:00pm').iso8601}"}]
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

  test 'fetch_json_by_query_hash with deeply nested joins' do
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
                where: 'cheap_prices.current_price < 15.0', as: 'cheap_prices', type: 'INNER JOIN' }],
      key: 'inexpensive_items'
    }
    expected_json = '{"inexpensive_items" : [{"name":"Nuclear Tongs","current_price":10}]}'
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with json columns' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', { json: "permissions->>'items'", as: 'item_permissions' }]
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","item_permissions":"permitted"},#{' '}
       {"name":"Homer Simpson","item_permissions":"permitted"}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test "fetch_json_by_query_hash when a json key doesn't exist" do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', { json: "permissions->>'profiles'", as: 'profile_permissions' }]
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","profile_permissions":null},#{' '}
       {"name":"Homer Simpson","profile_permissions":null}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with both associations and joins' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', { name: 'user_profile_pics.image_url', as: 'profile_pic_url' }],
        associations: {
          items: {
            klass: 'Item',
            columns: ['name'],
            associations: {
              item_prices: {
                klass: 'ItemPrice',
                key: 'prices',
                columns: [{ name: 'current_price', as: 'price' }]
              }
            }
          }
        },
        joins: [
          { klass: 'UserProfile', on: 'user_profiles.user_id', foreign_on: 'users.id' },
          { klass: 'UserProfilePic', on: 'user_profile_pics.user_profile_id', foreign_on: 'user_profiles.id' }
        ]
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","profile_pic_url":"bart.jpg","items":[{"name":"Skateboard","prices":[{"price":100}]}]},#{' '}
       {"name":"Homer Simpson","profile_pic_url":null,"items":[{"name":"Nuclear Tongs","prices":[{"price":10}]}]}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with an inner join' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', { name: 'user_profile_pics.image_url', as: 'profile_pic_url' }],
        joins: [
          { klass: 'UserProfile', on: 'user_profiles.user_id', foreign_on: 'users.id' },
          { klass: 'UserProfilePic', on: 'user_profile_pics.user_profile_id', foreign_on: 'user_profiles.id',
            type: 'INNER JOIN' }
        ]
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","profile_pic_url":"bart.jpg"}]
    JSON
    actual_json = Nativeson.fetch_json_by_query_hash(query_hash)[:json]
    assert_equal expected_json.strip, actual_json.strip
  end

  test 'fetch_json_by_query_hash with string formatting' do
    query_hash = query_defaults.merge(
      {
        klass: 'User',
        columns: ['name', { format: ['https://imgur.com/%s?size=%sx%s', 'user_profile_pics.image_url', 'user_profile_pics.image_width', 'user_profile_pics.image_height'], as: 'profile_pic_url' }],
        joins: [
          { klass: 'UserProfile', on: 'user_profiles.user_id', foreign_on: 'users.id' },
          { klass: 'UserProfilePic', on: 'user_profile_pics.user_profile_id', foreign_on: 'user_profiles.id',
            type: 'INNER JOIN' }
        ]
      }
    )
    expected_json = <<~JSON
      [{"name":"Bart Simpson","profile_pic_url":"https://imgur.com/bart.jpg?size=128x128"}]
    JSON
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

  #   ####  ###### #    # ###### #####    ##   ##### ######          ####   ####  #
  #  #    # #      ##   # #      #    #  #  #    #   #              #      #    # #
  #  #      #####  # #  # #####  #    # #    #   #   #####           ####  #    # #
  #  #  ### #      #  # # #      #####  ######   #   #                   # #  # # #
  #  #    # #      #   ## #      #   #  #    #   #   #              #    # #   #  #
  #   ####  ###### #    # ###### #    # #    #   #   ######          ####   ### # ######
  #                                                         #######

  test 'generate_sql' do
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
    expected_sql = <<~SQL
      SELECT JSON_AGG(t)
        FROM (
          SELECT users.name
          , ( SELECT JSON_AGG(tmp_items)
        FROM (
          SELECT items.name
            FROM items
          WHERE items.user_id = users.id
          ORDER BY items.id
        ) tmp_items
      ) AS items , ( SELECT JSON_AGG(tmp_widgets)
        FROM (
          SELECT widgets.name
            FROM widgets
          WHERE widgets.user_id = users.id
          ORDER BY widgets.id
        ) tmp_widgets
      ) AS widgets
          FROM users
          ORDER BY users.name ASC
          LIMIT 10
        ) t;
    SQL
    nativeson_hash = Nativeson.fetch_json_by_query_hash(query_hash, generate_sql: false, execute_query: false)

    assert_nil nativeson_hash[:sql]
    generated_sql = Nativeson.generate_sql(nativeson_hash)
    assert_equal expected_sql.strip, generated_sql[:sql].strip
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
       {"name":"Homer Simpson","items":[{"name":"Nuclear Tongs"}],"widgets":[{"name":"Widget"}]}]
    JSON
    nativeson_hash = Nativeson.fetch_json_by_query_hash(query_hash, execute_query: false)

    assert_nil nativeson_hash[:json]
    executed_sql = Nativeson.execute(nativeson_hash)
    assert_equal expected_json.strip, executed_sql[:json].strip
  end
end
