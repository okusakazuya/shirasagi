module Gws::Addon::Survey::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  # include Gws::Break

  set_addon_type :organization

  included do
    field :survey_default_due_date, type: Integer, default: 7
    # field :circular_max_member, type: Integer
    # field :circular_filesize_limit, type: Integer
    # field :circular_delete_threshold, type: Integer, default: 3
    # field :circular_files_break, type: String, default: 'vertically'

    permit_params :survey_default_due_date
    # permit_params :circular_default_due_date, :circular_max_member,
    #               :circular_filesize_limit, :circular_delete_threshold,
    #               :circular_files_break

    validates :survey_default_due_date, numericality: true
    # validates :circular_delete_threshold, numericality: true
    # validates :circular_files_break, inclusion: { in: %w(vertically horizontal), allow_blank: true }
    #
    # alias_method :circular_files_break_options, :break_options
  end

  # def circular_default_due_date
  #   self[:circular_default_due_date]
  # end
  #
  # def circular_max_member
  #   self[:circular_max_member]
  # end
  #
  # def circular_filesize_limit
  #   self[:circular_filesize_limit]
  # end
  #
  # def circular_delete_threshold
  #   self[:circular_delete_threshold]
  # end
  #
  # def circular_delete_threshold_options
  #   I18n.t('gws/circular.options.circular_delete_threshold').
  #     map.
  #     with_index.
  #     to_a
  # end
  #
  # def circular_delete_threshold_name
  #   I18n.t('gws/circular.options.circular_delete_threshold')[circular_delete_threshold]
  # end
end
