# frozen_string_literal: true

require_relative 'possible_key'
require_relative 'stats'
require 'yaml'
# this is lifted in whole from this article. i don't understand the maths and i don't want to
# https://www.sitepoint.com/machine-learning-ruby-naive-bayes-theorem/

class NaiveBayes # rubocop:disable Metrics/ClassLength
  include Stats

  YAML_PATH = File.join(__dir__, 'data.yml')

  WEIGHT = 5
  def training_data
    @training_data ||= begin
      PossibleKey.load
      PossibleKey.keys.each.with_object({}) do |key, data|
        key_class = key.key? ? 'key' : 'not_key'
        character_set = key.character_set
        key_key = "#{key_class}_#{character_set}"
        data[key_key] ||= []
        data[key_key] << key.features
      end
    end
  end

  def load_from_yaml
    data = YAML.safe_load(::File.read(YAML_PATH), [Symbol])

    @feature_set = data[:feature_set]
    @num_classes = data[:num_classes]
    @classes = data[:classes]
    @features = data[:features]
  end

  def save_to_yaml
    require 'yaml'
    File.write(YAML_PATH, {
      feature_set: feature_set,
      num_classes: num_classes,
      classes: classes,
      features: features
    }.to_yaml)
  end

  def initialize
    load_from_yaml if File.exist?(YAML_PATH)
  end

  def num_classes
    @num_classes ||= training_data&.length
  end

  def classes
    @classes ||= training_data&.keys
  end

  def features
    @features ||= training_data.first.last.first.keys
  end

  def feature_set # rubocop:disable Metrics/MethodLength
    @feature_set ||= classes.each.with_object({}) do |class_name, feature_set|
      feature_set[class_name] = {}

      features.each do |feature|
        values = training_data[class_name].map do |row|
          row[feature]
        end

        feature_set[class_name][feature] = {
          standard_deviation: standard_deviation(values),
          mean: mean(values),
          variance: variance(values)
        }
      end
    end
  end

  # given a class, this method determines the probability
  # of a certain value occurring for a given feature
  # index: index of the feature in consideration in the training data
  # value: the value of the feature for which we are finding the probability
  # class_name: name of the class in consideration
  def feature_probability(feature, value, class_name) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # get the feature value set
    fs = feature_set[class_name][feature]

    # statistical properties of the feature set
    fs_std = fs[:standard_deviation]
    fs_mean = fs[:mean]
    fs_var = fs[:variance]

    # deal with the edge case of a 0 standard deviation
    if fs_std == 0
      return fs_mean == value ? 1.0 : 0.0
    end

    # calculate the gaussian probability
    pi = Math::PI
    e = Math::E

    exp = -((value - fs_mean)**2) / (2 * fs_var)
    probability = (1.0 / Math.sqrt(2 * pi * fs_var)) * (e**exp)

    probability
  end

  # multiply together the feature probabilities for all of the
  # features in a class for given values
  def feature_multiplication(features, class_name)
    features.reduce(1.0) do |result, (key, value)|
      result * feature_probability(key, value, class_name)
    end
  end

  def debug(string) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    require 'terminal-table'

    features = PossibleKey.new(string).features

    table = Terminal::Table.new do |t|
      t << ['classes'] + classes
      t << :separator
      t << ['probabilities'] + classes.map { |c| class_probability(features, c) }
      features.each do |key, value|
        t << [key] + classes.map { |c| feature_probability(key, value, c).round(4) }
      end
    end
    puts table

    nil
  end

  # this is where we compute the final naive Bayesian probability
  # for a given set of features being a part of a given class.
  def class_probability(features, class_name)
    class_fraction = 1.0 / num_classes
    feature_bayes = feature_multiplication(features, class_name)
    feature_bayes *= (10**WEIGHT) if class_name.start_with?('key_')
    feature_bayes * class_fraction
  end

  # This the method we should be calling!
  # Given a set of feature values, it decides
  # what class to categorize them under
  def classify(features)
    classes.max_by do |class_name|
      class_probability(features, class_name)
    end
  end

  def key?(string)
    key_cache[string]
  end

  def key_cache
    @key_cache ||= Hash.new do |cache, string|
      cache[string] = classify(PossibleKey.new(string).features).start_with?('key')
    end
  end
end
