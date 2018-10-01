require_relative 'nativeson/railtie'
require_relative 'nativeson/nativeson_container'
module Nativeson
  ################################################################
  def self.fetch_json_by_query_hash(query_hash)
    nativeson_hash = {}
    nativeson_hash[:query_hash] = query_hash
    nativeson_hash[:container] = NativesonContainer.new(container_type: :base, query: nativeson_hash[:query_hash], parent: nil)
    nativeson_hash[:sql] = nativeson_hash[:container].generate_sql
    nativeson_hash[:json] = ActiveRecord::Base.connection.select_value(nativeson_hash[:sql])
    return nativeson_hash
  end
  ################################################################
  def self.fetch_json_by_rails_query(rails_query)
    if rails_query.respond_to?(:to_sql)
      nativeson_hash = {}
      nativeson_hash[:sql] = "
      SELECT JSON_AGG(t)
        FROM (
          #{rails_query.to_sql}
        )
      t;"
      result = ActiveRecord::Base.connection.execute(nativeson_hash[:sql])
      nativeson_hash[:json] = result.getvalue(0, 0)
      result.clear
      return nativeson_hash
    else
      raise ArgumentError.new("#{__method__} input doesn't respond to :to_sql")
    end
  end
  ################################################################
  def self.fetch_json_by_string(string)
    if string.is_a?(String)
      nativeson_hash = {}
      nativeson_hash[:sql] = "
      SELECT JSON_AGG(t)
        FROM (
          #{string}
        )
      t;"
      result = ActiveRecord::Base.connection.execute(nativeson_hash[:sql])
      nativeson_hash[:json] = result.getvalue(0, 0)
      result.clear
      return nativeson_hash
    else
      raise ArgumentError.new("#{__method__} input isn't a String")
    end
  end
  ################################################################
end

