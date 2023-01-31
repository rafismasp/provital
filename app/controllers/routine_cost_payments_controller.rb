class RoutineCostPaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_routine_cost_payment, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /routine_cost_payments
  # GET /routine_cost_payments.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    routine_cost_payments = RoutineCostPayment.where("date between ? and ?", session[:date_begin], session[:date_end]).order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("approved3_at desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']] 
      @option_filter_records = routine_cost_payments

      if params[:filter_column].present?
       routine_cost_payments = routine_cost_payments.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

      case params[:view_kind]
      when 'item'
        routine_cost_payments = RoutineCostPaymentItem.where(:status=> 'active')
        .includes(:routine_cost_payment,:routine_cost,:routine_cost_interval)
        .where(:routine_cost_payments => {:company_profile_id => current_user.company_profile_id})
        .where("routine_cost_payments.date between ? and ?", session[:date_begin], session[:date_end])
        .order("routine_cost_payments.date desc")
      else
        routine_cost_payments   = routine_cost_payments
      end

    # filter select - end


    logger.info "==========================="
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @routine_cost_payments = pagy(routine_cost_payments, page: params[:page], items: pagy_items)
  end

  # GET /routine_cost_payments/1
  # GET /routine_cost_payments/1.json
  def show
    @record_files = RoutineCostPaymentFile.where(:routine_cost_payment_id=>params[:id],:status=>"active")
  end

  # GET /routine_cost_payments/new
  def new
    @routine_cost_payment = RoutineCostPayment.new
  end

  # GET /routine_cost_payments/1/edit
  def edit

    @record_files = RoutineCostPaymentFile.where(:routine_cost_payment_id=>params[:id],:status=>"active")
  end

    def export
    template_report(controller_name, current_user.id, nil)
    puts "ini"
  end
  
  # POST /routine_cost_payments
  # POST /routine_cost_payments.json
  def create
    params[:routine_cost_payment]["company_profile_id"] = current_user.company_profile_id
    params[:routine_cost_payment]["created_by"] = current_user.id
    params[:routine_cost_payment]["created_at"] = DateTime.now()
    params[:routine_cost_payment]["number"] = document_number(controller_name, DateTime.now(), params[:routine_cost_payment]["department_id"], nil, nil)
    logger.info params[:routine_cost_payment]
    @routine_cost_payment = RoutineCostPayment.new(routine_cost_payment_params)

    respond_to do |format|
      if @routine_cost_payment.save
        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = RoutineCostPaymentFile.where(:routine_cost_payment_id=>@routine_cost_payment.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/routine_cost_payment/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                RoutineCostPaymentFile.create({
                  :routine_cost_payment_id=> @routine_cost_payment.id,
                  :filename_original=>filename_original,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path,
                  :ext=> ext,
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })             
              end
            end 
          end  
        else
         flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
        end

        params["new_record_item"].each do |item|
          wawa = RoutineCostPaymentItem.new({
            :routine_cost_id=> item["routine_cost_id"].to_i,
            :routine_cost_interval_id=> item["routine_cost_interval_id"].to_i,
            :routine_cost_payment_id=> @routine_cost_payment.id.to_i,
            :coa_name=> item["coa_name"],
            :coa_number=> item["coa_number"],
            :amount=> item["amount"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })

          wawa.save
          wawa.routine_cost_interval.update_columns({:status=>"closed"})
        end if params[:new_record_item].present?
        
        @routine_cost_payment.update_columns(:grand_total=> @routine_cost_payment.routine_cost_payment_items.sum(:amount) )
        format.html { redirect_to @routine_cost_payment, notice: 'Routine Cost Payment was successfully created.' }
        format.json { render :show, status: :created, location: @routine_cost_payment }
      else
        format.html { render :new }
        format.json { render json: @routine_cost_payment.errors, status: :unprocessable_entity }
      end
      logger.info @routine_cost_payment.errors
    end
  end

  def update
    params[:routine_cost_payment]["updated_by"] = current_user.id
    params[:routine_cost_payment]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @routine_cost_payment.update(routine_cost_payment_params)   
        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = RoutineCostPaymentFile.where(:routine_cost_payment_id=>@routine_cost_payment.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/routine_cost_payment/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                RoutineCostPaymentFile.create({
                  :routine_cost_payment_id=> @routine_cost_payment.id,
                  :filename_original=>filename_original,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path,
                  :ext=> ext,
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })             
              end
            end 
          end  
        else
         flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
        end

        params["record_file"].each do |item|
          file = RoutineCostPaymentFile.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            file.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          end
        end if params["record_file"].present?

        params["new_record_item"].each do |item|
          payment_item = RoutineCostPaymentItem.new({
            :routine_cost_id=> item["routine_cost_id"].to_i,
            :routine_cost_interval_id=> item["routine_cost_interval_id"].to_i,
            :routine_cost_payment_id=> @routine_cost_payment.id.to_i,
            :coa_name=> item["coa_name"],
            :coa_number=> item["coa_number"],
            :amount=> item["amount"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })

          payment_item.save
          payment_item.routine_cost_interval.update_columns({:status=>"closed"})
        end if params["new_record_item"].present?
        

        params["record_item"].each do |item|
          payment_item = RoutineCostPaymentItem.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            payment_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })

            payment_item.routine_cost_interval.update_columns({:status=>"open"})
          else
            payment_item.update_columns({
              :coa_name=> item["coa_name"],
              :coa_number=> item["coa_number"],
              :amount=> item["amount"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })

          end if payment_item.present?
        end if params["record_item"].present?

        @routine_cost_payment.update_columns(:grand_total=> @routine_cost_payment.routine_cost_payment_items.sum(:amount) )
        format.html { redirect_to routine_cost_payment_path(:id=> @routine_cost_payment.id), notice: "#{@routine_cost_payment.number} was successfully Updated" }
        format.json { render :show, status: :created, location: @routine_cost_payment }     
      else
        format.html { render :edit }
        format.json { render json: @routine_cost_payment.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve    
    case params[:status]
    when 'void'
      @routine_cost_payment.update({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()}) 
    when 'cancel_void'
      @routine_cost_payment.update({:status=> 'new'}) 
    when 'approve1'
      @routine_cost_payment.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @routine_cost_payment.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @routine_cost_payment.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @routine_cost_payment.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @routine_cost_payment.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @routine_cost_payment.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to routine_cost_payments_url, alert: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to routine_cost_payment_path(:id=> @routine_cost_payment.id), notice: "Routine Cost was successfully #{@routine_cost_payment.status}." }
        format.json { head :no_content }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  def print
      pdf = Prawn::Document.new(:page_size=> "A4", :margin=>10)
      pdf.font "Helvetica"
      pdf.font_size 9

      # HEADER         

      image_path      = "app/assets/images/logo.png" 
      company_ori     = "PT. PROVITAL PERDANA" 
      company         = "PT. PROVITAL PERDANA"
      company_address = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      city            = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      title           = "Jl. Kranji Blok F15 No. 1C,
          Delta Silicon 2, Lippo Cikarang"
      phone_number    = " "
     
      my_company       = ""

      # CONTENT
        pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>10, :right_margin=>10)
        pdf.font "Helvetica"
        pdf.font_size 9

        header = @routine_cost_payment
        items  = @routine_cost_payment_items


        case params[:print_kind]
        when 'print'
          case params[:print_kind]
          when 'print' 
            if header.printed_by.present?
              pdf.text "Sudah Pernah di Print, untuk print ulang silakan untuk Request Unlock Print."
            else
              header.update_columns({:printed_by=> current_user.id,:printed_at=>DateTime.now()})

              pdf.move_down 100
              tbl_header = [[{:content=> "No", width: 25, valign: :center, :font_style => :bold}, 
                        {:content=> "Nama Biaya", width: 150, valign: :center, :font_style => :bold},
                        {:content=> "Nama COA", width: 100, valign: :center, :font_style => :bold},
                        {:content=> "No.COA", width: 70, valign: :center, :font_style => :bold},
                        {:content=> "Periode Biaya", width: 50, valign: :center, :font_style => :bold},
                        {:content=> "Jenis Nominal", width: 80, valign: :center, :font_style => :bold},
                        {:content=> "Nominal", width: 100, valign: :center, :font_style => :bold}]]
              pdf.table(tbl_header, cell_style: {align: :center, size: 9, padding: 5})
              c = 1
              sum_cost_nominal = 0
              items.each do |item|

                routine_cost_interval = nil
                case item.routine_cost.interval 
                when 'annual'
                  routine_cost_interval = item.routine_cost_interval.date.strftime("%Y")
                when 'monthly'
                  routine_cost_interval = item.routine_cost_interval.date.strftime("%b-%Y")
                when 'weekly'
                  routine_cost_interval = item.routine_cost_interval.date.strftime("%A, %W , %Y")
                end
                pdf.table([[
                  {:content=>c.to_s+".", :align=>:right}, 
                  item.routine_cost.cost_name.to_s, item.coa_name.to_s, item.coa_number.to_s, routine_cost_interval.to_s, item.routine_cost.nominal_type.to_s,
                  {:content=> number_with_precision( item.amount, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
                  ] ], :column_widths => [25, 150, 100, 70, 50, 80, 100], :cell_style => {:padding=> 5})
                sum_cost_nominal += item.amount.to_f
                c +=1
              end

              pdf.table([[
                {:content=> "Total", :width=> 475, :align=>:center, :font_style => :bold}, 
                {:content=> number_with_precision( sum_cost_nominal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 100, :font_style => :bold}
              ]])

              pdf.move_down 10
              footer_sign  = [
                [{:content=> "Dibuat", width: 100, :align=> :center}, {:content=> "Diperiksa", width: 100, :align=> :center}, {:content=> "Disetujui", width: 100, :align=> :center}],
                [
                  {:content=> "#{header.created.first_name if header.created.present?}", width: 100, :align=> :center}, 
                  {:content=> "#{header.approved2.first_name if header.approved2.present?}", width: 100, :align=> :center}, 
                  {:content=> "#{header.approved3.first_name if header.approved3.present?}", width: 100, :align=> :center}]
              ]
              pdf.table([["",footer_sign,""]], :column_widths => [150, 300, 100], :cell_style => {:border_width => 0, :border_color => "000000", :padding => 2})

              pdf.move_down 10
              pdf.page_count.times do |i|
                pdf.go_to_page i+1
                pdf.table([
                  [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
                  [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
                  :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
                pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
                
                pdf.move_down 50
                pdf.draw_text ("ROUTINE COST PAYMENT"), :at => [160,5], :size => 14, :style=> :bold
                pdf.move_down 5   
                pdf.stroke_horizontal_rule  
                pdf.move_down 5     
                pdf.table([
                  [ {:content=> "No.BPK"}, {:content=> ": #{header.number}"}, {:content=> "Department"}, {:content=> ": #{header.department.name if header.department.present?}"}],
                  [ {:content=> "Tanggal"}, {:content=> ": #{header.date}"}]
                ],
                :column_widths => [60, 140, 60, 300], :cell_style => {:background_color => "ffffff", :border_color=> "ffffff", :padding=>1})
                }
              end
            end
          end
        else
          pdf.text "not yet available"
        end      

      # FOOTER
      pdf.page_count.times do |i|
        pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => 100) {
          pdf.go_to_page i+1
          pdf.number_pages "Halaman <page> s/d <total>", :size => 9         
        }
      end
      
      pdf.move_down 10
      send_data pdf.render, type: "application/pdf", disposition: "inline"
  end

  # DELETE /routine_cost_payments/1
  # DELETE /routine_cost_payments/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to routine_cost_payments_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def check_status
    if @routine_cost_payment.status == 'approved3'
      respond_to do |format|
        format.html { redirect_to @routine_cost_payment, notice: 'Cannot be edited because it has been approved' }
        format.json { render :show, status: :created, location: @routine_cost_payment }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_routine_cost_payment
      if params[:multi_id].present?
        @routine_cost_payment = RoutineCostPayment.where(:id=> params[:multi_id].split(','))
        if @routine_cost_payment.present?
          # nothing
        else
          respond_to do |format|
            format.html { redirect_to routine_cost_payments_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      else
        @routine_cost_payment = RoutineCostPayment.find_by(:id=> params[:id])
        if @routine_cost_payment.present?
          @routine_cost_payment_items = RoutineCostPaymentItem.where(:status=> 'active')
          .includes(:routine_cost_payment,:routine_cost,:routine_cost_interval)
          .where(:routine_cost_payments => {:id=> params[:id], :company_profile_id => current_user.company_profile_id })
          .order("routine_cost_payments.number desc")
        else
          respond_to do |format|
            format.html { redirect_to routine_cost_payments_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      end
    end

    def set_instance_variable
      @routine_cost_payments = RoutineCostPayment.where(:company_profile_id=> current_user.company_profile_id)

      @routine_cost = RoutineCost.where(:company_profile_id=> current_user.company_profile_id,:status=>'approved3')
      @routine_cost = @routine_cost.where(:department_id=>params[:select_department_id]) if params[:select_department_id].present?

      @routine_cost_interval = RoutineCostInterval.where(:company_profile_id=> current_user.company_profile_id,:status=>'open', :routine_cost_id=>@routine_cost.map { |e| e.id  })

      @work_statuses = WorkStatus.all
      @departments = Department.all
      @positions = Position.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def routine_cost_payment_params
      params.require(:routine_cost_payment).permit(:number, :company_profile_id, :department_id, :date, :remarks, :grand_total, :voucher_number, :created_by, :created_at, :updated_by, :updated_at, :img_created_signature)
    end
end
