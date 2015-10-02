require "rubygems"
require "daemons"
require "twitter"
require "logger"
require_relative "environment.rb"

Daemons.run_proc("estimates.rb") do
  class Estimates
    attr_accessor :twitter, :search_term, :anti_search_term

    def initialize(options)
      @twitter = Twitter::REST::Client.new do |config|
        config.consumer_key = EnvironmentVars::TWITTER_CONSUMER_KEY
        config.consumer_secret = EnvironmentVars::TWITTER_CONSUMER_SECRET
        config.access_token = EnvironmentVars::TWITTER_ACCESS_TOKEN
        config.access_token_secret = EnvironmentVars::TWITTER_ACCESS_TOKEN_SECRET
      end

      @search_term = options[:search_term]
      @anti_search_term = options[:anti_search_term]

      while true
        search_and_retweet
        sleep 43_200 # twice per day
      end
    end

    def search_and_retweet
      tweets = twitter.search search_term, lang: "en", result_type: "recent"
      qualifying_tweets = tweets.to_a.keep_if { |status| status_qualifies(status) }
      tweet = qualifying_tweets.first
      twitter.retweet tweet.id

    rescue Twitter::Error => error
      logger = Logger.new(STDERR)
      logger.error "#{error.class}: #{error.message}"
    end

    def status_qualifies(status)
      status.text.match(/#{search_term}/) &&
      !(status.text.match(/#{anti_search_term}/))
    end
  end

  Estimates.new(search_term: "Estimates", anti_search_term: "Free Estimates")
end
