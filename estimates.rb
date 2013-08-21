require 'twitter'
require_relative 'environment.rb'

Twitter.configure do |config|
  config.consumer_key = EnvironmentVars::TWITTER_CONSUMER_KEY
  config.consumer_secret = EnvironmentVars::TWITTER_CONSUMER_SECRET
  config.oauth_token = EnvironmentVars::TWITTER_OAUTH_TOKEN
  config.oauth_token_secret = EnvironmentVars::TWITTER_OAUTH_TOKEN_SECRET
end

class Estimates
  attr_accessor :twitter, :search_term

  def initialize(search_term='Estimates')
    @twitter = Twitter::Client.new
    @search_term = search_term

    while true
      search_and_retweet
      sleep(60)
    end
  end

  def search_and_retweet
    raw_tweets = twitter.search search_term,
      lang: 'en',
      result_type: 'recent'

    raw_tweets.results.each do |status|
      next unless status_qualifies(status)

      begin
        twitter.retweet(status.id)
      rescue Twitter::Error::Unauthorized => error
        puts "#{error.class}: #{error.message}"
      end
    end
  end

  def status_qualifies(status)
    status.text.match(search_term)
  end
end

Estimates.new()
