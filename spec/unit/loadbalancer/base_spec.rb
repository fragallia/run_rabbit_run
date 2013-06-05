require 'spec_helper'

describe 'loadbalancer base' do
  let(:queues)       { stub(:queues) }
  let(:loadbalancer) { RRR::Loadbalancer::Base.new(queues) }

  it 'saves and reloads worker' do
    worker = stub(:worker)
    RRR::Loadbalancer::Worker.should_receive(:new).with('worker_name', queues).and_return(worker)
    worker.should_receive('code=').with('code')
    worker.should_receive(:reload)

    loadbalancer.push('worker_name', 'code') 
  end

  it 'checks status for all workers' do
    worker = stub(:worker)
    worker.stub('code=')
    worker.stub(:reload)
    RRR::Loadbalancer::Worker.stub(:new).and_return(worker)

    loadbalancer.push('worker_name1', 'code') 
    loadbalancer.push('worker_name1', 'code') 
    loadbalancer.push('worker_name2', 'code') 

    worker.should_receive(:check_for_status).twice

    loadbalancer.check_status
  end
  
end

