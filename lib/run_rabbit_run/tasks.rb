require "run_rabbit_run"
require 'bunny'

namespace :rrr do
  desc 'Starts profile workers'
  task start: [ :config ] do
    RunRabbitRun::Master.start
  end

  desc 'Stops profile workers'
  task stop: [ :config ] do
    RunRabbitRun::Master.stop
  end

  desc 'Reloads config, stops old workers and runs new with new config'
  task reload: [ :config ] do
    RunRabbitRun::Master.reload
  end

  desc 'kills all processes with the name RunRabbitRun only on UNIX'
  task :kill_workers do
    system("kill `ps -ef | grep RunRabbitRun | grep -v grep | awk '{print $2}'`")
  end

  desc 'delete all of the queues'
  task :reset do
    `rabbitmqctl stop_app`
    `rabbitmqctl reset`
    `rabbitmqctl start_app`
  end

  namespace :master do
    desc 'Starts master'
    task start: [ :config ] do | t, args |
      RRR::MasterRunner.start
    end

    desc 'Stops master'
    task stop: [ :config ] do | t, args |
      RRR::MasterRunner.stop
    end
  end

  namespace :worker do
    desc 'Sends command to the master to start the worker'
    task :start, [ :path ] => [ :config ] do | t, args |
      raise 'Please specify path to worker' unless args[:path]
      worker_code = File.read(args[:path])
      EM.run do
        RRR::Amqp.start
        queue = RRR::Amqp::Queue.new("#{RunRabbitRun.config[:environment]}.system.worker.new", durable: true)
        queue.notify( code: worker_code ) do
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

    desc 'Adds one process for given worker'
    task :add, [ :worker_name ] => [ :config ] do | t, args |
      raise 'Please specify worker name' unless args[:worker_name]
      RunRabbitRun::Master.add_worker(args[:worker_name])
    end

    desc 'Stops one process for given worker'
    task :remove, [ :worker_name ] => [ :config ] do | t, args |
      raise 'Please specify worker name' unless args[:worker_name]
      RunRabbitRun::Master.remove_worker(args[:worker_name])
    end

    task :new, [ :worker_name, :worker_guid, :master_guid ] => [ :config ] do | t, args |
      raise 'Please specify worker name' unless args[:worker_name]
      raise 'Please specify worker guid' unless args[:worker_guid]
      raise 'Please specify worker guid' unless args[:master_guid]

      require 'run_rabbit_run/processes/worker'

      options = RunRabbitRun.config[:workers][args[:worker_name].to_sym]

      RunRabbitRun::Processes::Worker.new(args[:worker_guid], args[:master_guid], options).start
    end
  end

  task :config do
    RunRabbitRun.load_config(Rake.original_dir)
  end
end
