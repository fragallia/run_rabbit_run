RRR::Worker.run 'worker_name_2' do
  queue :queue1, durable: true

  subscribe :queue1

  def call headers, payload
    RRR.logger.info "received message #{payload}"
  end
end


