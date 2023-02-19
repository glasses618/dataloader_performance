# frozen_string_literal: true

module Types
  class PostType < BaseObject
    field :dataloader_user, Types::UserType, null: false
    field :dataloader_user_v2, Types::UserType, null: false
    field :graphql_batch_user, Types::UserType, null: false

    def graphql_batch_user
      AssociationLoader.for(object.class, :user).load(object)
    end

    def dataloader_user
      dataloader.with(::Sources::Association, object.class, :user).load(object)
    end

    def dataloader_user_v2
      dataloader.with(::Sources::AssociationV2, object.class, :user).load(object)
    end
  end
end
