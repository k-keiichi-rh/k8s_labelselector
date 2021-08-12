require "parslet"

module K8sLabelselector
  DOESNOTEXISTS = "!"
  EQUAL = "="
  DOUBLEEQUALS = "=="
  IN = "in"
  NOTEQUAL = "!="
  NOTIN = "notin"
  EXISTS = "exists"

  class Selector

    def initialize(requirements)
      @requirements = requirements
    end

    def self.parse(str)
      l = LabelSelectorParser.new
      parsed = l.parse(str)
      requirements = LabelSelectorTransform.new.apply(parsed)
      requirements.sort! { |a, b| a.key <=> b.key }
      Selector.new(requirements)
    rescue Parslet::ParseFailed => e
      $stderr.puts "unable to parse requirement: #{str}"
      $stderr.puts e.parse_failure_cause.ascii_tree
      nil
    end

    def match?(labels)
      @requirements.each{|r|
        if not r.match?(labels)
          return false
        end
      }
      return true
    end

    def to_s
      reqs = []
      @requirements.each{|r|
        reqs.push(r.to_s)
      }
      reqs.join(',')
    end
  end

  class Requirement
    attr_reader :key, :operator, :values

    def initialize(key, operator = "", values = [])
      @key = key
      @operator = operator
      @values = values
    end

    def match?(labels)
      case @operator
      when IN, EQUAL, DOUBLEEQUALS
        if not labels.key?(@key.to_sym)
          false
        end
        @values.include?(labels[@key.to_sym])
      when NOTIN, NOTEQUAL
        if not labels.key?(@key.to_sym)
          true
        end
        not @values.include?(labels[@key.to_sym])
      when EXISTS
        return labels.key?(@key.to_sym)
      when DOESNOTEXISTS
        not labels.key?(@key.to_sym)
      else
        false
      end
    end

    def to_s
      str = ""
      if @operator == DOESNOTEXISTS
        str += "!"
      end
      str += @key
      case @operator
      when EQUAL
        str += "="
      when DOUBLEEQUALS
        str += "=="
      when NOTEQUAL
        str += "!="
      when IN
        str += " in "
      when NOTIN
        str += " notin "
      end
      case @operator
      when IN, NOTIN
          str += "("
      end
      if @values.length == 1
        str += @values[0]
      else
        str += @values.join(',')
      end
      case @operator
      when IN, NOTIN
          str += ")"
      end
      str
    end
  end
end
