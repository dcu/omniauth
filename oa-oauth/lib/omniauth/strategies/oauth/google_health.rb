require 'omniauth/oauth'
require 'multi_json'

module OmniAuth
  module Strategies
    #
    # Authenticate to Google via OAuth and retrieve basic
    # user information.
    #
    # Usage:
    #
    #    use OmniAuth::Strategies::Google, 'consumerkey', 'consumersecret'
    #
    class GoogleHealth < OmniAuth::Strategies::OAuth
      def initialize(app, consumer_key=nil, consumer_secret=nil, options={}, &block)
        client_options = {
          :authorize_url => 'https://www.google.com/accounts/OAuthAuthorizeToken',
          :token_url => 'https://www.google.com/accounts/OAuthGetAccessToken',
        }

        super(app, :google_health, consumer_key, consumer_secret, client_options, options)
      end

      def auth_hash
        ui = user_info
        OmniAuth::Utils.deep_merge(super, {
          'uid' => ui['uid'],
          'user_info' => ui,
          'extra' => {'user_hash' => user_hash}
        })
      end

      def user_info
        email = user_hash['feed']['id']['$t']

        name = user_hash['feed']['author'].first['name']['$t']
        name = email if name.strip == '(unknown)'

        {
          'email' => email,
          'uid' => email,
          'name' => name
        }
      end

      def user_hash
        # Google is very strict about keeping authorization and
        # authentication separated.
        # They give no endpoint to get a user's profile directly that I can
        # find. We *can* get their name and email out of the contacts feed,
        # however. It will fail in the extremely rare case of a user who has
        # a Google Account but has never even signed up for Gmail. This has
        # not been seen in the field.
        @user_hash ||= MultiJson.decode(@access_token.get("http://www.google.com/health/feeds/profile/default/default?digest=true&alt=json").body)
      end
    end
  end
end
