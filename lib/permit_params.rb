# frozen_string_literal: true

module PermitParams
  class InvalidParameterError < StandardError
    attr_accessor :param, :options
  end

  def permitted_params(params, permitted = {}, strong_validation = false, options = {})
    return params if permitted.empty?

    coerced_params = Hash.new({})

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
    rescue ArgumentError
      raise InvalidParameterError, "'#{param}' is not a valid #{type}" if strong_validation
    end
  end

  def coerce_integer(param, options = {})
    Integer(param, options[:integer_precision] || 10)
  end

  def coerce_array(param, options = {})
    Array(param.split(options[:delimiter] || ',').map(&:strip))
  end

  def coerce_hash(param, options = {})
    return param if param.is_a?(Hash)

    key_value = param.split(options[:delimiter] || ',').map(&:strip).map do |c|
      c.split(options[:separator] || ':').map(&:strip)
    end
    Hash[key_value]
  end

  def coerce_boolean(param)
    coerced = if /^(false|f|no|n|0)$/i === param.to_s
                false
              else
                /^(true|t|yes|y|1)$/i === param.to_s ? true : nil
              end
    raise ArgumentError if coerced.nil?

    coerced
  end

  def coerce_shape(param, options = {})
    hash = coerce_hash(param)
    has_shape?(hash, options[:shape]) ? hash : nil
  end

  def has_shape?(hash, shape)
    hash.all? do |k, v|
      v.is_a?(Hash) ? has_shape?(v, shape[k]) : shape[k] === v
    end
  end
end
