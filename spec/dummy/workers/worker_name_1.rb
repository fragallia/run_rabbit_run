output = channel.queue('output', auto_delete: false)
input  = channel.queue('input', auto_delete: false)

publish(output, {some: 'data'})

subscribe(output, time_logging: true) do | header, data |
  RunRabbitRun.logger.info data.inspect
  publish(input, {received: 'data'})
end

subscribe(input) do | header, data |
  RunRabbitRun.logger.info data.inspect
end
