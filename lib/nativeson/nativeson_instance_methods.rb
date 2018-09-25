module NativesonInstanceMethods
  ################################################################
  def all_associations_by_name
    all_associations_by_name_hash = {}
    self.class.reflect_on_all_associations.each do |assoc|
      all_associations_by_name_hash[assoc.klass.table_name.freeze] = assoc
    end
    all_associations_by_name_hash
  end
  ################################################################
  def build_json_query(association_data_array)
    association_sql = String.new
    association_data_array.each_with_index do |assoc,idx|
      association_sql << ','.freeze if idx > 0
      association_sql << self.class.association_query_string(assoc)
    end
    "SELECT JSON_AGG(t)
        FROM (
          SELECT *, #{association_sql} FROM #{self.class.table_name} AS base_table
      ) t;"
  end
  ################################################################
  def build_json_query_complex(base_container, assoc_container)
    association_sql = String.new
    idx = 0
    assoc_container.each_value do |container|
      association_sql << ','.freeze if idx > 0
      association_sql << self.class.association_query_string_from_container(container)
      idx += 1
    end
    "SELECT JSON_AGG(t)
      FROM (
          SELECT #{self.class.select_columns(base_container)} ,
          #{association_sql}
          FROM #{self.class.table_name}
          AS base_table
          #{'WHERE '    + base_container.where.to_s.freeze unless base_container.where.blank?}
          #{'ORDER BY ' + base_container.order.to_s.freeze unless base_container.order.blank?}
          #{'LIMIT '    + base_container.limit.to_s.freeze unless base_container.limit.blank?}
      ) t;"
  end
  ################################################################
end
