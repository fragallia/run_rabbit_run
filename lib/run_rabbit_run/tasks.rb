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

  task :config do
    RunRabbitRun.load_config(Rake.original_dir)
  end
end
