output = channel.queue('output2', auto_delete: false)
input  = channel.queue('input2', auto_delete: false)

publish(output, {some: 'data'})

subscribe(output) do | headers, data |
  RunRabbitRun.logger.info data.inspect
  publish(input, {received: 'data'})
end

subscribe(input) do | headers, data |
  RunRabbitRun.logger.info data.inspect
end
