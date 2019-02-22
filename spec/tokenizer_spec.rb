RSpec.describe Spellr::Line do
  it 'returns tokens split by spaces' do
    tokens = described_class.new("This line").tokenize
    expect(tokens.map(&:to_s)).to eq ["This", "line"]
  end

  it 'returns tokens split by :' do
    tokens = described_class.new("Spellr::Line").tokenize
    expect(tokens.map(&:to_s)).to eq ["Spellr", "Line"]
  end

  it "doesn't tokenize a URL" do
    tokens = described_class.new('click here https://google.com').tokenize
    expect(tokens.map(&:to_s)).to eq ['click', 'here']
  end

  it "doesn't tokenize a URL with no scheme" do
    pending
    tokens = described_class.new('click here //google.com').tokenize
    expect(tokens.map(&:to_s)).to eq ['click', 'here']
  end

  it "doesn't tokenize an email" do
    tokens = described_class.new('href="mailto:robot@dana.sh"').tokenize
    expect(tokens.map(&:to_s)).to eq ['href']
  end

  it "doesn't tokenize short words" do
    tokens = described_class.new('to be or not to be').tokenize
    expect(tokens.map(&:to_s)).to eq ['not']
  end

  it 'excludes URLs with numbers in them' do
    tokens = described_class.new('http://www.the4wd.com').tokenize
    expect(tokens.map(&:to_s)).to be_empty
  end

  it "doesn't tokenize numbers only" do
    tokens = described_class.new('3.14 100 4,000').tokenize
    expect(tokens).to be_empty
  end

  it "dosen't tokenize maths only" do
    tokens = described_class.new('1+1 1/2 10>4 15-10').tokenize
    expect(tokens).to be_empty
  end

  it "tokenizes html tags" do
    tokens = described_class.new('<div style="background: red">').tokenize
    expect(tokens.map(&:to_s)).to eq ['div', 'style', 'background', 'red']
  end

  it "doesn't tokenize CSS colours" do
    tokens = described_class.new('color: #fee; background: #fad').tokenize
    expect(tokens.map(&:to_s)).to eq ['color', 'background']
  end

  it "doesn't split on apostrophes" do
    tokens = described_class.new("didn't shouldn't could've o'clock").tokenize
    expect(tokens.map(&:to_s)).to eq ["didn't", "shouldn't", "could've", "o'clock"]
  end

  it "splits on wrapping quotes" do
    tokens = described_class.new(%{"didn't" 'shouldn't' <could've> 'o'clock'}).tokenize
    expect(tokens.map(&:to_s)).to eq ["didn't", "shouldn't", "could've", "o'clock"]
  end

  it "splits on underscore" do
    tokens = described_class.new("this_that_the_other SCREAMING_SNAKE_CASE").tokenize
    expect(tokens.map(&:to_s)).to eq ['this', 'that', 'the', 'other', 'SCREAMING', 'SNAKE', 'CASE']
  end

  it 'splits on camel case' do
    tokens = described_class.new("CamelCase camelCase").tokenize
    expect(tokens.map(&:to_s)).to eq ['Camel', 'Case', 'camel', 'Case']
  end
end
