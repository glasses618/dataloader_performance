**Describe the bug**

When

**Versions**

`graphql` version: 2.0.17
`rails` version: 6.1.7.2
`graphql-batch` version: 0.5.2

**GraphQL schema**

Include relevant types and fields (in Ruby is best, in GraphQL IDL is ok). Any custom extensions, etc?

```ruby
class Sources::Association < GraphQL::Dataloader::Source
  def initialize(model, association_name)
    @model = model
    @association_name = association_name
    validate
  end

  def load(record)
    fail TypeError, "#{@model} loader can't load association for #{record.class}" if !record.is_a?(@model)
    super
  end

  def fetch(records)
    preload_association(records)
    records.map{|s| read_association(s) }
  end

  private

  def validate
    return if @model.reflect_on_association(@association_name)

    fail ArgumentError, "No association #{@association_name} on #{@model}"
  end

  def preload_association(records)
    ::ActiveRecord::Associations::Preloader.new.preload(records, @association_name)
  end

  def read_association(record)
    record.public_send(@association_name)
  end

  def association_loaded?(record)
    record.association(@association_name).loaded?
  end
end
```

```ruby
class AssociationLoader < GraphQL::Batch::Loader
  def self.validate(model, association_name)
    new(model, association_name)
    nil
  end

  def initialize(model, association_name)
    super()
    @model = model
    @association_name = association_name
    validate
  end

  def load(record)
    raise TypeError, "#{@model} loader can't load association for #{record.class}" unless record.is_a?(@model)
    return Promise.resolve(read_association(record)) if association_loaded?(record)
    super
  end

  # We want to load the associations on all records, even if they have the same id
  def cache_key(record)
    record.object_id
  end

  def perform(records)
    preload_association(records)
    records.each { |record| fulfill(record, read_association(record)) }
  end

  private

  def validate
    unless @model.reflect_on_association(@association_name)
      raise ArgumentError, "No association #{@association_name} on #{@model}"
    end
  end

  def preload_association(records)
    ::ActiveRecord::Associations::Preloader.new.preload(records, @association_name)
  end

  def read_association(record)
    record.public_send(@association_name)
  end

  def association_loaded?(record)
    record.association(@association_name).loaded?
  end
end
```

```ruby
module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :test_data_loader, [Types::PostType] do
      argument :size, Integer, required: true
    end

    def test_data_loader(size:)
      post = Post.joins(:user).last
      Array.new(size){ post }
    end
  end
end
```

```ruby
module Types
  class UserType < BaseObject
    field :id, Integer
  end
end
```

```ruby
module Types
  class PostType < BaseObject
    field :dataloader_user, Types::UserType, null: false
    field :graphql_batch_user, Types::UserType, null: false

    def graphql_batch_user
      AssociationLoader.for(object.class, :user).load(object)
    end

    def dataloader_user
      dataloader.with(::Sources::Association, object.class, :user).load(object)
    end
  end
end
```

**GraphQL query**

Example GraphQL query and response (if query execution is involved)

```graphql
query {
  testDataLoader(size: 3000) {
    dataloaderUser {
      id
    }
  }
}
```

```graphql
query {
  testDataLoader(size: 3000) {
    graphqlBatchUser {
      id
    }
  }
}
```

**Steps to reproduce**

Steps to reproduce the behavior

**Expected behavior**

A clear and concise description of what you expected to happen.

**Actual behavior**

What specifically went wrong?

Place full backtrace here (if a Ruby exception is involved):

<details>
<summary>Click to view exception backtrace</summary>

```
Something went wrong
2.6.0/gems/graphql-1.9.17/lib/graphql/subscriptions/instrumentation.rb:34:in `after_query'
… don't hesitate to include all the rows here: they will be collapsed
```

</details>

**Additional context**

Add any other context about the problem here.

With these details, we can efficiently hunt down the bug!
