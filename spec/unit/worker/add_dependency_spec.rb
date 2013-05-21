require 'spec_helper'

describe 'worker add_dependency' do
  it 'sets dependency for the worker' do
    worker = RRR::Worker.run 'name' do
      add_dependency 'name1', some: :params 
      add_dependency 'name2', some: :params 
      add_dependency 'name3'

      def call; end
    end

    worker.dependencies.should == {
      'name1' => [ { some: :params } ],
      'name2' => [ { some: :params } ],
      'name3' => [ ]
    }
  end
end

