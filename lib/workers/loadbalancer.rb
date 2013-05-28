#TODO
# 1. Queues : use name parameter as rabbitmq queue name if it exists.
# 2. Write tests for the loadbalancer worker
# 3. Optimize tests to have standart helpers for the worker
# 4. Optimize rake tasks to be able to run whole system with one command

RRR::Worker.run 'system_loadbalancer' do
  queue "#{RRR.config[:env]}.system.loadbalancer", durable: true
  queue "#{RRR.config[:env]}.system.worker.start", durable: true

  processes max: 1, min: 1, desirable: 1

  subscribe "#{RRR.config[:env]}.system.loadbalancer" 

  def call headers, payload
    if payload['action'] == 'deploy'
      raise 'No code given' unless payload['code']

      worker = eval(payload['code'])
      worker.processes[:min].times do | index |
        queues["#{RRR.config[:env]}.system.worker.start"].notify code: payload['code']
      end

      @workers ||= {}
      @workers[worker.name] ||= {}
      @workers[worker.name][:code] = payload['code']
    end
  end
end

