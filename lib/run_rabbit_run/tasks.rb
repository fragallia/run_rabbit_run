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

  desc 'Starts master and system workers'
  task boot: [ :config ] do | t, args |
    Rake::Task["rrr:start"].execute
    Rake::Task["rrr:worker:start"].execute(Rake::TaskArguments.new([:path], [ 'lib/workers' ]))
  end

  namespace :worker do
    desc 'Sends command to the master to start the worker'
    task :start, [ :path ] => [ :config ] do | t, args |
      raise 'Please specify path to worker(s)'   unless args[:path]
      raise 'Path you giving is not existing' unless File.exists? args[:path]
      files = File.directory?(args[:path]) ? Dir["#{args[:path]}/**/*.rb"] : [ args[:path] ]

      EM.run do
        RRR::Amqp.start
        queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.start", durable: true)

        send_message = Proc.new do
          file = files.shift
          if file
            puts "Starting [#{file}]"
            queue.notify( code: File.read(file), &send_message )
          else
            RRR::Amqp.stop(0)
          end
        end

        send_message.call
      end
    end

    desc 'Sends worker code to the loadbalancer'
    task :deploy, [ :path ] => [ :config ] do | t, args |
      raise 'Please specify path to worker(s)'   unless args[:path]
      raise 'Path you giving is not existing' unless File.exists? args[:path]
      files = File.directory?(args[:path]) ? Dir["#{args[:path]}/**/*.rb"] : [ args[:path] ]

      EM.run do
        RRR::Amqp.start
        queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.loadbalancer", durable: true)

        send_message = Proc.new do
          file = files.shift
          if file
            puts "Sending [#{file}]"
            queue.notify( action: :deploy, code: File.read(file), &send_message )
          else
            RRR::Amqp.stop(0)
          end
        end

        send_message.call
      end
    end

    desc 'Sends command to the master to stop the worker'
    task :stop, [ :name ] => [ :config ] do | t, args |
      raise 'Please specify name for worker' unless args[:name]
      EM.run do
        RRR::Amqp.start
        queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.stop", durable: true)
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
