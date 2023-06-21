require_relative File.realpath("#{__dir__}/../single_attributes_serializers.rb")
module BenchMarks
  module SingleAttributes
    module IncludingActiveRecords
      def self.ams_including_ar(limit, model, serializer)
        ActiveModelSerializers::SerializableResource.new(model.all.select(:single_attr).limit(limit), each_serializer: serializer).to_json
      end

      def self.panko_including_ar(limit, model, serializer)
        Panko::ArraySerializer.new(model.all.select(:single_attr).limit(limit), each_serializer: serializer).to_json
      end

      def self.nativeson_including_ar(limit, model)
        Nativeson.fetch_json_by_query_hash({klass: model, limit: limit, columns: ["single_attr"]})[:json]
      end

      def self.benchmark
        # BenchMarks::SingleAttributes::IncludingActiveRecords::benchmark
        loggers = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger, ActiveModelSerializers.logger = nil, Logger.new(nil)

        Benchmark.ips do |x|
          x.config(time: 7, warmup: 1)
          [SingleStringAttribute, SingleDateTimeAttribute, SingleFloatAttribute, SingleIntegerAttribute].each do |model|
            count = model.count
            Range.new(1, count).step(count / 7).each do |limit|
              panko_serializer = Object.const_get("SingleAttributeSerializers::PankoSerializers::Panko#{model}")
              ams_serializer = Object.const_get("SingleAttributeSerializers::AmsSerializers::Ams#{model}")
              x.report("panko_including_ar - #{model} - #{limit} :") { panko_including_ar(limit, model, panko_serializer) }
              x.report("ams_including_ar - #{model}   - #{limit} :") { ams_including_ar(limit, model, ams_serializer) }
              x.report("nativeson_including_ar - #{model} - #{limit} :") { nativeson_including_ar(limit, model.to_s) }
            end
          end
          x.compare!
        end
        ActiveRecord::Base.logger, ActiveModelSerializers.logger = loggers
        nil
      end
    end
  end
end
