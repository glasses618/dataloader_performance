module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :all_same_records, [Types::PostType] do
      argument :size, Integer, required: true
    end

    field :all_different_records, [Types::PostType] do
      argument :size, Integer, required: true
    end

    def all_same_records(size:)
      post = Post.joins(:user).last
      Array.new(size){ post }
    end

    def all_different_records(size:)
      Post.joins(:user).last(size)
    end
  end
end
