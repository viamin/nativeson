require 'faker'
I18n.reload!

3.times.each do
  users = []
  users << User.new(
      name:  (0...13).map { ('a'..'z').to_a[rand(26)] }.join,
      email: Faker::Internet.email
  )
  User.import users

  user_profiles, items, widgets = [], [], []
  User.find_each do |user|
    user_profiles << UserProfile.new(name: user.name, user_id: user.id)
    5.times.each do
      items << Item.new(name: user.name, user_id: user.id)
      widgets << Widget.new(name: user.name, user_id: user.id)
    end
  end
  Item.import items
  Widget.import widgets
  UserProfile.import user_profiles

  item_descriptions = []
  Item.find_each do |item|
    item_descriptions << ItemDescription.new(description: item.name, item_id: item.id)
  end
  ItemDescription.import item_descriptions

  sub_widgets = []
  Widget.find_each do |widget|
    3.times.each do
      sub_widgets << SubWidget.new(name: "#{widget.name}_#{rand() + rand(10)}", widget_id: widget.id)
    end
  end
  SubWidget.import sub_widgets
end
