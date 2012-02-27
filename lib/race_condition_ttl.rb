module RaceConditionTTL
  def self.included(base)
    base.alias_method_chain :read, :entry
    base.alias_method_chain :write, :entry
  end

  def initialize(*addresses)
    super

    @race_condition_ttl = mem_cache_options[:race_condition_ttl].to_i
    if @expires_in.to_i > 0
      @expires_in += @race_condition_ttl
    end
  end

  def fetch(key, options = {})
    @logger_off = true

    entry = read_with_entry(key, options)
    value = entry.try(:value)

    if entry.expired?
      entry.expires_in = Time.now.to_i + entry.race_condition_ttl
      write_with_entry(key, entry, options)

      value = nil
    end

    if !options[:force] && value
      @logger_off = false
      log("hit", key, options)
      value
    elsif block_given?
      @logger_off = false
      log("miss", key, options)

      value = nil
      ms = Benchmark.ms { value = yield }

      @logger_off = true
      entry = Entry.new(value, options.reverse_merge(:expires_in => @expires_in, :race_condition_ttl => @race_condition_ttl))
      write_with_entry(key, entry, options)
      @logger_off = false

      log('write (will save %.2fms)' % ms, key, nil)

      value
    end
  end

  def read_with_entry(key, options={})
    raw_value = read_without_entry(key, options)

    entry = Marshal.load(raw_value) rescue raw_value
    entry = Entry.new(entry, options) unless entry.is_a?(Entry)

    entry
  end

  def write_with_entry(key, entry, options={})
    unless entry.is_a?(Entry)
      entry = Entry.new(entry, options)
    end

    raw_value = Marshal.dump(entry)

    write_without_entry(key, raw_value, options.merge(:expires_in => entry.expires_in))

    entry
  end

  class Entry
    attr_accessor :value, :expires_in, :race_condition_ttl
    attr_reader :created_at

    def initialize(value, options)
      @value = value
      @created_at = Time.now.to_i

      options ||= {}

      @race_condition_ttl = options[:race_condition_ttl].to_i.seconds
      if options[:expires_in].to_i > 0
        @expires_in = options[:expires_in].to_i.seconds + @race_condition_ttl
      else
        @expires_in = 0
      end
    end

    def expired?
      return false if @expires_in == 0
      @created_at + @expires_in - @race_condition_ttl <= Time.now.to_i
    end

    def html_safe
      value.respond_to?(:html_safe) ? value.html_safe : value
    end
  end
end
