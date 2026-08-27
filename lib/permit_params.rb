# frozen_string_literal: true

require 'date'
require 'time'

module PermitParams
  class InvalidParameterError < StandardError
    attr_accessor :param, :options
  end

  def permitted_params(params, permitted = {}, strong_validation = false, options = {})
    return params if permitted.empty?

    coerced_params = {}

    params.each do |key, value|
      next unless permitted?(permitted: permitted, key: key, value: value)

      coerced = coerce(
        param: value,
        type: permitted[key.to_sym],
        strong_validation: strong_validation,
        options: options
      )
      coerced_params[key] = coerced unless coerced.nil?
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

  def permitted?(permitted:, key:, value:)
    permitted.keys.map(&:to_s).include?(key.to_s) && !value.nil?
  end

  def coerce(param:, type:, strong_validation: false, options: {})
    return param if type == Any

    begin
      return nil if param.nil?
      return param if begin
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
      return coerce_array(param, options) if type == Array
      return coerce_shape(param, options) if type == Shape
      return coerce_hash(param, options) if type == Hash
      return coerce_boolean(param) if [TrueClass, FalseClass, Boolean].include? type

      nil
    rescue StandardError
      # Any failure while coercing untrusted input (malformed value,
      # unexpected nested shape, missing stdlib constant, etc.) must never
      # crash the caller's request handler - it's either rejected loudly
      # (strong_validation) or dropped silently, same as an invalid value.
      raise InvalidParameterError, "'#{param}' is not a valid #{type}" if strong_validation

      nil
    end
  end

  def coerce_integer(param, options = {})
    Integer(param, options[:integer_precision] || 10)
  end

  def coerce_array(param, options = {})
    delimiter = valid_delimiter?(param, options[:delimiter])
    return unless delimiter

    Array(param.split(delimiter).map(&:strip))
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
