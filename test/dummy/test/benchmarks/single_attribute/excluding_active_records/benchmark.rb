require_relative File.realpath("#{__dir__}/../single_attributes_serializers.rb")
module BenchMarks
  module SingleAttributes
    module ExcludingActiveRecords
      def self.ams_excluding_ar(data, serializer)
        ActiveModelSerializers::SerializableResource.new(data, each_serializer: serializer).to_json
      end

      def self.panko_excluding_ar(data, serializer)
        Panko::ArraySerializer.new(data, each_serializer: serializer).to_json
      end

      def self.nativeson_including_ar(limit, model)
        Nativeson.fetch_json_by_query_hash({klass: model, limit: limit, columns: ["single_attr"]})[:json]
      end

      def self.benchmark
        # BenchMarks::SingleAttributes::ExcludingActiveRecords::benchmark
        loggers = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger, ActiveModelSerializers.logger = nil, Logger.new(nil)

        Benchmark.ips do |x|
          x.config(time: 5, warmup: 1)
          [SingleStringAttribute, SingleDateTimeAttribute, SingleFloatAttribute, SingleIntegerAttribute].each do |model|
            limit = model.count
            data = model.all.select(:single_attr).limit(limit).load
            panko_serializer = Object.const_get("SingleAttributeSerializers::PankoSerializers::Panko#{model}")
            ams_serializer = Object.const_get("SingleAttributeSerializers::AmsSerializers::Ams#{model}")
            x.report("panko_excluding_ar - #{model} - #{limit} :") { panko_excluding_ar(data, panko_serializer) }
            x.report("ams_excluding_ar - #{model}   - #{limit} :") { ams_excluding_ar(data, ams_serializer) }
            x.report("nativeson_including_ar - #{model} - #{limit} :") { nativeson_including_ar(limit, model.to_s) }
          end
          x.compare!
        end
        ActiveRecord::Base.logger, ActiveModelSerializers.logger = loggers
        nil
      end
    end
  end
end
