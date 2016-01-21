module RestPack::Serializer::Filterable
  extend ActiveSupport::Concern

  module ClassMethods
        
    def date_filter_suffixes
      ["gt","lt","gte","lte"]
    end

    def map_date_filter_suffix_to_operator suffix
      case suffix
      when 'gt'
        '>'
      when 'gte'
        '>='
      when 'lt'
        '<'
      when 'lte'
        '<='
      end
    end

    def serializable_filters
      @serializable_filters
    end

    # Custom filters will be included in the URLs when present, but
    # it's up to you to ensure they are applied to the data set. 
    # They will not be automatically applied.
    def custom_filters
      @custom_filters ||= []
    end

    def can_filter_by(*attributes)
      attributes.each do |attribute|
        @serializable_filters ||= []
        @serializable_filters << attribute.to_sym
      end
    end

    def has_custom_filters(*attributes)
      attributes.each do |attribute|
        custom_filters << attribute.to_sym
      end
    end

    def filterable_by
      # Default filters are the PK and any FK attributes
      filters = [self.model_class.primary_key.to_sym]
      filters += self.model_class.reflect_on_all_associations(:belongs_to).map(&:foreign_key).map(&:to_sym)

      # By default you can also filter on any date or datetime columns, including ranges
      self.model_class.columns.each do |c|
        next unless c.type == :datetime
        date_filter_suffixes.each do |suffix|
          filters << [c.name, suffix].join("_")
        end
      end
      filters += @serializable_filters if @serializable_filters
      filters.uniq
    end

    def custom_filterable_by
      custom_filters
    end
  end
end
