RRR::Processes::Worker.run 'worker_name_1' do
  queue 'queue1', durable: true

  def call
    100.times do | index |
      queues['queue1'].notify({ some: :data })
    end
  end
end


