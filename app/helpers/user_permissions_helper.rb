module UserPermissionsHelper
  def require_permission_view
    check_permission("view")
  end
  def require_permission_create
    check_permission("create")
  end
  def require_permission_edit
    check_permission("edit")
  end
  def require_permission_remove
    check_permission("remove")
  end
  def require_permission_export
    check_permission("export")
  end

  def require_permission_approve(param_status)
    check_permission(param_status)
  end

  def check_permission(kind)
    logger.info params[:q]
    logger.info "-------------------"

    if controller_name == 'accounts'
      permission_base_link = 'users' 
    else
      permission_base_link = controller_name
    end
    puts controller_name
    link_param = (params[:q].present? ? "?q=#{params[:q]}" : nil)
    link_param += "&q1=#{params[:q1]}" if params[:q1].present?
    link_param += "&q2=#{params[:q2]}" if params[:q2].present?
    
    if link_param.present?
      link_param += "&tbl_kind=#{params[:tbl_kind]}" if params[:tbl_kind].present?
    else
      link_param = "?tbl_kind=#{params[:tbl_kind]}" if params[:tbl_kind].present?
    end

    permission_base = PermissionBase.find_by(:link=> "/#{permission_base_link}", :link_param=> link_param )
    my_path  = "/#{permission_base_link}#{link_param}"

    case kind
    when 'edit'
      case controller_name
      when 'purchase_order_suppliers','purchase_requests','internal_transfers'
        if controller_name == 'accounts'
          record = Account.find_by(:id=> params[:id])
        else
          record = controller_name.singularize.camelize.constantize.find_by(:id=> params[:id])
        end
        if record.status == 'approved'
          respond_to do |format|
            format.html { redirect_to "/#{controller_name}#{link_param}", alert: "Can't edit when Document already approved!" }
          end
        else
          check_permission_user(kind, permission_base_link, permission_base, my_path)
        end
      else
        check_permission_user(kind, permission_base_link, permission_base, my_path)
      end
    else
      check_permission_user(kind, permission_base_link, permission_base, my_path)
    end
  end

  def check_permission_user(kind, permission_base_link, permission_base, my_path)
    if current_user.present?
      puts "check_permission_user ================== kind: #{kind}"
      user_permission = UserPermission.find_by(:company_profile_id=> current_user.company_profile_id, :user_id=> current_user.id, :permission_base_id=> permission_base.id, "access_#{kind}".to_sym => 1) if permission_base.present?
      old_status  = nil
      case kind
      when 'void'
        # 20210916: aden
        status_update = false
        if user_permission.present?
          record = controller_name.singularize.camelize.constantize.find_by(:id=> params[:id])
          if record.present?
            old_status = record.status

            case old_status
            when 'new', 'canceled1','approved1', 'canceled2'
              if user_permission.access_approve1.to_i == 1
                # bisa void jika punya hak akses approve1 dan status belum approve2
                status_update = true
              end
            end

            case old_status
            when 'new', 'canceled1','approved1', 'canceled2','approved1', 'canceled2'
              if user_permission.access_approve2.to_i == 1
                # bisa void jika punya hak akses approve2 dan status belum approve3
                status_update = true
              end
            end

            case old_status
            when 'new', 'canceled1','approved1', 'canceled2','approved1', 'canceled2','approved2', 'canceled3'
              if user_permission.access_approve3.to_i == 1
                # bisa void jika punya hak akses approve3
                status_update = true
              end
            end
          end
        end
      when 'approve1', 'cancel_approve1', 'approve2', 'cancel_approve2', 'approve3', 'cancel_approve3'
        status_update = false
        record = controller_name.singularize.camelize.constantize.find_by(:id=> params[:id])
        if record.present?
          old_status = record.status

          case params[:status]
          when 'approve1'
            case old_status
            when 'new', 'canceled1'
              status_update = true
            end
          when 'cancel_approve1', 'approve2'
            case old_status
            when 'approved1', 'canceled2'
              status_update = true
            end
          when 'cancel_approve2', 'approve3'
            case old_status
            when 'approved2', 'canceled3'
              status_update = true
            end
          when 'cancel_approve3'
            case old_status
            when 'approved3','unpaid'
              status_update = true
            end
          end

          case controller_name
          when 'invoice_customer_price_logs'
            status_update = true
          end
        end
      else
        status_update = true
      end

      if user_permission.blank?
        puts "No Access to #{kind} #{permission_base_link}."
        respond_to do |format|
          format.html { redirect_to my_path, alert: "No Access to #{kind.humanize} #{permission_base_link.humanize}." }
        end
      else
        if status_update == false
          respond_to do |format|
            format.html { redirect_to my_path, alert: "Current Status: #{old_status}" }
          end
        end
      end
      puts "check_permission_user ================== old_status: #{old_status}"
    else
      redirect_to root_path
      puts "redirect_to root_path"
    end
  end
end
