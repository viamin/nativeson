# frozen_string_literal: true

require 'faker'
I18n.reload!

def rand_str(size = 26)
  (0...13).map { ('a'..'z').to_a[rand(size)] }.join
end

single_datetime_attribute = []
single_float_attribute = []
single_integer_attribute = []
single_string_attribute = []
5000.times do
  single_datetime_attribute << SingleDateTimeAttribute.new(single_attr: DateTime.now)
  single_float_attribute << SingleFloatAttribute.new(single_attr: rand + rand(100))
  single_integer_attribute << SingleIntegerAttribute.new(single_attr: rand(100))
  single_string_attribute << SingleStringAttribute.new(single_attr: rand_str)
end
SingleDateTimeAttribute.import single_datetime_attribute
SingleFloatAttribute.import single_float_attribute
SingleIntegerAttribute.import single_integer_attribute
SingleStringAttribute.import single_string_attribute

users = []
3.times do
  users << User.new(
    name: rand_str,
    email: Faker::Internet.email,
    col_int: rand(1000),
    col_float: rand(1000) + rand,
    col_string: rand_str
  )
end
User.import users

user_profiles = []
items = []
widgets = []
User.find_each do |user|
  user_profiles << UserProfile.new(name: user.name, user_id: user.id)
  50.times.each do
    items << Item.new(
      name: user.name,
      user_id: user.id,
      col_int: rand(1000),
      col_float: rand(1000) + rand,
      col_string: rand_str
    )
    widgets << Widget.new(
      name: user.name,
      user_id: user.id,
      col_int: rand(1000),
      col_float: rand(1000) + rand,
      col_string: rand_str
    )
  end
end
Item.import items
Widget.import widgets
UserProfile.import user_profiles, on_duplicate_key_update: {
  conflict_target: [:user_id],
  columns: UserProfile.attribute_names.reject { |i| %w[created_at updated_at].include?(i) }
}

user_profile_pics = []
UserProfile.find_each do |user_profile|
  user_profile_pics << UserProfilePic.new(
    user_profile_id: user_profile.id,
    image_height: rand(900),
    image_width: rand(1600),
    image_url: rand_str
  )
end
UserProfilePic.import user_profile_pics, on_duplicate_key_update: {
  conflict_target: [:user_profile_id],
  columns: UserProfilePic.attribute_names.reject { |i| %w[created_at updated_at].include?(i) }
}

item_descriptions = []
item_prices = []
Item.find_each do |item|
  item_descriptions << ItemDescription.new(
    description: item.name,
    item_id: item.id,
    col_int: rand(1000),
    col_float: rand(1000) + rand,
    col_string: rand_str
  )
  item_prices << ItemPrice.new(
    item_id: item.id,
    current_price: rand(100) + rand,
    previous_price: rand(100) + rand
  )
end
ItemDescription.import item_descriptions, on_duplicate_key_update: {
  conflict_target: [:item_id],
  columns: ItemDescription.attribute_names.reject { |i| %w[created_at updated_at].include?(i) }
}
ItemPrice.import item_prices

sub_widgets = []
Widget.find_each do |widget|
  3.times.each do
    sub_widgets << SubWidget.new(
      name: "#{widget.name}_#{rand + rand(10)}",
      widget_id: widget.id,
      col_int: rand(1000),
      col_float: rand(1000) + rand,
      col_string: rand_str
    )
  end
end
SubWidget.import sub_widgets
