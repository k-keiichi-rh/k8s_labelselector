# frozen_string_literal: true

require_relative "k8s_labelselector/version"
require_relative "k8s_labelselector/selector"
require_relative "k8s_labelselector/parser"

module K8sLabelselector
  def parse(str)
    parsed_selector = Selector.parse(str)
  end

  module_function :parse
end
