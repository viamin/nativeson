require 'memory_profiler'
require 'benchmark/ips'
require_relative '../../users_no_associations_serializers'
ActiveRecord::Base.logger = nil
ActiveModelSerializers.logger = Logger.new(nil)

def ams_excluding_ar(data)
  ActiveModelSerializers::SerializableResource.new(
      data,
      each_serializer: UsersNoAssociationsSerializers::AMS::AmsUser).to_json
end

def panko_excluding_ar(data)
  Panko::ArraySerializer.new(
      data,
      each_serializer: UsersNoAssociationsSerializers::PankoSerializer::PankoUser).to_json
end

def nativeson_including_ar(limit)
  Nativeson.fetch_json_by_query_hash({klass: 'User', limit: limit})[:json]
end

USER_COUNT = User.count
puts """
The results here exclude the time ActiveRecord takes to fetch data and process it.
In this case, nativeson is expected to be slower due to DB access required from it.
An important note, while Panko and AMS show roughly a linear dependency on the
size of the data, nativeson scales better and the gap closes the data size increases
"""
Range.new(1,USER_COUNT).step(USER_COUNT/3).each do |limit|
  Benchmark.ips do |x|
    x.config(time: 3, warmup: 1)
    data = User.all.limit(limit).load
    x.report("panko_excluding_ar     - #{limit} :") { panko_excluding_ar(data) }
    x.report("ams_excluding_ar       - #{limit} :") { ams_excluding_ar(data) }
    x.report("nativeson_including_ar - #{limit} :") { nativeson_including_ar(limit) }
    x.compare!
  end
end ; nil




