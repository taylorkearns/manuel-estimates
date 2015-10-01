require "rubygems"
require "daemons"
require "twitter"
require_relative "environment.rb"

Daemons.run_proc("estimates.rb") do
  class Estimates
    attr_accessor :twitter, :search_term

    def initialize(search_term="Estimates")
      @twitter = Twitter::REST::Client.new do |config|
        config.consumer_key = EnvironmentVars::TWITTER_CONSUMER_KEY
        config.consumer_secret = EnvironmentVars::TWITTER_CONSUMER_SECRET
        config.access_token = EnvironmentVars::TWITTER_OAUTH_TOKEN
        config.access_token_secret = EnvironmentVars::TWITTER_OAUTH_TOKEN_SECRET
      end

      @search_term = search_term

      while true
        search_and_retweet
        sleep(43_200)
      end
    end

    def search_and_retweet
      tweets = twitter.search search_term,
        lang: "en",
        result_type: "recent"

      statuses = tweets.to_a.keep_if { |status| status_qualifies(status) }
      twitter.retweet(statuses.first.id)

    rescue Twitter::Error::Unauthorized => error
      puts "#{error.class}: #{error.message}"
    end

    def status_qualifies(status)
      status.text.match /#{search_term}/
    end
  end

  Estimates.new()
end
