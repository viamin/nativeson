# frozen_string_literal: true

module ItemsNoAssociationsSerializers
  module PankoSerializer
    class PankoItem < Panko::Serializer
      Item.attribute_names.each { |i| attributes i }
    end
  end

  module AMS
    class AmsItem < ActiveModel::Serializer
      Item.attribute_names.each { |i| attributes i }
    end
  end
end
