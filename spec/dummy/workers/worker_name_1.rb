output = channel.queue('output', durable: true, auto_delete: false)
input  = channel.queue('input', durable: true, auto_delete: false)

publish(output, {some: 'data'})

subscribe(output, time_logging: true) do | headers, data |
  RunRabbitRun.logger.info data.inspect
  publish(input, {received: 'data'})
end

subscribe(input, ack: true) do | headers, data |
  RunRabbitRun.logger.info data.inspect
  headers.ack
end
