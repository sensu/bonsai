module UsersHelper
  #
  # Return the image_tag of the specified user's gravatar based on their
  # email. If the user does not have a Gravatar, the default Gravatar image is
  # displayed. The default size is 48 pixels.
  #
  # @param user [User] the User for get the Gravatar for
  # @param options [Hash] options for the Gravatar
  # @option options [Integer] :size (48) the size of the Gravatar in pixels
  # @option options [Boolean] :hosted (false) the asset is hosted
  #
  # @example Gravtar for current_user
  #   gravatar_for current_user, size: 72
  #
  # @return [String] the HTML element for the image with the src being the
  #   user's Gravatar, the alt being the User's name and the class being
  #   gravatar.
  #
  def gravatar_for(user, options = {})
    options = {
      size: 36,
      hosted: false,
    }.merge(options)

    size = options[:size]
    hosted = options[:hosted]

    # use virtual user for hosted assets
    if hosted || (user.try(:company) && user.company == ENV['HOST_ORGANIZATION'])
      avatar_url = ActionController::Base.helpers.asset_url("#{ENV['HOST_LOGO']}")
    else
      if user.blank? || user.avatar_url.blank?
        hash = Digest::MD5.hexdigest(user.try(:email).try(:downcase) || "")
        avatar_url = "https://s.gravatar.com/avatar/#{hash}?s=#{size * 2}"
      else
        avatar_url = "#{user.avatar_url}&size=#{size * 2}"
      end
    end
    image_tag(avatar_url, style: "max-height: #{size}px; max-width: #{size}px", alt: user.name, class: 'gravatar')
  end

  #
  # Outputs pluralized stats with contextually appropriate markup
  #
  # @param count [Integer] how many there are
  # @param thing [String] the thing that we have some of
  #
  # @return [String] the pluralized string with appropriate formatting
  #
  def pluralized_stats(count, thing)
    new_count, new_thing = pluralize(count, thing).split(' ')
    raw "#{new_count} #{content_tag(:span, new_thing)}"
  end
end
