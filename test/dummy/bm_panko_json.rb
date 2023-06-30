# frozen_string_literal: true

require_relative './benchmarking_support'
require_relative './app'
# require_relative './setup'

class AuthorFastSerializer < Panko::Serializer
  attributes :id, :name
end

class PostFastSerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id, :created_at
end

class PostFastWithMethodCallSerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id, :method_call
  def method_call
    object.id * 2
  end
end

class PostWithHasOneFastSerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id
  has_one :author, serializer: AuthorFastSerializer
end

class AuthorWithHasManyFastSerializer < Panko::Serializer
  attributes :id, :name
  has_many :posts, serializer: PostFastSerializer
end

NATIVESON_QUERY_HASH = { klass: 'Post', limit: 50 }.freeze

def nativeson
  res = Nativeson.fetch_json_by_query_hash(NATIVESON_QUERY_HASH)
  res[:json]
end

def panko(posts = nil)
  posts = Benchmark.data[:small] if posts.nil?
  Panko::ArraySerializer.new(posts, { each_serializer: PostFastSerializer }).to_json
end

class PostSerializer < ActiveModel::Serializer
  attributes :id, :body, :title, :author_id, :created_at, :updated_at
end

def ams(posts = nil)
  posts = Benchmark.data[:small] if posts.nil?
  return ActiveModelSerializers::SerializableResource.new(
    posts,
    adapter: :json_api
  ).as_json; nil
end

Benchmark.data[:small]

ActiveRecord::Base.logger = nil
Benchmark.ips do |x|
  x.config(time: 10, warmup: 3)
  x.report('panko     :') { panko }
  x.report('nativeson :') { nativeson }
  x.compare!
end

nativeson_hash = Oj.load(nativeson)

panko_hash = Oj.load(panko)

[nativeson_hash, panko_hash].each do |array|
  array.each do |hash|
    %w[created_at updated_at].each { |attr| hash.delete(attr) }
  end
end

panko_hash == nativeson_hash
