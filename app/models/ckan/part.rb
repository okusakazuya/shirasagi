module Ckan::Part
  class Status
    include Cms::Model::Part
    include Ckan::Addon::Status
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ckan/status") }
  end

  class Page
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ckan/page") }
  end

  class Reference
    include Cms::Model::Part
    include Ckan::Addon::Reference
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    belongs_to :exporter, class_name: 'Opendata::Harvest::Exporter'

    default_scope ->{ where(route: "ckan/reference") }
  end
end
