# frozen_string_literal: true

require_relative 'possible_key'
require_relative 'stats'
require 'yaml'
# this is lifted in whole from this article. i don't understand the maths and i don't want to
# https://www.sitepoint.com/machine-learning-ruby-naive-bayes-theorem/

class NaiveBayes
  # :nocov:
  using ::Spellr::YAMLPermittedClasses if defined?(::Spellr::YAMLPermittedClasses)
  # :nocov:

  YAML_PATH = File.join(__dir__, 'data.yml')

  attr_reader :feature_set, :num_classes, :classes, :features

  def initialize(path = YAML_PATH)
    load_from_yaml(path)
    @key = {}
  end

  def key?(string)
    @key.fetch(string) do
      @key[string] = classify(PossibleKey.new(string).features).start_with?('key')
    end
  end

  def load_from_yaml(path = YAML_PATH)
    data = YAML.safe_load(::File.read(path), permitted_classes: [Symbol])

    @feature_set = data[:feature_set]
    @num_classes = data[:num_classes]
    @classes = data[:classes]
    @features = data[:features]
  end

  # given a class, this method determines the probability
  # of a certain value occurring for a given feature
  # feature: name of the feature in consideration in the training data
  # value: the value of the feature for which we are finding the probability
  # class_name: name of the class in consideration
  def feature_probability(feature, value, class_name)
    Stats.gaussian_probability(value, **feature_set[class_name][feature])
  end

  # multiply together the feature probabilities for all of the
  # features in a class for given values
  def feature_multiplication(features, class_name)
    features.reduce(1.0) do |result, (key, value)|
      result * feature_probability(key, value, class_name)
    end
  end

  def heuristic_weight
    @heuristic_weight ||= 10**Spellr.config.key_heuristic_weight
  end

  # this is where we compute the final naive Bayesian probability
  # for a given set of features being a part of a given class.
  def class_probability(features, class_name)
    class_fraction = 1.0 / num_classes
    feature_bayes = feature_multiplication(features, class_name)
    feature_bayes *= heuristic_weight if class_name.start_with?('key_')
    feature_bayes * class_fraction
  end

  def classify(features)
    classes.max_by do |class_name|
      class_probability(features, class_name)
    end
  end
end
