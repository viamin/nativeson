require 'memory_profiler'
require 'benchmark/ips'
require_relative '../../users_no_associations_serializers'
ActiveRecord::Base.logger = nil
ActiveModelSerializers.logger = Logger.new(nil)

def ams_including_ar(limit)
  ActiveModelSerializers::SerializableResource.new(
      User.all.limit(limit),
      each_serializer: UsersNoAssociationsSerializers::AMS::AmsUser).to_json
end

def panko_including_ar(limit)
  Panko::ArraySerializer.new(
      User.all.limit(limit),
      each_serializer: UsersNoAssociationsSerializers::PankoSerializer::PankoUser).to_json
end

def nativeson_including_ar(limit)
  Nativeson.fetch_json_by_query_hash({klass: 'User', limit: limit})[:json]
end


USER_COUNT = User.count
puts """
The results here include the time ActiveRecord takes to fetch data and process it.
This is aimed to simulate real world use cases, where a request arrives to the backend.
A DB query is constructed, the DB result is transformed to a JSON.
This JSON is sent to the frontend.
"""
Range.new(1,USER_COUNT).step(USER_COUNT/3).each do |limit|
  Benchmark.ips do |x|
    x.config(time: 3, warmup: 1)
    x.report("panko_including_ar     - #{limit} :") { panko_including_ar(limit) }
    x.report("ams_including_ar       - #{limit} :") { ams_including_ar(limit) }
    x.report("nativeson_including_ar - #{limit} :") { nativeson_including_ar(limit) }
    x.compare!
  end
end ; nil




