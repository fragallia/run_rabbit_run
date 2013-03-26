#TODO working_directory '/path/to/working/directory'

log "log/run_rabbit_run.log"
pid "tmp/pids/run_rabbit_run.pid"

worker :worker1, 'workers/worker_name_1.rb', processes: 1

worker :worker2, 'workers/worker_name_2.rb' do
  name 'Worker name 2'
  log_to_master true

  processes 1
end

worker :worker3, 'workers/worker_name_3.rb', processes: 0
