class VoucherPaymentReceivingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_voucher_payment_receiving, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit, :approve]
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

  # GET /voucher_payment_receivings
  # GET /voucher_paymennt_receivings.json
  def index 
    # 20220318 - Danny
    voucher_payment_receiving_updated = VoucherPaymentReceiving.where(:company_profile_id=> current_user.company_profile_id) 
    .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :voided)

    if @periode.present?
      voucher_payment_receiving_updated = voucher_payment_receiving_updated.where("date like '#{@periode.to_date.strftime("%Y-%m").to_s}%'")
    end
    if params["bank_type"].present?
      session["bank_type"] = params["bank_type"]
      voucher_payment_receiving_updated = voucher_payment_receiving_updated.where(:list_internal_bank_account_id=>@list_internal_bank_accounts.where(:code_voucher=>params["bank_type"]).map {|e| [e.id]})
    end

    payment_customers = PaymentCustomer.where(:company_profile_id=> current_user.company_profile_id)
    if @periode.present?
      payment_customers = payment_customers.where("date like '#{@periode.to_date.strftime("%Y-%m").to_s}%'")
    end
    if params["bank_type"].present?
      payment_customers = payment_customers.where(:bank_transfer_id=>@bank_transfers.where(:code=>params["bank_type"]).map {|e| [e.id]})
    end

    voucher_payment_receivings = voucher_payment_receiving_updated + payment_customers

    # filter select - begin
      @option_filters = [['No. Voucher','number'],['Nama Pengirim','name_account'],['Currency', 'currency_id'],['Status','status']] 
      @option_filter_records = voucher_payment_receivings
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        end

        voucher_payment_receivings = voucher_payment_receivings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:view_kind]
    when 'item'
      voucher_payment_receivings = VoucherPaymentReceivingItem.where(:status=> 'active').includes(:voucher_payment_receiving).where(:voucher_payment_receivings => {:company_profile_id => current_user.company_profile_id }).order("voucher_payment_receivings.number desc")      
    else
      # voucher_payment_receivings = voucher_payment_receivings.where(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("created_at asc")
      voucher_payment_receivings = voucher_payment_receivings
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @voucher_payment_receivings = pagy_array(voucher_payment_receivings, page: params[:page], items: pagy_items) 
  end

  # GET /voucher_payment_receivings/1
  # GET /voucher_payment_receivings/1.json
  def show
  end

  # GET /voucher_payment_receivings/new
  def new
    @voucher_payment_receiving = VoucherPaymentReceiving.new
  end
  # GET /voucher_payment_receivings/1/edit
  def edit
  end

  # POST /voucher_payment_receivings
  # POST /voucher_payment_receivings.json
  def create
    params[:voucher_payment_receiving]["company_profile_id"] = current_user.company_profile_id
    params[:voucher_payment_receiving]["created_by"] = current_user.id
    params[:voucher_payment_receiving]["created_at"] = DateTime.now()
    params[:voucher_payment_receiving]["img_created_signature"] = current_user.signature
    params[:voucher_payment_receiving]["created_at"] = DateTime.now()
    params[:voucher_payment_receiving]["number"] = document_number(controller_name, params[:voucher_payment_receiving]['date'].to_date, params[:voucher_payment_receiving]['list_internal_bank_account_id'], nil, nil)
    @voucher_payment_receiving = VoucherPaymentReceiving.new(voucher_payment_receiving_params)

    respond_to do |format|

      if @voucher_payment_receiving.save
        params[:new_record_item].each do |item|
          VoucherPaymentReceivingItem.create({
            :voucher_payment_receiving_id => @voucher_payment_receiving.id,
            :coa_number => item["coa_number"],
            :coa_name => item["coa_name"],
            :description => item["description"],
            :amount => item["amount"].gsub(/[\s,]/ ,""),
            :status => 'active',
            :created_at => DateTime.now(), :created_by => current_user.id
          })
        end if params[:new_record_item].present?

        format.html { redirect_to voucher_payment_receiving_path(:id=> @voucher_payment_receiving.id), notice: "#{@voucher_payment_receiving.number} was successfully created." }
        format.json { render :show, status: :created, location: @voucher_payment_receiving }
      else
        format.html { render :new }
        format.json { render json: @voucher_payment_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /voucher_payment_receivings/1
  # PATCH/PUT /voucher_payment_receivings/1.json
  def update
    respond_to do |format|
      params[:voucher_payment_receiving]["updated_by"] = current_user.id
      params[:voucher_payment_receiving]["updated_at"] = DateTime.now()
      params[:voucher_payment_receiving]["number"] = @voucher_payment_receiving.number
      if @voucher_payment_receiving.update(voucher_payment_receiving_params)

        params[:new_record_item].each do |item|
            record_item = VoucherPaymentReceivingItem.new({
              :voucher_payment_receiving_id=> @voucher_payment_receiving.id,
              :coa_number=> item["coa_number"],
              :coa_name=> item["coa_name"],
              :description=> item["description"],
              :amount => item["amount"].gsub(/[\s,]/ ,""),
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            record_item.save 
        end if params[:new_record_item].present?

        params[:record_item].each do |item|
          record_item = VoucherPaymentReceivingItem.find_by(:id=> item["id"])
          if record_item.present?
            case item["status"]
            when 'deleted'
              record_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })        
            else
              record_item.update_columns({
                :voucher_payment_receiving_id=> @voucher_payment_receiving.id,
                :coa_number=> item["coa_number"],
                :coa_name=> item["coa_name"],
                :description=> item["description"],
                :amount=> item["amount"].gsub(".",""),
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
            end
          end
        end if params[:record_item].present?
        format.html { redirect_to @voucher_payment_receiving, notice: "#{@voucher_payment_receiving.number} was successfully updated." }
        format.json { render :show, status: :ok, location: @voucher_payment_receiving }
      else
        format.html { render :edit }
        format.json { render json: @voucher_payment_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /voucher_payment_receivings/1
  # DELETE /voucher_payment_receivings/1.json
  def destroy
    @voucher_payment_receiving.update_columns({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    respond_to do |format|
      format.html { redirect_to voucher_payment_receivings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @voucher_payment_receiving.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @voucher_payment_receiving.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @voucher_payment_receiving.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @voucher_payment_receiving.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @voucher_payment_receiving.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature }) 
    when 'cancel_approve3'
      @voucher_payment_receiving.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
    when 'void'
      @voucher_payment_receiving.update({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to voucher_payment_receiving_path(:id=> @voucher_payment_receiving.id), notice: "#{@voucher_payment_receiving.number} was successfully #{@voucher_payment_receiving.status}." }
      format.json { head :no_content }
    end
  end

  def print
    if @voucher_payment_receiving.status == 'approved3'
      sop_number      = ""
      form_number     = "F-VR-001-Rev 01"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. Provital Perdana"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @voucher_payment_receiving
      items  = @voucher_payment_receiving_items
      name_prepared_by = account_name(header.created_by) 
      name_approved_by = account_name(header.approved3_by)
      my_currency = header.currency.name.upcase
      my_currency == "IDR" ? cur_prec = 2 : cur_prec = 4
      
      user_prepared_by = User.find_by(:id=> header.created_by) 
      if user_prepared_by.present? and header.img_created_signature.present?
        img_prepared_by = "public/uploads/signature/#{user_prepared_by.id}/#{header.img_created_signature}"
        if FileTest.exist?("#{img_prepared_by}")
          puts "File Exist"
          puts img_prepared_by
        else
          puts "File not found"
          img_prepared_by = nil
        end
      else
        img_prepared_by = nil
      end

      if header.status == 'approved3' and header.img_approved3_signature.present?
        user_approved_by = User.find_by(:id=> header.approved3_by)
        if user_approved_by.present?
          img_approved_by = "public/uploads/signature/#{user_approved_by.id}/#{header.img_approved3_signature}"
          if FileTest.exist?("#{img_approved_by}")
            puts "File Exist"
            puts img_approved_by
          else
            puts "File not found: #{img_approved_by}"
            img_approved_by = nil
          end
        else
          img_approved_by = nil
        end
      else
        img_approved_by = nil
      end  

      subtotal = 0

      document_name = "VOUCHER PAYMENT RECEIVED"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 0.90,
            :bottom_margin => 0.78, 
            :left_margin=> 0.59, 
            :right_margin=> 0.39 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')
          # danny record
          pdf.move_down 115
          tbl_width = [30, 140, 140, 140, 143]
          # tbl_width = [30, 148, 112, 154, 70, 80]
          c = 1
          pdf.move_down 2 #isi
          items.each do |item|          
            # if item.material.present?
              # part = item.material
            # end
            # (1..30).each do 
              y = pdf.y
              pdf.start_new_page if y < 600
              pdf.move_down 75 if y < 600
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center, :size=> 10}, 
                  {:content=>"#{item.coa_number}", :size=> 10},
                  {:content=>"#{item.coa_name}", :size=> 10},
                  {:content=> "#{item.description}", :size=> 10},
                  {:content=>number_with_precision(item.amount, precision: 2, delimiter: ".", separator: ","), :align=>:right, :size=> 10}
                  
                ]], :column_widths => tbl_width, :cell_style => {:padding => [4, 5, 0, 4], :border_color=>"ffffff"})
              c +=1
              subtotal += item.amount.to_f
            # end
          end
   
          pdf.page_count.times do |i|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1

              }

              pdf.bounding_box([0, 840], :width => 594, :height => 445) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end

              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.table([
                  [ 
                    {:image => image_path, :image_width => 100}, 
                    {:content=>document_name, :font_style => :bold, :align=>:center, :valign=>:center, :size=>12}, "",
                    ""
                  ]],:column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.stroke_horizontal_rule
 
                pdf.table([
                  [ 
                    {:content=> "No. Voucher", :size=>10, :align=> :left}, {:content=> ": #{header.number}", :size=>10, :align=> :left}, 
                    {:content=> "Nama Pengirim", :size=>10, :align=> :left}, {:content=> ": #{header.name_account}", :size=>10, :align=> :left}
                  ],
                  [ 
                    {:content=> "Tgl. Penerimaan", :size=>10, :align=> :left}, {:content=> ": #{header.date}", :size=>10, :align=> :left}, 
                    {:content=> "Total Amount", :size=>10, :align=> :left}, {:content=> ": #{number_with_precision(header.total_amount, precision: cur_prec, delimiter: ".", separator: ",").to_s}", :size=>10, :align=> :left}
                  ],
                  [ 
                    {:content=> "Bank Penerima", :size=>10, :align=> :left}, {:content=> ": #{header.list_internal_bank_account.name_account} - #{header.list_internal_bank_account.number_account}", :size=>10, :align=> :left}, ""
                  ]   
                ],:column_widths => [85, 279, 85, 145], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>5})

                # pdf.move_down 5
                pdf.stroke_horizontal_rule
                pdf.move_down 5
                       
                pdf.table([ [
                  {:content=>"No.", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"No. Coa", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Nama Coa", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Keterangan", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Amount", :height=> 25, :valign=> :center, :align=> :center}]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                pdf.move_down 170
                  pdf.table([[
                      {:content=> "Grand Total", :width=> 450, :align=>:center, :size=> 10, :font_style=> :bold}, 
                      {:content=> number_with_precision( subtotal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 143, :size=> 10, :font_style => :bold}
                    ]])
                pdf.move_down 5
                  pdf.table([[
                    {:content=>"Terbilang : "+number_to_words(header.total_amount.to_i).upcase+" ("+(my_currency)+") ", :height=> 40}]], :column_widths=> [450], :cell_style => {:size=>9,:padding => [3, 10, 0, 3]})
                pdf.move_down 5
                disetujui = [
                              [{:content=>"Disetujui", :width=>100, :align=> :center, :padding=> 1}],
                              [{:content=>"", :height=>40}],
                              [{:content=>"Dir.Utama / Dir.Keuangan", :align => :center, :padding=>1}]
                            ]
                diperiksa = [
                              [{:content=>"Diperiksa", :width=>105, :align=> :center, :padding=> 1}],
                              [{:content=>"", :height=>40}],
                              [{:content=>"Keuangan", :align => :center, :padding=>1}]
                            ]
                pdf.table([["",disetujui,diperiksa]], :column_widths=> [150,140,269], :cell_style => {:border_color => "ffffff"})

              }
            # header end

            # content begin
              dk_row = 0
              tbl_top_position = 720 #colom content
              
              tbl_width.each do |i|
                # puts dk_row
                dk_row += i
                pdf.bounding_box([0, tbl_top_position], :width => dk_row, :height => 170) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              # pdf.move_down 5
              # pdf.stroke_horizontal_rule

            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                # pdf.move_up 330

              }

              # pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @voucher_payment_receiving, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @voucher_payment_receiving }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
    puts "ini"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_voucher_payment_receiving
      @voucher_payment_receiving = VoucherPaymentReceiving.find_by(:id=> params[:id])
      if @voucher_payment_receiving.present?
        @voucher_payment_receiving_items = VoucherPaymentReceivingItem.where(:status=> 'active')
        .includes(:voucher_payment_receiving).where(:voucher_payment_receivings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id })
        .order("voucher_payment_receivings.number desc")      
      else
        respond_to do |format|
          format.html { redirect_to voucher_payment_receivings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @currencies = Currency.all
      @list_internal_bank_accounts = ListInternalBankAccount.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3')
      @periode = params[:periode].present? ? params[:periode] : DateTime.now.strftime("%Y-%m-01").to_s
      @months = Date.parse('2010-01-01').upto((Date.today+2.month)).map {|date| ["#{date.strftime("%Y-%B")}","#{date.to_s[0..-4]}"+"-01"]}.uniq.reverse
      session[:periode] = @periode
      @bank_voucher = @list_internal_bank_accounts.group("code_voucher").collect {|e| [e.code_voucher]}.uniq
      params[:bank_type] = (params[:bank_type].present? ? params[:bank_type] : (session["bank_type"].present? ? session["bank_type"] : "RTSI"))
      session["bank_type"] = params["bank_type"]
      @bank_transfers = BankTransfer.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
    end

    def check_status     
      if @voucher_payment_receiving.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @voucher_payment_receiving.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @voucher_payment_receiving, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @voucher_payment_receiving }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def voucher_payment_receiving_params
      params.require(:voucher_payment_receiving).permit(:voucher_payment_receiving_id, :currency_id, :company_profile_id, :list_internal_bank_account_id, :number, :name_account, :date, :total_amount, :coa_number, :coa_name, :description, :amount, :created_by, :created_at, :updated_at, :updated_by, :img_created_signature)
    end
end
