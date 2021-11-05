require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Copier do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ copier }).should.be.instance_of Command::Copier
      end
    end
  end
end

