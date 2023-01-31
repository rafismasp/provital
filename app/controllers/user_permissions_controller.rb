class UserPermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_permission, only: [:show, :edit, :update, :destroy]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create, :save_duplicate]
  before_action :require_permission_remove, only: [:destroy]

  # GET /user_permissions
  # GET /user_permissions.json
  def index
    @user_permissions = UserPermission.all
    @users = User.where(:id=> UserPermission.group(:user_id).select(:user_id), :status=> 'active').order("first_name asc")
  end

  # GET /user_permissions/1
  # GET /user_permissions/1.json
  def show
    @user = User.find_by(:id=> params[:id])
    @user_permissions = UserPermission.where(:user_id=> params[:id])
  end

  # GET /user_permissions/new
  def new
    @user_permission = UserPermission.new
    @users = User.where.not(:id=> UserPermission.group(:user_id).select(:user_id))
  end

  # GET /user_permissions/1/edit
  def edit
    @users = User.where(:id=> params[:id])
    @user_permissions = UserPermission.where(:user_id=> params[:id])
  end

  # POST /user_permissions
  # POST /user_permissions.json
  def create
    params[:permission_parent].each do |permission|
      find_permission = UserPermission.find_by(:user_id=> params[:user_permission]["user_id"], :permission_base_id=> permission["permission_base_id"])
      if find_permission.present?
        find_permission.update_columns({
          :user_id=> params[:user_permission]["user_id"],
          :permission_base_id=> permission["permission_base_id"],
          :name=> permission["name"],
          :access_view=> permission["access_view"].to_i,
          :updated_by=> current_user.id,
          :updated_at=> DateTime.now()
        })
      else
        UserPermission.create({
          :user_id=> params[:user_permission]["user_id"],
          :permission_base_id=> permission["permission_base_id"],
          :name=> permission["name"],
          :access_view=> permission["access_view"].to_i,
          :created_by=> current_user.id,
          :created_at=> DateTime.now()
        })
      end
      logger.info "----------------------"
      logger.info permission["permission_base_id"]
      logger.info permission["name"]
      logger.info permission["access_view"]
      logger.info permission["access_create"]
      logger.info permission["access_edit"]
      logger.info permission["access_remove"]
      logger.info "----------------------"
    end if params[:permission_parent].present?

    grant_permission(params[:permission_child1])
    grant_permission(params[:permission_child2])

    # @user_permission = UserPermission.new(user_permission_params)

    respond_to do |format|
      format.html { redirect_to '/user_permissions', notice: 'User permission was successfully created.' }
    end
  end

  # PATCH/PUT /user_permissions/1
  # PATCH/PUT /user_permissions/1.json
  def update
    params[:permission_parent].each do |permission|
      find_permission = UserPermission.find_by(:user_id=> params[:user_permission]["user_id"], :permission_base_id=> permission["permission_base_id"])
      if find_permission.present?
        find_permission.update_columns({
          :user_id=> params[:user_permission]["user_id"],
          :permission_base_id=> permission["permission_base_id"],
          :name=> permission["name"],
          :access_view=> (permission["access_view"].present? ? 1 : 0),
          :updated_by=> current_user.id,
          :updated_at=> DateTime.now()
        })
      else
        UserPermission.create({
          :user_id=> params[:user_permission]["user_id"],
          :permission_base_id=> permission["permission_base_id"],
          :name=> permission["name"],
          :access_view=> (permission["access_view"].present? ? 1 : 0),
          :created_by=> current_user.id,
          :created_at=> DateTime.now()
        })
      end
      logger.info "----------------------"
      logger.info permission["permission_base_id"]
      logger.info permission["name"]
      logger.info permission["access_view"]
      logger.info permission["access_create"]
      logger.info permission["access_edit"]
      logger.info permission["access_remove"]
      logger.info "----------------------"
    end if params[:permission_parent].present?

    grant_permission(params[:permission_child1])
    grant_permission(params[:permission_child2])

    respond_to do |format|
      format.html { redirect_to '/user_permissions', notice: 'User permission was successfully created.' }
    end
  end

  # DELETE /user_permissions/1
  # DELETE /user_permissions/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to user_permissions_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def duplicate
    @users = User.includes(:department).where(status: 'active')
  end

  def save_duplicate
    user_id = params[:to_user_id]
    created = DateTime.now()
    permissions = UserPermission.where(user_id: params[:from_user_id])

    UserPermission.where(user_id: user_id).delete_all
    permissions.each do |data|
      UserPermission.create({
        :user_id => user_id,
        :permission_base_id => data.permission_base_id,
        :name => data.name,
        :access_view => data.access_view,
        :access_export => data.access_export,
        :access_create => data.access_create,
        :access_edit => data.access_edit,
        :access_remove => data.access_remove,
        :access_approve1 => data.access_approve1,
        :access_cancel_approve1 => data.access_cancel_approve1,
        :access_approve2 => data.access_approve2,
        :access_cancel_approve2 => data.access_cancel_approve2,
        :access_approve3 => data.access_approve3,
        :access_cancel_approve3 => data.access_cancel_approve3,
        :access_void => data.access_void,
        :access_cancel_void => data.access_cancel_void,
        :access_unlock_print => data.access_unlock_print,
        :created_by=> current_user.id,
        :created_at=> created
      })
    end

    respond_to do |format|
      format.html { redirect_to '/user_permissions', notice: 'User permission was duplicated successfully.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_permission
      @user_permission = UserPermission.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_permission_params

      params.require(:user_permission).permit(:name, :user_id)
    end

    def grant_permission(new_permission)
      new_permission.each do |permission|
        find_permission = UserPermission.find_by(:user_id=> params[:user_permission]["user_id"], :permission_base_id=> permission["permission_base_id"])
        access_export = (permission["access_export"].present? ? permission["access_export"] : 0)
        access_view = (permission["access_view"].present? ? permission["access_view"] : 0)
        access_create = (permission["access_create"].present? ? permission["access_create"] : 0)
        access_edit = (permission["access_edit"].present? ? permission["access_edit"] : 0)
        access_approve1 = (permission["access_approve1"].present? ? permission["access_approve1"] : 0)
        access_cancel_approve1 = (permission["access_cancel_approve1"].present? ? permission["access_cancel_approve1"] : 0)
        access_approve2 = (permission["access_approve2"].present? ? permission["access_approve2"] : 0)
        access_cancel_approve2 = (permission["access_cancel_approve2"].present? ? permission["access_cancel_approve2"] : 0)
        access_approve3 = (permission["access_approve3"].present? ? permission["access_approve3"] : 0)
        access_cancel_approve3 = (permission["access_cancel_approve3"].present? ? permission["access_cancel_approve3"] : 0)
        access_unlock_print = (permission["access_unlock_print"].present? ? permission["access_unlock_print"] : 0)
        access_void = (permission["access_void"].present? ? permission["access_void"] : 0)
        access_cancel_void = (permission["access_cancel_void"].present? ? permission["access_cancel_void"] : 0)
        access_remove = (permission["access_void"].present? ? permission["access_void"] : 0)
        
        if find_permission.present?
          find_permission.update_columns({
            :user_id=> params[:user_permission]["user_id"],
            :permission_base_id=> permission["permission_base_id"],
            :name=> permission["name"],
            :access_export=> access_export,
            :access_view=> access_view,
            :access_create=> access_create,
            :access_edit=> access_edit,
            :access_approve1=> access_approve1,
            :access_cancel_approve1=> access_cancel_approve1,
            :access_approve2=> access_approve2,
            :access_cancel_approve2=> access_cancel_approve2,
            :access_approve3=> access_approve3,
            :access_cancel_approve3=> access_cancel_approve3,
            :access_unlock_print=> access_unlock_print,
            :access_void=> access_void,
            :access_cancel_void=> access_cancel_void,
            :access_remove=> access_remove,
            :updated_by=> current_user.id,
            :updated_at=> DateTime.now()
          })
        else
          UserPermission.create({
            :user_id=> params[:user_permission]["user_id"],
            :permission_base_id=> permission["permission_base_id"],
            :name=> permission["name"],
            :access_export=> access_export,
            :access_view=> access_view,
            :access_create=> access_create,
            :access_edit=> access_edit,
            :access_approve1=> access_approve1,
            :access_cancel_approve1=> access_cancel_approve1,
            :access_approve2=> access_approve2,
            :access_cancel_approve2=> access_cancel_approve2,
            :access_approve3=> access_approve3,
            :access_cancel_approve3=> access_cancel_approve3,
            :access_unlock_print=> access_unlock_print,
            :access_void=> access_void,
            :access_cancel_void=> access_cancel_void,
            :access_remove=> access_remove,
            :created_by=> current_user.id,
            :created_at=> DateTime.now()
          })
        end
        logger.info "----------------------"
        logger.info permission["permission_base_id"]
        logger.info permission["name"]
        logger.info permission["access_view"]
        logger.info permission["access_create"]
        logger.info permission["access_edit"]
        logger.info permission["access_remove"]
        logger.info "----------------------"
      end if new_permission.present?
    end
end
