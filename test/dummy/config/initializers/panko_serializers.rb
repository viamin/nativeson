class ItemSerializer < Panko::Serializer
  attributes :id, :upc, :price, :created_at, :updated_at, :user_id
end

class SearchResultSerializer < Panko::Serializer
  attributes :id, :result_score, :created_at, :updated_at, :user_id, :search_id
end


class AccountSerializer < Panko::Serializer
  attributes :id, :account_number, :created_at, :updated_at, :user_id
end

class SearchSerializer < Panko::Serializer
  attributes :id, :keywords, :created_at, :updated_at, :user_id
  has_many :search_results, serializer: SearchResultSerializer
end

class UserSerializer < Panko::Serializer
  attributes :id, :name, :email, :created_at, :updated_at
  has_many :items, serializer: ItemSerializer
  has_many :searches, serializer: SearchSerializer
  has_one  :account, serializer: AccountSerializer
  has_many :search_results, serializer: SearchResultSerializer
end
