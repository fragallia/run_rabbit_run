RRR::Processes::Worker.run 'worker_name_2' do
  queue :queue1, durable: true

  processes capacity: 10, prefetch: 1

  subscribe :queue1, ack: true

  def call headers, payload
    puts 'hey'
    sleep 5
    headers.ack
  end
end


