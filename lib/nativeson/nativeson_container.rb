class NativesonContainer
  ################################################################
  attr_accessor :reflection , :container_type
  attr_accessor :all_columns, :all_reflections_by_name, :columns_string, :parent, :query, :sql
  ################################################################
  ALLOWED_ATTRIBUTES = [:where, :order, :limit, :columns, :associations, :klass]
  CONTAINER_TYPES    = [:base, :asscoation]
  ALLOWED_ATTRIBUTES.each { |i| attr_accessor i }
  ################################################################
  def initialize(container_type: , query: , parent: nil)
    @parent = parent
    @container_type = container_type
    @associations = {}
    @query = query
    query[:klass].is_a?(String) ? @klass = self.class.const_get(query[:klass]) : @klass = query[:klass]
    get_all_reflections
    get_all_columns
    select_columns
    get_parent_table
    get_foreign_key
    ALLOWED_ATTRIBUTES.each do |i|
      if i == :associations
        next unless query[i]
        query[i].each_pair { |k,v| create_association(k ,v) }
      elsif i == :klass
        next
      else
        instance_variable_set("@#{i}", query[i])
      end
    end
  end
  ################################################################
  def create_association(association_name, association_query)
    @associations[association_name] = NativesonContainer.new(container_type: :association, query: association_query, parent: self)
  end
  ################################################################
  def select_columns
    @columns_string = ''
    if @columns.blank?
      @columns_string << '*'
    else
      @columns.each_with_index do |column,idx|
        @columns_string << ' , ' if idx > 0
        @columns_string << column
      end
    end
  end
  ################################################################
  def get_foreign_key
    @foreign_key = nil
    return @foreign_key if @parent.nil?
    if @parent.all_reflections_by_name[@klass.table_name].nil?
      reflection   = all_reflections_by_name[@parent.klass.name.downcase]
      @foreign_key = "#{reflection.name}_id" if reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
    else
      @foreign_key = @parent.all_reflections_by_name[@klass.table_name].foreign_key
    end
  end
  ################################################################
  def get_parent_table
    if @parent.nil?
      @parent_table = @klass.table_name
    elsif @parent.container_type == :base
      @parent_table = "base_table.#{@klass.primary_key}"
    else
      @parent_table = "#{@parent.klass.table_name}.#{@parent.klass.primary_key}"
    end
  end
  ################################################################
  def generate_association_sql(name, prefix, tmp_sql)
    "
    ( SELECT JSON_AGG(tmp_#{@klass.table_name} )
        FROM (
          SELECT #{@columns_string}
          #{" , " + tmp_sql unless tmp_sql.blank?}
          FROM   #{@klass.table_name}
          WHERE  #{@foreign_key} = #{@parent_table}
          #{'AND '      + @where.to_s unless @where.blank?}
          #{'ORDER BY ' + @order.to_s unless @order.blank?}
          #{'LIMIT '    + @limit.to_s unless @limit.blank?}
         ) tmp_#{@klass.table_name}
     ) AS #{name}
    ".split("\n").map { |i| "#{prefix}#{i}" }.join("\n")
  end
  ################################################################
  def generate_base_sql
    "
    SELECT JSON_AGG(t)
       FROM (
        SELECT #{@columns_string}
        #{" , " + @sql unless @sql.blank?}
        FROM #{@klass.table_name}
        AS base_table
        #{'WHERE '      + @where.to_s unless @where.blank?}
        #{'ORDER BY ' + @order.to_s unless @order.blank?}
        #{'LIMIT '    + @limit.to_s unless @limit.blank?}
      ) t;
    "
  end
  ################################################################
  def generate_sql(name = nil, prefix = '')
    prefix << "  "
    @sql = ''
    @associations.each_pair do |k,v|
      tmp_sql = v.generate_sql(k, prefix)
      tmp_sql = v.generate_association_sql(k, prefix, tmp_sql)
      @sql.blank? ? @sql << tmp_sql : @sql << " , #{tmp_sql}"
    end
    @sql = generate_base_sql if @parent.nil?
    @sql
  end
  ################################################################
  def get_all_columns
    @all_columns = {}
    @klass.columns.each { |i| @all_columns[i.name] = i }
  end
  ################################################################
  def get_all_reflections
#    @klass.reflect_on_all_associations.each { |i| @all_reflections_by_name[i.name] = i }
    @all_reflections_by_name = @klass.reflections
  end
  ################################################################
end