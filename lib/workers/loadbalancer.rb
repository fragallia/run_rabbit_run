#TODO
# * Queues : use name parameter as rabbitmq queue name if it exists.
# * Write tests for the loadbalancer worker
# * Optimize tests to have standart helpers for the worker
# * Optimize rake tasks to be able to run whole system with one command

RRR::Worker.run 'system_loadbalancer' do
  queue :loadbalancer, name: "#{RRR.config[:env]}.system.loadbalancer", durable: true
  queue :worker_start, name: "#{RRR.config[:env]}.system.worker.start", durable: true

  processes max: 1, min: 1, desirable: 1

  subscribe :loadbalancer

  def call headers, payload
    if payload['action'] == 'deploy'
      raise 'No code given' unless payload['code']

      worker = eval(payload['code'])
      worker.processes[:min].times do | index |
        queues[:worker_start].notify code: payload['code']
      end

      @workers ||= {}
      @workers[worker.name] ||= {}
      @workers[worker.name][:code] = payload['code']
    end
  end
end

