input  = channel.queue('input', durable: true, auto_delete: false)

10.times do | index |
  publish(input, { some: 'zero data' })
end

stop
