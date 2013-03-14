require 'run_rabbit_run'

RunRabbitRun.start do
  output = RunRabbitRun::Queue.new('output')
  input  = RunRabbitRun::Queue.new('input')

  send(output, {some: 'data'})

  subscribe(output) do | header, data |
    puts data.inspect
    send(input, {received: 'data'})
  end

  subscribe(input) do | header, data |
    puts data.inspect
  end

end
