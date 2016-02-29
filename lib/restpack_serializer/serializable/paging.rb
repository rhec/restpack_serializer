module RestPack::Serializer::Paging
  extend ActiveSupport::Concern

  module ClassMethods
    def page(params = {}, scope = nil, context = {})
      page_with_options RestPack::Serializer::Options.new(self, params, scope, context)
    end

    def page_with_options(options)
      page = options.scope_with_filters.page(options.page).per(options.page_size)
      page = page.reorder(sort_clause(options.sorting)) if options.sorting.any?
      result = RestPack::Serializer::Result.new
      result.resources[self.key] = serialize_page(page, options)
      result.meta[self.key] = serialize_meta(page, options)

      if options.include_links
        result.links = self.links
        Array(RestPack::Serializer::Factory.create(*options.include)).each do |serializer|
          result.links.merge! serializer.class.links
        end
      end

      side_load_data = side_loads(page, options)
      result.meta.merge!(side_load_data[:meta] || {})
      result.resources.merge! side_load_data.except(:meta)
      result.serialize
    end

    private

    def serialize_page(page, options)
      page.map { |model| self.as_json(model, options.context) }
    end

    def serialize_meta(page, options)
      # Singular resources don't require any of this metadata
      return {} if options.context.fetch(:singular, false)
      meta = {
          page: page.current_page,
          page_size: page.limit_value,
          count: page.total_count,
          page_count: page.total_pages,
      }

      meta[:first_href] = page_href(1, options)
      meta[:previous_href] = page_href(page.prev_page, options)
      meta[:next_href] = page_href(page.next_page, options)
      meta[:last_href] = page_href(meta[:page_count], options)
      meta
    end

    def page_href(page, options)
      return nil unless page

      url = "#{self.href_prefix}/#{self.key}"

      params = []
      params << "page=#{page}" unless page == 1
      params << "page_size=#{options.page_size}" unless options.default_page_size?
      params << "include=#{options.include.join(',')}" if options.include.any?
      params << options.sorting_as_url_params if options.sorting.any?
      params << options.filters_as_url_params if options.filters.any?
      params << options.custom_filters_as_url_params if options.custom_filters.any?

      # TODO: refactor all the param generating methods above to generate a hash directly instead
      #       of string parameters
      hash_params = Hash[params.map { |p| p.split("=") }.sort]
      url += '?' + hash_params.to_query if params.any?
      url
    end

    def sort_clause sorting_parameters
      case_insensitive_sorting_attributes ||= []
      sorting_parameters.map do |col_name, sort_direction| 
        col_name = "lower(#{col_name})" if case_insensitive_sorting_attributes.include? col_name
        [col_name, sort_direction].join(" ")
      end.join(",")
    end
  end
end
