require 'test_helper'

class HashCache
  attr_accessor :cache

  def initialize(*addresses)
    @cache = {}
  end

  def read(key, options=nil)
    @cache[key]
  end

  def write(key, value, options=nil)
    @cache[key] = value
  end

  def method_missing(method, *args, &block)
  end

  include RaceConditionTTL
end

class RaceConditionTtlTest < ActiveSupport::TestCase
  test "read should return an entry" do
    cache = HashCache.new
    cache.cache = {:a => Marshal.dump(1)}

    assert(cache.read(:a).is_a?(RaceConditionTTL::Entry), "Failure message.")
  end

  test "write should write an entry" do
    cache = HashCache.new
    cache.write(:a, 1)

    assert(Marshal.load(cache.cache[:a]).is_a?(RaceConditionTTL::Entry), "Write didn't marshal correctly")
  end

  test "fetch should not write a new value if not expired" do
    cache = HashCache.new
    cache.write(:a, 1, :expires_in => 1.week)

    cache.fetch(:a) { 2 }

    assert_equal(1, cache.read(:a).value)
  end

  test "fetch should write a new value if expired" do
    cache = HashCache.new
    entry = RaceConditionTTL::Entry.new(1, :expires_in => 1.seconds)
    entry.instance_variable_set(:@created_at, 1.day.ago.to_i)

    cache.write(:a, entry)

    cache.fetch(:a) { 2 }

    assert_equal(2, cache.read(:a).value)
  end
end
