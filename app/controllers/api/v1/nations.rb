# frozen_string_literal: true

module API
  module V1
    #
    # Nations API
    #
    class Nations < Grape::API
      include API::V1::Defaults
      resource :nations do
        desc 'Return all nations'
        get '' do
          Nation.all
        end

        desc 'Return a nation'
        params do
          requires :name, type: String, desc: 'The name of the nation'
        end
        get ':name' do
          Nation.where(name: permitted_params[:name]).first!
        end
      end
    end
  end
end
