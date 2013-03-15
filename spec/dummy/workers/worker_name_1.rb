output = queue.new('output')
input  = queue.new('input')

send(output, {some: 'data'})

subscribe(output, time_loging: true) do | header, data |
  RunRabbitRun.logger.info data.inspect
  send(input, {received: 'data'})
end

subscribe(input) do | header, data |
  RunRabbitRun.logger.info data.inspect
end
