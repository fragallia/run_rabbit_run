require 'spec_helper'

describe 'worker settings' do
  it 'takes settings config' do
    worker = RRR::Processes::Worker.run 'name' do
      settings queue_size: 10, prefetch: 1, capacity: 5
      def call; end
    end

    worker.settings.should == { queue_size: 10, prefetch: 1, capacity: 5 }
  end

  it 'sets defaults' do
    worker = RRR::Processes::Worker.run 'name' do
      def call; end
    end

    worker.settings.should == { queue_size: 250, prefetch: 10, capacity: 10 }
  end

  context 'validations' do

    it 'raises error if capacity is zero and smaller' do
      expect do
        worker = RRR::Processes::Worker.run 'name' do
          settings capacity: 0
          def call; end
        end
      end.to raise_error('Capacity can\'t be zero or less')
    end

    it 'raises error if capacity is bigger than 100' do
      expect do
        worker = RRR::Processes::Worker.run 'name' do
          settings capacity: 101
          def call; end
        end
      end.to raise_error('Capacity can\'t be bigger than 100')
    end

    it 'raises error if queue size is smaller than 1' do
      expect do
        worker = RRR::Processes::Worker.run 'name' do
          settings queue_size: 0
          def call; end
        end
      end.to raise_error('Queue size cannot be smaller than 1')
    end

    it 'raises error if prefetch is smaller than 1' do
      expect do
        worker = RRR::Processes::Worker.run 'name' do
          settings prefetch: 0
          def call; end
        end
      end.to raise_error('Prefetch cannot be smaller than 1')
    end
  end
end

