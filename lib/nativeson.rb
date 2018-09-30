require_relative 'nativeson/railtie'
require_relative 'nativeson/nativeson_container'
module Nativeson
  def self.fetch_json_by_query_hash(query_hash)
    @nativeson_hash = {}
    @nativeson_hash[:query_hash] = query_hash
    @nativeson_hash[:container] = NativesonContainer.new(container_type: :base, query: @nativeson_hash[:query_hash], parent: nil)
    @nativeson_hash[:sql] = @nativeson_hash[:container].generate_sql
    @nativeson_hash[:json] = ActiveRecord::Base.connection.select_value(@nativeson_hash[:sql])
    return @nativeson_hash
  end
end

