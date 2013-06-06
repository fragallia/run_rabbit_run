RRR::Processes::Worker.run 'worker_name_2' do
  queue     "queue1", durable: true
  subscribe "queue1", ack: true

  processes min: 1, max: 10, desirable: 5
  settings  queue_size: 10, capacity: 10, prefetch: 1

  def call headers, payload
    sleep 5
    headers.ack
  end
end
