RRR::Processes::Worker.run 'worker_name_2' do
  queue "queue1", durable: true

  processes min: 1, max: 10, desirable: 5, capacity: 10, prefetch: 1

  subscribe "queue1", ack: true

  def call headers, payload
    sleep 5
    headers.ack
  end
end
