# frozen_string_literal: true

# Copyright 2018 Ohad Dahan, Al Chou
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

require_relative 'nativeson/railtie'
require_relative 'nativeson/nativeson_container'
module Nativeson
  ################################################################
  def self.fetch_json_by_query_hash(query_hash, execute_query = true)
    nativeson_hash = {}
    nativeson_hash[:query_hash] = query_hash
    nativeson_hash[:container] =
      NativesonContainer.new(container_type: :base, query: nativeson_hash[:query_hash], parent: nil)
    sql = nativeson_hash[:container].generate_sql
    nativeson_hash[:sql] = sql
    nativeson_hash = execute(nativeson_hash) if execute_query
    nativeson_hash
  end

  ################################################################
  def self.fetch_json_by_rails_query(rails_query, execute_query = true)
    raise ArgumentError, "#{__method__} input doesn't respond to :to_sql" unless rails_query.respond_to?(:to_sql)

    nativeson_hash = {}
    nativeson_hash[:sql] = "
      SELECT JSON_AGG(t)
        FROM (
          #{rails_query.to_sql}
        )
      t;"
    nativeson_hash = execute(nativeson_hash) if execute_query
    nativeson_hash
  end

  ################################################################
  def self.fetch_json_by_string(string, execute_query = true)
    raise ArgumentError, "#{__method__} input isn't a String" unless string.is_a?(String)

    nativeson_hash = {}
    nativeson_hash[:sql] = "
      SELECT JSON_AGG(t)
        FROM (
          #{string}
        )
      t;"
    nativeson_hash = execute(nativeson_hash) if execute_query
    nativeson_hash
  end

  ################################################################
  def self.execute(nativeson_hash)
    result = ActiveRecord::Base.connection.execute(nativeson_hash[:sql])
    nativeson_hash[:json] = result.getvalue(0, 0)
    result.clear
    nativeson_hash
  end
end
