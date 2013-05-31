RRR::Processes::Worker.run 'worker_name_1' do
  queue :queue1, durable: true

  def call
    50.times do | index |
      queues[:queue1].notify({ some: :data })
    end
  end
end


