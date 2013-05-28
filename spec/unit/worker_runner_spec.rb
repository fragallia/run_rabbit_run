require 'spec_helper'
require 'tempfile'

describe 'worker' do
  context '#RRR::WorkerRunner.start' do
    it 'reports to master when worker starts and finishes its job' do
      path_to_worker_file = create_worker_file <<-EOS
        RRR::Worker.run 'name' do
          def call; end
        end
      EOS

      channel  = stub(:channel)
      exchange = stub(:exchange)

      RRR::Utils::System.stub(:ip_address).and_return('1.1.1.1')

      RRR::Amqp.stub(:channel).and_return(channel)

      channel.stub(:prefetch)
      channel.stub(:direct).and_return(exchange)

      exchange.should_receive(:publish).with("{\"message\":\"started\"}", master_default_headers)
      exchange.should_receive(:publish).with("{\"message\":\"finished\"}", master_default_headers)

      Timecop.freeze(Time.local(2000)) do
        RRR::WorkerRunner.start 'master.1', path_to_worker_file
      end
    end
  end

  context '#RRR::WorkerRunner.build' do
    it 'runs worker' do
      worker_code = <<-EOS
        RRR::Worker.run 'worker_name' do
          add_dependency 'redis', '=3.0.3'
          add_dependency 'mongo'
          add_dependency 'sinatra', git: 'git://github.com/sinatra/sinatra.git'

          queue :input
          def call; end
        end
      EOS

      File.should_receive(:exists?).with(/worker_name$/).and_return(false)
      File.should_receive(:exists?).with(/Gemfile\.lock/).and_return(false)
      File.should_receive(:exists?).with(/Gemfile\.lock/).and_return(true)

      RRR::WorkerRunner.should_receive(:`).with(/bundle install/).once
      RRR::WorkerRunner.should_receive(:`).with(/bundle exec/).once

      RRR::WorkerRunner.build :master, worker_code

      File.read("#{RRR.config[:root]}/tmp/workers/test/worker_name/worker.rb").should == worker_code
      File.read("#{RRR.config[:root]}/tmp/workers/test/worker_name/Gemfile").should   == <<-EOS
source 'https://rubygems.org'

gem 'run_rabbit_run', {:path=>"../../../../../"}
gem 'redis', "=3.0.3"
gem 'mongo'
gem 'sinatra', {:git=>"git://github.com/sinatra/sinatra.git"}
      EOS
    end

    context 'validations' do
      it 'raises exception if worker code evaluates with exception' do
        RRR.logger.should_receive(:error).with(/worker evaluates with exceptions/)

        RRR::WorkerRunner.build 'master', <<-EOS
          RRR::Worker.run 'worker_name' do
            add_dependency 'some-unreal-gem-name'
          end
        EOS
      end
      it 'raises exception if bundle install failed' do
        RRR.logger.should_receive(:error).with(/bundle install failed/)
        RRR::WorkerRunner.build 'master', <<-EOS
          RRR::Worker.run 'worker_name' do
            add_dependency 'some-unreal-gem-name'
            queue :input
            def call; end
          end
        EOS
      end
    end
  end
end

