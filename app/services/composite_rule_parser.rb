class CompositeRuleParser
  class ParseError < StandardError; end

  # AST Nodes
  AlarmRef = Struct.new(:name, :target_state) do
    def evaluate(states)
      states[name] == target_state
    end
  end

  AndNode = Struct.new(:left, :right) do
    def evaluate(states)
      left.evaluate(states) && right.evaluate(states)
    end
  end

  OrNode = Struct.new(:left, :right) do
    def evaluate(states)
      left.evaluate(states) || right.evaluate(states)
    end
  end

  NotNode = Struct.new(:child) do
    def evaluate(states)
      !child.evaluate(states)
    end
  end

  def self.parse(rule)
    new(rule).parse
  end

  def self.valid?(rule)
    parse(rule)
    true
  rescue ParseError
    false
  end

  def initialize(rule)
    @tokens = tokenize(rule)
    @pos = 0
  end

  def parse
    raise ParseError, "empty expression" if @tokens.empty?

    result = parse_or
    raise ParseError, "unexpected token: #{current}" if @pos < @tokens.length
    result
  end

  private

  def alarm_ref_token(name, target_state)
    [ :ALARM_REF, name, target_state ]
  end

  def tokenize(rule)
    tokens = []
    scanner = StringScanner.new(rule.strip)

    until scanner.eos?
      scanner.skip(/\s+/)
      break if scanner.eos?

      if scanner.scan(/AND\b/)
        tokens << :AND
      elsif scanner.scan(/OR\b/)
        tokens << :OR
      elsif scanner.scan(/NOT\b/)
        tokens << :NOT
      elsif scanner.scan(/ALARM\(([^)]+)\)/)
        tokens << alarm_ref_token(scanner[1].strip, "alarm")
      elsif scanner.scan(/OK\(([^)]+)\)/)
        tokens << alarm_ref_token(scanner[1].strip, "ok")
      elsif scanner.scan(/INSUFFICIENT_DATA\(([^)]+)\)/)
        tokens << alarm_ref_token(scanner[1].strip, "insufficient_data")
      elsif scanner.scan(/\(/)
        tokens << :LPAREN
      elsif scanner.scan(/\)/)
        tokens << :RPAREN
      else
        raise ParseError, "unexpected character: #{scanner.peek(10)}"
      end
    end

    tokens
  end

  def current
    @tokens[@pos]
  end

  def consume(expected = nil)
    tok = current
    if expected && tok != expected
      raise ParseError, "expected #{expected}, got #{tok}"
    end
    @pos += 1
    tok
  end

  # Grammar: expression := term (OR term)*
  def parse_or
    left = parse_and
    while current == :OR
      consume(:OR)
      right = parse_and
      left = OrNode.new(left, right)
    end
    left
  end

  # term := factor (AND factor)*
  def parse_and
    left = parse_not
    while current == :AND
      consume(:AND)
      right = parse_not
      left = AndNode.new(left, right)
    end
    left
  end

  # factor := NOT factor | atom
  def parse_not
    if current == :NOT
      consume(:NOT)
      child = parse_not
      NotNode.new(child)
    else
      parse_atom
    end
  end

  # atom := ALARM_REF | ( expression )
  def parse_atom
    if current == :LPAREN
      consume(:LPAREN)
      node = parse_or
      consume(:RPAREN)
      node
    elsif current.is_a?(Array) && current[0] == :ALARM_REF
      tok = consume
      AlarmRef.new(tok[1], tok[2])
    else
      raise ParseError, "unexpected token: #{current}"
    end
  end
end
