# Nativeson

Nativeson provides methods to generate JSON from database records
faster and with a smaller memory footprint on your web server by using database-native functions.

Nativeson generates the SQL query needed to make the database directly construct a JSON string ready to be sent to
your front-end.

Nativeson doesn't replace other serializers completely, given that serializers use ActiveRecord objects
that you can process through some business logic before you generate JSON from them.  Nativeson fits when a SQL query (WHERE/SORT/ORDER/etc.) is sufficient for constructing the needed data.

## Requirements

PostgreSQL 9.2 or higher.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'nativeson'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install nativeson
```

## Usage

Given models defined like so:
```ruby
class User < ApplicationRecord
  has_many :items
  has_one :user_profile
  has_many :widgets
end

class Item < ApplicationRecord
  has_one :item_description
  has_many :item_prices
end

class UserProfile < ApplicationRecord
  has_one :user_profile_pic
end

class UserProfilePic < ApplicationRecord
end

class Widget < ApplicationRecord
  has_many :sub_widgets
end

class SubWidget < ApplicationRecord
end
```
you can call Nativeson as follows:
```ruby
sql = Nativeson.fetch_json_by_query_hash(
  { klass: 'User',
    where: 'created_at > CURRENT_TIMESTAMP - INTERVAL \'1 day\' ',
    order: 'created_at desc',
    limit: 10,
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
)

result = ActiveRecord::Base.connection.execute(sql)
json_string = result.getvalue(0, 0)
result.clear # <- good housekeeping practice to free the memory allocated by the PG gem
```

## Benchmarks

We compared Nativeson to [`ActiveModel::Serializer`](https://github.com/rails-api/active_model_serializers) as a Rails standard and to [Panko](https://github.com/yosiat/panko_serializer), which according to https://yosiat.github.io/panko_serializer/performance.html is 5-10x as fast as AMS in microbenchmarking and ~3x as fast as AMS in an end-to-end Web page load test.
It's important to note that both rely on `ActiveRecord` to fetch the data for them, which makes a huge difference in the benchmark comparisons to Nativeson.

In a "standard" flow, such as `Panko` and `ActiveModel::Serializer`.
The cycle is:
* `request`
* `DB query`
* `ActiveRecord`
* `Panko` or `ActiveModel::Serializer` serialization.
* `JSON response`

With Nativeson the cycle is shorter:
* `request`
* `DB query`
* `JSON response`

Because of the above, there are a few important items to take into account:
* Nativeson should be used when a SQL query is sufficient to retrieve/calculate all
  the data needed to create your response.
  If you need to query the database and then do complex postprocessing of the data in Ruby,
  then Nativeson may not fit your needs.
* We compared performance with/without the `ActiveRecord`
  database query stage. We believe this stage should be included in any decision to use one or another of these gems, because in real world use, the cycle
  time will usually include it.

The fastest result for each row is shown in bold in the table below.  Note that, like in Panko's own published benchmark results, `Panko`'s speedup relative to `ActiveModel::Serializer` is partly obscured in real-world usage by the large fraction of time spent just querying the database and constructing `ActiveRecord` object instances; Nativeson sidesteps that work entirely, calling upon the database's native JSON generation functions to produce a JSON string directly.

<table>
  <thead style='background-color: #F0FFFF'>
    <tr>
      <th>Data Size (number of database records)</th>
      <th>Includes time spent in ActiveRecord?</th>
      <th>Includes association queries/data?</th>
      <th>AMS ips</th>
      <th>Panko ips</th>
      <th>Nativeson ips</th>
      <th>Comments</th>
      <th>Link</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>No</td>
      <td>No</td>
      <td>4813</td>
      <td><b>47718</b></td>
      <td>2429</td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_no_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>202</td>
      <td>No</td>
      <td>No</td>
      <td>44</td>
      <td><b>728</b></td>
      <td>510</td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_no_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>403</td>
      <td>No</td>
      <td>No</td>
      <td>26</td>
      <td><b>359</b></td>
      <td>349</td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_no_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>1</td>
      <td>Yes</td>
      <td>No</td>
      <td>989</td>
      <td>1584</td>
      <td><b>2341</b></td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_no_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>    
    <tr style='background-color: #E5E4E2'>
      <td>202</td>
      <td>Yes</td>
      <td>No</td>
      <td>21</td>
      <td>189</td>
      <td><b>550</b></td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_no_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>    
    <tr style='background-color: #E5E4E2'>
      <td>403</td>
      <td>Yes</td>
      <td>No</td>
      <td>11</td>
      <td>112</td>
      <td><b>295</b></td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_no_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>     
    <tr>
      <td>1</td>
      <td>No</td>
      <td>Yes</td>
      <td>126</td>
      <td><b>621</b></td>
      <td>237</td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_all_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>202</td>
      <td>No</td>
      <td>Yes</td>
      <td>3</td>
      <td><b>33</b></td>
      <td>14</td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_all_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>       
    <tr>
      <td>403</td>
      <td>No</td>
      <td>Yes</td>
      <td>2</td>
      <td><b>32</b></td>
      <td>13</td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_all_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>     
    <tr style='background-color: #E5E4E2'>
      <td>1</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>31</td>
      <td>50</td>
      <td><b>238</b></td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_all_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>     
    <tr style='background-color: #E5E4E2'>
      <td>202</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>1.1</td>
      <td>3.4</td>
      <td><b>15.2</b></td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_all_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>403</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>1.0</td>
      <td>3.0</td>
      <td><b>12.6</b></td>
      <td>Comments</td>
      <td>
        <a href='dummy/test/benchmarks/users_all_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>      
  </tbody>
</table>

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
