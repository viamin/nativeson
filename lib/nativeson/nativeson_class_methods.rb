module NativesonClassMethods
  ################################################################
  def select_columns(container)
    columns = ''
    if container.columns.blank?
      columns << '*'
    else
      container.columns.each_with_index do |column,idx|
        columns << ',' if idx > 0
        columns << "#{container.table_name}.#{column}"
      end
    end
    columns
  end
  ################################################################
  def association_name(assoc)
    assoc.name.to_s.freeze
  end
  ################################################################
  def association_table_name(assoc)
    assoc.klass.table_name.freeze
  end
  ################################################################
  def association_type(assoc)
    case assoc.class.to_s
    when 'ActiveRecord::Reflection::HasManyReflection'
      :has_many
    when 'ActiveRecord::Reflection::HasOneReflection'
      :has_one
    else
      raise ArgumentError.new("#{__method__} : #{assoc.class} of #{assoc.klass.table_name.freeze} is unsupported")
    end
  end
  ################################################################
  def association_data(assoc)
    {
        table_name: association_table_name(assoc),
        name: association_name(assoc),
        type: association_type(assoc),
        foreign_key: assoc.foreign_key
    }
  end
  ################################################################
  def get_association_data(associations_by_name_hash, all_associations_by_name_hash, reflection: false)
    associations_data = []
    (associations_by_name_hash.empty? ? all_associations_by_name_hash : associations_by_name_hash).each_value do |assoc|
      if reflection && assoc.is_a?(NativesonContainer)
        assoc.add_association_data(association_data(assoc.reflection))
      else
        associations_data << association_data(assoc)
      end
    end
    reflection ? associations_by_name_hash : associations_data
  end
  ################################################################
  def verify_input_associations(associations_by_name_hash, all_associations_by_name_hash, reflection: false)
    associations_by_name_hash.each_key do |name|
      val = all_associations_by_name_hash[name]
      raise ArgumentError.new("#{__method__} : #{name}") if val.nil?
      if reflection && associations_by_name_hash[name].is_a?(NativesonContainer)
        associations_by_name_hash[name].reflection = val
      elsif associations_by_name_hash[name].is_a?(Hash)
        associations_by_name_hash[name] = val
      else
        raise ArgumentError.new("#{__method__} : #{name} , class is unsupported #{associations_by_name_hash[name].class}")
      end
    end
  end
  ################################################################
  def association_query_string(association_data_hash)
    "( SELECT JSON_AGG(tmp_#{association_data_hash[:table_name]} )
        FROM (
             SELECT * FROM #{association_data_hash[:table_name]} WHERE #{association_data_hash[:table_name]}.#{association_data_hash[:foreign_key]} = base_table.id
         ) tmp_#{association_data_hash[:table_name]}
    ) AS #{association_data_hash[:name]}"
  end
  ################################################################
  def association_query_string_from_container(container)
    "( SELECT JSON_AGG(tmp_#{container.table_name} )
        FROM (
             SELECT #{select_columns(container)} FROM #{container.table_name}
             WHERE #{container.table_name}.#{container.foreign_key} = base_table.id
             #{'AND ' + container.where unless container.where.blank?}
             #{'ORDER BY ' + container.order unless container.order.blank?}
             #{'LIMIT ' + container.limit unless container.limit.blank?}
         ) tmp_#{container.table_name}
    ) AS #{container.name}"
  end
  ################################################################
  def to_json_agg_qeury(input, raw=false)
    return "select json_agg(t) from (#{input}) t;" if raw
    [ActiveRecord::Relation, ActiveRecord::AssociationRelation].each do |type|
      return "select json_agg(t) from (#{input.to_sql}) t;" if input.class.ancestors.include?(type)
    end
    raise ArgumentError.new("#{__method__} : input class '#{input.class.to_s}' is the wrong type")
  end
  ################################################################
  def send_query_to_db(sql, fetch_name: 'json_agg')
    ActiveRecord::Base.connection.exec_query(sql)[0].fetch(fetch_name)
  end
  ################################################################
  def fetch_json_agg(input, raw = false)
    ActiveRecord::Base.connection.exec_query(to_json_agg_qeury(input, raw))[0].fetch('json_agg')
  end
  ################################################################
  def convert_to_hash(*associations_by_name_array)
    associations_by_name_array.map {|i| [i, nil]}.to_h
  end
  ################################################################
  def generate_containers(query_hash)
    base_container  = NativesonContainer.new(:base, query_hash)
    assoc_container = {}
    query_hash.fetch(:associations,{}).each_pair do |assoc_name, assoc_query_hash|
      assoc_container[assoc_name.to_s.freeze] = NativesonContainer.new(assoc_name, assoc_query_hash)
    end
    return base_container, assoc_container
  end
  ################################################################
end
