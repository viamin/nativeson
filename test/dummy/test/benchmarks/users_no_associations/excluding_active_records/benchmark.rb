require_relative File.realpath("#{__dir__}/../users_no_associations_serializers.rb")

module BenchMarks
  module UsersNoAssociations
    module ExcludingActiveRecords
      def self.ams_excluding_ar(data)
        ActiveModelSerializers::SerializableResource.new(
            data,
            each_serializer: UsersNoAssociationsSerializers::AMS::AmsUser).to_json
      end

      def self.panko_excluding_ar(data)
        Panko::ArraySerializer.new(
            data,
            each_serializer: UsersNoAssociationsSerializers::PankoSerializer::PankoUser).to_json
      end

      def self.nativeson_including_ar(limit)
        Nativeson.fetch_json_by_query_hash({klass: 'User', limit: limit})[:json]
      end

      def self.benchmark
        # BenchMarks::UsersNoAssociations::ExcludingActiveRecords::benchmark
        user_count = User.count
        loggers    = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger ,ActiveModelSerializers.logger = nil , Logger.new(nil)
        Range.new(1,user_count).step(user_count/3).each do |limit|
          Benchmark.ips do |x|
            x.config(time: 5, warmup: 1)
            data = User.all.limit(limit).load
            x.report("panko_excluding_ar     - #{limit} :") { panko_excluding_ar(data) }
            x.report("ams_excluding_ar       - #{limit} :") { ams_excluding_ar(data) }
            x.report("nativeson_including_ar - #{limit} :") { nativeson_including_ar(limit) }
            x.compare!
          end
        end ; nil
        ActiveRecord::Base.logger , ActiveModelSerializers.logger = loggers ; nil
      end
    end
  end
end





