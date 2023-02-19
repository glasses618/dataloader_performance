# frozen_string_literal: true

class Sources::Association < GraphQL::Dataloader::Source
  def initialize(model, association_name)
    @model = model
    @association_name = association_name
    validate
  end

  def load(record)
    fail TypeError, "#{@model} loader can't load association for #{record.class}" if !record.is_a?(@model)
    super(record)
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
