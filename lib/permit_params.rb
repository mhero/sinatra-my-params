module PermitParams
  def permitted_params(params, permitted)
    params.select do |k,v| 
      permitted.keys.map(&:to_s).include?(k.to_s) && !v.nil? && coerce(v, permitted[k.to_sym])
    end
  end

  private

  def coerce(param, type, strong = false, options = {})
    begin
      return nil if param.nil?
      return param if (param.is_a?(type) rescue false)
      return Integer(param, 10) if type == Integer
      return Float(param) if type == Float
      return String(param) if type == String
      return Date.parse(param) if type == Date
      return Time.parse(param) if type == Time
      return DateTime.parse(param) if type == DateTime
      return Array(param.split(options[:delimiter] || ",")) if type == Array
      return Hash[param.split(options[:delimiter] || ",").map{|c| c.split(options[:separator] || ":")}] if type == Hash
      if [TrueClass, FalseClass, Boolean].include? type
        coerced = /^(false|f|no|n|0)$/i === param.to_s ? false : /^(true|t|yes|y|1)$/i === param.to_s ? true : nil
        raise ArgumentError if coerced.nil?
        return coerced
      end
      return nil
    rescue ArgumentError
      if strong
        raise InvalidParameterError, "'#{param}' is not a valid #{type}"
      end
    end
  end
end

