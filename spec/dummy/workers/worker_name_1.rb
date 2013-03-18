output = channel.queue('output', auto_delete: false)
input  = channel.queue('input', auto_delete: false)

send(output, {some: 'data'})

subscribe(output, time_logging: true) do | header, data |
  RunRabbitRun.logger.info data.inspect
  send(input, {received: 'data'})
end

subscribe(input) do | header, data |
  RunRabbitRun.logger.info data.inspect
end
