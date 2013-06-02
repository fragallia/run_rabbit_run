require 'spec_helper'

describe 'loadbalancer' do
  let(:worker) { load_worker File.expand_path('../../../../lib/workers/loadbalancer.rb', __FILE__) }

  it 'calls push for loadbalancer' do
    RRR::Loadbalancer::Base.any_instance.should_receive(:push).with('name', 'code')

    worker.push_message(action: :push, worker_name: 'name', code: 'code')
  end

  it 'calls stats for loadbalancer' do
    RRR::Loadbalancer::Base.any_instance.should_receive(:stats).with('master_name', { "worker" => 1} )

    worker.push_message(action: :stats, stats: { worker: 1 }, name: 'master_name')
  end

  context 'validations' do
    it 'fails if action not given' do
      expect {
        worker.push_message({})
      }.to raise_error 'No action given'
    end

    context 'action #push' do
      it 'fails if code is not given' do
        expect {
          worker.push_message(action: :push, worker_name: 'name')
        }.to raise_error 'No code given'
      end

      it 'fails if worker name is not given' do
        expect {
          worker.push_message(action: :push, code: 'code')
        }.to raise_error 'No worker name given'
      end
    end

    context 'action #stats' do
      it 'fails if code is not given' do
        expect {
          worker.push_message(action: :stats, stats: 'stats')
        }.to raise_error 'No master name given'
      end

      it 'fails if worker name is not given' do
        expect {
          worker.push_message(action: :stats, name: 'name')
        }.to raise_error 'No stats given'
      end
    end
  end
end

