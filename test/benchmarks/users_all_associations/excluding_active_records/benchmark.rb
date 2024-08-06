# frozen_string_literal: true

require_relative File.realpath("#{__dir__}/../users_all_associations_serializers.rb")

module BenchMarks
  module UsersAllAssociations
    module ExcludingActiveRecords
      def self.ams_excluding_ar(data)
        ActiveModelSerializers::SerializableResource.new(
          data,
          each_serializer: UsersAllAssociationsSerializers::AMS::AmsUser
        ).to_json
      end

      def self.panko_excluding_ar(data)
        Panko::ArraySerializer.new(
          data,
          each_serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoUser
        ).to_json
      end

      def self.nativeson_including_ar(limit)
        Nativeson.fetch_json_by_query_hash(
          { klass: 'User',
            limit: limit,
            associations: {
              items: {
                klass: 'Item',
                associations: {
                  item_description: {
                    klass: 'ItemDescription'
                  },
                  item_prices: {
                    klass: 'ItemPrice'
                  }
                }
              },
              user_profile: {
                klass: 'UserProfile',
                associations: {
                  user_profile_pic: {
                    klass: 'UserProfilePic'
                  }
                }
              },
              widgets: {
                klass: 'Widget',
                associations: {
                  sub_widgets: {
                    klass: 'SubWidget'
                  }
                }
              }
            } }
        )[:json]
      end

      def self.benchmark
        # BenchMarks::UsersAllAssociations::ExcludingActiveRecords::benchmark
        user_count = User.count
        loggers = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger = nil
        ActiveModelSerializers.logger = Logger.new(nil)
        Range.new(1, user_count).step(user_count / 3).each do |limit|
          Benchmark.ips do |x|
            x.config(time: 5, warmup: 1)
            data = User.all.includes(items: %i[item_description item_prices], user_profile: [:user_profile_pic],
                                     widgets: [:sub_widgets]).limit(limit).load
            x.report("panko_excluding_ar     - #{limit} :") { panko_excluding_ar(data) }
            x.report("ams_excluding_ar       - #{limit} :") { ams_excluding_ar(data) }
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
