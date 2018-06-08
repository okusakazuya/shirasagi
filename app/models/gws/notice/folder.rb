class Gws::Notice::Folder
  include SS::Document
  include Gws::Model::Folder
  include Gws::Addon::Notice::ResourceLimitation
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  class << self
    def create_my_folder!(site, group)
      full_name = ''
      depth = 0
      last_folder = nil
      group.name.split('/').each do |part|
        full_name << '/' if full_name.present?
        full_name << part
        depth += 1

        folder = self.site(site).where(name: full_name, depth: depth).first_or_create! do |folder|
          if last_folder
            folder.notice_individual_body_size_limit = last_folder.notice_individual_body_size_limit
            folder.notice_total_body_size_limit = last_folder.notice_total_body_size_limit
            folder.notice_individual_file_size_limit = last_folder.notice_individual_file_size_limit
            folder.notice_total_file_size_limit = last_folder.notice_total_file_size_limit
          else
            folder.notice_total_body_size_limit = SS.config.gws.notice['default_notice_total_body_size_limit']
            folder.notice_individual_file_size_limit = SS.config.gws.notice['default_notice_individual_file_size_limit']
            folder.notice_total_file_size_limit = SS.config.gws.notice['default_notice_total_file_size_limit']
          end

          group_ids = Gws::Group.all.active.where(name: full_name).pluck(:id)

          conds = []
          conds << { name: full_name }
          conds << { name: /#{Regexp.escape(full_name)}\// }
          descendants_group_ids = Gws::Group.all.active.where('$and' => [{ '$or' => conds }]).pluck(:id)

          folder.member_group_ids = group_ids
          folder.readable_setting_range = 'select'
          folder.readable_group_ids = descendants_group_ids
          folder.group_ids = group_ids
        end

        last_folder = folder
      end

      last_folder
    end
  end

  def notices
    Gws::Notice::Post.all.site(site).where(folder_id: id)
  end

  def reclaim!
    set(
      notice_total_body_size: notices.pluck(:text).map(&:size).sum,
      notice_total_file_size: SS::File.in(id: notices.pluck(:file_ids).flatten).sum(:size)
    )
  end
end
