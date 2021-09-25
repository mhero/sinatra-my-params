# frozen_string_literal: true

module PermitParams
  class InvalidParameterError < StandardError
    attr_accessor :param, :options
  end

  def permitted_params(params, permitted = {}, strong_validation = false, options = {})
    return params if permitted.empty?

    coerced_params = Hash.new({})

    params.each do |key, value|
      if permitted.keys.map(&:to_s).include?(key.to_s) && !value.nil?
        coerced = coerce(value, permitted[key.to_sym], strong_validation, options)
        coerced_params[key] = coerced unless coerced.nil?
      end
    end
    coerced_params
  end

  private

  Boolean = :boolean
  Any = :any

  def coerce(param, type, strong_validation = false, options = {})
    return param if type == Any

    begin
      return nil if param.nil?
      return param if (param.is_a?(type) rescue false)
      return Integer(param, options[:integer_precision] || 10 ) if type == Integer
      return Float(param) if type == Float
      return String(param) if type == String
      return Date.parse(param) if type == Date
      return Time.parse(param) if type == Time
      return DateTime.parse(param) if type == DateTime
      return coerce_array(param) if type == Array
      return coerce_hash(param) if type == Hash
      return coerce_boolean(param) if [TrueClass, FalseClass, Boolean].include? type
      return nil
    rescue ArgumentError
      raise InvalidParameterError, "'#{param}' is not a valid #{type}" if strong_validation
    end
  end

  def coerce_array(param, options = {})
    Array(param.split(options[:delimiter] || ',').map(&:strip))
  end

  def coerce_hash(param, options = {})
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
end
