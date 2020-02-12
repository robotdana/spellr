# frozen_string_literal: true

require_relative 'possible_key'
require_relative 'stats'
require 'yaml'
# this is lifted in whole from this article. i don't understand the maths and i don't want to
# https://www.sitepoint.com/machine-learning-ruby-naive-bayes-theorem/

class NaiveBayes
  YAML_PATH = File.join(__dir__, 'data.yml')

  def initialize(path = YAML_PATH)
    load_from_yaml(path) if File.exist?(path)
    @key = {}
  end

  def key?(string)
    @key.fetch(string) do
      @key[string] = classify(PossibleKey.new(string).features).start_with?('key')
    end
  end

  def load_from_yaml(path = YAML_PATH)
    data = YAML.safe_load(::File.read(path), [Symbol])

    @feature_set = data[:feature_set]
    @num_classes = data[:num_classes]
    @classes = data[:classes]
    @features = data[:features]
  end

  def save_to_yaml(path = YAML_PATH)
    write_yaml(path,
               feature_set: feature_set,
               num_classes: num_classes,
               classes: classes,
               features: features)
  end

  private

  def write_yaml(path = YAML_PATH, **hash)
    require 'yaml'

    File.write(path, hash.to_yaml)
  end

  def training_data
    @training_data ||= PossibleKey.keys.each_with_object({}) do |key, data|
      data[key.classification] ||= []
      data[key.classification] << key.features
    end
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

  def feature_set
    @feature_set ||= classes.each.with_object({}) do |class_name, feature_set|
      feature_set[class_name] = features.each.with_object({}) do |feature, feature_set_for_class|
        feature_set_for_class[feature] = feature_stats_for_class(class_name, feature)
      end
    end
  end

  def feature_stats_for_class(class_name, feature)
    values = training_data[class_name].map { |row| row[feature] }

    feature_stats(values)
  end

  def feature_stats(values)
    {
      standard_deviation: Stats.standard_deviation(values),
      mean: Stats.mean(values),
      variance: Stats.variance(values)
    }
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
