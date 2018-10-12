module BenchMarks
  module ItemsNoAssociations
    module ExcludingActiveRecords
      def self.ams_excluding_ar(data)
        ActiveModelSerializers::SerializableResource.new(
            data,
            each_serializer: ItemsNoAssociationsSerializers::AMS::AmsItem).to_json
      end

      def self.panko_excluding_ar(data)
        Panko::ArraySerializer.new(
            data,
            each_serializer: ItemsNoAssociationsSerializers::PankoSerializer::PankoItem).to_json
      end

      def self.nativeson_including_ar(limit)
        Nativeson.fetch_json_by_query_hash({klass: 'Item', limit: limit})[:json]
      end

      def self.benchmark
        # BenchMarks::ItemsNoAssociations::ExcludingActiveRecords::benchmark
        item_count = Item.count
        loggers    = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger ,ActiveModelSerializers.logger = nil , Logger.new(nil)

        Range.new(1,item_count).step(item_count/3).each do |limit|
          Benchmark.ips do |x|
            x.config(time: 5, warmup: 1)
            data = Item.all.limit(limit).load
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




