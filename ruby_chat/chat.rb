require 'json'
require 'bunny'
class Chat

  # Initializes RabbitMQ, setups channels, exchanges and queues
  def initialize
    print 'Type in your name: '
    @current_user = gets.strip
    puts "Hi #{@current_user}, you just joined a chat room! Type your message in and press enter."

    conn = Bunny.new
    conn.start

    @channel = conn.create_channel
    @exchange = @channel.fanout('super.chat')
    @queue = @channel.queue(@current_user)
    @queue.bind(@exchange)
  end

  # Setups message subscription, then go into main loop
  # Bug was here, recursive approach lead to stack overflow
  def wait_for_message
    listen_for_messages
    loop { publish_message(@current_user, gets.strip) }
  end

  # Subscribes to queue with message printer
  def listen_for_messages
    @queue.subscribe do |_delivery_info, _metad5ata, payload|
      data = JSON.parse(payload)
      display_message(data['user'], data['message'])
    end
  end

  # Publishes messages
  def publish_message(user, message)
    @exchange.publish({user: user, message: message}.to_json)
  end

  # Prints a message
  def display_message(user, message)
    puts "#{user}: #{message}"
  end
end

chat = Chat.new
chat.wait_for_message
