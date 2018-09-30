class Item < ApplicationRecord
  belongs_to :user
  has_one :item_description, dependent: :destroy
end
