module RestPack::Serializer
  class Options
    attr_accessor :page, :page_size, :include, :filters, :custom_filters,
                   :serializer, :model_class, :scope, :context, :include_links,
                  :sorting, :string_sorting

    def initialize(serializer, params = {}, scope = nil, context = {})
      params.symbolize_keys! if params.respond_to?(:symbolize_keys!)
      @page = params[:page] ? params[:page].to_i : 1
      @page_size = params[:page_size] ? params[:page_size].to_i : RestPack::Serializer.config.page_size
      @include = params[:include] ? params[:include].split(',') : []
      @filters = filters_from_params(params, serializer)
      @custom_filters = custom_filters_from_params(params, serializer)
      @sorting = sorting_from_params(params, serializer)
      @serializer = serializer
      @model_class = serializer.model_class
      @scope = scope || model_class.send(:all)
      @context = context
      @include_links = true
    end

    def scope_with_filters
      scope_filter = {}
      @filters.each do |key, value|
        unless model_class.column_names.include? key
          # It's not a real column, but it might contain a date filter, check to make sure
          suffix_position = key =~ /(#{serializer.date_filter_suffixes.collect { |s| '_'+Regexp.escape(s) }.join('|')})$/
          if suffix_position
            column_name = key.slice(0...suffix_position)
            if model_class.column_names.include? column_name
              # yep, it's a filter
              suffix = key.slice((suffix_position+1)..-1)
              operator = serializer.map_date_filter_suffix_to_operator(suffix)
              clause = "#{column_name} #{operator} ?"
              @scope = @scope.where(clause, DateTime.parse(value[0]))
              next
            end
          end
        end
        # We can fall through from the above logic to here
        value = query_to_array(@filters[key])
        scope_filter[key] = value
      end
      @scope.where(scope_filter)
    end

    def default_page_size?
      @page_size == RestPack::Serializer.config.page_size
    end

    def filters_as_url_params
      @filters.stringify_keys.sort.map { |k,v| map_filter_ids(k,v) }.join('&')
    end

    def custom_filters_as_url_params
      @custom_filters.stringify_keys.sort.map { |k,v| map_filter_ids(k,v) }.join('&')
    end

    def sorting_as_url_params
      sorting_values = sorting.map { |k, v| v == :asc ? k : "-#{k}" }.join(',')
      "sort=#{sorting_values}"
    end

    private

    def filters_from_params(params, serializer)
      filters = {}
      serializer.filterable_by.each do |filter|
        [filter, "#{filter}s".to_sym].each do |key|
          filters[filter] = params[key].to_s.split(',') if params[key]
        end
      end
      filters
    end

    def custom_filters_from_params(params, serializer)
      filters = {}
      serializer.custom_filterable_by.each do |filter|
        [filter, "#{filter}s".to_sym].each do |key|
          filters[filter] = params[key].to_s.split(',') if params[key]
        end
      end
      filters
    end

    def sorting_from_params(params, serializer)
      sort_values = params[:sort] && params[:sort].split(',')
      return {} if sort_values.blank? || serializer.serializable_sorting_attributes.blank?
      sorting_parameters = {}

      string_condition = false
      sort_values.each do |sort_value|
        sort_order = sort_value[0] == '-' ? :desc : :asc
        sort_value = sort_value.gsub(/\A\-/, '').downcase.to_sym
        string_condition = true if sort_value =~ /lower\(/
        sorting_parameters[sort_value] = sort_order if serializer.serializable_sorting_attributes.include?(sort_value)
      end
      if string_condition
        # Build a string condition
        @string_sorting = sorting_parameters.map { |pair| pair.join(" ") }.join(',')
      end
      # Return the hash condition
      sorting_parameters
    end

    def map_filter_ids(key,value)
      case value
      when Hash
        value.map { |k,v| map_filter_ids(k,v) }
      else
         "#{key}=#{value.join(',')}"
      end
    end

    def query_to_array(value)
      case value
        when String
          value.split(',')
        when Hash
          value.each { |k, v| value[k] = query_to_array(v) }
        else
          value
      end
    end
  end
end
