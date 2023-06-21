require_relative File.realpath("#{__dir__}/../items_no_associations_serializers.rb")
module BenchMarks
  module ItemsNoAssociations
    module IncludingActiveRecords
      def self.ams_including_ar(limit)
        ActiveModelSerializers::SerializableResource.new(
          Item.all.limit(limit),
          each_serializer: ItemsNoAssociationsSerializers::AMS::AmsItem
        ).to_json
      end

      def self.panko_including_ar(limit)
        Panko::ArraySerializer.new(
          Item.all.limit(limit),
          each_serializer: ItemsNoAssociationsSerializers::PankoSerializer::PankoItem
        ).to_json
      end

      def self.nativeson_including_ar(limit)
        Nativeson.fetch_json_by_query_hash({klass: "Item", limit: limit})[:json]
      end

      def self.benchmark
        # BenchMarks::ItemsNoAssociations::IncludingActiveRecords::benchmark
        item_count = Item.count
        loggers = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger, ActiveModelSerializers.logger = nil, Logger.new(nil)
        Range.new(1, item_count).step(item_count / 3).each do |limit|
          Benchmark.ips do |x|
            x.config(time: 10, warmup: 1)
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
