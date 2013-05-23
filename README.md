# RunRabbitRun

git@github.com:fragallia/run_rabbit_run.git

## Installation

Add this line to your application's Gemfile:

    gem 'run_rabbit_run'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install run_rabbit_run

## Usage


### Including the rake tasks

Require the rake tasks in your **Rakefile**

    require "run_rabbit_run/tasks"

#### Rake tasks

```console
RAKE_ENV=production bundle exec rake rrr:start
```

Starts the master process and it starts all worker processes for **production** environment (default is **development**).

```console
bundle exec rake rrr:stop
```

Stops the master process. Master process sends **QUIT** signal to workers and waits for 5 seconds. If processes are still running the master kills them.

```console
bundle exec rake rrr:reload
```

Master stops all workers and then starts the profile again.

```console
bundle exec rake rrr:worker:add[worker_name]
```

Master runs new process for given worker.

```console
bundle exec rake rrr:worker:remove[worker_name]
```

Master stops one worker process.

### Configuration

you need to create __config/rrr.rb__ file to set your config variables

```ruby
log "log/run_rabbit_run.log"
pid "tmp/pids/run_rabbit_run.pid"

worker :worker1, 'workers/worker_name_1.rb', processes: 0
worker :worker2, 'workers/worker_name_2.rb', processes: 2
worker :worker3, 'workers/worker_name_3.rb', processes: 1
```

* **log** sets path to log file
* **pid** sets path to pid file
* **worker** sets settings for worker. The first argument is the worker name. The second argument is the path to the worker ruby file. And you can pass options as a third parameter. The **processes** option sets the process count for worker, default is 1. If process count is 0 then no processes will be run, you can run the process by `bundle exec rake rrr:worker:add[worker_name]`.

Another config file you need to create is configuration file for environment eg. **config/rrr/development.rb** or **config/rrr/production.rb**

```ruby
run :worker1, :worker2

```
**run** points the workers which will be run for the environment. In this case it will run only `worker1` and `worker2` but exlude the `worker3`.

### Creating worker

This is the "Hello world" worker. It creates **test_queue**, sends simple message to this queue, subscribes to the same queue and prints it into log file.

```ruby
test_queue = channel.queue('test_queue', auto_delete: false)

publish(test_queue, {some: 'data'})

subscribe(test_queue) do | header, data |
  RRR.logger.info data.inspect
end
```

Sometimes we need to have workers which does something and shuts down. For example send some messages and end the process. It is possible if you set `processes` to **0** for the worker in config file. If the `processes` count is set to number bigger than **0** then master will run the process again after it finishes. 

__config/rrr.rb__

```ruby
# ... some code
worker :worker1, 'workers/worker_name_1.rb', processes: 0
# ... some code
```
__workers/worker_name_1.rb__

```ruby
test_queue = channel.queue('test_queue', auto_delete: false)

publish(test_queue, {some: 'data'})
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
