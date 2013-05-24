require "run_rabbit_run"

namespace :rrr do
  desc 'kills all processes with the name RunRabbitRun only on UNIX'
  task :kill do
    system("kill `ps -ef | grep ruby.rrr | grep -v grep | awk '{print $2}'`")
  end

  desc 'delete all of the queues'
  task :reset do
    `rabbitmqctl stop_app`
    `rabbitmqctl reset`
    `rabbitmqctl start_app`
  end

  desc 'Starts master'
  task start: [ :config ] do | t, args |
    RRR::MasterRunner.start
  end

  desc 'Stops master'
  task stop: [ :config ] do | t, args |
    RRR::MasterRunner.stop
  end

  namespace :worker do
    desc 'Sends command to the master to start the worker'
    task :start, [ :path ] => [ :config ] do | t, args |
      raise 'Please specify path to worker' unless args[:path]
      worker_code = File.read(args[:path])
      EM.run do
        RRR::Amqp.start
        queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.new", durable: true)
        queue.notify( code: worker_code ) do
          RRR::Amqp.stop(0)
        end
      end
    end

    desc 'Sends command to the master to stop the worker'
    task :stop, [ :name ] => [ :config ] do | t, args |
      raise 'Please specify name for worker' unless args[:name]
      EM.run do
        RRR::Amqp.start
        queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.destroy", durable: true)
        queue.notify( name: args[:name] ) do
          RRR::Amqp.stop(0)
        end
      end
    end

    desc 'Runs the worker for master'
    task :run, [ :master_name, :path ] => [ :config ] do | t, args |
      raise 'Please specify master_name' unless args[:master_name]
      raise 'Please specify path to worker' unless args[:path]
      RRR::WorkerRunner.start(args[:master_name], args[:path])
    end

  end

  task :config do
    RRR.load_config(Rake.original_dir)
  end
end
