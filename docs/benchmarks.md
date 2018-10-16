`BenchMarks::SingleAttributes::IncludingActiveRecords::benchmark` compares Nativeson performance to that of ActiveModel::Serializer (AMS) and Panko for database tables that have only a single column of a single datatype, for several datatypes (actually, the tables also have the standard Rails timestamps columns cteated_at and updated_at but omit the standard id column).

Although extremely unrealistic, we expect that these cases will allow AMS and Panko to show their best possible performance, because they have the least possible number of ActiveRecord attribute values to instantiate. However, we do include the time spent in the ActiveRecord database query, because for Web applications this mode of usage will be typical.

Results in the graphs below are normalized to AMS's performance and show that Nativeson performs between 12x and ~50x as fast as AMS and Panko performs between 1x and 6x as fast as AMS. The Apple Numbers spreadsheet by which the graphs were generated is linked immediately below.

[Raw results Mac Numbers spreadsheet](BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords.numbers)


<table>
  <thead>
    <tr>
      <th>Model</th>
      <th>Comments</th>
      <th>Results</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>SingleDateTimeAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleDateTimeAttribute.png"/></td>
    </tr>
    <tr>
      <td>SingleFloatAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleFloatAttribute.png"/></td>
    </tr>
    <tr>
      <td>SingleIntegerAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleIntegerAttribute.png"/></td>
    </tr>
    <tr>
      <td>SingleStringAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleStringAttribute.png"/></td>
    </tr>    
  </tbody>
</table>



<table>
  <thead>
    <tr>
      <th>Model</th>
      <th>Comments</th>
      <th>Results</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>SingleDateTimeAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleDateTimeAttribute--Trend.png"/></td>
    </tr>
    <tr>
      <td>SingleFloatAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleFloatAttribute--Trend.png"/></td>
    </tr>
    <tr>
      <td>SingleIntegerAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleIntegerAttribute--Trend.png"/></td>
    </tr>
    <tr>
      <td>SingleStringAttribute</td>
      <td></td>
      <td><img src="BenchMarks--SingleAttributes--IncludingActiveRecords/BenchMarks--SingleAttributes--IncludingActiveRecords--benchmark--SingleStringAttribute--Trend.png"/></td>
    </tr>    
  </tbody>
</table>
