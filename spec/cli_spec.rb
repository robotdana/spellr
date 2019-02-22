EXE_PATH=File.expand_path('../../exe', __FILE__)
def run_command(command, &block)
  command "#{EXE_PATH}/#{command}"
  context command, &block
end
RSpec.describe 'command line' do
  run_command 'spellr --version' do
    it 'returns the version' do
      expect(subject.stdout.chomp).to eq "0.1.0"
      expect(subject.stderr).to be_empty
      expect(subject.exitstatus).to be 0
    end
  end
end
