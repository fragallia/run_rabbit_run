require 'run_rabbit_run'

#TODO stderr_path "log/run_rabbit_run.stderr.log"
#TODO stdout_path "log/run_rabbit_run.stdout.log"
#TODO working_directory '/path/to/working/directory'

pid "tmp/pids/run_rabbit_run.pid"

worker :worker1, 'workers/worker_name_1.rb' #TODO , process_count_min: 0, process_count_max: 6

worker :worker2, 'workers/worker_name_2.rb' do
  name 'Worker name 2'
  #TODO set :process_count_min, 1
  #TODO set :process_count_max, 7
end
