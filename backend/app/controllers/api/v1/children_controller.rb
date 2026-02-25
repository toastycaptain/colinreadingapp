class Api::V1::ChildrenController < Api::V1::BaseController
  before_action :require_parent!
  before_action :set_child, only: :update

  def index
    render json: current_user.child_profiles.order(created_at: :asc).as_json(
      only: %i[id name avatar_url created_at updated_at],
    )
  end

  def create
    child = current_user.child_profiles.create!(child_params)
    render json: child.as_json(only: %i[id name avatar_url created_at updated_at]), status: :created
  end

  def update
    @child.update!(child_params)
    render json: @child.as_json(only: %i[id name avatar_url created_at updated_at])
  end

  private

  def set_child
    @child = current_user.child_profiles.find(params[:id])
  end

  def child_params
    params.permit(:name, :avatar_url, :pin_hash)
  end
end
