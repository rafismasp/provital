
class Users::AccountsController < Devise::RegistrationsController
  before_action :set_user, only: [:edit, :update]
  before_action :authenticate_user!

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index]
  before_action :require_permission_edit, only: [:edit, :update]


	def index
		@users = User.all
	end

	def edit
    @sections = @sections.where(:department_id=> params[:select_department_id]) if params[:select_department_id].present?
	end
	def update
    respond_to do |format|
      if @user.update(user_params)
      	puts "update successfully"
        format.html { redirect_to '/users', notice: "User: #{@user.username} was successfully updated." }
        # format.json { render :show, status: :ok, location: @user }
      else
      	puts "update failed"
        format.html { render :edit }
        # format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def upload_signature
    require 'fileutils'
    digest = Digest::MD5.hexdigest("#{current_user.username}_#{DateTime.now()}")
    filename = "#{digest}.png"
    my_path = "public/uploads/signature/#{current_user.id}"

    Dir.mkdir(my_path) unless File.exists?(my_path)

    path = File.join(my_path, filename)
    File.open(path, "wb") { |f| f.write(params[:data][:signature].read) }

    @user = User.find_by(:id=> current_user.id)
    
    @user.update_columns({:signature=> filename})
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
      @sections = EmployeeSection.where(:status=> 'active', :department_id=> @user.department_id)
      @company_profiles = CompanyProfile.where(:status=> 'active')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:email, :username, :first_name, :last_name, :department_id, :employee_section_id, :status, :avatar, :avatar_cache)
    end
end