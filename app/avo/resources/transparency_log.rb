# frozen_string_literal: true

class Avo::Resources::TransparencyLog < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :events_type, as: :text
    field :body, as: :code
  end
end
