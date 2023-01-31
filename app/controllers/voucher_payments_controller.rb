class VoucherPaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_voucher_payment, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /voucher_payments
  # GET /voucher_paymennts.json
  def index 
    voucher_payments = VoucherPayment.where(:company_profile_id=> current_user.company_profile_id) 
    .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :voided, :list_internal_bank_account)

    if @periode.present?
      voucher_payments = voucher_payments.where("date like '#{@periode.to_date.strftime("%Y-%m").to_s}%'")
    end
    if params[:bank_type].present?
      logger.info "params['bank_type']: #{params["bank_type"]}"
      voucher_payments = voucher_payments.where(:list_internal_bank_accounts=> {:code_voucher=> params[:bank_type]})
    end

    # filter select - begin
      @option_filters = [['No. Voucher','number'],['Nama','list_external_bank_account_id'],['Currency', 'currency_id'],['Status','status']] 
      @option_filter_records = voucher_payments
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        when 'list_external_bank_account_id'
          @option_filter_records = ListExternalBankAccount.all
        end

        voucher_payments = voucher_payments.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    # test load
    case params[:partial]
    when 'load_bpk_list'
      # test
      bpk_routines  = RoutineCostPayment.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3', :voucher_number=>[nil, ""])
      bpks          = ProofCashExpenditure.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3', :voucher_number=>[nil, ""])
      bpk_kasbons   = CashSettlement.where(:company_profile_id=> current_user.company_profile_id,:status=>'approved3', :voucher_number=>[nil, ""])
      @bpk_lists    = bpk_routines + bpks + bpk_kasbons

      bpk_routine_items = ProofCashExpenditureItem.where(:proof_cash_expenditure_id=>params[:stuff1], :status=> 'active')
      bpk_items         = RoutineCostPaymentItem.where(:routine_cost_payment_id=>params[:stuff2], :status=> 'active')
      kasbon_items      = CashSettlementItem.where(:cash_settlement_id=>params[:stuff3], :status=> 'active')
      @bpk_items        = bpk_routine_items + bpk_items + kasbon_items
    end

    case params[:view_kind]
    when 'item'
      # voucher_payments = VoucherPaymentItem.where(:status=> 'active').includes(:voucher_payment).where(:voucher_payments => {:company_profile_id => current_user.company_profile_id }).order("voucher_payments.number desc")      
      voucher_payments = VoucherPaymentItem.where(:status=> 'active').includes(:voucher_payment).where(:voucher_payments => {:company_profile_id => current_user.company_profile_id, :kind=> params[:kind] }).order("voucher_payments.number desc")      
    else
      voucher_payments = voucher_payments.where(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("voucher_payments.created_at asc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @voucher_payments = pagy(voucher_payments, page: params[:page], items: pagy_items) 
  end

  # GET /voucher_payments/1
  # GET /voucher_payments/1.json
  def show
  end

  # GET /voucher_payments/new
  def new
    @voucher_payment = VoucherPayment.new

    bpk_routines  = RoutineCostPayment.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3', :voucher_number=>[nil, ""])
    bpks          = ProofCashExpenditure.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3', :voucher_number=>[nil, ""])
    bpk_kasbons   = CashSettlement.where(:company_profile_id=> current_user.company_profile_id,:status=>'approved3', :voucher_number=>[nil, ""])
    params[:stuff1] = (params[:stuff1].present? ? params[:stuff1] : [])
    params[:stuff2] = (params[:stuff2].present? ? params[:stuff2] : [])
    params[:stuff3] = (params[:stuff3].present? ? params[:stuff3] : [])
    @bpk_lists    = bpk_routines + bpks + bpk_kasbons

    @bpk_items        = nil
    bpk_routine_items = ProofCashExpenditureItem.where(:proof_cash_expenditure_id=>params[:stuff1], :status=> 'active') if params[:stuff1].present?
    bpk_items         = RoutineCostPaymentItem.where(:routine_cost_payment_id=>params[:stuff2], :status=> 'active') if params[:stuff2].present?
    kasbon_items      = CashSettlementItem.where(:cash_settlement_id=>params[:stuff3], :status=> 'active') if params[:stuff3].present?

    @bpk_items        += bpk_routine_items if bpk_routine_items.present?
    @bpk_items        += bpk_items if bpk_items.present?
    @bpk_items        += kasbon_items if kasbon_items.present?
  end
  # GET /voucher_payments/1/edit
  def edit
    # @voucher_payment = VoucherPayment.find_by(:id=> params[:id])
    # @voucher_payment_items = VoucherPaymentItem.where(:status=> 'active').includes(:voucher_payment).where(:voucher_payments => {:id=> params[:id], :company_profile_id => current_user.company_profile_id })
    params[:stuff1] = (params[:stuff1].present? ? params[:stuff1] : [])
    params[:stuff2] = (params[:stuff2].present? ? params[:stuff2] : [])
    params[:stuff3] = (params[:stuff3].present? ? params[:stuff3] : [])

    @voucher_payment_items.each do |item|
      if item.proof_cash_expenditure_id.present?
        params[:stuff1] << item.proof_cash_expenditure_id
      end
      if item.routine_cost_payment_id.present?
        params[:stuff2] << item.routine_cost_payment_id
      end
      if item.cash_settlement_id.present?
        params[:stuff3] << item.cash_settlement_id
      end
    end

    bpk_routines  = RoutineCostPayment.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3', :voucher_number=>[nil, ""])
    bpks          = ProofCashExpenditure.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3', :voucher_number=>[nil, ""])
    bpk_kasbons   = CashSettlement.where(:company_profile_id=> current_user.company_profile_id,:status=>'approved3', :voucher_number=>[nil, ""])
    @bpk_lists    = bpk_routines + bpks + bpk_kasbons

    bpk_routine_items = ProofCashExpenditureItem.where(:proof_cash_expenditure_id=>params[:stuff1], :status=> 'active')
    bpk_items         = RoutineCostPaymentItem.where(:routine_cost_payment_id=>params[:stuff2], :status=> 'active')
    kasbon_items      = CashSettlementItem.where(:cash_settlement_id=>params[:stuff3], :status=> 'active')
    @bpk_items        = bpk_routine_items + bpk_items + kasbon_items
  end

  # POST /voucher_payments
  # POST /voucher_payments.json
  def create
    params[:voucher_payment]["company_profile_id"] = current_user.company_profile_id
    params[:voucher_payment]["created_by"] = current_user.id
    params[:voucher_payment]["created_at"] = DateTime.now()
    params[:voucher_payment]["img_created_signature"] = current_user.signature
    params[:voucher_payment]["created_at"] = DateTime.now()

      params[:voucher_payment]["sub_total"] = (params[:voucher_payment]["sub_total"].gsub(".","").gsub(",",".")).to_f
      params[:voucher_payment]["ppn_total"] = (params[:voucher_payment]["ppn_total"].gsub(".","").gsub(",",".")).to_f
      params[:voucher_payment]["pph_percent"] = (params[:voucher_payment]["pph_percent"].gsub(".","").gsub(",",".")).to_f
      params[:voucher_payment]["pph_total"] = (params[:voucher_payment]["pph_total"].gsub(".","").gsub(",",".")).to_f
      params[:voucher_payment]["other_cut_fee"] = (params[:voucher_payment]["other_cut_fee"]).to_f
      params[:voucher_payment]["grand_total"] = (params[:voucher_payment]["grand_total"].gsub(".","").gsub(",",".")).to_f
      
    list_internal_bank_account = ListInternalBankAccount.find_by(:id=> params[:voucher_payment]['list_internal_bank_account_id'])
    if list_internal_bank_account.present?
      params[:voucher_payment]["currency_id"] = list_internal_bank_account.currency_id
    end
    # 20211222 - request suci untuk input manual nomor
    # params[:voucher_payment]["number"] = document_number(controller_name, params[:voucher_payment]['date'].to_date, params[:voucher_payment]['list_internal_bank_account_id'], nil, nil)
    @voucher_payment = VoucherPayment.new(voucher_payment_params)

    respond_to do |format|

      if @voucher_payment.save
        params[:new_record_item].each do |item|
          dtest = VoucherPaymentItem.create({
            :voucher_payment_id => @voucher_payment.id,
            :routine_cost_payment_id => item["routine_cost_payment_id"],
            :routine_cost_payment_item_id => item["routine_cost_payment_item_id"],
            :proof_cash_expenditure_id => item["proof_cash_expenditure_id"],
            :proof_cash_expenditure_item_id => item["proof_cash_expenditure_item_id"],
            :cash_settlement_id => item["cash_settlement_id"],
            :cash_settlement_item_id => item["cash_settlement_item_id"],
            :cost_type => item["cost_type"],
            :coa_number => item["coa_number"],
            :cost_detail => item["cost_detail"],
            :cost_for => item["cost_for"],
            :nominal => item["nominal"].gsub(".","").gsub(",",".").to_f,
            :status => 'active',
            :created_at => DateTime.now(), :created_by => current_user.id
          })
          dtest.save!

        end if params[:new_record_item].present?

        format.html { redirect_to voucher_payment_path(:id=> @voucher_payment.id, :kind=> @voucher_payment.kind), notice: "#{@voucher_payment.number} was successfully created." }
        format.json { render :show, status: :created, location: @voucher_payment }
      else
        format.html { render :new }
        format.json { render json: @voucher_payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /voucher_payments/1
  # PATCH/PUT /voucher_payments/1.json
  def update
    respond_to do |format|
      params[:voucher_payment]["updated_by"] = current_user.id
      params[:voucher_payment]["updated_at"] = DateTime.now()
      list_internal_bank_account = ListInternalBankAccount.find_by(:id=> params[:voucher_payment]['list_internal_bank_account_id'])
      if list_internal_bank_account.present?
        params[:voucher_payment]["currency_id"] = list_internal_bank_account.currency_id
      end
      # params[:voucher_payment]['date']   = @voucher_payment.date
      # params[:voucher_payment]["number"] = @voucher_payment.number
      # convert string to float
        params[:voucher_payment]["sub_total"] = (params[:voucher_payment]["sub_total"].gsub(".","").gsub(",",".")).to_f
        params[:voucher_payment]["ppn_total"] = (params[:voucher_payment]["ppn_total"].gsub(".","").gsub(",",".")).to_f
        params[:voucher_payment]["pph_percent"] = (params[:voucher_payment]["pph_percent"].gsub(".","").gsub(",",".")).to_f
        params[:voucher_payment]["pph_total"] = (params[:voucher_payment]["pph_total"].gsub(".","").gsub(",",".")).to_f
        params[:voucher_payment]["other_cut_fee"] = (params[:voucher_payment]["other_cut_fee"]).to_f
        params[:voucher_payment]["grand_total"] = (params[:voucher_payment]["grand_total"].gsub(".","").gsub(",",".")).to_f

      if @voucher_payment.update(voucher_payment_params)

        # clear vouceher payment item
        VoucherPaymentItem.where(:voucher_payment_id=> @voucher_payment.id, :status=> 'active').each do |item|
          item.routine_cost_payment.update_columns(:voucher_number=> '') if item.routine_cost_payment.present?
          item.proof_cash_expenditure.update_columns(:voucher_number=> '') if item.proof_cash_expenditure.present?
          item.cash_settlement.update_columns(:voucher_number=> '') if item.cash_settlement.present?

          item.update_columns(:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now())
        end

        # parameter new_record_item digunakan untuk load data
        if params[:new_record_item].present?
          # insert or update
          params[:new_record_item].each do |item|
            if item["routine_cost_payment_id"].present?
              voucher_payment_items = VoucherPaymentItem.find_by(
                :voucher_payment_id=> @voucher_payment.id,
                :routine_cost_payment_id=> item["routine_cost_payment_id"],
                :routine_cost_payment_item_id=> item["routine_cost_payment_item_id"]
              )
            elsif item["proof_cash_expenditure_id"].present?
              voucher_payment_items = VoucherPaymentItem.find_by(
                :voucher_payment_id=> @voucher_payment.id,
                :proof_cash_expenditure_id=> item["proof_cash_expenditure_id"],
                :proof_cash_expenditure_item_id=> item["proof_cash_expenditure_item_id"]
              )
            elsif item["cash_settlement_id"].present?
              voucher_payment_items = VoucherPaymentItem.find_by(
                :voucher_payment_id=> @voucher_payment.id,
                :cash_settlement_id=> item["cash_settlement_id"],
                :cash_settlement_item_id=> item["cash_settlement_item_id"]
              )
            end

            if voucher_payment_items.present?
              # jika data ada, maka ubah status jadi active
              voucher_payment_items.update_columns({
                :cost_type=> item["cost_type"],
                :coa_number=> item["coa_number"],
                :cost_detail=> item["cost_detail"],
                :cost_for=> item["cost_for"],
                :nominal => item["nominal"].gsub(".","").gsub(",","."),
                :status=> 'active', :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
            else
              # jika data tidak ditemukan makan insert baru
              record_item = VoucherPaymentItem.new({
                :voucher_payment_id=> @voucher_payment.id,
                :routine_cost_payment_id=> item["routine_cost_payment_id"],
                :routine_cost_payment_item_id=> item["routine_cost_payment_item_id"],
                :proof_cash_expenditure_id=> item["proof_cash_expenditure_id"],
                :proof_cash_expenditure_item_id=> item["proof_cash_expenditure_item_id"],
                :cash_settlement_id=> item["cash_settlement_id"],
                :cash_settlement_item_id=> item["cash_settlement_item_id"],
                :cost_type=> item["cost_type"],
                :coa_number=> item["coa_number"],
                :cost_detail=> item["cost_detail"],
                :cost_for=> item["cost_for"],
                :nominal => item["nominal"].gsub(".","").gsub(",","."),
                :status=> 'active',
                :created_at=> DateTime.now(), :created_by=> current_user.id
              })
              record_item.save 
            end
          end
        end

        # parameter record_item digunakan untuk update Jenis Biaya dan nomor COA
        params[:record_item].each do |item|
          record_item = VoucherPaymentItem.find_by(:id=> item["id"])
          if record_item.present?
            case item["status"]
            when 'deleted'
              record_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })        
            else
              item.routine_cost_payment.update_columns(:voucher_number=> @voucher_payment.number ) if item.routine_cost_payment.present?
              item.proof_cash_expenditure.update_columns(:voucher_number=> @voucher_payment.number ) if item.proof_cash_expenditure.present?
              item.cash_settlement.update_columns(:voucher_number=> @voucher_payment.number ) if item.cash_settlement.present?

              record_item.update_columns({
                :voucher_payment_id=> @voucher_payment.id,
                :cost_type=> item["cost_type"],
                :coa_number=> item["coa_number"],
                :cost_detail=> item["cost_detail"],
                :cost_for=> item["cost_for"],
                :nominal => item["nominal"].gsub(/[\s,]/ ,""),
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
            end
          end
        end if params[:record_item].present?

        format.html { redirect_to voucher_payment_path(:kind=> params[:kind]), notice: "#{@voucher_payment.number} was successfully updated." }
        format.json { render :show, status: :ok, location: @voucher_payment }
      else
        format.html { render :edit }
        format.json { render json: @voucher_payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /voucher_payments/1
  # DELETE /voucher_payments/1.json
  def destroy
    @voucher_payment.update_columns({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    respond_to do |format|
      format.html { redirect_to voucher_payments_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @voucher_payment.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @voucher_payment.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @voucher_payment.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @voucher_payment.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      if params[:multi_id].present?
        @voucher_payment.each do |header|
          case header.kind
          when 'kasbon'
            bon = CashSubmission.find(header.cash_submission_id)
            if bon.present?
              bon.update({:voucher_number=>header.number})
            end
          when 'pettycash'
            record_items = VoucherPaymentItem.where(:voucher_payment_id=>header.id)
            if record_items.present?
              record_items.each do |item|
                if item.routine_cost_payment_id.present?
                  bon = RoutineCostPayment.find(item.routine_cost_payment_id)
                  if bon.present?
                    bon.update({:voucher_number=>header.number})
                  end
                end
                if item.proof_cash_expenditure_id.present?
                  bon = ProofCashExpenditure.find(item.proof_cash_expenditure_id)
                  if bon.present?
                    bon.update({:voucher_number=>header.number})
                  end
                end
                if item.cash_settlement_id.present?
                  bon = CashSettlement.find(item.cash_settlement_id)
                  if bon.present?
                    bon.update({:voucher_number=>header.number})
                  end
                end

              end
            end
          end
        end
      else
        case @voucher_payment.kind
        when 'kasbon'
          bon = CashSubmission.find(@voucher_payment.cash_submission_id)
          if bon.present?
            bon.update({:voucher_number=>@voucher_payment.number})
          end
        when 'pettycash'
          record_items = VoucherPaymentItem.where(:voucher_payment_id=>params[:id])
          if record_items.present?
            record_items.each do |item|
              if item.routine_cost_payment_id.present?
                bon = RoutineCostPayment.find(item.routine_cost_payment_id)
                if bon.present?
                  bon.update({:voucher_number=>@voucher_payment.number})
                end
              end
              if item.proof_cash_expenditure_id.present?
                bon = ProofCashExpenditure.find(item.proof_cash_expenditure_id)
                if bon.present?
                  bon.update({:voucher_number=>@voucher_payment.number})
                end
              end
              if item.cash_settlement_id.present?
                bon = CashSettlement.find(item.cash_settlement_id)
                if bon.present?
                  bon.update({:voucher_number=>@voucher_payment.number})
                end
              end

            end
          end
        end
      end

      @voucher_payment.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature }) 



    when 'cancel_approve3'
      if params[:multi_id].present?
        @voucher_payment.each do |header|
          case header.kind
          when 'kasbon'
            bon = CashSubmission.find(header.cash_submission_id)
            if bon.present?
              bon.update({:voucher_number=>nil})
            end
          when 'pettycash'
            record_items = VoucherPaymentItem.where(:voucher_payment_id=>header.id)
            if record_items.present?
              record_items.each do |item|
                if item.routine_cost_payment_id.present?
                  bon = RoutineCostPayment.find(item.routine_cost_payment_id)
                  if bon.present?
                    bon.update({:voucher_number=>nil})
                  end
                end
                if item.proof_cash_expenditure_id.present?
                  bon = ProofCashExpenditure.find(item.proof_cash_expenditure_id)
                  if bon.present?
                    bon.update({:voucher_number=>nil})
                  end
                end
                if item.cash_settlement_id.present?
                  bon = CashSettlement.find(item.cash_settlement_id)
                  if bon.present?
                    bon.update({:voucher_number=>nil})
                  end
                end

              end
            end
          end
        end
      else
        logger.info "===================================================="
        logger.info @voucher_payment
        case @voucher_payment.kind
        when 'kasbon'
          bon = CashSubmission.find(@voucher_payment.cash_submission_id)
          if bon.present?
            bon.update({:voucher_number=>nil})
          end
        when 'pettycash'
          record_items = VoucherPaymentItem.where(:voucher_payment_id=>params[:id])
          if record_items.present?
            record_items.each do |item|
              if item.routine_cost_payment_id.present?
                bon = RoutineCostPayment.find(item.routine_cost_payment_id)
                if bon.present?
                  bon.update({:voucher_number=>nil})
                end
              end
              if item.proof_cash_expenditure_id.present?
                bon = ProofCashExpenditure.find(item.proof_cash_expenditure_id)
                if bon.present?
                  bon.update({:voucher_number=>nil})
                end
              end
              if item.cash_settlement_id.present?
                bon = CashSettlement.find(item.cash_settlement_id)
                if bon.present?
                  bon.update({:voucher_number=>nil})
                end
              end

            end
          end
        end
        logger.info "===================================================="
      end

      @voucher_payment.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
    when 'void'
      @voucher_payment.update({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()})
    end

    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to voucher_payments_url, alert: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to voucher_payment_path(:id=> @voucher_payment.id, :kind=> @voucher_payment.kind), notice: "#{@voucher_payment.number} was successfully #{@voucher_payment.status}." }
        format.json { head :no_content }
      end
    end

  end

  def print
    if @voucher_payment.status == 'approved3'
      sop_number      = ""
      form_number     = ""
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. Provital Perdana"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, 
      Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = VoucherPayment.find_by(:id=> params[:id], :company_profile_id=> current_user.company_profile_id)
      if header.status == 'approved3'
        name_prepared_by = account_name(header.created_by) 
        name_approved_by = account_name(header.approved3_by)
        my_currency = header.currency.name.upcase
        my_currency == "IDR" ? cur_prec = 2 : cur_prec = 4
        # items = VoucherPaymentItem.where(:voucher_payment_id => header.id).order("created_at asc")
        case params[:kind]
        when "kasbon"
          items = CashSubmission.where(:id => header.cash_submission_id).order("created_at asc")
        else
          items = @voucher_payment_items
        end

      # case header.status
      # when 'approved3','canceled3','approved2'
      #   # header.update({:printed_by=> session[:id],:printed_at=>DateTime.now()},:without_protection=>true)
      #   name_prepared_by = account_name(header.created_by) 
      #   name_approved_by = account_name(header.approved3_by)
      #   my_currency = header.currency.name.upcase
      #   my_currency == "IDR" ? cur_prec = 2 : cur_prec = 4

      #   case params[:kind]
      #   when "kasbon"
      #     items = CashSubmission.where(:id => header.cash_submission_id).order("created_at asc")
      #   else
      #     # items  = @voucher_payment_items
      #   end
        
      # end

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

        document_name = "VOUCHER PAYMENT #{@voucher_payment.kind.upcase}" 
        respond_to do |format|
          format.html do
            pdf = Prawn::Document.new(:page_size=> "A4",
              :top_margin => 0.90,
              :bottom_margin => 0.78, 
              :left_margin=> 0.59, 
              :right_margin=> 0.39 ) 
           
            # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')
            # danny
            pdf.move_down 115
            tbl_width = [30, 135, 120, 208, 100]
     
            pdf.page_count.times do |i|
              # header begin
                pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                  pdf.go_to_page i+1
                }

                # pdf.bounding_box([0, 840], :width => 594, :height => 460) do #garis bawah
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end

                pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                  pdf.go_to_page i+1
                  pdf.table([
                    [{:image => image_path, :image_width => 100}, "", "",""],
                    [{:content=>company_address1, :size=>10},"","",""],
                    ["",{:content=>document_name, :font_style => :bold, :align=>:center, :valign=>:center, :size=>12},"",""
                    ]],:column_widths => [200, 200, 70, 124], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>2}) 
                  pdf.stroke_horizontal_rule
   
                  pdf.table([
                    [ {:content=> "No. Voucher", :size=>10, :align=> :left}, {:content=> ": #{header.number}", :size=>10, :align=> :left}, 
                      {:content=> "Nama Penerima", :size=>10, :align=> :left}, {:content=> ": #{header.list_external_bank_account.name_account}", :size=>10, :align=> :left}],
                    [ {:content=> "Tgl. Pengajuan", :size=>10, :align=> :left}, {:content=> ": #{header.date}", :size=>10, :align=> :left}, 
                      {:content=> "Bank Penerima", :size=>10, :align=> :left}, {:content=> ": #{header.list_external_bank_account.dom_bank.bank_name}", :size=>10, :align=> :left}],
                    [ {:content=> "Tgl. Pembayaran", :size=>10, :align=> :left}, {:content=> ": #{header.payment_date}", :size=>10, :align=> :left}, 
                      {:content=> "No. Rekening", :size=>10, :align=> :left}, {:content=> ": #{header.list_external_bank_account.number_account}", :size=>10, :align=> :left}
                    ],
                    [ {:content=> "Bank Pengirim", :size=>10, :align=> :left}, {:content=> ": #{header.list_internal_bank_account.name_account} - #{header.list_internal_bank_account.number_account}", :size=>10, :align=> :left}, 
                      {:content=> "Total Amount", :size=>10, :align=> :left}, {:content=> ": #{number_with_precision(header.grand_total, precision: cur_prec, delimiter: ".", separator: ",").to_s}", :size=>10, :align=> :left}]    
                  ],:column_widths => [85, 179, 85, 245], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>5})

                  # pdf.move_down 5
                  pdf.stroke_horizontal_rule
                  pdf.move_down 5
                   
                  case params[:kind]
                  when "kasbon"      
                    pdf.table([ [
                      {:content=>"No.", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Dept", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"No. Kasbon", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Keperluan", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Amount", :height=> 25, :valign=> :center, :align=> :center}]], 
                      :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                    c = 1
                    items.each do |item|
                      pdf.table([[
                          {:content=>c.to_s+".", :align=>:right}, 
                          item.department.name, 
                          item.number.to_s,
                          item.description.to_s,
                          {:content=> number_with_precision( item.amount, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                          ]], :column_widths => [30, 135, 120, 208, 100], :cell_style => {:size=> 10, :padding=> 5})
                        subtotal += item.amount.to_f
                        c +=1
                    end
                  when "general"
                    pdf.table([ [
                      {:content=>"No.", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Nama COA", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"No. COA", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Keterangan Biaya", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Amount", :height=> 25, :valign=> :center, :align=> :center}]], 
                      :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                    c = 1
                    items.each do |item|
                      pdf.table([[
                          {:content=>c.to_s+".", :align=>:right}, 
                          item.cost_type, 
                          item.coa_number,
                          item.cost_detail.to_s,
                          {:content=> number_with_precision( item.nominal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                          ] ], :column_widths => [30, 135, 120, 208, 100], :cell_style => {:size=> 10, :padding=> 5})
                        subtotal += item.nominal.to_f
                        c +=1
                    end
                  when "pettycash"
                    pdf.table([ [
                      {:content=>"No.", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Dept", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"No. BPK", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Keterangan", :height=> 25, :valign=> :center, :align=> :center},
                      {:content=>"Amount", :height=> 25, :valign=> :center, :align=> :center}]], 
                      :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                    c = 1
                    items.each do |item|
                      pdf.table([[
                          {:content=>c.to_s+".", :align=>:right},
                          # {:content=> "#{item.proof_cash_expenditure.present? ? item.proof_cash_expenditure.department.name :} #{item.cash_settlement.department.name if item.cash_settlement.present?} #{item.routine_cost_payment.department.name if item.routine_cost_payment.present?}" },
                          { :content=> "#{item.proof_cash_expenditure.present? ? item.proof_cash_expenditure.department.name : item.cash_settlement.present? ? item.cash_settlement.department.name : item.routine_cost_payment.present? ? item.routine_cost_payment.department.name : ''}"},
                          { :content=> "#{item.proof_cash_expenditure.present? ? item.proof_cash_expenditure.number : item.cash_settlement.present? ? item.cash_settlement.number : item.routine_cost_payment.present? ? item.routine_cost_payment.number : ''}"},
                          item.cost_detail.to_s,
                          {:content=> number_with_precision( item.nominal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                          ] ], :column_widths => [30, 135, 120, 208, 100], :cell_style => {:size=> 10, :padding=> 5})
                        subtotal += item.nominal.to_f
                        c +=1
                    end
                  else
                    case params[:print_kind]
                    when "petty"
                        pdf.font_size 10
                        pdf.table([[
                          {:content=>"No."}, 
                          {:content=>"Dept"}, 
                          {:content=>"No. BPK"},
                          {:content=>"Jenis Biaya"}, 
                          {:content=>"No. COA"}, 
                          {:content=>"Keterangan"},
                          {:content=>"Amount"}
                        ]], :column_widths => [20, 100, 100, 93, 80, 100, 100], :cell_style => {:align=>:center, :size=>10,:padding => 2, :border_color=>"000000", :background_color => "f0f0f0", :borders=>[:left, :right, :top,:bottom]})
    
                        last_n = nil
                        c = 1
                        count = 1
                        subtotal = 0
                        grand_total = 0
                        items.each do |record_item|
                          borders = [:left, :right]

                          y = pdf.y
                          if y < 75
                            pdf.start_new_page 
                            pdf.move_down 135 
                            borders = [:left, :right,:top]
                          end

                          if record_item.routine_cost_payment_item_id.present?
                            detail_item = record_item.routine_cost_payment_item
                            detail_header = record_item.routine_cost_payment
                          end
                          if record_item.proof_cash_expenditure_item_id.present?
                            detail_item = record_item.proof_cash_expenditure_item
                            detail_header = record_item.proof_cash_expenditure
                          end
                          if record_item.cash_settlement_item_id.present?
                            detail_item = record_item.cash_settlement_item
                            detail_header = record_item.cash_settlement
                          end
                          
                          if last_n == detail_header.number
                            samaa = true
                          elsif last_n != detail_header.number
                            subtotal = record_item.nominal if last_n.blank?
                            c+=1
                            samaa = false
                            pdf.table([[
                              {:content=>"", :borders=>[:left, :bottom,:top]},
                              {:content=>"", :borders=>[:bottom,:top]},
                              {:content=>"Sub Total Item", :align=>:right, :borders=>[:bottom, :right,:top]},
                              {:content=>number_with_precision(subtotal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                              ]], :column_widths=> [20, 80, 393, 100], :cell_style => {:size=>10})

                            subtotal = 0
                          end if last_n.present?

                          pdf.table([[
                            {:content=> (samaa ? "" : c.to_s ), :width=>20, :borders=> borders},
                            {:content=> (samaa ? "" : detail_header.department.name), :width=> 100, :borders=> borders},
                            {:content=> (samaa ? "" : detail_header.number), :width=> 100, :borders=> borders},
                            {:content=> record_item.cost_type, :width=> 93},
                            {:content=> record_item.coa_number.to_s, :width=> 80},
                            {:content=> record_item.cost_detail, :width=>100} ,
                            {:content=> number_with_precision(record_item.nominal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>100}
                          ]] )

                          grand_total += record_item.nominal
                          subtotal += record_item.nominal

                          if count == items.count
                            subtotal = record_item.nominal if last_n.blank?
                            pdf.table([[
                              {:content=>"", :borders=>[:left, :bottom,:top]},
                              {:content=>"", :borders=>[:bottom,:top]},
                              {:content=>"Sub Total Item", :align=>:right, :borders=>[:bottom, :right,:top]},
                              {:content=>number_with_precision(subtotal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                              ]], :column_widths=> [20, 80, 393, 100], :cell_style => {:size=>10})
                          end
                          
                          count+=1
                          last_n = detail_header.number
                        end

                        pdf.table([[
                        {:content=>"Sub Total", :align=>:right, :font_style=> :bold},
                        {:content=>number_with_precision(grand_total, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                        ]], :column_widths=> [493, 100], :cell_style => {:size=>10})

                        pdf.table([[
                        {:content=>"PPN Total", :align=>:right, :font_style=> :bold},
                        {:content=>number_with_precision(header.ppn_total.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                        ]], :column_widths=> [493, 100], :cell_style => {:size=>10})

                        pdf.table([[
                        {:content=>"PPH Total", :align=>:right, :font_style=> :bold},
                        {:content=>number_with_precision(header.pph_total.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                        ]], :column_widths=> [493, 100], :cell_style => {:size=>10})

                        pdf.table([[
                        {:content=>"Potongan Lain", :align=>:right, :font_style=> :bold},
                        {:content=>number_with_precision(header.other_cut_fee.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                        ]], :column_widths=> [493, 100], :cell_style => {:size=>10})

                        pdf.table([[
                        {:content=>"Grand Total", :align=>:right, :font_style=> :bold},
                        {:content=>number_with_precision(header.grand_total.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                        ]], :column_widths=> [493, 100], :cell_style => {:size=>10})

                      pdf.move_down 10
                      pdf.table([[
                        {:content=>"Terbilang : "+number_to_words(grand_total.to_i).upcase+" ("+(my_currency)+") ", :height=> 40}]], :column_widths=> [493], :cell_style => {:size=>9,:padding => [3, 10, 0, 3]})
                      # pdf.move_down 10
                      pdf.move_down 5
                      footer_sign  = [
                        [{:content=> "Disetujui", width: 100, :align=> :center}, {:content=> "Diperiksa", width: 100, :align=> :center}],
                        [
                          {:content=> "#{header.approved2.first_name if header.approved2.present?}", width: 100, :height=>30, :align=> :center}, 
                          {:content=> "#{header.approved3.first_name if header.approved3.present?}", width: 100, :height=>30, :align=> :center}],
                        [{:content=> "Dir.Utama / Dir.Keuangan", width: 125, :align=> :center}, {:content=> "Keuangan", width: 100, :align=> :center}]
                      ]
                      pdf.table([["",footer_sign,""]], :column_widths => [150, 300, 100], :cell_style => {:border_width => 0, :border_color => "000000", :padding => 2})
                    end
                  end   

                  case params[:kind]
                  when "kasbon","general","pettycash"
                    # pdf.move_down 170
                    pdf.table([[
                        {:content=> "Sub Total", :width=> 493, :align=>:right, :size=> 10, :font_style=> :bold}, 
                        {:content=> number_with_precision( subtotal.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 100, :size=> 10, :font_style => :bold}
                      ]])
                    pdf.table([[
                        {:content=> "PPN Total", :width=> 493, :align=>:right, :size=> 10, :font_style=> :bold}, 
                        {:content=> number_with_precision( header.ppn_total.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 100, :size=> 10, :font_style => :bold}
                      ]])
                    pdf.table([[
                        {:content=> "PPH Total", :width=> 493, :align=>:right, :size=> 10, :font_style=> :bold}, 
                        {:content=> number_with_precision( header.pph_total.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 100, :size=> 10, :font_style => :bold}
                      ]])

                    pdf.table([[
                        {:content=> "Potongan Lain", :width=> 493, :align=>:right, :size=> 10, :font_style=> :bold}, 
                        {:content=> number_with_precision( header.other_cut_fee.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 100, :size=> 10, :font_style => :bold}
                      ]])
                    pdf.table([[
                        {:content=> "Grand Total", :width=> 493, :align=>:right, :size=> 10, :font_style=> :bold}, 
                        {:content=> number_with_precision( header.grand_total.to_f, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 100, :size=> 10, :font_style => :bold}
                      ]])
                    pdf.move_down 5
                      pdf.table([[
                        {:content=>"Terbilang : "+number_to_words(header.grand_total.to_i).upcase+" ("+(my_currency)+") ", :height=> 40}]], :column_widths=> [493], :cell_style => {:size=>9,:padding => [3, 10, 0, 3]})
                    pdf.move_down 5
                    disetujui = [
                                  [{:content=>"Disetujui", :width=>100, :align=> :center, :padding=> 1}],
                                  [{:content=>"#{header.approved2.first_name if header.approved2.present?}", :align=>:center, :height=>30}],
                                  [{:content=>"Dir.Utama / Dir.Keuangan", :align => :center, :padding=>1}]
                                ]
                    diperiksa = [
                                  [{:content=>"Diperiksa", :width=>105, :align=> :center, :padding=> 1}],
                                  [{:content=>"#{header.approved3.first_name if header.approved3.present?}", :align=>:center, :height=>30}],
                                  [{:content=>"Keuangan", :align => :center, :padding=>1}]
                                ]
                    pdf.table([["",disetujui,diperiksa]], :column_widths=> [150,140,269], :cell_style => {:border_color => "ffffff"})
                  end

                }
              # header end

              # content begin
                # dk_row = 0
                # tbl_top_position = 698 #colom content
                
                # tbl_width.each do |i|
                #   # puts dk_row
                #   dk_row += i
                #   pdf.bounding_box([0, tbl_top_position], :width => dk_row, :height => 150) do
                #     pdf.stroke_color '000000'
                #     pdf.stroke_bounds
                #   end
                # end
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
        pdf.text "Belum approve 3"
      end
    else
      respond_to do |format|
        format.html { redirect_to @voucher_payment, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @voucher_payment }
      end
    end
  end

  def export
    # template_report(controller_name, current_user.id, nil)
    template_report(controller_name, current_user.id, params[:kind])
    puts "ini"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_voucher_payment
      if params[:multi_id].present?
        id_selected = params[:multi_id].split(',')
        @voucher_payment = VoucherPayment.where(:id=> id_selected)
      else
        id_selected = params[:id]
        @voucher_payment = VoucherPayment.find_by(:id=> id_selected)
      end

      if @voucher_payment.present?
        @voucher_payment_items = VoucherPaymentItem.where(:status=> 'active')
        .includes(:voucher_payment).where(:voucher_payments => {:id=> id_selected, :company_profile_id => current_user.company_profile_id })
        .includes(routine_cost_payment: [:department], proof_cash_expenditure: [:department], cash_settlement: [:department])
        .order("voucher_payments.number desc")       
      else
        respond_to do |format|
          format.html { redirect_to voucher_payments_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @currencies = Currency.all
      @list_internal_bank_accounts = ListInternalBankAccount.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3')
      @list_external_bank_accounts = ListExternalBankAccount.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved1')

      if params[:kind].present?
        case params[:kind]
        when 'kasbon'
          @cash_submissions = CashSubmission.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3')
        end
      else    
        @departments = Department.all
        @dom_banks          = DomBank.all
        @cash_submissions = CashSubmission.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3')

        @periode = params[:periode].present? ? params[:periode] : DateTime.now.strftime("%Y-%m-01").to_s
        @months = Date.parse('2010-01-01').upto(Date.today).map {|date| ["#{date.strftime("%Y-%B")}","#{date.to_s[0..-4]}"+"-01"]}.uniq.reverse
        session[:periode] = @periode
        @bank_voucher = @list_internal_bank_accounts.group("code_voucher").collect {|e| [e.code_voucher]}.uniq

        params[:bank_type] = (params[:bank_type].present? ? params[:bank_type] : (session["bank_type"].present? ? session["bank_type"] : "RTSI"))
        session["bank_type"] = params["bank_type"]
      end
    end

    def check_status     
      if @voucher_payment.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @voucher_payment.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @voucher_payment, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @voucher_payment }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def voucher_payment_params
      params.require(:voucher_payment).permit(:voucher_payment_id, :kind,:tax_id, :currency_id, :cash_submission_id, :company_profile_id, :list_internal_bank_account_id, :list_external_bank_account_id, :department_id, :number, :name_account, :date, :payment_date, :routine_cost_payment_id, :routine_cost_payment_item_id, :proof_cash_expenditure_id, :proof_cash_expenditure_item_id, :cash_settlement_id, :cash_settlement_item_id, :coa_number, :cost_type, :remarks, :cost_detail, :cost_for, :nominal, :sub_total, :ppn_total, :pph_percent, :pph_total, :other_cut_fee, :grand_total, :created_by, :created_at, :updated_at, :updated_by, :img_created_signature)
    end
end
