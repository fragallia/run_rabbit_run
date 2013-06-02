require 'spec_helper'

describe 'loadbalancer worker' do
  let(:queues) { stub(:queues) }

  it 'reloads the worker when set the code' do
    worker = RRR::Loadbalancer::Worker.new('worker_name', queues)
    worker.code = <<-EOS
      RRR::Processes::Worker.run 'worker_name_2' do
        queue "queue1", durable: true
        def call; end
      end
    EOS

    worker.worker.processes[:min].should == 1

    worker.code = <<-EOS
      RRR::Processes::Worker.run 'worker_name_2' do
        queue "queue1", durable: true
        processes min: 5
        def call; end
      end
    EOS

    worker.worker.processes[:min].should == 5
  end

end

