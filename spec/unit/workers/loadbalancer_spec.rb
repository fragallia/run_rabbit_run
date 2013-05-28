require 'spec_helper'

describe 'loadbalancer' do
  let(:worker) { load_worker File.expand_path('../../../../lib/workers/loadbalancer.rb', __FILE__) }

  context 'action #deploy' do
    it 'fails if code is not given' do
      worker.push_message(action: :deploy)

      worker.logger_messages.should == [ [ :error, 'No code given' ] ]
    end

    it 'starts minimum amount of processes' do
      worker_code = <<-EOS
        RRR::Worker.run 'name' do
          processes min: 3
          def call; end
        end
      EOS
      worker.push_message(action: :deploy, code: worker_code )

      worker.logger_messages.should be_empty
      worker.sent_messages.first.should == { queue: :worker_start, message: { code: worker_code } }
      worker.sent_messages.count.should == 3
    end

    it 'saves the worker code and instance' do
      worker_code = <<-EOS
        RRR::Worker.run 'name' do
          def call; end
        end
      EOS
      worker.push_message(action: :deploy, code: worker_code )

      workers = worker.instance_variable_get('@workers')

      workers.size.should == 1
      workers['name'][:code].should == worker_code
      workers['name'][:instance].should be_a(RRR::Worker::Base)
      workers['name'][:instance].name.should == 'name'
    end
  end
end

