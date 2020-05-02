# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/file'

RSpec.describe Spellr::File do
  describe '#first_line' do
    subject { described_class.new(path) }

    before { with_temp_dir }

    let(:path) { stub_fs_file('whatever.rb', <<~FILE) }
      #!/usr/bin/env bash

      ruby
    FILE

    it 'is memoized' do
      expect(::File).to receive(:new).once.and_call_original

      expect(subject.first_line).to start_with "#!/usr/bin/env bash\n"
      expect(subject.first_line).to start_with "#!/usr/bin/env bash\n"
    end
  end
end
