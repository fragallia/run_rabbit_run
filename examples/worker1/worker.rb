RRR::Worker.run 'worker_name_1' do
  queue :output, durable: true

  def call
    queues[:output].notify({ some: :data })
  end
end


