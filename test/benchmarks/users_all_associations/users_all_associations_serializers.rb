# frozen_string_literal: true

module UsersAllAssociationsSerializers
  module PankoSerializer
    class PankoSubWidget < Panko::Serializer
      SubWidget.attribute_names.each { |i| attributes i }
    end

    class PankoWidget < Panko::Serializer
      Widget.attribute_names.each { |i| attributes i }
      has_many :sub_widgets, serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoSubWidget
    end

    class PankoUserProfilePic < Panko::Serializer
      UserProfilePic.attribute_names.each { |i| attributes i }
    end

    class PankoUserProfile < Panko::Serializer
      UserProfile.attribute_names.each { |i| attributes i }
      has_one :user_profile_pic, serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoUserProfilePic
    end

    class PankoItemPrice < Panko::Serializer
      ItemPrice.attribute_names.each { |i| attributes i }
    end

    class PankoItemDescription < Panko::Serializer
      ItemDescription.attribute_names.each { |i| attributes i }
    end

    class PankoItem < Panko::Serializer
      Item.attribute_names.each { |i| attributes i }
      has_one :item_description, serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoItemDescription
      has_many :item_prices, serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoItemPrice
    end

    class PankoUser < Panko::Serializer
      User.attribute_names.each { |i| attributes i }
      has_many :items, serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoItem
      has_many :widgets, serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoWidget
      has_one :user_profile, serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoUserProfile
    end
  end

  module AMS
    class AmsSubWidget < ActiveModel::Serializer
      SubWidget.attribute_names.each { |i| attributes i }
    end

    class AmsWidget < ActiveModel::Serializer
      Widget.attribute_names.each { |i| attributes i }
      has_many :sub_widgets, serializer: UsersAllAssociationsSerializers::AMS::AmsSubWidget
    end

    class AmsUserProfilePic < ActiveModel::Serializer
      UserProfilePic.attribute_names.each { |i| attributes i }
    end

    class AmsUserProfile < ActiveModel::Serializer
      UserProfile.attribute_names.each { |i| attributes i }
      has_one :user_profile_pic, serializer: UsersAllAssociationsSerializers::AMS::AmsUserProfilePic
    end

    class AmsItemPrice < ActiveModel::Serializer
      ItemPrice.attribute_names.each { |i| attributes i }
    end

    class AmsItemDescription < ActiveModel::Serializer
      ItemDescription.attribute_names.each { |i| attributes i }
    end

    class AmsItem < ActiveModel::Serializer
      Item.attribute_names.each { |i| attributes i }
      has_one :item_description, serializer: UsersAllAssociationsSerializers::AMS::AmsItemDescription
      has_many :item_prices, serializer: UsersAllAssociationsSerializers::AMS::AmsItemPrice
    end

    class AmsUser < ActiveModel::Serializer
      User.attribute_names.each { |i| attributes i }
      has_many :items, serializer: UsersAllAssociationsSerializers::AMS::AmsItem
      has_many :widgets, serializer: UsersAllAssociationsSerializers::AMS::AmsWidget
      has_one :user_profile, serializer: UsersAllAssociationsSerializers::AMS::AmsUserProfile
    end
  end
end
