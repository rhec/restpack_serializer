module RestPack::Serializer::Sortable
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :serializable_sorting_attributes
    attr_reader :case_insensitive_sorting_attributes
    attr_reader :month_day_sorting_attributes

    def can_sort_by(*attributes)
      @serializable_sorting_attributes ||= []
      @serializable_sorting_attributes += attributes
    end

    def case_insensitive_sort_by(*attributes)
      can_sort_by(*attributes)
      @case_insensitive_sorting_attributes ||= []
      @case_insensitive_sorting_attributes += attributes
    end

    def month_day_sort_by(*attributes)
      can_sort_by(*attributes)
      @month_day_sorting_attributes ||= []
      @month_day_sorting_attributes += attributes
    end
  end
end
