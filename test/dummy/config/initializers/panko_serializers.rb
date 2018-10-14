class ItemDescriptionSerializer < Panko::Serializer
  ItemDescription.attribute_names.each { |i| attributes i }
end

class ItemPriceSerializer < Panko::Serializer
  ItemPrice.attribute_names.each { |i| attributes i }
end

class ItemOnlySerializer < Panko::Serializer
  Item.attribute_names.each { |i| attributes i }
end

class ItemFullSerializer < Panko::Serializer
  Item.attribute_names.each { |i| attributes i }
  has_one :item_description, serializer: ItemDescriptionSerializer
  has_many :item_prices, serializer: ItemPriceSerializer
end

class UserItemFullSerializer < Panko::Serializer
  User.attribute_names.each { |i| attributes i }
  has_many :items, serializer: ItemFullSerializer
end

class UserItemOnlySerializer < Panko::Serializer
  User.attribute_names.each { |i| attributes i }
  has_many :items, serializer: ItemOnlySerializer
end

class UserOnlySerializer < Panko::Serializer
  User.attribute_names.each { |i| attributes i }
end