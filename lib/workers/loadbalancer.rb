RRR::Processes::Worker.run 'system_loadbalancer' do
  queue :loadbalancer, name: "#{RRR.config[:env]}.system.loadbalancer", durable: true
  queue :worker_start, name: "#{RRR.config[:env]}.system.worker.start", durable: true
  queue :worker_stop,  name: "#{RRR.config[:env]}.system.worker.stop", durable: true

  processes max: 1, min: 1, desirable: 1

  subscribe :loadbalancer

  def call headers, payload
    raise 'No action given'      unless payload['action']

    @loadbalancer = RRR::Loadbalancer::Base.new

    case payload['action']
    when 'push'
      raise 'No code given'        unless payload['code']
      raise 'No worker name given' unless payload['worker_name']

      @loadbalancer.push payload['worker_name'], payload['code']
    when 'stats'
      raise 'No master name given' unless payload['name']
      raise 'No stats given'       unless payload['stats']

      @loadbalancer.stats payload['name'], payload['stats']
    end

    @stats_timer ||= EM::PeriodicTimer.new(1) { @loadbalancer.check }

    # if master did not report in 5 mins set count to 0 for all workers
    @master_updates_timer ||= EM::PeriodicTimer.new(300) { @loadbalancer.check_masters }
  end
end

