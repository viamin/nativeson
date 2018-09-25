class NativesonContainer
  def self.allowed_attributes
    [:where, :order, :limit, :columns, :associations]
  end
  attr_accessor :input_name, :reflection
  allowed_attributes.each { |i| attr_accessor i }
  def initialize(input_name, opts)
    @input_name = input_name.to_s.freeze
    self.class.allowed_attributes.each do |i|
      instance_variable_set("@#{i}", opts[i])
    end
  end

  def add_association_data(association_data)
    association_data.each_pair do |k,v|
      instance_variable_set("@#{k}", v)
      self.class.attr_accessor k
    end
  end
end