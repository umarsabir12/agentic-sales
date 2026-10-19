class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ edit update destroy ]

  def index
    @users = User.order(Arel.sql("approved_at IS NOT NULL"), :name)
  end

  def approve
    @user = User.find(params[:id])
    @user.approve!
    redirect_to admin_users_path, notice: "#{@user.name} can now sign in."
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(approved_at: Time.current))

    if @user.save
      redirect_to admin_users_path, notice: "#{@user.name} was added to the team."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs = user_params
    attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

    if @user.update(attrs)
      redirect_to admin_users_path, notice: "#{@user.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "You can't remove yourself."
    else
      @user.destroy!
      redirect_to admin_users_path, notice: "#{@user.name} was removed.", status: :see_other
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: %i[ name email role password password_confirmation ])
    end
end
