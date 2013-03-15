output = queue.new('output2')
input  = queue.new('input2')

send(output, {some: 'data'})

subscribe(output) do | header, data |
  RunRabbitRun.logger.info data.inspect
  send(input, {received: 'data'})
end

subscribe(input) do | header, data |
  RunRabbitRun.logger.info data.inspect
end
