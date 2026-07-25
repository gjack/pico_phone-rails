# frozen_string_literal: true

# Rails 7.0's SQLite3Adapter hard-requires the sqlite3 gem's 1.4.x series
# (`gem "sqlite3", "~> 1.4"` in its adapter source) and raises a LoadError
# under the 2.x series that later Rails versions (and this repo's own
# Gemfile) use — so 7.0 needs its own override here.
appraise "rails-7.0" do
  gem "rails", "~> 7.0.0"
  gem "sqlite3", "~> 1.4"
end

%w[7.1 7.2 8.0 8.1].each do |rails_version|
  appraise "rails-#{rails_version}" do
    gem "rails", "~> #{rails_version}.0"
  end
end
