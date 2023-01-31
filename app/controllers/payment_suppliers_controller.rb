class PaymentSuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_supplier, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :set_instance_variable
  before_action :check_status, only: [:edit]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end
  # GET /payment_suppliers
  # GET /payment_suppliers.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    payment_suppliers = PaymentSupplier.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin]..session[:date_end])
    .where(:status=> ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3'])
    .includes(:supplier, :currency, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3)
    
    # filter select - begin
      @option_filters = [['Pay.Number','number'],['Pay.Status','status'], ['Supplier Name', 'supplier_id']  ] 
      @option_filter_records = payment_suppliers
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc").includes(:currency)
        end

        payment_suppliers = payment_suppliers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @payment_suppliers = payment_suppliers.order("number desc")

    if params[:payment_request_supplier_id].present?
      @payment_request_suppliers = @payment_request_suppliers.where(:id=> params[:payment_request_supplier_id]).order("number asc")
    else
      @payment_request_suppliers = @payment_request_suppliers.where(:supplier_id=> params[:supplier_id], :payment_supplier_id=> nil).order("number asc")
    end
    @payment_request_supplier_items = @payment_request_supplier_items.where(:payment_request_supplier_id=> params[:payment_request_supplier_id])
  end

  # GET /payment_suppliers/1
  # GET /payment_suppliers/1.json
  def show
  end

  # GET /payment_suppliers/new
  def new
    @payment_supplier = PaymentSupplier.new
    @suppliers        = @suppliers.where(:payment_request_suppliers=> {:payment_supplier_id=> nil})
  end

  # GET /payment_suppliers/1/edit
  def edit
    @payment_request_suppliers = @payment_request_suppliers.where(:supplier_id=> @payment_supplier.supplier_id, :payment_supplier_id=> [nil, @payment_supplier.id]).order("number asc")
    
  end

  # POST /payment_suppliers
  # POST /payment_suppliers.json
  def create
    params[:payment_supplier]["company_profile_id"] = current_user.company_profile_id
    params[:payment_supplier]["created_by"] = current_user.id
    params[:payment_supplier]["created_at"] = DateTime.now()
    params[:payment_supplier]["status"] = "new"
    @payment_supplier = PaymentSupplier.new(payment_supplier_params)

    respond_to do |format|
      if @payment_supplier.save
        params[:new_record_item].each do |item|
          tax_rate_id = (item["tax_rate_id"].present? ? item["tax_rate_id"] : nil)
          payreq_item = PaymentSupplierItem.new({
            :payment_supplier_id=> @payment_supplier.id,
            :invoice_supplier_id=> item["invoice_supplier_id"],
            :payment_request_supplier_id=> item["payment_request_supplier_id"],
            :payment_request_supplier_item_id=> item["payment_request_supplier_item_id"],
            :tax_rate_id=> tax_rate_id,
            :ppntotal=> item["ppntotal"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          payreq_item.save!
          logger.info payreq_item.errors.full_messages
        end if params[:new_record_item].present?
        
        payment_supplier = PaymentSupplier.find_by(:id=> @payment_supplier.id)
        if payment_supplier.present?
          payment_supplier.update({:updated_at=> DateTime.now()})
        end
        format.html { redirect_to @payment_supplier, notice: 'Payment Request supplier was successfully created.' }
        format.json { render :show, status: :created, location: @payment_supplier }
      else
        @payment_request_suppliers = @payment_request_suppliers.where(:supplier_id=> params[:payment_supplier][:supplier_id], :payment_supplier_id=> nil).order("number asc")
        format.html { render :new }
        format.json { render json: @payment_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payment_suppliers/1
  # PATCH/PUT /payment_suppliers/1.json
  def update
    respond_to do |format|
      params[:payment_supplier]["updated_by"] = current_user.id
      params[:payment_supplier]["updated_at"] = DateTime.now()
      if params[:new_record_item].present?
        PaymentSupplierItem.where(:payment_supplier_id=> @payment_supplier.id, :status=> 'active').each do |payment_item|
          payment_item.update(:status=> 'deleted')
          payment_item.payment_request_supplier.update(:payment_supplier_id=> nil)
        end

        params[:new_record_item].each do |item|
          tax_rate_id = (item["tax_rate_id"].present? ? item["tax_rate_id"] : nil)

          payment_item = PaymentSupplierItem.find_by({              
            :payment_supplier_id=> @payment_supplier.id,
            :payment_request_supplier_id=> item["payment_request_supplier_id"],
            :invoice_supplier_id=> item["invoice_supplier_id"],
            :payment_request_supplier_item_id=> item["payment_request_supplier_item_id"]
          })

          if payment_item.present?
            payment_item.update({
              :tax_rate_id=> tax_rate_id,
              :ppntotal=> item["ppntotal"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
            logger.info "update item"
          else
            payment_item = PaymentSupplierItem.create({
              :payment_supplier_id=> @payment_supplier.id,
              :payment_request_supplier_id=> item["payment_request_supplier_id"],
              :invoice_supplier_id=> item["invoice_supplier_id"],
              :payment_request_supplier_item_id=> item["payment_request_supplier_item_id"],
              :tax_rate_id=> tax_rate_id,
              :ppntotal=> item["ppntotal"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
         
        end if params[:new_record_item].present?
      end

      if params[:record_item].present?
        params[:record_item].each do |item|
          payment_item = PaymentSupplierItem.find_by(:id=> item["id"])
          if payment_item.present?
            payment_item.update({:status=> item["status"]})
            payment_item.payment_request_supplier.update(:payment_supplier_id=> nil) if item["status"] == 'deleted'
          end 
        end
      end

      if @payment_supplier.update(payment_supplier_params)
        format.html { redirect_to @payment_supplier, notice: 'Invoice supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @payment_supplier }
      else
        format.html { render :edit }
        format.json { render json: @payment_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    logger.info "session[:date_begin]: #{session[:date_begin]}"
    logger.info "session[:date_end]: #{session[:date_end]}"
    template_report(controller_name, current_user.id, nil)
  end

  def print
    case @payment_supplier.status
    when 'approved2','canceled3','approved3'
      image_path      = "app/assets/images/logo.png" 
      company_ori     = "PT. PROVITAL PERDANA" 
      company         = "PT. PROVITAL PERDANA"
      company_address = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      city            = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      title           = "Jl. Kranji Blok F15 No. 1C,
          Delta Silicon 2, Lippo Cikarang"
      phone_number    = " "
      
      my_company       = CompanyProfile.find_by(:id=> current_user.company_profile_id, :status=> 'active')

      pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>10, :right_margin=>10)
      pdf.font "Helvetica"
      pdf.font_size 9

      header = @payment_supplier
      items  = @payment_supplier_items
      my_currency = (header.currency.present? ? header.currency.name.upcase : "-")
      
      case params[:print_kind]
      when 'print', 'dpp', 'ppn'
        case params[:print_kind]
        when 'print' # dpp+ppn
          pdf.move_down 90
          pdf.table([
                [ {:content=>"No."},
                {:content=>"No.Invoice"},
                {:content=>"Sub-Total"},
                {:content=>"PPN"},
                {:content=>"PPH"},
                {:content=>"DP"},
                {:content=>"Amount"}
            ]], :column_widths => [30, 110, 100, 70, 70, 90, 100], :cell_style => {:align=>:center, :size=>9,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
          c = 1
          grand_total = 0
          items.each do |item|
            pdf.table([[
              {:content=>c.to_s, :align=>:center}, 
              {:content=>item.invoice_supplier.number.to_s},
              {:content=>number_with_precision(sub_total = (item.invoice_supplier.present? ? item.invoice_supplier.subtotal : 0), precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
              {:content=>number_with_precision(ppn = (item.invoice_supplier.present? ? item.invoice_supplier.ppntotal : 0), precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
              {:content=>number_with_precision(pph = (item.invoice_supplier.present? ? item.invoice_supplier.pphtotal : 0), precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
              {:content=>number_with_precision(dp = (item.invoice_supplier.present? ? item.invoice_supplier.dptotal : 0), precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
              {:content=>number_with_precision(total = sub_total+ppn-pph-dp, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}                      
             ] ], :column_widths =>[30, 110, 100, 70, 70, 90, 100], :cell_style => {:size=>9,:padding => [3, 5, 0, 3]})
            grand_total += total

           c +=1
          end

          pdf.table([[
            {:content=>"Grand Total", :align=>:right},
            {:content=>number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
            ]], :column_widths=> [460, 110], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
          pdf.move_down 10
          
          if pdf.y < 100
            pdf.start_new_page 
            pdf.move_down 90 
          end

          pdf.table([[
            {:content=>"Terbilang : "+number_to_words(grand_total.to_i).upcase+" ("+(my_currency)+") ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>9,:padding => [3, 10, 0, 3]})
          pdf.move_down 5
          pdf.text "Harap Lampirkan Bukti Pendukung Pembayaran", :size => 8, :style=> :italic
          pdf.move_down 10
            disetujui = [
                          [{:content=>"Disetujui", :width=>100, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Dir.Utama / Dir.Keuangan", :align => :center, :padding=>1}]
                        ]
            dicatat = [
                          [{:content=>"Dicatat", :width=>105, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Akuntansi", :align => :center, :padding=>1}]
                        ]
            dikeluarkan = [
                          [{:content=>"Dikeluarkan", :width=>105, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Keuangan", :align => :center, :padding=>1}]
                        ]
            diterima = [
                          [{:content=>"Diterima", :width=>100, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Penerima", :align => :center, :padding=>1}]
                        ]


            pdf.table([["",disetujui,dicatat,dikeluarkan,diterima]], :column_widths=> [150,105,105,105,105], :cell_style => {:border_color => "ffffff"})

          pdf.move_down 10
          pdf.page_count.times do |i|
            pdf.go_to_page i+1
            pdf.table([
              [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
              [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
              :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
            
            pdf.move_down 50
            pdf.draw_text ("VOUCHER PAYMENT (DPP+PPN)"), :at => [180,5], :size => 14, :style=> :bold
            
            pdf.table([
              ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..14], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method.present?)]
            ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
            pdf.table([
              ["Tgl. Pengajuan",":", PaymentRequestSupplier.where(:payment_supplier_id=> header.id).order("date asc").first.date.to_s,"","Uang sejumlah",":", my_currency+" "+number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
              ["Tgl. Pembayaran",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
            ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
          

            }
          end
        when 'dpp'
          pdf.move_down 90
          pdf.table([
                [ {:content=>"No."},
                {:content=>"No.Invoice"},
                {:content=>"Sub-Total"},
                {:content=>"PPH"},
                {:content=>"DP"},
                {:content=>"Jumlah"}
            ]], :column_widths => [20, 150, 100, 90, 100, 110], :cell_style => {:align=>:center, :size=>9,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
          c = 1
          grand_total = 0
          items.each do |item|
            pdf.table([[
              {:content=>c.to_s, :align=>:center}, 
              {:content=>item.invoice_supplier.number.to_s},
              {:content=>number_with_precision(sub_total = (item.invoice_supplier.present? ? item.invoice_supplier.subtotal : 0), precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
              {:content=>number_with_precision(pph_total = (item.invoice_supplier.present? ? item.invoice_supplier.pphtotal : 0), precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
              {:content=>number_with_precision(dp_total = (item.invoice_supplier.present? ? item.invoice_supplier.dptotal : 0), precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
              {:content=>number_with_precision(total = sub_total - pph_total - dp_total, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}                
             ] ], :column_widths => [20, 150, 100, 90, 100, 110], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
            grand_total += total
           c +=1
          end 
          pdf.table([[
            {:content=>"Grand Total", :align=>:right},
            {:content=>number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
            ]], :column_widths=> [460, 110], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
          pdf.move_down 10
          pdf.table([[
            {:content=>"Terbilang : "+number_to_words(grand_total.to_i).upcase+" ( "+(my_currency)+" ) ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
          pdf.move_down 5
          pdf.text "Harap Lampirkan Bukti Pendukung Pembayaran", :size => 8, :style=> :italic
          pdf.move_down 10
            disetujui = [
                          [{:content=>"Disetujui", :width=>100, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Dir.Utama / Dir.Keuangan", :align => :center, :padding=>1}]
                        ]
            dicatat = [
                          [{:content=>"Dicatat", :width=>105, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Akuntansi", :align => :center, :padding=>1}]
                        ]
            dikeluarkan = [
                          [{:content=>"Dikeluarkan", :width=>105, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Keuangan", :align => :center, :padding=>1}]
                        ]
            diterima = [
                          [{:content=>"Diterima", :width=>100, :align=> :center, :padding=> 1}],
                          [{:content=>"", :height=>40}],
                          [{:content=>"Penerima", :align => :center, :padding=>1}]
                        ]

            pdf.table([["",disetujui,dicatat,dikeluarkan,diterima]], :column_widths=> [150,105,105,105,105], :cell_style => {:border_color => "ffffff"})

          pdf.move_down 10
          pdf.page_count.times do |i|
            pdf.go_to_page i+1
            pdf.table([
              [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
              [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
              :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
              pdf.move_down 50
              pdf.draw_text ("VOUCHER PAYMENT ("+params[:print_kind].upcase+")"), :at => [200,5], :size => 14, :style=> :bold
              pdf.table([
                ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..14], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method_id.present?)]
              ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
              pdf.table([
                ["Tgl. Pengajuan",":", PaymentRequestSupplier.where(:payment_supplier_id=> header.id).order("date asc").first.date.to_s,"","Uang sejumlah",":", my_currency+" "+number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                ["Tgl. Pembayaran",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
              ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
            }
          end
        when 'ppn'
          # items = FinSupplierPaymentRequestItem.where(:status=>'active', :fin_supplier_payment_request_id=> header.fin_supplier_payment_request_id )
          if items.find_by(:tax_rate_id=> 1).present?                      # PPN dalam mata uang IDR
            pdf.table([
              [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
              [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
              :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {                     
              pdf.move_down 50
                pdf.draw_text ("VOUCHER PAYMENT (PPN)"), :at => [200,5], :size => 14, :style=> :bold
                pdf.table([
                  ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..14], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method_id.present?)]
                ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
                pdf.table([
                  ["Tgl. Pengajuan",":", PaymentRequestSupplier.where(:payment_supplier_id=> header.id).order("date asc").first.date.to_s,"","Uang sejumlah",":", "IDR "+number_with_precision(items.where(:tax_rate_id=> 1).sum(:ppntotal), precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                  ["Tgl. Pembayaran",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
                ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
            }

            pdf.table([
                  [ {:content=>"No."},
                  {:content=>"No.Invoice"},
                  {:content=>"PPN"}
              ]], :column_widths => [50, 400, 120], :cell_style => {:align=>:center, :size=>9,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
            c = 1
            items.where(:tax_rate_id=> 1).each do |item|
              pdf.table([[
                {:content=>c.to_s, :align=>:center}, 
                {:content=>item.invoice_supplier.number.to_s},
                {:content=>number_with_precision(item.ppntotal, precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right}                 
               ] ], :column_widths =>[50, 400, 120], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
             c +=1
            end
            pdf.table([[
              {:content=>"Grand Total", :align=>:right},
              {:content=>number_with_precision(items.where(:tax_rate_id=> 1).sum(:ppntotal), precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
              ]], :column_widths=> [450, 120], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})

            pdf.move_down 10
            pdf.table([[
              {:content=>"Terbilang : "+number_to_words(items.where(:tax_rate_id=> 1).sum(:ppntotal).to_i).upcase+" (IDR) ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
            pdf.move_down 5
            pdf.text "Harap Lampirkan Bukti Pendukung Pembayaran", :size => 8, :style=> :italic
            pdf.move_down 10
              disetujui = [
                            [{:content=>"Disetujui", :width=>100, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Dir.Utama / Dir.Keuangan", :align => :center, :padding=>1}]
                          ]
              dicatat = [
                            [{:content=>"Dicatat", :width=>105, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Akuntansi", :align => :center, :padding=>1}]
                          ]
              dikeluarkan = [
                            [{:content=>"Dikeluarkan", :width=>105, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Keuangan", :align => :center, :padding=>1}]
                          ]
              diterima = [
                            [{:content=>"Diterima", :width=>100, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Penerima", :align => :center, :padding=>1}]
                          ]

              pdf.table([["",disetujui,dicatat,dikeluarkan,diterima]], :column_widths=> [150,105,105,105,105], :cell_style => {:border_color => "ffffff"})
            pdf.start_new_page if items.where(:tax_rate_id=> nil).present?
          end
          if items.where(:tax_rate_id=> nil).present?
            # PPn dibayarkan dgn mata uang asing
            pdf.table([
                [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
                [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
                :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {                     
              pdf.move_down 50
                pdf.draw_text ("VOUCHER PAYMENT (PPN)"), :at => [200,5], :size => 14, :style=> :bold
                pdf.table([
                  ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..14], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method_id.present?)]
                ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
                pdf.table([
                  ["Tgl. Pengajuan",":", FinSupplierPaymentRequest.where(:payment_supplier_id=> header.id).order("date asc").first.date.to_s,"","Uang sejumlah",":", header.sys_currency.name.to_s+" "+number_with_precision(items.where(:tax_rate_id=> nil).sum(:ppn), precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                  ["Tgl. Pembayaran",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
                ], :column_widths=> [80,10, 90,10,80,10, 110, 10, 80,10,80], :cell_style => {:border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
            }

            pdf.table([
                  [ {:content=>"No."},
                  {:content=>"No.Invoice"},
                  {:content=>"PPN"}
              ]], :column_widths => [50, 400, 120], :cell_style => {:align=>:center, :size=>9,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
            c = 1
            items.where(:tax_rate_id=> nil).each do |item|
              pdf.table([[
                {:content=>c.to_s, :align=>:center}, 
                {:content=>item.fin_supplier_invoice.number.to_s},
                {:content=>number_with_precision(item.ppn, precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right}                 
               ] ], :column_widths =>[50, 400, 120], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
             c +=1
            end
            pdf.table([[
              {:content=>"Grand Total", :align=>:right},
              {:content=>number_with_precision(items.where(:tax_rate_id=> nil).sum(:ppn), precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
              ]], :column_widths=> [450, 120], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})

            pdf.move_down 10
            pdf.table([[
              {:content=>"Terbilang : "+number_to_words(items.where(:tax_rate_id=> nil).sum(:ppn).to_i).upcase+" ("+header.sys_currency.name.to_s+") ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
            pdf.move_down 5
            pdf.text "Harap Lampirkan Bukti Pendukung Pembayaran", :size => 8, :style=> :italic
            pdf.move_down 10
              disetujui = [
                            [{:content=>"Disetujui", :width=>100, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Dir.Utama / Dir.Keuangan", :align => :center, :padding=>1}]
                          ]
              dicatat = [
                            [{:content=>"Dicatat", :width=>105, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Akuntansi", :align => :center, :padding=>1}]
                          ]
              dikeluarkan = [
                            [{:content=>"Dikeluarkan", :width=>105, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Keuangan", :align => :center, :padding=>1}]
                          ]
              diterima = [
                            [{:content=>"Diterima", :width=>100, :align=> :center, :padding=> 1}],
                            [{:content=>"", :height=>40}],
                            [{:content=>"Penerima", :align => :center, :padding=>1}]
                          ]

              pdf.table([["",disetujui,dicatat,dikeluarkan,diterima]], :column_widths=> [150,105,105,105,105], :cell_style => {:border_color => "ffffff"})
          end
        end                 
      else
        pdf.text "not yet available"
      end

      pdf.move_down 10
      send_data pdf.render, type: "application/pdf", disposition: "inline"  
    else
      respond_to do |format|
        format.html { redirect_to @payment_supplier, alert: 'Cannot be displayed, status must be Approve 2' }
        format.json { render :show, status: :ok, location: @payment_supplier }
      end
    end
  end


  def approve
    check_payreq = nil
    case params[:status]
    when 'approve1'
      @payment_supplier.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @payment_supplier.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @payment_supplier.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @payment_supplier.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      if params[:multi_id].present?
        id_selected       = params[:multi_id].split(',')
      else
        id_selected       = params[:id]        
      end
      PaymentRequestSupplier.where(:payment_supplier_id=> id_selected ).each do |payreq|
        if payreq.status != 'approved3'
          check_payreq = "#{payreq.number} not yet approved!"
        end
      end
      if check_payreq.blank?
        @payment_supplier.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
      end
    when 'cancel_approve3'
      @payment_supplier.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end

    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to payment_suppliers_url, notice: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        if check_payreq.present?
          format.html { redirect_to payment_supplier_path(:id=> @payment_supplier.id), alert: "Can't #{params[:status]} because #{check_payreq}" }
          format.json { head :no_content }
        else
          format.html { redirect_to payment_supplier_path(:id=> @payment_supplier.id), notice: "Payment was successfully #{@payment_supplier.status}." }
          format.json { head :no_content }
        end
      end
    end
  end

  # DELETE /payment_suppliers/1
  # DELETE /payment_suppliers/1.json
  def destroy
    @payment_supplier.update({:number=> "delete-#{@payment_supplier.number}", :status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    respond_to do |format|
      format.html { redirect_to payment_suppliers_url, notice: 'Payment Supplier was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment_supplier
      if params[:multi_id].present?
        id_selected       = params[:multi_id].split(',')
        @payment_supplier = PaymentSupplier.where(:id=> id_selected)
      else
        id_selected       = params[:id]
        @payment_supplier = PaymentSupplier.find_by(:id=> id_selected)
      end

      if @payment_supplier.present?
        @payment_supplier_items = PaymentSupplierItem.where(:status=> 'active')
        .includes(payment_request_supplier: [:currency])
        .includes(invoice_supplier: [invoice_supplier_items: [:purchase_order_supplier, :material_receiving, :product_receiving, :general_receiving, :consumable_receiving, :equipment_receiving]])
        .includes(:payment_supplier).where(:payment_suppliers => {:id=> id_selected, :company_profile_id => current_user.company_profile_id })
        .order("payment_suppliers.number desc")
      else
        respond_to do |format|
          format.html { redirect_to payment_suppliers_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @payment_request_suppliers = PaymentRequestSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
      @payment_request_supplier_items = PaymentRequestSupplierItem.where(:status=> 'active').includes(:payment_request_supplier).where(:payment_request_suppliers => {:company_profile_id => current_user.company_profile_id, :status=> 'approved3' }).order("payment_request_suppliers.number desc")      
      # supplier_by_payreq = @payment_request_suppliers.group(:supplier_id).select(:supplier_id)
      # @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active', :id=> supplier_by_payreq).order("name asc")
      @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:tax, :payment_request_suppliers).where(:payment_request_suppliers=> {:company_profile_id => current_user.company_profile_id, :status=> 'approved3', :date=> session[:date_begin]..session[:date_end] }).order("suppliers.name asc")
      
      @invoice_supplier_items = InvoiceSupplierItem.where(:status=> 'active')
      .includes(:invoice_supplier).where(:invoice_suppliers => {:company_profile_id => current_user.company_profile_id, :status=> 'approved3' })
      .order("invoice_suppliers.number desc")      
      # @invoice_suppliers = InvoiceSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')

      @supplier_payment_methods = SupplierPaymentMethod.where(:status=> 'active')
      @bank_transfers = BankTransfer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')


      @material_batch_number = MaterialBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
      @tax_rates = TaxRate.where(:status=> "active").where("end_date >= ?", DateTime.now()).order("end_date desc")
      @taxes = Tax.where(:status=> "active")
      @term_of_payments = TermOfPayment.all
      @currencies = Currency.all
    end

    def check_status      
      noitce_msg = nil 

      if @payment_supplier.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          noitce_msg = 'Cannot be edited because it has been approved'
        end
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @payment_supplier.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @payment_supplier, alert: noitce_msg }
          format.json { render :show, status: :created, location: @payment_supplier }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def payment_supplier_params
      params.require(:payment_supplier).permit(:company_profile_id, :status, :number, :kind_dpp, :supplier_id, :currency_id, :date, :supplier_payment_method_id, :bank_transfer_id, :payment_methode_number, :subtotal, :ppntotal, :pphtotal, :dptotal, :remarks, :grandtotal, :created_by, :created_at, :updated_by, :updated_at)
    end
end
