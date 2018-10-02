require 'memory_profiler'
require 'benchmark/ips'

ID = User.first.id
DATA = {
    user_only_all:        {data: User.all, serializer: UserOnlySerializer},
    user_item_only_all:   {data: User.includes(:items).all, serlializer: UserItemOnlySerializer},
    user_item_full_all:   {data: User.includes(:items).all, serializer: UserItemFullSerializer},
    user_only_first:      {data: User.find(ID), serializer: UserOnlySerializer} ,
    user_item_only_first: {data: User.includes(:items).where(id: ID).take, serlializer: UserItemOnlySerializer},
    user_item_full_first: {data: User.includes(:items).where(id: ID).take, serializer: UserItemFullSerializer}
}


def panko_from_cache(type)
  Panko::ArraySerializer.new(DATA[type][:data], each_serializer: DATA[type][:serializer]).to_json
end

NATIVESON_QUERY_HASH = {
    klass: 'User',
    columns: ['id'],
    associations: {
        items: {
            klass: 'Item',
        },
        searches: {
            klass: 'Search',
            associations: {
                search_results: {
                    klass: 'SearchResult'
                }
            }
        },
        account: {
            klass: 'Account'
        },
        search_results: {
            klass: 'SearchResult'
        }
    }
}

res = Nativeson.fetch_json_by_query_hash(NATIVESON_QUERY_HASH)

def nativeson
  res = Nativeson.fetch_json_by_query_hash(NATIVESON_QUERY_HASH)
  res[:json]
end

panko_hash     = Oj.load(panko) ; nil
nativeson_hash = Oj.load(nativeson) ; nil

File.open('n.json','w') do |fh|
  nativeson_hash = Oj.load(nativeson) ; nil
  fh.write(Oj.dump(nativeson_hash, indent: 2))
end
File.open('p.json','w') do |fh|
  panko_hash     = Oj.load(panko) ; nil
  fh.write(Oj.dump(panko_hash, indent: 2))
end

ActiveRecord::Base.logger = nil
Benchmark.ips do |x|
  x.config(time: 10, warmup: 3)
  x.report("panko     :") { panko }
  x.report("nativeson :") { nativeson }
  x.compare!
end







