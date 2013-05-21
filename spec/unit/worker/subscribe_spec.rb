require 'spec_helper'

describe 'worker subscribe' do
  it 'sets subscription options' do
    worker = RRR::Worker.run 'name' do
      subscribe :input, ack: true
      def call; end
    end

    worker.instance_variable_get("@subscribe").should == { queue: :input, options: { ack: true } }
  end

  context 'invalid setup' do
    it 'raises error if there are another subscribe statement' do
      expect {
        RRR::Worker.run 'name' do
          subscribe :input1, ack: true
          subscribe :input2, ack: true
          def call; end
        end
      }.to raise_error('You can subscribe only to one queue')
    end
  end
end

