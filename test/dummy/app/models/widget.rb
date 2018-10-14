class Widget < ApplicationRecord
  belongs_to :user
  has_many :sub_widgets, dependent: :destroy
end
