# frozen_string_literal: true

class Sources::AssociationV2 < GraphQL::Dataloader::Source
  def initialize(model, association_name)
    @model = model
    @association_name = association_name
    validate
    @cache = {}
  end

  def load(record)
    fail TypeError, "#{@model} loader can't load association for #{record.class}" if !record.is_a?(@model)
    cache_key = cache_key(record)
    @cache[cache_key] = record
    super(cache_key)
  end

  def fetch(cache_keys)
    records = cache_keys.map{|k| @cache[k] ||= @model.find(k) }
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

  def cache_key(record)
    record.object_id
  end
end
