# frozen_string_literal: true

require 'pathname'
require_relative 'stats'
require_relative '../backports'

class PossibleKey # rubocop:disable Metrics/ClassLength
  include Stats

  VOWELS = %i{
    a e i o u
    A E I O U
  }.freeze
  CONSONANTS = %i{
    b c d f g h j k l m n p q r s t v w x y z
    B C D F G H J K L M N P Q R S T V W X Y Z
  }.freeze
  BASE_64 = VOWELS + CONSONANTS + %i{0 1 2 3 4 5 6 7 8 9 - _ + / =}.freeze
  LETTER_COUNT_HASH = BASE_64.map { |k| [k.to_sym, 0] }.to_h
  FEATURE_LETTERS = %i{+ - _ / A z Z q Q X x}.freeze

  class << self
    def keys
      @keys ||= begin
        load_from_file('false_positives.txt', false) +
          load_from_file('keys.txt', true)
      end
    end

    private

    def load_from_file(filename, key)
      Pathname.new(__dir__).join('data', filename).each_line.map! do |line|
        line = line.chomp
        next if line.empty?

        PossibleKey.new(line, key)
      end.compact
    end
  end

  attr_reader :string

  def initialize(string, key = nil)
    @string = string
    @key = key
  end

  def features # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    {
      **letter_frequency_difference_features,
      equal: letter_count[:'='],
      length: length,
      hex: character_set == :hex ? 1 : 0,
      lower36: character_set == :lower36 ? 1 : 0,
      upper36: character_set == :upper36 ? 1 : 0,
      base64: character_set == :base64 ? 1 : 0,
      mean_title_chunk_size: mean(title_chunks, &:length),
      variance_title_chunk_size: variance(title_chunks, &:length),
      max_title_chunk_size: max(title_chunks, &:length),
      mean_lower_chunk_size: mean(lower_chunks, &:length),
      variance_lower_chunk_size: variance(lower_chunks, &:length),
      mean_upper_chunk_size: mean(upper_chunks, &:length),
      variance_upper_chunk_size: variance(upper_chunks, &:length),
      mean_alpha_chunk_size: mean(alpha_chunks, &:length),
      variance_alpha_chunk_size: variance(alpha_chunks, &:length),
      mean_alnum_chunk_size: mean(alnum_chunks, &:length),
      variance_alnum_chunk_size: variance(alnum_chunks, &:length),
      mean_digit_chunk_size: mean(digit_chunks, &:length),
      variance_digit_chunk_size: variance(digit_chunks, &:length),
      vowel_consonant_ratio: vowel_consonant_ratio,
      alpha_chunks: alpha_chunks.length,
      alnum_chunks: alnum_chunks.length,
      digit_chunks: digit_chunks.length,
      title_chunks: title_chunks.length,
      mean_letter_frequency_difference: mean(letter_frequency_difference.values),
      variance_letter_frequency_difference: max(letter_frequency_difference.values)
    }
  end

  def key?
    @key
  end

  def classification
    key_class = key? ? 'key' : 'not_key'
    "#{key_class}_#{character_set}"
  end

  def length
    string.length
  end

  def letter_frequency_difference_features
    letter_frequency_difference.slice(*FEATURE_LETTERS)
  end

  def character_set # rubocop:disable Metrics/MethodLength
    @character_set ||= case string
    when /^[a-fA-F0-9\-]+$/ then :hex
    when /^[a-z0-9]+$/ then :lower36
    when /^[A-Z0-9]+$/ then :upper36
    when %r{^[A-Za-z0-9\-_+/]+={0,2}$} then :base64
    else
      raise "#{string.inspect} is an unrecognised character set"
    end
  end

  def character_set_total # rubocop:disable Metrics/MethodLength
    case character_set
    when :hex then 16
    when :lower36 then 36
    when :upper36 then 36
    when :base64 then 64
    end
  end

  def ideal_letter_frequency
    1.0 / character_set_total * length
  end

  def letter_count
    @letter_count ||= begin
      string.chars.each_with_object(LETTER_COUNT_HASH.dup) do |letter, hash|
        hash[letter.to_sym] += 1
      end
    end
  end

  def letter_frequency
    @letter_frequency ||= begin
      l = letter_count.dup
      l.each { |k, v| l[k] = v.to_f / string.length }
      l
    end
  end

  def letter_frequency_difference
    @letter_frequency_difference ||= begin
      l = letter_frequency.dup
      l.each { |k, v| l[k] = (v - ideal_letter_frequency).abs }
      l
    end
  end

  def vowel_consonant_ratio
    vowels = letter_count.fetch_values(*VOWELS).sum
    consonants = letter_count.fetch_values(*CONSONANTS).sum
    vowels / (consonants.nonzero? || 1)
  end

  def digit_chunks
    @digit_chunks ||= string.scan(/\d+/)
  end

  def title_chunks
    @title_chunks ||= string.scan(/[A-Z][a-z]+/)
  end

  def lower_chunks
    @lower_chunks ||= string.scan(/[a-z]+/)
  end

  def upper_chunks
    @upper_chunks ||= string.scan(/[A-Z]+/)
  end

  def alpha_chunks
    @alpha_chunks ||= string.scan(/[A-Za-z]+/)
  end

  def alnum_chunks
    @alnum_chunks ||= string.scan(/[A-Za-z0-9]+/)
  end
end
