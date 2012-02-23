RaceConditionTtl
================

This plugin backports the Rails 3 cache option :race_condition_ttl. You can read more on the [Caching With Rails Guide](http://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-store).

Example
=======

```ruby
caches_page :index, :expires_in => 30.minutes, :race_condition_ttl => 5.seconds
```

Copyright (c) 2012 Bleacher Report, released under the MIT license
