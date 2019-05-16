# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/file'

RSpec.describe Spellr::File do
  describe '#hashbang' do
    subject { described_class.new(path) }

    around { |example| with_temp_dir { example.run } }

    context 'when it has an extension' do
      let(:path) { stub_fs_file('whatever.rb', <<~FILE) }
        #!/usr/bin/env bash

        ruby
      FILE

      it "doesn't even look at the file" do
        expect(subject.hashbang).to be_nil
      end
    end

    context "when it doesn't have an extension" do
      let(:path) { stub_fs_file('whatever', <<~FILE) }
        #!/usr/bin/env bash

        bash
      FILE

      it 'returns the hashbang' do
        expect(subject.hashbang).to eq "#!/usr/bin/env bash\n"
      end
    end
  end
end
