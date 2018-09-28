require_relative 'nativeson/railtie'
require_relative 'nativeson/nativeson_class_methods'
require_relative 'nativeson/nativeson_instance_methods'
require_relative 'nativeson/nativeson_container'
# Usage : include Nativeson in whatever model you want
module Nativeson
  def self.included(base)
    base.send(:include, NativesonInstanceMethods)
    base.extend(NativesonClassMethods)
  end
  ################################################################
  def fetch_json_by_association_names(*associations_by_name_array)
    all_associations_by_name_hash = all_associations_by_name
    associations_by_name_hash = self.class.convert_to_hash(*associations_by_name_array)
    self.class.verify_input_associations(associations_by_name_hash, all_associations_by_name_hash) unless associations_by_name_hash.empty?
    association_data_array = self.class.get_association_data(associations_by_name_hash, all_associations_by_name_hash)
    sql = build_json_query(association_data_array)
    self.class.send_query_to_db(sql)
  end
  ################################################################
  # Input Hash example:
  # {
  #   where: 'string condition',
  #   order: 'string condition',
  #   limit: 'number',
  #   columns: ['col1', 'col2', ...]
  #   associations: {
  #     'association_name': {
  #       where: 'string condition',
  #       order: 'string condition',
  #       limit: 'number',
  #       columns: ['col1', 'col2', ...]
  #     },
  #     ......
  #     ......
  #   }
  # }

  def fetch_json_by_query_hash(query_hash)
    all_associations_by_name_hash = all_associations_by_name
    base_container, assoc_container = NativesonContainer.generate_containers(query_hash)
    self.class.verify_input_associations(assoc_container, all_associations_by_name_hash, reflection: true)
    self.class.get_association_data(assoc_container, all_associations_by_name_hash, reflection: true)
    sql = build_json_query_complex(base_container, assoc_container)
  end
end

