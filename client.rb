require 'slack-ruby-client'
require 'dotenv'
require 'pry'
Dotenv.load

Slack.configure do |config|
  config.token = ENV['TOKEN']
end

class DeleterBot

  def initialize
    @client = Slack::Web::Client.new
    @user = ENV["JASON"]
    @channel = ENV["CHANNEL"]
    @excluded_sub_types = ['group_join', 'group_purpose']
  end

  def run
    puts "Starting deleter-bot for User: #{@user} on Channel: #{@channel}"
    messages = get_messages
    filtered_messages = filter_messages(messages)
    puts "Got #{filtered_messages.count} of your messages. Are you sure you want to delete them? (y/n)"
    if gets.chomp == 'y'
      delete_messages(filtered_messages)
      puts "Success!"
    else
      puts "Exiting without deleting messages."
      exit
    end
  end

  def get_messages
    puts "Getting all messages..."
    messages = []
    options = {channel: @channel}
    begin
      response = @client.groups_history(options)
      messages << response["messages"]
      options[:latest] = response['messages'].last["ts"]
    end until response["has_more"] == false
    messages.flatten
  end

  def filter_messages(messages)
    puts "Filtering messages..."
    messages.select{|m| m["user"] == @user}
  end

  def delete_messages(filtered_messages)
    puts "Deleting messages..."
    filtered_messages.each do |message|
      delete_message(message) if is_message?(message)
    end
    puts "Messages deleted!"
  end

  def delete_message(message)
    options = {ts: message["ts"], channel: @channel }
    @client.chat_delete(options)
  end

  def is_message?(message)
    true unless @excluded_sub_types.include? message["subtype"]
  end
end

bot = DeleterBot.new
bot.run
