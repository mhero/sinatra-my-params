# frozen_string_literal: true

require 'date'
require 'time'

module PermitParams
  class InvalidParameterError < StandardError
    attr_accessor :param, :options
  end

  # Raised when a field marked required: true has no value and no
  # default:. Always a subclass of InvalidParameterError, so existing
  # `rescue PermitParams::InvalidParameterError` code keeps working
  # unchanged if you don't care about the distinction.
  class MissingParameterError < InvalidParameterError; end

  def permitted_params(params, permitted = {}, strong_validation = false, options = {})
    return params if permitted.empty?

    coerced_params = {}
    seen = {}

    params.each do |key, value|
      next unless permitted?(permitted: permitted, key: key, value: value)

      spec = normalize_spec(permitted[key.to_sym])
      seen[key.to_sym] = true

      coerced = coerce(
        param: value,
        type: spec[:type],
        strong_validation: strong_validation,
        options: merge_field_options(options, spec)
      )
      coerced = apply_constraints(coerced, spec, raw_value: value, strong_validation: strong_validation)

      if coerced.nil?
        fill_missing!(coerced_params, key, spec, present: true, raw_value: value)
      else
        coerced_params[key] = coerced
      end
    end

    permitted.each_key do |perm_key|
      next if seen[perm_key]

      spec = normalize_spec(permitted[perm_key])
      fill_missing!(coerced_params, perm_key, spec, present: false, raw_value: nil)
    end

    coerced_params
  end

  private

  Boolean = :boolean
  Any = :any
  Shape = :shape

  # Mirrors the fix Ruby itself shipped for CVE-2021-41817 (ReDoS in
  # Date/Time/DateTime parsing methods): never hand an unbounded,
  # attacker-controlled string to a parser that uses backtracking regexes.
  PARSE_LENGTH_LIMIT = 128

  DATE_TIME_TYPES = [Date, Time, DateTime].freeze
  NUMERIC_PARSE_TYPES = [Integer, Float].freeze

  # Per-field overrides that can live inside a Hash spec (e.g.
  # `{ type: Array, of: Integer, delimiter: ';' }`) instead of only in
  # the global 4th-argument `options` hash. Field-level values win.
  FIELD_OPTION_KEYS = %i[delimiter separator integer_precision shape of].freeze

  def permitted?(permitted:, key:, value:)
    permitted.keys.map(&:to_s).include?(key.to_s) && !value.nil?
  end

  # A permitted value can still just be a bare type (`Integer`, `String`,
  # `Boolean`, ...) exactly like before - that keeps every pre-0.0.12
  # usage working unchanged. It can now ALSO be a Hash describing a
  # richer contract: { type:, required:, default:, in:, match:, min:,
  # max:, of:, shape:, delimiter:, separator:, integer_precision: }.
  def normalize_spec(raw_spec)
    if raw_spec.is_a?(::Hash)
      spec = raw_spec.dup
      spec[:type] = Any unless spec.key?(:type)
      spec
    else
      { type: raw_spec }
    end
  end

  def merge_field_options(global_options, spec)
    overrides = spec.select { |k, _| FIELD_OPTION_KEYS.include?(k) }
    global_options.merge(overrides)
  end

  # Called once per permitted field whenever it ends up without a
  # coerced value - either because it failed validation (present: true)
  # or because it was never supplied at all (present: false).
  def fill_missing!(coerced_params, key, spec, present:, raw_value:)
    if spec.key?(:default)
      coerced_params[key] = spec[:default]
    elsif spec[:required]
      if present
        raise InvalidParameterError, "'#{raw_value}' is not a valid #{spec[:type]}"
      else
        raise MissingParameterError, "'#{key}' is required"
      end
    end
    # else: optional and absent/invalid - silently omitted, same as pre-0.0.12
  end

  def apply_constraints(value, spec, raw_value:, strong_validation:)
    return value if value.nil?

    violation = constraint_violation(value, spec)
    return value unless violation

    raise InvalidParameterError, "'#{raw_value}' is not a valid #{spec[:type]} (#{violation})" if strong_validation

    nil
  end

  def constraint_violation(value, spec)
    return "must be one of #{spec[:in].inspect}" if spec[:in] && !spec[:in].include?(value)
    return 'does not match required format' if spec[:match] && !(value.is_a?(String) && spec[:match].match?(value))

    comparable = comparable_value(value)
    return "must be >= #{spec[:min]}" if spec[:min] && comparable && comparable < spec[:min]
    return "must be <= #{spec[:max]}" if spec[:max] && comparable && comparable > spec[:max]

    nil
  end

  # What min:/max: compares against: the value itself for numbers, its
  # length for anything else that has one (String, Array, Hash).
  def comparable_value(value)
    return value if value.is_a?(Numeric)
    return value.length if value.respond_to?(:length)

    nil
  end

  def coerce(param:, type:, strong_validation: false, options: {})
    return param if type == Any

    begin
      return nil if param.nil?

      # `of:` on an Array field means every element needs its own
      # coercion, so an already-Array param (e.g. from a JSON body)
      # can't take the "already the right class" shortcut below.
      of = options[:of]
      array_with_of = type == Array && of

      return param if !array_with_of && begin
        param.is_a?(type)
      rescue StandardError
        false
      end

      if param.is_a?(String) && (DATE_TIME_TYPES.include?(type) || NUMERIC_PARSE_TYPES.include?(type))
        raise ArgumentError, "'#{type}' input exceeds #{PARSE_LENGTH_LIMIT} bytes" if param.bytesize > PARSE_LENGTH_LIMIT
      end

      return coerce_integer(param, options) if type == Integer
      return Float(param) if type == Float
      return String(param) if type == String
      return Date.parse(param) if type == Date
      return Time.parse(param) if type == Time
      return DateTime.parse(param) if type == DateTime
      return coerce_array(param, options, strong_validation: strong_validation) if type == Array
      return coerce_shape(param, options) if type == Shape
      return coerce_hash(param, options) if type == Hash
      return coerce_boolean(param) if [TrueClass, FalseClass, Boolean].include? type

      nil
    rescue InvalidParameterError
      # Raised by a nested coerce() call (e.g. one bad element inside an
      # `of:` array). Re-raise as-is so the precise inner message survives
      # instead of being replaced by a generic outer one.
      raise if strong_validation

      nil
    rescue StandardError
      # Any other failure while coercing untrusted input (malformed
      # value, unexpected nested shape, missing stdlib constant, etc.)
      # must never crash the caller's request handler - it's either
      # rejected loudly (strong_validation) or dropped silently, same
      # as an invalid value.
      raise InvalidParameterError, "'#{param}' is not a valid #{type}" if strong_validation

      nil
    end
  end

  def coerce_integer(param, options = {})
    Integer(param, options[:integer_precision] || 10)
  end

  def coerce_array(param, options = {}, strong_validation: false)
    elements =
      if param.is_a?(Array)
        param
      else
        delimiter = valid_delimiter?(param, options[:delimiter])
        return unless delimiter

        param.split(delimiter).map(&:strip)
      end

    of = options[:of]
    return Array(elements) unless of

    elements.map { |el| coerce(param: el, type: of, strong_validation: strong_validation, options: options) }.compact
  end

  def coerce_hash(param, options = {})
    return param if param.is_a?(Hash)

    delimiter =  valid_delimiter?(param, options[:delimiter])
    return unless delimiter

    separator = valid_separator?(param, options[:separator])
    return unless separator

    key_value = param.split(delimiter).map(&:strip).map do |c|
      c.split(separator).map(&:strip)
    end
    Hash[key_value]
  end

  def coerce_boolean(param)
    # \A/\z (not ^/$) anchor to the start/end of the *whole string*. In Ruby
    # ^ and $ only anchor to line boundaries, so e.g. "true\nDROP TABLE..."
    # would incorrectly match as a clean boolean with ^/$.
    coerced = if /\A(false|f|no|n|0)\z/i === param.to_s
                false
              else
                /\A(true|t|yes|y|1)\z/i === param.to_s ? true : nil
              end
    raise ArgumentError if coerced.nil?

    coerced
  end

  def valid_delimiter?(param, delimiter)
    delimiter ||= ','
    delimiter if delimiter && param.include?(delimiter)
  end

  def valid_separator?(param, separator)
    separator ||= ':'
    separator if separator && param.include?(separator)
  end

  def coerce_shape(param, options = {})
    hash = coerce_hash(param, options)
    has_shape?(hash, options[:shape]) ? hash : nil
  end

  def has_shape?(hash, shape)
    # `hash` can be nil (coerce_hash gave up on a malformed string) and
    # `shape` can be nil/non-Hash (caller forgot to pass shape:, or an
    # attacker sent an unexpected nested hash the shape never described).
    # Either used to raise NoMethodError deep inside a supposedly "safe"
    # input filter, crashing the whole request. Reject instead of raising.
    return false unless hash.is_a?(Hash) && shape.is_a?(Hash)

    hash.all? do |k, v|
      v.is_a?(Hash) ? has_shape?(v, shape[k]) : shape[k] === v
    end
  end
end
