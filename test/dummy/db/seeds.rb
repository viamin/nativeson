require 'faker'
I18n.reload!

def rand_str(size=26)
  (0...13).map { ('a'..'z').to_a[rand(size)] }.join
end

3.times.each do
  users = []
  users << User.new(
      name: rand_str,
      email: Faker::Internet.email,
      col_int: rand(1000),
      col_float: rand(1000) + rand,
      col_string: rand_str
  )
  User.import users

  user_profiles, items, widgets = [], [], []
  User.find_each do |user|
    user_profiles << UserProfile.new(name: user.name, user_id: user.id)
    5.times.each do
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
  UserProfile.import user_profiles

  item_descriptions = []
  Item.find_each do |item|
    item_descriptions << ItemDescription.new(
        description: item.name,
        item_id: item.id,
        col_int: rand(1000),
        col_float: rand(1000) + rand,
        col_string: rand_str
        )
  end
  ItemDescription.import item_descriptions

  sub_widgets = []
  Widget.find_each do |widget|
    3.times.each do
      sub_widgets << SubWidget.new(
          name: "#{widget.name}_#{rand() + rand(10)}",
          widget_id: widget.id,
          col_int: rand(1000),
          col_float: rand(1000) + rand,
          col_string: rand_str
      )
    end
  end
  SubWidget.import sub_widgets
end
