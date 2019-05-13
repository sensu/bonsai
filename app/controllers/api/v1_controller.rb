require 'mixlib/authentication/signatureverification'

class Api::V1Controller < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  skip_before_action :verify_authenticity_token

  private

  #
  # Render the error message with a status of 404 and a message letting the
  # user know the resource does not exist.
  #
  def render_404
    error(
      {
        error_messages: [t('api.error_messages.not_found')],
        error_code: t('api.error_codes.not_found')
      },
      404
    )
  end

  #
  # Render not authorized.
  #
  # @param messages [Array<String>] the error messages
  #
  def render_not_authorized(messages)
    error(
      {
        error_code: t('api.error_codes.unauthorized'),
        error_messages: messages
      },
      401
    )
  end

  #
  # Renders an JSON body with an error and a header with a given status.
  #
  def error(body, status = 400)
    render json: body, status: status
  end

  #
  # This creates instance variables for +start+ and +items+, which are shared
  # between the index and search methods. Also +order+ which is for ordering.
  #
  # Pass in the start and items params to specify the index at which to start
  # and how many to return. You can pass in an order param to specify how
  # you'd like the the collection ordered. Possible values are
  # recently_updated, recently_added, most_downloaded, most_followed.
  #
  # @example
  #   GET /api/v1/extensions?start=5&items=15
  #   GET /api/v1/extensions?order=recently_updated
  #
  def init_params
    @start = params.fetch(:start, 0).to_i
    @items = [params.fetch(:items, 10).to_i, 100].min

    if @start < 0 || @items < 0
      return error(
        error_code: t('api.error_codes.invalid_data'),
        error_messages: [t('api.error_messages.negative_parameter',
                           start: params.fetch(:start, 'not provided'),
                           items: params.fetch(:items, 'not provided'))]
      )
    end
    @next_page_params = {
      start: @start.to_i + @items.to_i,
      items: params[:items].presence && @items.to_i
    }

    @order = params.fetch(:order, 'name ASC').to_s
  end

  #
  # Finds a user specified in the request header or renders an error if
  # the user doesn't exist. Then attempts to authorize the signed request
  # against the users public key or renders an error if it fails.
  #
  def authenticate_user!
    username = request.headers['X-Ops-Userid']
    user = Account.for_provider.where(username: username).first.try(:user)

    unless user
      return error(
        {
          error_code: t('api.error_codes.authentication_failed'),
          error_messages: [t('api.error_messages.invalid_username', username: username)]
        },
        401
      )
    end

    if user.public_key.nil?
      return error(
        {
          error_code: t('api.error_codes.authentication_failed'),
          error_messages: [t('api.error_messages.missing_public_key_error', current_host: request.base_url)]
        },
        401
      )
    end

    # hack pending integration of non-chef oauth
    if ENV['OAUTH_ACCOUNT_PROVIDER'] == 'chef_oauth2'
      auth = Mixlib::Authentication::SignatureVerification.new.authenticate_user_request(
        request,
        OpenSSL::PKey::RSA.new(user.public_key)
      )
    else
      auth = true
    end

    if auth
      @current_user = user
    else
      error(
        {
          error_code: t('api.error_codes.authentication_failed'),
          error_messages: [t('api.error_messages.authentication_key_error')]
        },
        401
      )
    end
  end

end
