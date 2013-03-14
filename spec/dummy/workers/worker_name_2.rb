require 'run_rabbit_run'

RunRabbitRun.start do
  output = RunRabbitRun::Queue.new('output2')
  input  = RunRabbitRun::Queue.new('input2')

  send(output, {some: 'data'})

  subscribe(output) do | header, data |
    puts data.inspect
    send(input, {received: 'data'})
  end

  subscribe(input) do | header, data |
    puts data.inspect
  end

end
