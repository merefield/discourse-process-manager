# frozen_string_literal: true

module ProcessManager
  class ProcessOptionSerializer < ApplicationSerializer
    attributes :id, :name, :slug
  end
end
