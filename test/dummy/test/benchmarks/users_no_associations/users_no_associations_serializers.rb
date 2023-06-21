module UsersNoAssociationsSerializers
  module PankoSerializer
    class PankoUser < Panko::Serializer
      User.attribute_names.each { |i| attributes i }
    end
  end

  module AMS
    class AmsUser < ActiveModel::Serializer
      User.attribute_names.each { |i| attributes i }
    end
  end
end
