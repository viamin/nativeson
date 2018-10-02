class Item < ApplicationRecord
  belongs_to :user
  has_one :item_description, dependent: :destroy
  has_many :item_prices, dependent: :destroy
end
