# Nativeson

(forked from <https://gitlab.com/nativeson/nativeson>)

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
bundle
```

Or install it yourself as:

```bash
gem install nativeson
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
nativeson_hash = Nativeson.fetch_json_by_query_hash(
  { klass: 'User',
    where: 'created_at > CURRENT_TIMESTAMP - INTERVAL \'10 day\' ',
    key: 'users',
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
```

where

* `nativeson_hash[:query_hash]` is the query hash supplied as input
* `nativeson_hash[:container]` is the underlying `Nativeson` query tree structure
* `nativeson_hash[:sql]` is the SQL query used to generate the JSON string
* `nativeson_hash[:json]` is the JSON string, ready to be sent to the front-end

### Associations vs Joins

The query hash can take an association object or a joins array (or both). The association object is used when you want a nested object in your JSON output (see the example output below for items.) Associations require that the nesting matches the database structure (the child association must have a key pointing to the parent association.) Joins are used when you want to include a joined column in the main (non-nested) output or create a custom structure.

### Other ways to query

Nativeson also supports two other calling interfaces:

1. Pass an ActiveRecord query object to `Nativeson.fetch_json_by_rails_query`. The query you're passing must `respond_to?(:to_sql)` by producing a String containing a SQL query.

```ruby
nativeson_hash = Nativeson.fetch_json_by_rails_query(User.where('id > ?', 1).order(:created_at => :desc))
```

1. Pass a raw SQL query string to `Nativeson.fetch_json_by_string`.

```ruby
nativeson_hash = Nativeson.fetch_json_by_string('select id, created_at from users limit 2')
```

where

* `nativeson_hash[:sql]` is the SQL query used to generate the JSON  string
* `nativeson_hash[:json]` is the JSON string, ready to be sent to the front-end

Here is a short example of the JSON output for a single User model instance with some associations and nested associations:

```json
{"users":[{"id":1,"created_at":"2018-10-13T20:37:16.59672","updated_at":"2018-10-13T20:37:16.59672","name":"ayankfjpxlfjo","email":"taliahyatt@lueilwitz.org","col_int":918,"col_float":70.8228834313906,"col_string":"ygsvwobjiadfw","klass":"User","items":[{"id":1,"user_id":1,"created_at":"2018-10-13T20:37:16.847055","updated_at":"2018-10-13T20:37:16.847055","name":"ayankfjpxlfjo","col_int":111,"col_float":826.58466863469,"col_string":"ehbautrrelysd","klass":"Item","item_description":[{"id":1,"item_id":1,"description":"ayankfjpxlfjo","created_at":"2018-10-13T20:37:17.40971","updated_at":"2018-10-13T20:37:17.40971","col_int":70,"col_float":586.497122020896,"col_string":"vixbltiopskxy","klass":"ItemDescription"}],"item_prices":[{"id":1,"item_id":1,"current_price":55.834605139059,"previous_price":57.4058337411023,"created_at":"2018-10-13T20:37:17.514948","updated_at":"2018-10-13T20:37:17.514948","klass":"ItemPrice"}]},
 {"id":2,"user_id":1,"created_at":"2018-10-13T20:37:16.847055","updated_at":"2018-10-13T20:37:16.847055","name":"ayankfjpxlfjo","col_int":136,"col_float":631.548964229925,"col_string":"watxmnafzzmeu","klass":"Item","item_description":[{"id":2,"item_id":2,"description":"ayankfjpxlfjo","created_at":"2018-10-13T20:37:17.40971","updated_at":"2018-10-13T20:37:17.40971","col_int":878,"col_float":511.772295898348,"col_string":"khzoaziqopnkl","klass":"ItemDescription"}],"item_prices":[{"id":2,"item_id":2,"current_price":33.8844481909688,"previous_price":97.403522117916,"created_at":"2018-10-13T20:37:17.514948","updated_at":"2018-10-13T20:37:17.514948","klass":"ItemPrice"}]}],"user_profile":[{"id":1,"user_id":1,"created_at":"2018-10-13T20:37:17.204195","updated_at":"2018-10-13T20:37:17.204195","name":"ayankfjpxlfjo","col_int":null,"col_float":null,"col_string":null,"klass":"UserProfile","user_profile_pic":[{"id":1,"user_profile_id":1,"image_url":"wljyqyzyxqfsn","image_width":104,"image_height":228,"created_at":"2018-10-13T20:37:17.235248","updated_at":"2018-10-13T20:37:17.235248","klass":"UserProfilePic"}]}],"widgets":[{"id":1,"user_id":1,"created_at":"2018-10-13T20:37:17.100901","updated_at":"2018-10-13T20:37:17.100901","name":"ayankfjpxlfjo","col_int":242,"col_float":223.65750025762,"col_string":"cxaqmdnmufnvt","klass":"Widget","sub_widgets":[{"id":3,"name":"ayankfjpxlfjo_5.92774893856709","widget_id":1,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":687,"col_float":851.650101581247,"col_string":"toozdtwuyaesn","klass":"SubWidget"},
 {"id":2,"name":"ayankfjpxlfjo_4.07599669367832","widget_id":1,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":943,"col_float":257.325888075186,"col_string":"rscziazmauagm","klass":"SubWidget"},
 {"id":1,"name":"ayankfjpxlfjo_2.9579304830078375","widget_id":1,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":896,"col_float":38.2691573106148,"col_string":"fmetacimdbjnv","klass":"SubWidget"}]},
 {"id":2,"user_id":1,"created_at":"2018-10-13T20:37:17.100901","updated_at":"2018-10-13T20:37:17.100901","name":"ayankfjpxlfjo","col_int":956,"col_float":949.173224865556,"col_string":"oeoybsrtkjnfb","klass":"Widget","sub_widgets":[{"id":6,"name":"ayankfjpxlfjo_5.943535906853784","widget_id":2,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":601,"col_float":218.619706269916,"col_string":"qvslwrgieoidv","klass":"SubWidget"},
 {"id":5,"name":"ayankfjpxlfjo_2.003554122744414","widget_id":2,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":220,"col_float":583.631142121848,"col_string":"yerhhrsmsyydc","klass":"SubWidget"},
 {"id":4,"name":"ayankfjpxlfjo_4.047681099308994","widget_id":2,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":668,"col_float":839.024125756382,"col_string":"oegjbumatstvp","klass":"SubWidget"}]},
 {"id":3,"user_id":1,"created_at":"2018-10-13T20:37:17.100901","updated_at":"2018-10-13T20:37:17.100901","name":"ayankfjpxlfjo","col_int":391,"col_float":99.9364653444063,"col_string":"incqzwrenmrxh","klass":"Widget","sub_widgets":[{"id":9,"name":"ayankfjpxlfjo_0.37354840663121935","widget_id":3,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":558,"col_float":991.578355632946,"col_string":"ihqoxbanvsqfn","klass":"SubWidget"},
 {"id":8,"name":"ayankfjpxlfjo_1.8483953654699228","widget_id":3,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":21,"col_float":203.657249239792,"col_string":"khmzcemxpkvub","klass":"SubWidget"},
 {"id":7,"name":"ayankfjpxlfjo_1.1359488386694","widget_id":3,"created_at":"2018-10-13T20:37:17.912943","updated_at":"2018-10-13T20:37:17.912943","col_int":335,"col_float":144.911845441697,"col_string":"gpbpeniemwpdk","klass":"SubWidget"}]}]}]}
```

## Benchmarks

We compared Nativeson to [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers) as a Rails standard and to [Panko](https://github.com/yosiat/panko_serializer), which according to <https://yosiat.github.io/panko_serializer/performance.html> is 5-10x as fast as AMS in microbenchmarking and ~3x as fast as AMS in an end-to-end Web page load test.
It's important to note that both rely on ActiveRecord to fetch the data for them, which makes a huge difference in the benchmark comparisons to Nativeson.

In a "standard" flow, such as Panko and ActiveModel::Serializer,
the lifecycle is:

1. HTTP request received
1. database query
1. ActiveRecord model object instantiation
1. Panko or ActiveModel::Serializer serialization
1. JSON response

With Nativeson the lifecycle is shorter:

1. HTTP request received
1. database query
1. JSON response

Because of the above, there are a few important items to take into account:

* Nativeson should be used when a SQL query is sufficient to retrieve/calculate all
  the data needed to create your response.
  If you need to query the database and then do complex postprocessing of the data in Ruby,
  then Nativeson may not fit your needs.
* We compared performance with/without the ActiveRecord
  database query stage. We believe this stage should be included in any decision to use one or another of these gems, because in real world use, the lifecycle
  will usually include it.

The fastest result for each row is shown in bold in the table below.  Note that, like in Panko's own published benchmark results, Panko's speedup relative to ActiveModel::Serializer is partly obscured in real-world usage by the large fraction of time spent just querying the database and constructing ActiveRecord object instances; Nativeson sidesteps that work entirely, calling upon the database's native JSON generation functions to produce a JSON string directly.

Benchmark results table:

<table>
  <thead style='background-color: #F0FFFF'>
    <tr>
      <th>Model</th>
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
      <td>User</td>
      <td>1</td>
      <td>No</td>
      <td>No</td>
      <td>4813</td>
      <td><b>47718</b></td>
      <td>2429</td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_no_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>User</td>
      <td>202</td>
      <td>No</td>
      <td>No</td>
      <td>44</td>
      <td><b>728</b></td>
      <td>510</td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_no_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>User</td>
      <td>403</td>
      <td>No</td>
      <td>No</td>
      <td>26</td>
      <td><b>359</b></td>
      <td>349</td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_no_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>User</td>
      <td>1</td>
      <td>Yes</td>
      <td>No</td>
      <td>989</td>
      <td>1584</td>
      <td><b>2341</b></td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_no_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>User</td>
      <td>202</td>
      <td>Yes</td>
      <td>No</td>
      <td>21</td>
      <td>189</td>
      <td><b>550</b></td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_no_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>User</td>
      <td>403</td>
      <td>Yes</td>
      <td>No</td>
      <td>11</td>
      <td>112</td>
      <td><b>295</b></td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_no_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>User</td>
      <td>1</td>
      <td>No</td>
      <td>Yes</td>
      <td>126</td>
      <td><b>621</b></td>
      <td>237</td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_all_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>User</td>
      <td>202</td>
      <td>No</td>
      <td>Yes</td>
      <td>3</td>
      <td><b>33</b></td>
      <td>14</td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_all_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr>
      <td>User</td>
      <td>403</td>
      <td>No</td>
      <td>Yes</td>
      <td>2</td>
      <td><b>32</b></td>
      <td>13</td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_all_associations/excluding_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>User</td>
      <td>1</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>31</td>
      <td>50</td>
      <td><b>238</b></td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_all_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>User</td>
      <td>202</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>1.1</td>
      <td>3.4</td>
      <td><b>15.2</b></td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_all_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
    <tr style='background-color: #E5E4E2'>
      <td>User</td>
      <td>403</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>1.0</td>
      <td>3.0</td>
      <td><b>12.6</b></td>
      <td></td>
      <td>
        <a href='test/dummy/test/benchmarks/users_all_associations/including_active_records/benchmark.rb'>
          benchmark
        </a>
      </td>
    </tr>
  </tbody>
</table>

[More benchmarks](docs/benchmarks.md)

## Contributing

Set up steps for development:

1. Fork the project.
1. `git clone` your forked repository to your development machine.
1. `pushd nativeson`
1. `brew install imagemagick` if you're going to use `gruff` (see next step for more details)
1. `bundle` (you can comment out the `gruff` gem if you don't need to generate graphs of performance tests)
1. `pushd test/dummy`
1. `bundle exec rake db:create db:setup`
1. `popd`
1. Run the tests: `./bin/test`
1. If the tests run and pass, you are in good shape to develop on Nativeson.

* Then make your feature addition or bug fix.
* Add tests for it.
* Run `./bin/test` and make sure all tests still run and pass. Contributions with failing tests or tests that fail to run will not be accepted.
* Commit. Do not mess with version.rb or commit history other than on your own branches. If you want to have your own version number in version.rb, that is fine, but change that in a commit by itself in another branch so it can be ignored when the pull request is merged.
* Submit a pull request to this repository. Bonus points for topic branches.

## License

The gem is available as open source under the terms of the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
