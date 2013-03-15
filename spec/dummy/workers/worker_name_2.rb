output = channel.queue('output2', auto_delete: false)
input  = channel.queue('input2', auto_delete: false)

send(output, {some: 'data'})

subscribe(output) do | header, data |
  RunRabbitRun.logger.info data.inspect
  send(input, {received: 'data'})
end

subscribe(input) do | header, data |
  RunRabbitRun.logger.info data.inspect
end
