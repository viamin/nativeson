# frozen_string_literal: true

require 'memory_profiler'
require 'benchmark/ips'
Dir.glob("#{Rails.root}/test/benchmarks/*/*/benchmark.rb").sort.each do |benchmark_file|
  require_relative benchmark_file
end; nil
