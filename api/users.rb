require 'grape'
require_relative '../config/algolia'
require_relative '../config/mongo'
require_relative '../lib/securerandom'
require_relative 'entities/user'

module API
  class Users < Grape::API

    desc "Users", hidden: true
    namespace :users, hidden: true do

      get "/:email", requirements: {email:  /.+@.+/}  do
        user = $db[:users].find({email: params[:email]}).to_a.first
        present :data, user, with: Entities::User
      end

      post "/signed_in", hidden: true do
        user = $db[:users].find({email: params[:profile][:email]}).find_one_and_update({
          "$inc" => {signInCount:  1},
          "$set" => {
            profile: params[:profile],
          },
          "$setOnInsert" => {
            "_id" => SecureRandom.uuid().to_s.upcase.gsub('-', ''),
            "allowedOrigins" => []
          }
        }, {upsert: true, return_document: :after})

        if user[:algoliaApiKey].nil?
          #  Algolia.generate_secured_api_key(user[:email])
          index = Algolia::Index.new('common-standards-project')
          key = index.add_user_key({
            :maxQueriesPerIPPerHour => 200,
            :indexes                => ["common-standards-project"],
            :acl                    => ["search"],
            :description            => "#{user[:email]} - #{user[:profile][:name]} - Limited to searching standards"
          })
          user = $db[:users].find({_id: user[:_id]}).find_one_and_update({
            "$set" => {algoliaApiKey: key["key"]}
          }, {return_document: :after})
        end

        if user[:apiKey].nil?
          user = $db[:users].find({_id: user[:_id]}).find_one_and_update({
            "$set" => {apiKey: SecureRandom.base58(24)}
          }, {return_document: :after})
        end

        present :data, user, with: Entities::User
      end


      post "/:id/allowed_origins", hidden: true do
        user = $db[:users].find({_id: params[:id]}).find_one_and_update({
          "$set" => {allowedOrigins: params[:data]}
        }, {return_document: true})
        present :data, user, with: Entities::User
      end

    end
  end
end
