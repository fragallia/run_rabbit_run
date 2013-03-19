require 'run_rabbit_run'

#TODO working_directory '/path/to/working/directory'

log "log/run_rabbit_run.log"
pid "tmp/pids/run_rabbit_run.pid"

worker :worker1, 'workers/worker_name_1.rb', processes: 1 #TODO, process_count_max: 6

worker :worker2, 'workers/worker_name_2.rb' do
  name 'Worker name 2'
  log_to_master true

  processes 2

  #TODO processes_max 7
end
