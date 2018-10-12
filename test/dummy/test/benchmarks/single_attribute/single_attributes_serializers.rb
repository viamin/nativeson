module SingleAttributeSerializers
  module PankoSerializers
    class PankoSingleDateTimeAttribute < Panko::Serializer
      attributes :single_attr
    end
    class PankoSingleFloatAttribute < Panko::Serializer
      attributes :single_attr
    end
    class PankoSingleIntegerAttribute < Panko::Serializer
      attributes :single_attr
    end
    class PankoSingleStringAttribute < Panko::Serializer
      attributes :single_attr
    end
  end
  module AmsSerializers
    class AmsSingleDateTimeAttribute < ActiveModel::Serializer
      attributes :single_attr
    end
    class AmsSingleFloatAttribute < ActiveModel::Serializer
      attributes :single_attr
    end
    class AmsSingleIntegerAttribute < ActiveModel::Serializer
      attributes :single_attr
    end
    class AmsSingleStringAttribute < ActiveModel::Serializer
      attributes :single_attr
    end
  end
end

