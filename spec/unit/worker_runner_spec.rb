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

      exchange = stub(:exchange)
      RRR::Amqp::System.any_instance.stub(:exchange).and_return(exchange)
      exchange.should_receive(:publish).with("{\"message\":\"started\"}", master_default_headers)
      exchange.should_receive(:publish).with("{\"message\":\"finished\"}", master_default_headers)

      Timecop.freeze(Time.local(2000)) do
        RRR::WorkerRunner.start 'master.1', path_to_worker_file
      end
    end
  end
end

