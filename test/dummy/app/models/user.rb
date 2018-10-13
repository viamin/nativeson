class User < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :widgets, dependent: :destroy
  has_one :user_profile, dependent: :destroy
end
