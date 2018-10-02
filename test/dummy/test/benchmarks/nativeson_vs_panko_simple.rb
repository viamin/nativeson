require 'memory_profiler'
require 'benchmark/ips'
ActiveRecord::Base.logger = nil

ID = User.first.id
SERIALIZER = UserItemFullSerializer

def panko_all(serializer)
  Panko::ArraySerializer.new(User.includes(:items).all, each_serializer: serializer).to_json
end
def panko_one(serializer)
  Panko::ArraySerializer.new(User.where(id: ID), each_serializer: serializer).to_json
end

def nativeson(query)
  Nativeson.fetch_json_by_query_hash(query)[:json]
end


Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)
  x.report("panko - one     :") { panko_one(SERIALIZER) }
  x.report("nativeson - one :") { nativeson({klass: 'User', where: "id = #{ID}"}) }
  x.compare!
end ; nil

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)
  x.report("panko - all     :") { panko_all(SERIALIZER) }
  x.report("nativeson - all :") { nativeson({klass: 'User'}) }
  x.compare!
end ; nil




