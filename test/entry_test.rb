require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  test "should alter the expiration time based on race_condition_ttl" do
    entry = RaceConditionTTL::Entry.new(1, :expires_in => 5.minutes, :race_condition_ttl => 30.seconds)
    assert_equal(5.minutes + 30.seconds, entry.expires_in)
  end

  test "should know that it's not expired" do
    entry = RaceConditionTTL::Entry.new(1, :expires_in => 5.minutes, :race_condition_ttl => 30.seconds)
    entry.instance_variable_set(:@created_at, 4.minutes.ago.to_i)

    assert(!entry.expired?, "Entry expired too early")
  end

  test "should know that it's expired" do
    entry = RaceConditionTTL::Entry.new(1, :expires_in => 5.minutes, :race_condition_ttl => 30.seconds)
    entry.instance_variable_set(:@created_at, 5.minutes.ago.to_i - 1)

    assert(entry.expired?, "Entry wasn't properly expired.")
  end

  test "should never expire with no expires_in" do
    entry = RaceConditionTTL::Entry.new(1, :race_condition_ttl => 30.seconds)
    entry.instance_variable_set(:@created_at, 5.minutes.ago.to_i - 1)

    assert(!entry.expired?, "Entry isn't supposed to expire.")
  end
end
