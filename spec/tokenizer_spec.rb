# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/tokenizer'

RSpec::Matchers.define :have_tokens do |*expected|
  match do |actual|
    @actual = Spellr::Tokenizer.new(actual).tokenize.map(&:to_s)
    expect(@actual).to match(expected)
  end

  diffable
end
RSpec::Matchers.alias_matcher :have_no_tokens, :have_tokens

RSpec::Matchers.define :have_token_positions do |*expected|
  match do |actual|
    @actual = Spellr::Tokenizer.new(actual).tokenize.map(&:coordinates)
    expect(@actual).to match(expected)
  end

  diffable
end

RSpec.describe Spellr::Tokenizer do
  describe '#positions' do
    it 'tracks newlines' do
      expect("first line\nsecond line").to have_token_positions [1, 0], [1, 6], [2, 0], [2, 7]
    end

    it 'tracks newlines of only blank lines' do
      expect("first line\n\nsecond line").to have_token_positions [1, 0], [1, 6], [3, 0], [3, 7]
    end

    it 'tracks newlines of different line ending styles \r\n' do
      expect("first line\r\nsecond line").to have_token_positions [1, 0], [1, 6], [2, 0], [2, 7]
    end

    it 'tracks newlines of different line ending styles \n,\r' do
      expect("first line\n\rsecond line").to have_token_positions [1, 0], [1, 6], [3, 0], [3, 7]
    end

    it 'tracks newlines with nonsense at the beginning' do
      expect("!first line\n!second line").to have_token_positions [1, 1], [1, 7], [2, 1], [2, 8]
    end

    it 'tracks newlines with nonsense at the end' do
      expect("!first line!\n!second line!").to have_token_positions [1, 1], [1, 7], [2, 1], [2, 8]
    end

    it 'tracks newlines with a whole line of nonsense' do
      expect("!first line!\n!!!!!\n!second line!").to have_token_positions [1, 1], [1, 7], [3, 1], [3, 8]
    end
  end

  describe '#tokens' do
    it 'splits tokens by spaces' do
      expect('This line').to have_tokens 'This', 'line'
    end

    it 'splits tokens by :' do
      expect('Spellr::Line').to have_tokens 'Spellr', 'Line'
    end

    it 'excludes URLs' do
      expect('click here https://google.com').to have_tokens 'click', 'here'
    end

    it 'excludes URLs in parentheses' do
      expect('[link](ftp://example.org)').to have_tokens 'link'
    end

    it 'excludes URLs in angle brackets' do
      expect('Dave <dave@example.com>').to have_tokens 'Dave'
    end

    it 'excludes URLs when followed by punctuation' do
      expect('read this http://google.com, and this http://apple.com').to have_tokens 'read', 'this', 'and', 'this'
    end

    it 'excludes URLs with a query string' do
      expect('query https://the-google.com?query-string=whatever%2Bthing').to have_tokens 'query'
    end

    it 'excludes URLs with paths and no scheme' do
      expect('whatever.com/whatever').to have_no_tokens
    end

    it "doesn't exclude only hostnames because they could be method chains" do
      expect('whatever.com(this)').to have_tokens 'whatever', 'com', 'this'
      expect('whatever.co.nz(this)').to have_tokens 'whatever', 'this'
    end

    it 'excludes localhost without any tlds' do
      expect('localhost:80/whatever').to have_no_tokens
    end

    it 'excludes IP URLs' do
      expect('127.0.0.1:80/whatever').to have_no_tokens
    end

    it 'excludes URLs with no scheme' do
      expect('click here //google.com').to have_tokens 'click', 'here'
    end

    it "doesn't excludes things just starting with //" do
      expect('this//that').to have_tokens('this', 'that')
    end

    it 'excludes mailto: email links' do
      expect('href="mailto:robot@dana.sh"').to have_tokens 'href'
    end

    it 'excludes emails' do
      expect('send here: robot@dana.sh').to have_tokens 'send', 'here'
    end

    it 'excludes short words' do
      expect('to be or not to be').to have_tokens 'not'
    end

    it 'can configure how short a short word is' do
      stub_config(word_minimum_length: 2)

      expect('to be or not to be').to have_tokens 'to', 'be', 'or', 'not', 'to', 'be'
    end

    it 'excludes URLs with numbers in them' do
      expect('http://www.the4wd.com').to have_no_tokens
    end

    it 'excludes numbers only' do
      expect('3.14 100 4,000').to have_no_tokens
    end

    it 'excludes maths only' do
      expect('1+1 1/2 10>4 15-10').to have_no_tokens
    end

    it 'tokenizes html tags' do
      expect('<a style="background: red">').to have_tokens 'style', 'background', 'red'
    end

    it 'excludes CSS colours' do
      expect('color: #fee; background: #fad').to have_tokens 'color', 'background'
    end

    it "doesn't split on apostrophes" do
      expect("Didn't shouldn't could've o'clock").to have_tokens "Didn't", "shouldn't", "could've", "o'clock"
    end

    it 'excludes wrapping quotes' do
      expect(%{"Didn't" 'shouldn't' <could've> 'o'clock'}).to have_tokens "Didn't", "shouldn't", "could've", "o'clock"
    end

    it 'splits on underscore' do
      expect('this_that_the_other').to have_tokens 'this', 'that', 'the', 'other'
    end

    it 'splits on underscore when all caps' do
      expect('SCREAMING_SNAKE_CASE').to have_tokens 'SCREAMING', 'SNAKE', 'CASE'
    end

    it 'splits on dashes' do
      expect('align-items:center').to have_tokens 'align', 'items', 'center'
    end

    it 'splits on dashes in all caps' do
      expect('CAPS-WITH-DASHES').to have_tokens 'CAPS', 'WITH', 'DASHES'
    end

    it 'splits on camel case' do
      expect('CamelCase littleBig').to have_tokens 'Camel', 'Case', 'little', 'Big'
    end

    it 'splits on camel case with all caps' do
      expect('HTTParty GoogleAPI').to have_tokens 'HTT', 'Party', 'Google', 'API'
    end

    it "excludes 's" do
      expect("do's and don't's").to have_tokens 'and', "don't"
    end

    it "excludes 'S with all caps" do
      expect("DO'S AND DON'T'S").to have_tokens 'AND', "DON'T"
    end

    it "excludes 's with all camel case" do
      expect("TheThing's").to have_tokens 'The', 'Thing'
    end

    it "excludes 's after all caps" do
      expect("DVD's and URI's").to have_tokens 'DVD', 'and', 'URI'
    end

    it 'excludes sole s after all caps' do
      expect('DVDs and URIs').to have_tokens 'DVD', 'and', 'URI'
    end

    it 'excludes tokens that look like keys' do
      expect('a0abcdeA12a2ABaAabAaA0ABCDEaABCaABaAaABabcA1a012Aa').to have_no_tokens
    end
  end

  # spellr:disable
  xdescribe '#subwords' do
    it 'returns nothing for the shortest word' do
      expect('foo').to have_no_subwords
    end

    it 'returns nothing for the just slightly longer than the shortest word' do
      expect('food').to have_no_subwords
    end

    it 'splits once for double the shortest word' do
      expect('foobar').to have_subwords %w{foo bar}
    end

    it 'has both splitting points for just slightly longer than double the shortest word' do
      expect('foodbar').to have_subwords %w{food bar}, %w{foo dbar}
    end

    it 'splits into three for three times the longest word, and also has all possible pairs' do
      expect('foobarbaz').to have_subwords %w{foo bar baz}, %w{foob arbaz}, %w{fooba rbaz},
        %w{foobar baz}, %w{foo barbaz}
    end

    it 'just keeps going' do
      expect('foobarbazz').to have_subwords %w{foo barbazz}, %w{foo bar bazz}, %w{foo barb azz},
        %w{foob arbazz}, %w{foob arb azz}, %w{fooba rbazz}, %w{foobar bazz}, %w{foobarb azz}
    end
  end
  # spellr:enable
end
