require "rubygems"
require "daemons"
require "twitter"
require_relative "environment.rb"

Daemons.run_proc("estimates.rb") do
  class Estimates
    attr_accessor :twitter, :search_term, :anti_search_term

    def initialize(search_term="Estimates", anti_search_term="Free Estimates")
      @twitter = Twitter::REST::Client.new do |config|
        config.consumer_key = EnvironmentVars::TWITTER_CONSUMER_KEY
        config.consumer_secret = EnvironmentVars::TWITTER_CONSUMER_SECRET
        config.access_token = EnvironmentVars::TWITTER_ACCESS_TOKEN
        config.access_token_secret = EnvironmentVars::TWITTER_ACCESS_TOKEN_SECRET
      end

      @search_term = search_term
      @anti_search_term = anti_search_term

      while true
        search_and_retweet
        sleep 43_200
      end
    end

    def search_and_retweet
      tweets = twitter.search search_term,
        lang: "en",
        result_type: "recent"

      status = tweets.to_a.keep_if { |status| status_qualifies(status) }.first
      #tweet = build_tweet(status)
      #twitter.update(tweet) unless tweet.nil?
      twitter.retweet status.id

    rescue Twitter::Error::Unauthorized => error
      puts "#{error.class}: #{error.message}"
    end

    def status_qualifies(status)
      status.text.match(/#{search_term}/) &&
      !(status.text.match(/#{anti_search_term}/))
    end

    def build_tweet(status)
      words = status.text.squeeze(" ").split(" ")
      i = words.index search_term
      p i
      if i > 1
        "#{words[i - 2]} #{words[i - 1]} me!"
      elsif i == 1
        "#{words.first} me!"
      end
    end
  end

  Estimates.new()
end
