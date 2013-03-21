require "run_rabbit_run"

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

  namespace :worker do
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

    task :new, [ :worker_name, :worker_guid ] => [ :config ] do | t, args |
      raise 'Please specify worker name' unless args[:worker_name]
      raise 'Please specify worker guid' unless args[:worker_guid]

      require 'run_rabbit_run/processes/worker'

      options = RunRabbitRun.config[:workers][args[:worker_name].to_sym]

      RunRabbitRun::Processes::Worker.new(args[:worker_guid], options).start
    end
  end

  task :config do
    RunRabbitRun.load_config(Rake.original_dir)
  end
end
