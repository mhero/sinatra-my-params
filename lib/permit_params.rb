module PermitParams
  class InvalidParameterError < StandardError
    attr_accessor :param, :options
  end

  def permitted_params(params, permitted = {}, strong_validation = false)
    return params if permitted.empty?
  
    params.select do |k,v| 
      permitted.keys.map(&:to_s).include?(k.to_s) && 
        !v.nil? && 
        !coerce(v, permitted[k.to_sym], strong_validation).nil?
    end
  end

  private

  Boolean = :boolean

  def coerce(param, type, strong_validation = false, options = {})
    begin
      return nil if param.nil?
      return param if (param.is_a?(type) rescue false)
      return Integer(param, 10) if type == Integer
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

  def coerce_array(param)
    Array(param.split(options[:delimiter] || ","))
  end

  def coerce_hash(param)
    Hash[param.split(options[:delimiter] || ",").map{|c| c.split(options[:separator] || ":")}]
  end

  def coerce_boolean(param)
    coerced = /^(false|f|no|n|0)$/i === param.to_s ? false : /^(true|t|yes|y|1)$/i === param.to_s ? true : nil
    raise ArgumentError if coerced.nil?
    coerced
  end
end

