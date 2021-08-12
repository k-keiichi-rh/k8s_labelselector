require "parslet"

module K8sLabelselector
  class LabelSelectorParser < Parslet::Parser
    root(:selector)

    rule(:comma) { str(",") >> whitespace? }
    rule(:lparen) { str("(") >> whitespace? }
    rule(:rparen) { str(")") >> whitespace? }
    rule(:does_not_exist) { str("!").as(:op) >> whitespace? }
    rule(:double_equals) { str("==").as(:op) >> whitespace? }
    rule(:equal) { str("=").as(:op) >> whitespace? }
    rule(:notequal) { str("!=").as(:op) >> whitespace? }
    rule(:inclusion) { str("in").as(:op) >> whitespace? }
    rule(:exclusion) { str("notin").as(:op) >> whitespace? }
    rule(:whitespace) { match("[\s\r\n\t]").repeat(1) }
    rule(:whitespace?) { whitespace.maybe }
    # Fix me
    rule(:label_value) { match("[A-Za-z0-9._-]").repeat.maybe.as(:label_value) >> whitespace? }
    # Fix me
    rule(:label_key) { match("[A-Za-z0-9._-]").repeat(1).as(:label_key) >> whitespace? }

    rule(:selector) do
      whitespace? >> (requirement >> (comma >> requirement).repeat).as(:selector) |
        str("").as(:everything).as(:selector)

    end

    rule(:requirement) do
      key >> (set_based_restriction | exact_match_restriction) |
        does_not_exist.maybe >> key
    end

    rule(:set_based_restriction) do
      (inclusion | exclusion) >> value_set
    end

    rule(:exact_match_restriction) do
      (double_equals | equal | notequal) >> value
    end

    rule(:value_set) do
      lparen >> values >> rparen
    end

    rule(:values) do
      (label_value >> ((comma >> label_value).repeat.maybe)).as(:values)
    end

    rule(:key) do
      label_key.as(:key)
    end

    rule(:value) do
      label_value.as(:value)
    end
  end

  class LabelSelectorTransform < Parslet::Transform
    rule(
      selector: subtree(:selector)
    ) do
      if selector.is_a?(Array)
        selector
      elsif selector != nil
        [selector]
      else
        []
      end
    end
    rule(
      everything: simple(:val)
    ) do
      nil
    end
    rule(
      key: simple(:key),
      op: simple(:op),
      value: simple(:value)
    ) do
      case op
      when "="
        Requirement.new(key, EQUAL, [value])
      when "=="
        Requirement.new(key, DOUBLEEQUALS, [value])
      when "!="
        Requirement.new(key, NOTEQUAL, [value])
      else
        p "strange!"
      end
    end
    rule(
      key: simple(:key),
      op: simple(:op),
      values: subtree(:values)
    ) do
      operator = ""
      case op
      when "in"
        operator = IN
      when "notin"
        operator = NOTIN
      else
        p "strange!"
      end

      if values.is_a?(Array)
        Requirement.new(key, operator, values)
      else
        Requirement.new(key, operator, [values])
      end
    end
    rule(
      op: simple(:op),
      key: simple(:key)
    ) do
      case op
      when "!"
        Requirement.new(key, DOESNOTEXISTS)
      else
        p "strange!"
      end
    end
    rule(
      key: simple(:key)
    ) do
      Requirement.new(key.to_s, EXISTS)
    end
    rule(
      label_value: simple(:value)
    ) do
      value.to_s
    end
    rule(
      label_key: simple(:value)
    ) do
      value.to_s
    end
  end
end
