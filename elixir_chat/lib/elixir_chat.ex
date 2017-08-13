defmodule ElixirChat do

  # Initializes RabbitMQ, setups channels, exchanges and queues, subscribes to queue and goes into main loop
  def start do
    user = IO.gets("Type in your name: ") |> String.trim
    IO.puts "Hi #{user}, you just joined a chat room! Type your message in and press enter."

    {:ok, conn} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(conn)
    {:ok, queue_data } = AMQP.Queue.declare channel, user

    AMQP.Exchange.fanout(channel, "super.chat")
    AMQP.Queue.bind channel, queue_data.queue, "super.chat"

    listen_for_messages(channel, queue_data.queue)
    wait_for_message(user, channel)
  end

  # Awaits user input, then publishes messages
  def wait_for_message(user, channel) do
    message = IO.gets("") |> String.trim
    publish_message(user, message, channel)
    wait_for_message(user, channel)
  end

  # Subscribes to queue with message printer
  def listen_for_messages(channel, queue_name) do
    AMQP.Queue.subscribe channel, queue_name, fn(payload, _meta) ->
      { :ok, data } = JSON.decode(payload)
      display_message(data["user"], data["message"])
    end
  end

  # Publishes messages
  def publish_message(user, message, channel) do
    { :ok, data } = JSON.encode(user: user, message: message)
    AMQP.Basic.publish channel, "super.chat", "", data
  end

  # Prints a message
  def display_message(user, message) do
    IO.puts("#{user}: #{message}")
  end

end

ElixirChat.start
