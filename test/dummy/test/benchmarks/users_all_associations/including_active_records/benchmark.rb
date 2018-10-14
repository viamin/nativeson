require_relative File.realpath("#{__dir__}/../users_all_associations_serializers.rb")

module BenchMarks
  module UsersAllAssociations
    module IncludingActiveRecords
      def self.ams_including_ar(limit)
        ActiveModelSerializers::SerializableResource.new(
            User.all.includes(items: [:item_description, :item_prices], user_profile: [:user_profile_pic], widgets: [:sub_widgets]).limit(limit),
            each_serializer: UsersAllAssociationsSerializers::AMS::AmsUser).to_json
      end

      def self.panko_including_ar(limit)
        Panko::ArraySerializer.new(
            User.all.includes(items: [:item_description, :item_prices], user_profile: [:user_profile_pic], widgets: [:sub_widgets]).limit(limit),
            each_serializer: UsersAllAssociationsSerializers::PankoSerializer::PankoUser).to_json
      end

      def self.nativeson_including_ar(limit)
        Nativeson.fetch_json_by_query_hash(
            {klass: 'User',
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
             }
            }
        )[:json]
      end

      def self.benchmark
        # BenchMarks::UsersAllAssociations::IncludingActiveRecords::benchmark
        user_count = User.count
        loggers    = [ActiveRecord::Base.logger, ActiveModelSerializers.logger]
        ActiveRecord::Base.logger ,ActiveModelSerializers.logger = nil , Logger.new(nil)
        Range.new(1,user_count).step(user_count/3).each do |limit|
          Benchmark.ips do |x|
            x.config(time: 20, warmup: 1)
            x.report("panko_including_ar     - #{limit} :") { panko_including_ar(limit) }
            x.report("ams_including_ar       - #{limit} :") { ams_including_ar(limit) }
            x.report("nativeson_including_ar - #{limit} :") { nativeson_including_ar(limit) }
            x.compare!
          end
        end ; nil
        ActiveRecord::Base.logger , ActiveModelSerializers.logger = loggers ; nil
      end
    end
  end
end



