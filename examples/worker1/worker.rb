RRR::Worker.run 'worker_name_1' do
  queue :queue1, durable: true

  def call
    queues[:queue1].notify({ some: :data })
  end
end


