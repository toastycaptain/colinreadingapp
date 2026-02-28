class Publisher::TeamMembersController < Publisher::BaseController
  before_action :require_owner!

  def index
    @team_members = current_publisher.publisher_users.order(created_at: :desc)
  end

  def create
    generated_password = SecureRandom.base58(24)
    member = current_publisher.publisher_users.new(
      email: params.require(:email),
      role: params.require(:role),
      password: generated_password,
      password_confirmation: generated_password,
    )

    if member.save
      member.send_reset_password_instructions
      redirect_to publisher_team_members_path, notice: "Team member added. Reset instructions sent."
    else
      @team_members = current_publisher.publisher_users.order(created_at: :desc)
      flash.now[:alert] = member.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    member = current_publisher.publisher_users.find(params[:id])
    if member == current_publisher_user
      return redirect_to publisher_team_members_path, alert: "You cannot remove your own account."
    end

    member.destroy!
    redirect_to publisher_team_members_path, notice: "Team member removed."
  end
end
