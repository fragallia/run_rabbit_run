require 'spec_helper'

describe 'worker processes' do
  it 'takes processes config' do
    worker = RRR::Processes::Worker.run 'name' do
      processes min: 1, max: 3, desirable: 2
      def call; end
    end

    worker.processes.should == { min: 1, max: 3, desirable: 2 }
  end

  it 'sets defaults' do
    worker = RRR::Processes::Worker.run 'name' do
      def call; end
    end

    worker.processes.should == { max: 1, min: 1, desirable: 1 }
  end

  context 'validations' do
    it 'sets max to min if max is not set' do
      worker = RRR::Processes::Worker.run 'name' do
        processes min: 3
        def call; end
      end

      worker.processes.should == { max: 3, min: 3, desirable: 3 }
    end

    it 'sets desirable to min if desirable not set' do
      worker = RRR::Processes::Worker.run 'name' do
        processes min: 3
        def call; end
      end

      worker.processes.should == { max: 3, min: 3, desirable: 3 }
    end

    it 'raises error if min is bigger than max' do
      expect do
        worker = RRR::Processes::Worker.run 'name' do
          processes min: 3, max: 1
          def call; end
        end
      end.to raise_error('Max processes count cannot be smaller than min')
    end

    it 'raises error if desirable is bigger than max' do
      expect do
        worker = RRR::Processes::Worker.run 'name' do
          processes min: 2, max: 3, desirable: 4
          def call; end
        end
      end.to raise_error('Desirable processes cannot be bigger than max')
    end

    it 'raises error if desirable is smaller than min' do
      expect do
        worker = RRR::Processes::Worker.run 'name' do
          processes min: 2, max: 3, desirable: 1
          def call; end
        end
      end.to raise_error('Desirable processes cannot be smaller than min')
    end

  end
end

