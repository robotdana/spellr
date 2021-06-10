# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/spellr/tokenizer'

RSpec::Matchers.define :have_tokens do |*expected|
  match do |actual|
    @actual = ::Spellr::Tokenizer.new(::StringIO.new(actual)).terms
    expect(@actual).to match(expected)
  end

  diffable
end
RSpec::Matchers.alias_matcher :have_no_tokens, :have_tokens

RSpec::Matchers.define :have_token_positions do |*expected|
  match do |actual|
    @actual = Spellr::Tokenizer.new(::StringIO.new(actual)).map(&:coordinates)
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

    xit 'tracks newlines of different line ending styles \n,\r' do
      expect("first line\n\rthird line").to have_token_positions [1, 0], [1, 6], [3, 0], [3, 6]
    end

    it 'tracks newlines with nonsense at the beginning' do
      expect("!first line\n!second line").to have_token_positions [1, 1], [1, 7], [2, 1], [2, 8]
    end

    it 'tracks newlines with nonsense at the end' do
      expect("!first line!\n!second line!").to have_token_positions [1, 1], [1, 7], [2, 1], [2, 8]
    end

    it 'tracks newlines with a whole line of nonsense' do
      expect("!first line!\n!!!!!\n!second line!")
        .to have_token_positions [1, 1], [1, 7], [3, 1], [3, 8]
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
      expect('read this http://google.com, and this http://apple.com')
        .to have_tokens 'read', 'this', 'and', 'this'
    end

    it 'excludes URLs with a query string' do
      expect('query https://the-google.com?query-string=whatever%2Bthing').to have_tokens 'query'
    end

    it 'excludes URLs with a query string and a root path' do
      expect('query https://the-google.com/?query-string=whatever%2Bthing').to have_tokens 'query'
    end

    it 'excludes URLs with underscores in the path' do
      expect('https://external.xx.fbcdn.net/safe_image.php').to have_no_tokens
    end

    it 'excludes URLs with underscore and dash in the query string' do
      expect('https://external.xx.fbcdn.net/?safe_image-suffix&safe_image-suffix.php')
        .to have_no_tokens
    end

    it 'excludes URLs with tilde in the path' do
      expect('https://www.in-ulm.de/~mascheck/various/shebang').to have_no_tokens
    end

    it 'excludes URLs with backslash escaped characters' do
      expect('https://external.xx.fbcdn.net/safe_image.php?url=https\\u00253A\\u00252F\\u00252F')
        .to have_no_tokens
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

    it 'excludes hex codes' do
      expect('#bac 0xfed').to have_no_tokens
    end

    it 'excludes naked hex codes heuristically' do
      expect('bac1fed').to have_no_tokens
    end

    it 'excludes url encoded things' do
      expect('search%5Baccount_type').to have_tokens 'search', 'account', 'type'
    end

    it "doesn't exclude hex codes that are just part of words" do
      expect('#background').to have_tokens 'background'
    end

    it 'can configure how short a short word is' do
      stub_config(word_minimum_length: 2)

      expect('to be or not to be').to have_tokens 'to', 'be', 'or', 'not', 'to', 'be'
    end

    it 'excludes URLs with numbers in them' do
      expect('http://www.the4wd.com').to have_no_tokens
    end

    it 'excludes URLs with @ in the path' do
      expect('https://medium.com/@jessebeach/beware-smushed-off-screen-accessible-text-5952a4c2cbfe')
        .to have_no_tokens
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
      expect("Didn't shouldn't could've o'clock")
        .to have_tokens "Didn't", "shouldn't", "could've", "o'clock"
    end

    it 'excludes wrapping quotes' do
      expect(%{"Didn't" 'shouldn't' <could've> 'o'clock'})
        .to have_tokens "Didn't", "shouldn't", "could've", "o'clock"
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

    it 'splits single-letter camel case' do
      expect('MAssetUploader').to have_tokens 'Asset', 'Uploader'
    end

    it "excludes 's after all caps" do
      expect("DVD's and URI's").to have_tokens 'DVD', 'and', 'URI'
    end

    it 'excludes sole s after all caps' do
      expect('DVDs and URIs').to have_tokens 'DVD', 'and', 'URI'
    end

    it 'excludes tokens that look like keys' do
      expect('a0bcdefA12g2ABhAibCjA0DEFGjkHIJlKLmMnNOopqR1r012Ss').to have_no_tokens
      expect('AB/abcABCa0abAaABC0bAaABaABC').to have_no_tokens
      expect('SG.AAaA0a0AAA0a_aaA00a0aa.00AaaaaAAAA0AAAAAAaAAAAAA0aAa0aaaAAAaa0AAAA')
        .to have_no_tokens
      expect('xy1xy2xy3').to have_no_tokens

      # long things like this are never going to be words
      expect('long1' * 41).to have_no_tokens
    end

    it 'excludes from the token escape code characters' do
      expect('\never \rate /\Atheist\Seat/ \there')
        .to have_tokens 'ever', 'ate', 'theist', 'eat', 'here'
    end

    it 'excludes the color escape code character' do
      expect('\033[0mother \e[36;1meat').to have_tokens 'other', 'eat'
    end

    it 'excludes terms between spellr:disable and spellr:enable' do
      expect('this spellr:disable and spellr:enable that').to have_tokens 'this', 'that'
    end

    it 'excludes whole line with spellr:disable-line' do
      expect('this spellr:disable-line and that').to have_no_tokens
      expect('spellr:disable-line this and that').to have_no_tokens
      expect('this and that spellr:disable-line').to have_no_tokens
    end

    it 'excludes whole line with spellr:disable:line' do
      expect('this spellr:disable:line and that').to have_no_tokens
      expect('spellr:disable:line this and that').to have_no_tokens
      expect('this and that spellr:disable:line').to have_no_tokens
    end

    it 'excludes terms between spellr:disable and spellr:enable across multiple lines' do
      expect("this\nspellr:disable\nand\nspellr:enable\nthat").to have_tokens 'this', 'that'
    end
  end
end
