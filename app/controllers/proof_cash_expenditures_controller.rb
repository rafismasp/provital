class ProofCashExpendituresController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_proof_cash_expenditure, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /proof_cash_expenditures
  # GET /proof_cash_expenditures.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    proof_cash_expenditures = ProofCashExpenditure.where(:company_profile_id=> current_user.company_profile_id).where("proof_cash_expenditures.date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:department, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :voided).order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("approved3_at desc")
    # filter select - begin
      @option_filters = [['No. BPK','number'],['Department Name','department_id'],['Status','status']] 
      @option_filter_records = proof_cash_expenditures
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'department_id'
          @option_filter_records = Department.where(:status=> 'active').order("name asc")
        end
        proof_cash_expenditures = proof_cash_expenditures.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:view_kind]
    when 'item'
      proof_cash_expenditures = ProofCashExpenditureItem.where(:status=> 'active')
      .includes(:proof_cash_expenditure).where(:proof_cash_expenditures => {:company_profile_id => current_user.company_profile_id })
      .where("proof_cash_expenditures.date between ? and ?", session[:date_begin], session[:date_end]).order("proof_cash_expenditures.date desc")
      puts "ayam"
    else
      proof_cash_expenditures = proof_cash_expenditures.where(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("created_at asc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @proof_cash_expenditures = pagy(proof_cash_expenditures, page: params[:page], items: pagy_items) 
  end

  # GET /proof_cash_expenditures/1
  # GET /proof_cash_expenditures/1.json
  def show
    @record_files = ProofCashExpenditureFile.where(:proof_cash_expenditure_id=> params[:id], :status=>"active")
  end

  # GET /proof_cash_expenditures/new
  def new
    @proof_cash_expenditure = ProofCashExpenditure.new
  end

  # GET /proof_cash_expenditures/1/edit
  def edit
    @record_files = ProofCashExpenditureFile.where(:proof_cash_expenditure_id=> params[:id], :status=>"active")
  end

  # POST /proof_cash_expenditures
  # POST /proof_cash_expenditures.json
  def create        
    params[:proof_cash_expenditure]["company_profile_id"] = current_user.company_profile_id
    params[:proof_cash_expenditure]["created_by"] = current_user.id
    params[:proof_cash_expenditure]["created_at"] = DateTime.now()
    params[:proof_cash_expenditure]["img_created_signature"] = current_user.signature
    params[:proof_cash_expenditure]["number"] = document_number(controller_name, params[:proof_cash_expenditure]["date"].to_date, params[:proof_cash_expenditure]["department_id"], nil, nil)
    puts "#{params[:proof_cash_expenditure]["department_id"]} ayam"
    # document_number(ctrl_name, period, kind, kind2, kind3)
    @proof_cash_expenditure = ProofCashExpenditure.new(proof_cash_expenditure_params)

    respond_to do |format|
      if @proof_cash_expenditure.save
        params[:proof_cash_expenditure_item].each do |item|
        ProofCashExpenditureItem.create({
          :proof_cash_expenditure_id=> @proof_cash_expenditure.id,
          :bon_count=> item["bon_count"],
          :type_cost=> item["type_cost"],
          :no_coa=> item["no_coa"],
          :remarks=> item["remarks"],
          :nominal=> item["nominal"],
          :status=> 'active',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })

        end if params[:proof_cash_expenditure_item].present?

        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = ProofCashExpenditureFile.where(:proof_cash_expenditure_id=>@proof_cash_expenditure.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/proof_cash_expenditure/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                ProofCashExpenditureFile.create({
                  :proof_cash_expenditure_id=> @proof_cash_expenditure.id,
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

        if params[:proof_cash_expenditure_file].present?
          params["proof_cash_expenditure_file"].each do |bon_files|
            require 'base64'
            if bon_files[:attachment].present?
              images = bon_files[:attachment]
              ext = images.split("/")[1].split(";")[0]
              mime_type = Rack::Mime.mime_type(".#{ext}")
              filename = ( "BON-#{@proof_cash_expenditure.id}-#{bon_files[:bon_count]}-#{DateTime.now()}.#{ext}")
              metadata = "data:#{mime_type};base64,"
              base64_string = images[metadata.size..-1]
              blob = Base64.decode64(base64_string)

              
              path_file = ("public/uploads/proof_cash_expenditure/#{filename}")
                    
              File.open(path_file, 'wb') do |file|
                file.write(blob)
                hash = Digest::MD5.hexdigest(blob)
              end
              ProofCashExpenditureFile.create({
                  :proof_cash_expenditure_id=> @proof_cash_expenditure.id,
                  :bon_count=> bon_files[:bon_count],
                  :filename_original=>filename,
                  :file_hash=> hash,
                  :filename=> filename,
                  :path=> path_file,
                  :ext=> ext,
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })
            end
          end
        end

        format.html { redirect_to proof_cash_expenditure_path(:id=> @proof_cash_expenditure.id), notice: "#{@proof_cash_expenditure.number} was successfully created."}
        format.json { render :show, status: :created, location: @proof_cash_expenditure }
      else
        format.html { render :new }
        format.json { render json: @proof_cash_expenditure.errors, status: :unprocessable_entity }
      end
      logger.info @proof_cash_expenditure.errors
    end
  end

  # PATCH/PUT /proof_cash_expenditures/1
  # PATCH/PUT /proof_cash_expenditures/1.json
  def update
    respond_to do |format|
        # params[:proof_cash_expenditure]["automatic_calculation"] = @proof_cash_expenditure.automatic_calculation
        params[:proof_cash_expenditure]["updated_by"] = current_user.id
        params[:proof_cash_expenditure]["updated_at"] = DateTime.now()
        params[:proof_cash_expenditure]["number"] = @proof_cash_expenditure.number
        if @proof_cash_expenditure.update(proof_cash_expenditure_params)      

          params[:proof_cash_expenditure_item].each do |item|
            wawa = ProofCashExpenditureItem.new({
              :proof_cash_expenditure_id=> @proof_cash_expenditure.id,
              :bon_count=> item["bon_count"],
              :type_cost=> item["type_cost"],
              :no_coa=> item["no_coa"],
              :remarks=> item["remarks"],
              :nominal=> item["nominal"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            wawa.save
              logger.info wawa.errors.full_messages
          end if params[:proof_cash_expenditure_item].present?

          if params[:file].present?
            params["file"].each do |many_files|
              content =  many_files[:attachment].read
              hash = Digest::MD5.hexdigest(content)
              fid = ProofCashExpenditureFile.where(:proof_cash_expenditure_id=>@proof_cash_expenditure.id)
              pf = fid.find_by(:file_hash=>hash)
              if pf.blank?
                filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
                ext=File.extname(filename_original)
                filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
                dir = "public/uploads/proof_cash_expenditure/"
                FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
                path = File.join(dir, "#{hash}#{ext}")
                tmp_path_filename=File.join('/tmp', filename)
                File.open(path, 'wb') do |file|
                  file.write(content)
                  ProofCashExpenditureFile.create({
                    :proof_cash_expenditure_id=> @proof_cash_expenditure.id,
                    :filename_original=>filename_original,
                    :file_hash=> hash,
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

          if params[:proof_cash_expenditure_file].present?
            params["proof_cash_expenditure_file"].each do |bon_files|
              require 'base64'
              if bon_files[:attachment].present?
                images = bon_files[:attachment]
                ext = images.split("/")[1].split(";")[0]
                mime_type = Rack::Mime.mime_type(".#{ext}")
                filename = ( "BON-#{@proof_cash_expenditure.id}-#{bon_files[:bon_count]}-#{DateTime.now()}.#{ext}")
                metadata = "data:#{mime_type};base64,"
                base64_string = images[metadata.size..-1]
                blob = Base64.decode64(base64_string)
                
                path_file = ("public/uploads/proof_cash_expenditure/#{filename}")
                      
                File.open(path_file, 'wb') do |file|
                  file.write(blob)
                  hash = Digest::MD5.hexdigest(blob)
                end
                  old_file = ProofCashExpenditureFile.where(:proof_cash_expenditure_id=> @proof_cash_expenditure.id,:bon_count=>bon_files[:bon_count])
                  old_file.update_all({:status=> 'deleted'})
                  ProofCashExpenditureFile.create({
                    :proof_cash_expenditure_id=> @proof_cash_expenditure.id,
                    :bon_count=>bon_files[:bon_count],
                    :filename_original=>filename,
                    :file_hash=> hash,
                    :filename=> filename,
                    :path=> path_file,
                    :ext=> ext,
                    :created_at=> DateTime.now,
                    :created_by=> session[:id]
                  })
              end
            end
          end

          params["record_file"].each do |item|
            file = ProofCashExpenditureFile.find_by(:id=> item["id"].to_s)
            case item["status"]
            when 'deleted'
              file.update_columns({
                 :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })
            end
          end if params["record_file"].present?

          params["record_item"].each do |item|
            cash_item = ProofCashExpenditureItem.find_by(:id=> item["id"].to_s)
            case item["status"]
            when 'deleted'
              cash_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })
            else
              cash_item.update_columns({
                :proof_cash_expenditure_id=> @proof_cash_expenditure.id,
                :type_cost=> item["type_cost"],
                :no_coa=> item["no_coa"],
                :remarks=> item["remarks"],
                :nominal=> item["nominal"],
                :status=> 'active'
              })

            end if cash_item.present?
          end if params["record_item"].present?
          
        format.html { redirect_to proof_cash_expenditure_path(:id=> @proof_cash_expenditure.id), notice: "#{@proof_cash_expenditure.number} was successfully Updated" }
        format.json { render :show, status: :created, location: @proof_cash_expenditure }     
      else
        format.html { render :edit }
        format.json { render json: @proof_cash_expenditure.errors, status: :unprocessable_entity }
        end
    end
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

        header = @proof_cash_expenditure
        items  = @proof_cash_expenditure_items


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
                        {:content=> "Nama Biaya / Nama COA", width: 250, valign: :center, :font_style => :bold},
                        {:content=> "No.COA", width: 70, valign: :center, :font_style => :bold},
                        {:content=> "Keterangan", width: 130, valign: :center, :font_style => :bold},
                        {:content=> "Nominal", width: 100, valign: :center, :font_style => :bold}]]
              pdf.table(tbl_header, cell_style: {align: :center, size: 9, padding: 5})
              c = 1
              sum_cost_nominal = 0
              items.each do |item|

                pdf.table([[
                  {:content=>c.to_s+".", :align=>:right}, 
                  item.type_cost.to_s, item.no_coa.to_s, item.remarks.to_s,
                  {:content=> number_with_precision( item.nominal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
                  ] ], :column_widths => [25, 250, 70, 130, 100], :cell_style => {:padding=> 5})
                sum_cost_nominal += item.nominal.to_f
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
                pdf.draw_text ("BUKTI PENGELUARAN KAS"), :at => [160,5], :size => 14, :style=> :bold
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

  def approve
    case params[:status]
    when 'approve1'
      @proof_cash_expenditure.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @proof_cash_expenditure.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @proof_cash_expenditure.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @proof_cash_expenditure.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @proof_cash_expenditure.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature}) 
    when 'cancel_approve3'
      @proof_cash_expenditure.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
    when 'void'
      @proof_cash_expenditure.update({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now(), :img_approved3_signature=>nil})
    end

    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to proof_cash_expenditures_url, alert: 'successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to proof_cash_expenditure_path(:id=> @proof_cash_expenditure.id), notice: "#{@proof_cash_expenditure.number} was successfully #{@proof_cash_expenditure.status}." }
        format.json { head :no_content }
      end
    end
  end


  def export    
    template_report(controller_name, current_user.id, params[:q])
  end
  # DELETE /proof_cash_expenditures/1
  # DELETE /proof_cash_expenditures/1.json
  def destroy
    @proof_cash_expenditure.update_columns({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    respond_to do |format|
      format.html { redirect_to proof_cash_expenditures_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def check_status    
    noitce_msg = nil 
    if @proof_cash_expenditure.status == 'approved3'
      if params[:status] == "cancel_approve3"
      else
        noitce_msg = 'Cannot be edited because it has been approved'
      end
    end
    if noitce_msg.present?
      puts "-------------------------------"
      puts  @proof_cash_expenditure.status
      puts "-------------------------------"
      respond_to do |format|
        format.html { redirect_to proof_cash_expenditure_path(:id=> @proof_cash_expenditure.id, :q=> params[:q]), alert: noitce_msg }
        format.json { render :show, status: :created, location: @proof_cash_expenditure }
      end
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_proof_cash_expenditure
      if params[:multi_id].present?
        @proof_cash_expenditure = ProofCashExpenditure.where(:id=> params[:multi_id].split(','))
        if @proof_cash_expenditure.present?
          # nothing
        else
          respond_to do |format|
            format.html { redirect_to proof_cash_expenditures_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      else
        @proof_cash_expenditure = ProofCashExpenditure.find_by(:id=> params[:id])
        if @proof_cash_expenditure.present?
          @proof_cash_expenditure_items = ProofCashExpenditureItem.where(:status=> 'active')
          .includes(:proof_cash_expenditure)
          .where(:proof_cash_expenditures => {:id=> params[:id], :company_profile_id => current_user.company_profile_id })
          .order("proof_cash_expenditures.number desc")
        else
          respond_to do |format|
            format.html { redirect_to proof_cash_expenditures_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      end
    end

    def set_instance_variable
      @department = Department.where(:status=> 'active')
    
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def proof_cash_expenditure_params
      params.require(:proof_cash_expenditure).permit(:proof_cash_expenditure_id, :company_profile_id, :department_id, :automatic_calculation, :bon_count, :img_created_signature, :number, :date, :grand_total, :voucher_payment, :type_cost, :no_coa, :nominal, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end
end
