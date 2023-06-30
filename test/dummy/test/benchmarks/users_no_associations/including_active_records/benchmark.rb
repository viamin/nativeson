# frozen_string_literal: true

require_relative File.realpath("#{__dir__}/../users_no_associations_serializers.rb")

module BenchMarks
  module UsersNoAssociations
    module IncludingActiveRecords
      def self.ams_including_ar(limit)
        ActiveModelSerializers::SerializableResource.new(
          User.all.limit(limit),
          each_serializer: UsersNoAssociationsSerializers::AMS::AmsUser
        ).to_json
      end

      def self.panko_including_ar(limit)
        Panko::ArraySerializer.new(
          User.all.limit(limit),
          each_serializer: UsersNoAssociationsSerializers::PankoSerializer::PankoUser
        ).to_json
      end

      def self.nativeson_including_ar(limit)
        Nativeson.fetch_json_by_query_hash({ klass: 'User', limit: limit })[:json]
      end

      def self.benchmark
        # BenchMarks::UsersNoAssociations::IncludingActiveRecords::benchmark
        user_count = User.count
        loggers = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger = nil
        ActiveModelSerializers.logger = Logger.new(nil)
        Range.new(1, user_count).step(user_count / 3).each do |limit|
          Benchmark.ips do |x|
            x.config(time: 5, warmup: 1)
            x.report("panko_including_ar     - #{limit} :") { panko_including_ar(limit) }
            x.report("ams_including_ar       - #{limit} :") { ams_including_ar(limit) }
            x.report("nativeson_including_ar - #{limit} :") { nativeson_including_ar(limit) }
            x.compare!
          end
        end
        ActiveRecord::Base.logger, ActiveModelSerializers.logger = loggers
        nil
      end
    end
  end
end
