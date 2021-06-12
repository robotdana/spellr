# frozen_string_literal: true

require_relative 'wordlist_reporter'
require_relative 'output_stubbed'
require_relative 'file_list'
require_relative 'check_parallel'
require_relative 'string_format'
require_relative 'reporter'

module Spellr
  class Prune
    class << self
      def run
        prunable_wordlists.each do |wordlist|
          prune_wordlist(wordlist)
        end

        0
      end

      private

      def prune_wordlist(wordlist)
        report_start(wordlist)
        prepare_wordlist(wordlist)

        reporter = check_with_independent_reporter
        report_pruned_count(wordlist, reporter)
        update_wordlist(wordlist, reporter)
      end

      def prepare_wordlist(wordlist)
        wordlist.force_nonexistence
      end

      def check_with_independent_reporter
        reporter = ::Spellr::WordlistReporter.new(Spellr::OutputStubbed.new)
        ::Spellr.config.checker.new(files: files, reporter: reporter).check
        reporter
      end

      def update_wordlist(wordlist, reporter)
        if reporter.words.empty?
          wordlist.delete
        elsif reporter.words.length < wordlist.length
          wordlist.write(reporter.words.sort.join)
        end
      end

      def report_start(wordlist)
        print "pruning: #{wordlist.path.basename}"
      end

      def report_pruned_count(wordlist, reporter)
        wordlist.clear_cache
        count = wordlist.length - reporter.words.length

        puts "\rpruned: #{wordlist.path.basename} #{StringFormat.pluralize('word', count)} removed"
      end

      def puts(string)
        ::Spellr.config.output.puts(string)
      end

      def print(string)
        ::Spellr.config.output.print(string)
      end

      def prunable_wordlists
        Spellr.config.languages.select { |l| l.project_wordlist.exist? }.sort_by do |language|
          files.count { |file| language.matches?(file) }
        end.reverse.map(&:project_wordlist)
      end

      def files
        @files ||= Spellr::FileList.new
      end
    end
  end
end
