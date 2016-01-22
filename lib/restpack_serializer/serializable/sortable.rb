module RestPack::Serializer::Sortable
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :serializable_sorting_attributes

    def can_sort_by(*attributes)
      @serializable_sorting_attributes = []
      attributes.each do |attribute|
        @serializable_sorting_attributes << attribute.to_sym
        # Allow sorting by lowercase as well
        @serializable_sorting_attributes << "lower(#{attribute})".to_sym
      end
    end
  end
end
