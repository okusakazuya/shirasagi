class Gws::Circular::Topic
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Board::Postable
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Board::Category

  # override
  store_in collection: 'gws_circular_topics'
  set_permission_name 'gws_circular_topics'

  field :due_date, type: DateTime
  field :mark_type, type: String, default: 'normal'

  field :mark_hash, type: Hash, default: {}

  permit_params :due_date, :mark_type

  validates :due_date, presence: true

  has_many :children, class_name: 'Gws::Circular::Post', dependent: :destroy, inverse_of: :parent, order: { created: -1 }
  has_many :descendants, class_name: 'Gws::Circular::Post', dependent: :destroy, inverse_of: :topic, order: { created: -1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if sort_num = params[:sort].to_i
      criteria = criteria.order_by(new.sort_hash(sort_num))
    end

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end

    criteria
  }

  # 回覧板へのコメントを許可しているか？
  # ・コメントを編集する権限を持っている
  # ・ユーザーもしくはメンバーに含まれる
  def permit_comment?(*args)
    opts = {user: user, site: site}.merge(args.extract_options!)

    Gws::Circular::Post.allowed?(:edit, opts[:user], site: opts[:site]) &&
        (user_ids.include?(opts[:user].id) || member?(opts[:user]))
  end

  def commented?(u=user)
    children.where(user_ids: u.id).exists?
  end

  def markable?(u=user)
    member?(u) && mark_hash.exclude?(u.id.to_s)
  end

  def mark_by(u=user)
    self.mark_hash[u.id.to_s] = Time.zone.now if markable?(u)
    self
  end

  def unmarkable?(u=user)
    member?(u) && mark_hash.include?(u.id.to_s)
  end
  alias marked? unmarkable?

  def unmark_by(u=user)
    self.mark_hash.delete(u.id.to_s) if unmarkable?(u)
    self
  end

  def toggle_by(u=user)
    marked?(u) ? unmark_by(u) : mark_by(u)
  end

  def mark_at(u)
    mark_hash[u.id.to_s]
  end

  def mark_action_label(u=user)
    marked?(u) ? I18n.t('gws/circular.topic.unmark') : I18n.t('gws/circular.topic.mark')
  end

  def mark_type_options
    [
        [I18n.t('gws/circular.options.mark_type.normal'), 'normal'],
        [I18n.t('gws/circular.options.mark_type.simple'), 'simple']
    ]
  end

  def sort_items
    [
        { key: :updated, order: -1, name: I18n.t('mongoid.attributes.ss/document.updated')},
        { key: :created, order: -1, name: I18n.t('mongoid.attributes.ss/document.created')}
    ]
  end

  def sort_hash(num=0)
    result = {}
    item = sort_items[num]
    result[item[:key]] = item[:order]
    result
  end

  def sort_options
    sort_items.map.with_index { |item, i| [item[:name], i] }
  end

  def custom_group_member?(user)
    custom_groups.where(member_ids: user.id).exists?
  end

  def allowed?(action, user, opts = {})
    return true if super(action, user, opts)
    member?(user) || custom_group_member?(user) if action =~ /read/
  end

  class << self
    # def allow(action, user, opts = {})
    #   result = super(action, user, opts)
    #   result.exists? ? result : member(user)
    # end

    def allow_condition(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
      action = permission_action || action

      if level = user.gws_role_permissions["#{action}_other_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { member_ids: user.id },
          { permission_level: { "$lte" => level } },
        ] }
      elsif level = user.gws_role_permissions["#{action}_private_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { member_ids: user.id },
          { :group_ids.in => user.group_ids, "$or" => [{ permission_level: { "$lte" => level } }] }
        ] }
      else
        { "$or" => [
          { user_ids: user.id },
          { member_ids: user.id }
        ] }
      end
    end

    def to_csv
      CSV.generate do |data|
        data << I18n.t('gws/circular.csv')
        each do |item|
          item.members.each do |member|
            post = item.children.where(user_id: member.id).first
            data << [
                item.id,
                item.name,
                post.try(:id),
                item.marked?(member),
                member.name,
                post.try(:text),
                post.try(:updated)
            ]
          end
        end
      end
    end
  end
end