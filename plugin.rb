# frozen_string_literal: true
# name: discourse-novachain-plugin
# about: NovaChain Proof-of-Action integration for Discourse - Auto-Transfer at 5000 EP
# version: 1.1.1
# authors: NovaChain Team
# url: https://nova-chain.io/presale
# required_version: 2.7.0

enabled_site_setting :novachain_enabled

after_initialize do
  module ::NovaChain
    PLUGIN_NAME = "discourse-novachain-plugin"
    AUTO_TRANSFER_THRESHOLD = 5000
    
    ENERGY_POINTS = {
      topic_created: 5,
      post_created: 3,
      solution_accepted: 8,
      badge_earned: 4,
      like_given: 2,
      like_received: 1,
      daily_visit: 1
    }
    
    class << self
      def award_energy(user, points, activity_type)
        return unless SiteSetting.novachain_enabled && user
        
        current_balance = user.custom_fields["novachain_energy_balance"].to_i
        new_balance = current_balance + points
        user.custom_fields["novachain_energy_balance"] = new_balance
        
        today = Date.today.to_s
        daily_key = "novachain_energy_earned_#{today}"
        daily_earned = user.custom_fields[daily_key].to_i
        user.custom_fields[daily_key] = daily_earned + points
        
        user.save_custom_fields(true)
        
        Rails.logger.info("[NovaChain] #{user.username} +#{points} EP (#{activity_type}) -> Balance: #{new_balance}")
        
        check_and_trigger_transfer(user, new_balance)
      end
      
      def check_and_trigger_transfer(user, balance)
        wallet = user.custom_fields["novachain_wallet_address"]
        return unless wallet.present?
        
        transferred = user.custom_fields["novachain_energy_transferred"].to_i
        pending = balance - transferred
        
        if pending >= AUTO_TRANSFER_THRESHOLD
          trigger_blockchain_transfer(user, pending, wallet)
        end
      end
      
      def trigger_blockchain_transfer(user, amount, wallet)
        api_url = "https://mjeqsapfdnpufhkquzhn.supabase.co/functions/v1/external-energy-transfer"
        api_key = SiteSetting.novachain_api_key rescue ""
        
        begin
          require "net/http"
          require "uri"
          require "json"
          
          uri = URI.parse(api_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.read_timeout = 10
          
          request = Net::HTTP::Post.new(uri.path, {
            "Content-Type" => "application/json",
            "x-api-key" => api_key
          })
          
          request.body = {
            action: "transfer",
            wallet_address: wallet,
            energy_amount: amount,
            user_id: user.id,
            username: user.username,
            timestamp: Time.now.to_i,
            source: "discourse_forum"
          }.to_json
          
          response = http.request(request)
          
          if response.is_a?(Net::HTTPSuccess)
            current_transferred = user.custom_fields["novachain_energy_transferred"].to_i
            user.custom_fields["novachain_energy_transferred"] = current_transferred + amount
            user.custom_fields["novachain_last_transfer_at"] = Time.now.to_i
            user.custom_fields["novachain_last_transfer_amount"] = amount
            user.save_custom_fields(true)
            
            Rails.logger.info("[NovaChain] AUTO-TRANSFER #{amount} EP -> Wallet #{wallet} (User: #{user.username})")
          else
            Rails.logger.error("[NovaChain] Transfer failed: #{response.code} - #{response.body}")
            user.custom_fields["novachain_transfer_pending"] = amount
            user.custom_fields["novachain_transfer_retry_at"] = (Time.now + 1.hour).to_i
            user.save_custom_fields(true)
          end
          
        rescue => e
          Rails.logger.error("[NovaChain] Transfer Exception: #{e.message}")
          user.custom_fields["novachain_transfer_error"] = e.message
          user.custom_fields["novachain_transfer_pending"] = amount
          user.save_custom_fields(true)
        end
      end
    end
  end
  
  # Activity Hooks
  on(:topic_created) do |topic, opts, user|
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:topic_created], "topic")
  end
  
  on(:post_created) do |post, opts, user|
    next if post.is_first_post?
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:post_created], "post")
  end
  
  on(:accepted_solution) do |post|
    NovaChain.award_energy(post.user, NovaChain::ENERGY_POINTS[:solution_accepted], "solution")
  end
  
  on(:user_badge_granted) do |badge_id, user_id|
    user = User.find_by(id: user_id)
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:badge_earned], "badge") if user
  end
  
  on(:like_created) do |post_action|
    post = Post.find_by(id: post_action.post_id)
    NovaChain.award_energy(post.user, NovaChain::ENERGY_POINTS[:like_given], "like_received") if post && post.user
    
    user = User.find_by(id: post_action.user_id)
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:like_received], "like_given") if user
  end
  
  on(:user_logged_in) do |user|
    last_visit = user.custom_fields["novachain_last_visit_date"]
    today = Date.today.to_s
    
    if last_visit != today
      NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:daily_visit], "daily_visit")
      user.custom_fields["novachain_last_visit_date"] = today
      user.save_custom_fields(true)
    end
  end
  
  Rails.logger.info("[NovaChain] Energy Plugin v1.1.1 loaded - Auto-Transfer at #{NovaChain::AUTO_TRANSFER_THRESHOLD} EP")
end
