class PaymentRequestSuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_request_supplier, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /payment_request_suppliers
  # GET /payment_request_suppliers.json
  def index
    payment_request_suppliers = PaymentRequestSupplier.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).where(:status=> ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3'])
    
    # filter select - begin
      @option_filters = [['Payreq.Number','number'],['Payreq.Status','status'], ['Supplier Name', 'supplier_id'] ] 
      @option_filter_records = payment_request_suppliers
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc").includes(:currency)
        end

        payment_request_suppliers = payment_request_suppliers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @payment_request_suppliers = payment_request_suppliers.order("number desc")

    if params[:invoice_supplier_id].present?
      @invoice_suppliers = @invoice_suppliers.where(:id=> params[:invoice_supplier_id]).order("number asc") 
    else
      @invoice_suppliers = @invoice_suppliers.where(:supplier_id=> params[:supplier_id], :payment_request_supplier_id=> nil).order("number asc")
    end

  end

  # GET /payment_request_suppliers/1
  # GET /payment_request_suppliers/1.json
  def show
  end

  # GET /payment_request_suppliers/new
  def new
    @payment_request_supplier = PaymentRequestSupplier.new
    @payment_request_supplier[:number]= document_number(controller_name, DateTime.now(), nil, nil, nil)
  end

  # GET /payment_request_suppliers/1/edit
  def edit
    @invoice_suppliers = @invoice_suppliers.where(:supplier_id=> @payment_request_supplier.supplier_id).where(:payment_request_supplier_id=> [@payment_request_supplier.id, nil]).order("number asc")
  end

  # POST /payment_request_suppliers
  # POST /payment_request_suppliers.json
  def create
    params[:payment_request_supplier]["company_profile_id"] = current_user.company_profile_id
    params[:payment_request_supplier]["created_by"] = current_user.id
    params[:payment_request_supplier]["created_at"] = DateTime.now()
    params[:payment_request_supplier]["status"] = "new"
    params[:payment_request_supplier]["number"] = document_number(controller_name, params[:payment_request_supplier]["date"].to_date, nil, nil, nil)
    @payment_request_supplier = PaymentRequestSupplier.new(payment_request_supplier_params)

    respond_to do |format|
      if @payment_request_supplier.save
        params[:new_record_item].each do |item|
          tax_rate_id = (item["tax_rate_id"].present? ? item["tax_rate_id"] : nil)

          payreq_item = PaymentRequestSupplierItem.new({
            :payment_request_supplier_id=> @payment_request_supplier.id,
            :invoice_supplier_id=> item["invoice_supplier_id"],
            :tax_rate_id=> tax_rate_id,
            :ppntotal=> item["ppntotal"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          payreq_item.save!
          invoice_supplier = InvoiceSupplier.find_by(:id=> item["invoice_supplier_id"])
          invoice_supplier.update_columns(:payment_request_supplier_id=> @payment_request_supplier.id) if invoice_supplier.present?
        end if params[:new_record_item].present?

        payment_request_supplier = PaymentRequestSupplier.find_by(:id=> @payment_request_supplier.id)
        if payment_request_supplier.present?
          payment_request_supplier.update({:updated_at=> DateTime.now()})
        end
        format.html { redirect_to @payment_request_supplier, notice: 'Payment Request supplier was successfully created.' }
        format.json { render :show, status: :created, location: @payment_request_supplier }
      else
        format.html { render :new }
        format.json { render json: @payment_request_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payment_request_suppliers/1
  # PATCH/PUT /payment_request_suppliers/1.json
  def update
    respond_to do |format|
      params[:payment_request_supplier]["updated_by"] = current_user.id
      params[:payment_request_supplier]["updated_at"] = DateTime.now()
      if @payment_request_supplier.update(payment_request_supplier_params)
        PaymentRequestSupplierItem.where(:payment_request_supplier_id=> @payment_request_supplier.id, :status=> 'active').each do |payreq_item|
          payreq_item.update_columns(:status=> 'deleted')
          payreq_item.invoice_supplier.update_columns(:payment_request_supplier_id=> nil)
        end
        params[:new_record_item].each do |item|
          case item["status"] 
          when 'active'
            tax_rate_id = (item["tax_rate_id"].present? ? item["tax_rate_id"] : nil)

            payreq_item = PaymentRequestSupplierItem.find_by({              
              :payment_request_supplier_id=> @payment_request_supplier.id,
              :invoice_supplier_id=> item["invoice_supplier_id"]
            })

            if payreq_item.present?
              payreq_item.update_columns({
                :tax_rate_id=> tax_rate_id,
                :ppntotal=> item["ppntotal"],
                :remarks=> item["remarks"],
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
            else
              payreq_item = PaymentRequestSupplierItem.create({
                :payment_request_supplier_id=> @payment_request_supplier.id,
                :invoice_supplier_id=> item["invoice_supplier_id"],
                :tax_rate_id=> tax_rate_id,
                :ppntotal=> item["ppntotal"],
                :remarks=> item["remarks"],
                :status=> 'active',
                :created_at=> DateTime.now(), :created_by=> current_user.id
              })
            end

            invoice_supplier = InvoiceSupplier.find_by(:id=> item["invoice_supplier_id"], :payment_request_supplier_id=> nil)
            invoice_supplier.update_columns(:payment_request_supplier_id=> @payment_request_supplier.id) if invoice_supplier.present?
          end
        end if params[:new_record_item].present?

        format.html { redirect_to @payment_request_supplier, notice: 'Invoice supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @payment_request_supplier }
      else
        format.html { render :edit }
        format.json { render json: @payment_request_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  def print
    case @payment_request_supplier.status 
    when 'approved2', 'canceled3','approved3'
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

        header = @payment_request_supplier
        items  = @payment_request_supplier_items
        my_currency = header.currency.name.upcase
        my_currency == "IDR" ? cur_prec = 2 : cur_prec = 4

        po_selected = InvoiceSupplierItem.where(:status=> 'active')
          .includes([:purchase_order_supplier, invoice_supplier: [:payment_request_supplier]])
          .where(:invoice_suppliers => {:payment_request_supplier_id => header.id, :status=> 'approved3' }).group(:purchase_order_supplier_id).select(:purchase_order_supplier_id)
        # po_selected = po_selected.map { |e| e.purchase_order_supplier_id }.join(", ")

        puts "po_selected: #{po_selected}"
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
              ]], :column_widths => [20, 100, 100, 80, 80, 80, 110], :cell_style => {:align=>:center, :size=>9,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
            c = 1
            # grand_total = 0
            items.each do |item|
              sub_total = item.invoice_supplier.subtotal
              ppn = item.invoice_supplier.ppntotal
              pph = item.invoice_supplier.pphtotal
              dp  = item.invoice_supplier.dptotal
            
              pdf.table([[
                {:content=>c.to_s, :align=>:center}, 
                {:content=>item.invoice_supplier.number.to_s},
                {:content=>number_with_precision(sub_total, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
                {:content=>number_with_precision(ppn, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
                {:content=>number_with_precision(pph, precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
                {:content=>number_with_precision(dp, precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right},
                # {:content=>number_with_precision(ppn = item.ppn).to_s, :align=>:right},
                {:content=>number_with_precision(total = (((sub_total+ppn)-pph)-dp), precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}                      
               ] ], :column_widths =>[20, 100, 100, 80, 80, 80, 110], :cell_style => {:size=> 8,:padding => [3, 3, 0, 3]})
              # grand_total += total
             c +=1
            end

            pdf.table([[
              {:content=>"Grand Total", :align=>:right},
              {:content=>number_with_precision(header.subtotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
              {:content=>number_with_precision(header.ppntotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
              {:content=>number_with_precision(header.pphtotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
              {:content=>number_with_precision(header.dptotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
              {:content=>number_with_precision(header.grandtotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
              ]], :column_widths=> [120, 100, 80, 80, 80, 110], :cell_style => {:size=>9,:padding => [3, 3, 0, 3]})
            pdf.move_down 10
            pdf.table([[
              {:content=>"Terbilang : "+number_to_words(header.grandtotal.to_i).upcase+" ("+(my_currency)+") ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>9,:padding => [3, 10, 0, 3]})
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

              pdf.table([["",disetujui,dicatat,dikeluarkan,diterima]], :column_widths=> [150,105,105,105,105], :cell_style => {:size=> 8, :border_color => "ffffff"})

            pdf.move_down 10
            pdf.page_count.times do |i|
              pdf.go_to_page i+1
              pdf.table([
                [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
                [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
                :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
              
              pdf.move_down 50
              pdf.draw_text ("VOUCHER PAYMENT REQUEST (DPP+PPN)"), :at => [160,5], :size => 14, :style=> :bold
              
              pdf.table([
                ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..15], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method.present?)]
              ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
              pdf.table([
                ["Tgl. Pengajuan",":", header.date.to_s,"","Uang sejumlah",":", my_currency+" "+number_with_precision(header.grandtotal, precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                ["Tgl. Realisasi",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
              ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
            

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
                {:content=>number_with_precision(sub_total = item.invoice_supplier.subtotal.to_f, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},             
                {:content=>number_with_precision(pph_total = item.invoice_supplier.pphtotal.to_f, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right} ,                
                {:content=>number_with_precision(dp_total  = item.invoice_supplier.dptotal.to_f, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},              
                {:content=>number_with_precision(total     = (sub_total - pph_total) - dp_total, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}                
               ] ], :column_widths => [20, 150, 100, 90, 100, 110], :cell_style => {:size=>8,:padding => [3, 10, 0, 3]})
              grand_total += total
             c +=1
            end 
            pdf.table([[
              {:content=>"Grand Total", :align=>:right},
              {:content=>number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
              ]], :column_widths=> [460, 110], :cell_style => {:size=>9,:padding => [3, 10, 0, 3]})
            pdf.move_down 10
            pdf.table([[
              {:content=>"Terbilang : "+number_to_words(grand_total.to_i).upcase+" ("+(my_currency)+") ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
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

              pdf.table([["",disetujui,dicatat,dikeluarkan,diterima]], :column_widths=> [150,105,105,105,105], :cell_style => {:size=> 8, :border_color => "ffffff"})

            pdf.move_down 10
            pdf.page_count.times do |i|
              pdf.go_to_page i+1
              pdf.table([
                [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
                [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
                :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
              
              pdf.move_down 50
                pdf.draw_text ("VOUCHER PAYMENT REQUEST ("+params[:print_kind].upcase+")"), :at => [160,5], :size => 14, :style=> :bold
                
                pdf.table([
                  ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..15], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method.present?)]
                ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
                pdf.table([
                  ["Tgl. Pengajuan",":", header.created_at.strftime("%Y-%m-%d").to_s,"","Uang sejumlah",":", my_currency+" "+number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                  ["Tgl. Realisasi",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
                ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
            

              }
            end
          when 'ppn'
            # menampilkan 2 pdf:
            # PPN dalam mata uang IDR
            if items.find_by(:tax_rate=> 1).present? 
              pdf.table([
                [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
                [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
                :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {                     
                pdf.move_down 50
                  pdf.draw_text ("VOUCHER PAYMENT REQUEST (PPN)"), :at => [160,5], :size => 14, :style=> :bold
                  pdf.table([
                    ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..15], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method.present?)]
                  ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
                  pdf.table([
                    ["Tgl. Pengajuan",":", header.created_at.strftime("%Y-%m-%d").to_s,"","Uang sejumlah",":", "IDR "+number_with_precision(items.where(:tax_rate=> 1).sum(:ppntotal), precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                    ["Tgl. Realisasi",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
                  ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
              }

              pdf.table([
                    [ {:content=>"No."},
                    {:content=>"No.Invoice"},
                    {:content=>"PPN"}
                ]], :column_widths => [50, 400, 120], :cell_style => {:align=>:center, :size=>9,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
              c = 1
              items.where(:tax_rate=> 1).each do |item|
                pdf.table([[
                  {:content=>c.to_s, :align=>:center}, 
                  {:content=>item.invoice_supplier.number.to_s},
                  {:content=>number_with_precision(item.ppntotal, precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right}                 
                 ] ], :column_widths =>[50, 400, 120], :cell_style => {:size=>9,:padding => [3, 10, 0, 3]})
               c +=1
              end
              pdf.table([[
                {:content=>"Grand Total", :align=>:right},
                {:content=>number_with_precision(items.where(:tax_rate=> 1).sum(:ppntotal), precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
                ]], :column_widths=> [450, 120], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})

              pdf.move_down 10
              pdf.table([[
                {:content=>"Terbilang : "+number_to_words(items.where(:tax_rate=> 1).sum(:ppntotal).to_f).upcase+" (IDR) ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
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
              
              pdf.start_new_page if items.find_by(:tax_rate=> nil).present?
            end
            # PPn dibayarkan dgn mata uang asing
            if items.find_by(:tax_rate=> nil).present?
              pdf.table([
                  [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
                  [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
                  :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {                     
                pdf.move_down 50
                  pdf.draw_text ("VOUCHER PAYMENT REQUEST (PPN)"), :at => [160,5], :size => 14, :style=> :bold
                  pdf.table([
                    ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.purch_supplier.name.to_s[0..14], "", "Cara Pembayaran", ":", (header.fin_payment_methode.name.to_s if header.fin_payment_methode_id.present?)]
                  ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
                  pdf.table([
                    ["Tgl. Pengajuan",":", header.date.to_s,"","Uang sejumlah",":", header.sys_currency.name.to_s+" "+number_with_precision(items.where(:tax_rate=> nil).sum(:ppn), precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                    ["Tgl. Realisasi",":", header.planning_date.to_s,"","","", "", "", "Bank", ":", (header.acc_coa.name if header.acc_coa_id.present?)]
                  ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
              }

              pdf.table([
                    [ {:content=>"No."},
                    {:content=>"No.Invoice"},
                    {:content=>"PPN"}
                ]], :column_widths => [50, 400, 120], :cell_style => {:align=>:center, :size=>9,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
              c = 1
              items.where(:tax_rate=> nil).each do |item|
                pdf.table([[
                  {:content=>c.to_s, :align=>:center}, 
                  {:content=>item.invoice_number.to_s},
                  {:content=>number_with_precision(item.ppn, precision: 2, delimiter: ".", separator: "," ).to_s, :align=>:right}                 
                 ] ], :column_widths =>[50, 400, 120], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
               c +=1
              end
              pdf.table([[
                {:content=>"Grand Total", :align=>:right},
                {:content=>number_with_precision(items.where(:tax_rate=> nil).sum(:ppn), precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}
                ]], :column_widths=> [450, 120], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})

              pdf.move_down 10
              pdf.table([[
                {:content=>"Terbilang : "+number_to_words(items.where(:tax_rate=> nil).sum(:ppn).to_f).upcase+" ("+header.sys_currency.name.to_s+") ", :height=> 40}]], :column_widths=> [570], :cell_style => {:size=>11,:padding => [3, 10, 0, 3]})
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
        when 'vpr_inv'
          # OK
          pdf.move_down 90
          c = 1
          c2 = 2
          grand_total = 0
          pdf.font_size 7
          y = nil
          invoice_number = nil

          grn_items = prn_items = nil
          grn_items = MaterialReceivingItem.where(:status=> 'active')
            .includes([
              :material,
              material_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )
          
          prn_items = ProductReceivingItem.where(:status=> 'active')
            .includes([
              :product,
              product_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )

          gen_items = GeneralReceivingItem.where(:status=> 'active')
            .includes([
              :general,
              general_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )

          con_items = ConsumableReceivingItem.where(:status=> 'active')
            .includes([
              :consumable,
              consumable_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )

          equ_items = EquipmentReceivingItem.where(:status=> 'active')
            .includes([
              :equipment,
              equipment_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )

          items.each do |item|
            pdf_item = []
            rcv_counter = 1
            sub_total = 0
            invoice_items = InvoiceSupplierItem.where(:invoice_supplier_id=> item.invoice_supplier_id, :status=> 'active')
            invoice_item_count = invoice_items.count()
            invoice_items.order("material_receiving_id asc, product_receiving_id asc, general_receiving_id asc").each do |inv_item|
              y = pdf.y
              records = nil
              if inv_item.material_receiving_item.present?
                records = grn_items.where(:id=> inv_item.material_receiving_item_id)
              elsif inv_item.product_receiving_item.present?
                records = prn_items.where(:id=> inv_item.product_receiving_item_id)
              elsif inv_item.general_receiving_item.present?
                records = gen_items.where(:id=> inv_item.general_receiving_item_id)
              elsif inv_item.consumable_receiving_item.present?
                records = con_items.where(:id=> inv_item.consumable_receiving_item_id)
              elsif inv_item.equipment_receiving_item.present?
                records = equ_items.where(:id=> inv_item.equipment_receiving_item_id)
              end

              records.each do |rcv_item|
                spg_number = spg_date = part_name = nil
                if inv_item.material_receiving_item.present?
                  spg_number = rcv_item.material_receiving.number
                  spg_date   = rcv_item.material_receiving.date.strftime("%d/%m/%Y")
                  part_name  = rcv_item.material.name
                elsif inv_item.product_receiving_item.present?
                  spg_number = rcv_item.product_receiving.number
                  spg_date   = rcv_item.product_receiving.date.strftime("%d/%m/%Y")
                  part_name  = rcv_item.product.name
                elsif inv_item.general_receiving_item.present?
                  spg_number = rcv_item.general_receiving.number
                  spg_date   = rcv_item.general_receiving.date.strftime("%d/%m/%Y")
                  part_name  = rcv_item.general.name
                elsif inv_item.consumable_receiving_item.present?
                  spg_number = rcv_item.consumable_receiving.number
                  spg_date   = rcv_item.consumable_receiving.date.strftime("%d/%m/%Y")
                  part_name  = rcv_item.consumable.name
                elsif inv_item.equipment_receiving_item.present?
                  spg_number = rcv_item.equipment_receiving.number
                  spg_date   = rcv_item.equipment_receiving.date.strftime("%d/%m/%Y")
                  part_name  = rcv_item.equipment.name
                end
                asterix = (rcv_item.purchase_order_supplier_item.unit_price != inv_item.unit_price ? "* " : "") # Beritanda asterix (*) jika harga invoice dgn PO berbeda
                
                if y < 95
                  borders = [:left, :right, :bottom]
                elsif y > 720
                  pdf.table([ [ 
                    {:content=>"No."}, {:content=>"No.Invoice"}, {:content=>"No.RCV"},
                    {:content=>"Tgl.RCV"}, {:content=>"No.PO"}, {:content=>"Part Name"}, {:content=>"Jumlah"},
                    {:content=>"Harga ("+my_currency.to_s+")"}, {:content=>"Total Harga ("+my_currency.to_s+")"}
                    ]], :column_widths => [20, 80, 80, 60, 90, 70, 45, 60, 70], :cell_style => {:align=>:center, :size=>8,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
              
                  borders = [:left, :right, :top]
                else
                  borders = [:left, :right]
                end

                if invoice_number == item.invoice_supplier.number
                  pdf.table([[
                    {:content=> (c.to_s if y > 720), :width=>20, :borders=> borders},
                    {:content=> (item.invoice_supplier.number.to_s if y > 720), :width=>80, :borders=> borders},                             
                    {:content=> spg_number.to_s, :width=>80},  
                    {:content=> spg_date, :width=>60},
                    {:content=>rcv_item.purchase_order_supplier_item.purchase_order_supplier.number.to_s, :width=>90},
                    {:content=> part_name.to_s, :width=>70} ,
                    {:content=> number_with_precision(inv_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45},
                    {:content=> asterix+number_with_precision(inv_item.unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>60},
                    {:content=> asterix+number_with_precision(inv_item.quantity * inv_item.unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>70}
                   ]])
                else
                  pdf.table([[
                    {:content=>c.to_s, :width=>20, :borders=> [:left, :right, :top]},
                    {:content=> item.invoice_supplier.number.to_s, :width=>80, :borders=> [:left, :right, :top]},
                    
                    {:content=> spg_number, :width=>80},  
                    {:content=> spg_date, :width=>60},
                    {:content=> rcv_item.purchase_order_supplier_item.purchase_order_supplier.number.to_s, :width=>90},
                    {:content=> part_name.to_s, :width=>70} ,
                    {:content=> number_with_precision(inv_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45},
                    {:content=> asterix+number_with_precision(inv_item.unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>60},
                    {:content=> asterix+number_with_precision(inv_item.quantity * inv_item.unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>70}
                   ]])
                end

                y = pdf.y
                if y < 95
                  pdf.start_new_page 
                  pdf.move_down 90 
                  pdf.stroke_horizontal_rule
                end
                invoice_number = item.invoice_supplier.number
                sub_total   += inv_item.unit_price * rcv_item.quantity
                grand_total += inv_item.unit_price * rcv_item.quantity
              end if records.present?              

              if rcv_counter == invoice_item_count
                pdf.table([
                  [
                    {:content=>"Subtotal", :borders=> [:left, :right], :align=>:right},
                    {:content=> number_with_precision(sub_total, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right}]
                  ], :column_widths=> [505, 70])                            
              end
              rcv_counter +=1
            end
            c +=1
          end
          pdf.table([[
              {:content=>"Grand Total ("+my_currency.to_s+")", :align=>:right},
              {:content=>number_with_precision(grand_total, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
              ]], :column_widths=> [505, 70], :cell_style => {:size=>8})
         
          pdf.move_down 10
          pdf.font_size 9

          pdf.page_count.times do |i|
            pdf.go_to_page i+1
            pdf.table([
              [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
              [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
              :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true) 

            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
              pdf.move_down 50                    
              pdf.draw_text ("Attachment Voucher Payment Request By Invoice"), :at => [150,5], :size => 15, :style=> :bold                      
              pdf.table([
                ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..14], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method.present?)]
              ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
              pdf.table([
                ["Tgl. Pengajuan",":", header.created_at.strftime("%Y-%m-%d"),"","Uang sejumlah",":", my_currency+" "+number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                ["Tgl. Realisasi",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
              ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
            }
        
          end
        when 'vpr_po'
          # OK
          pdf.move_down 90
          
          pdf.font_size 7
          c = 1

          # menampilkan semua GRN dalam PO yg sama
          # yg warna kuning adalah GRN yg dalam invoice ini
          invoice_items = nil
          invoice_items = InvoiceSupplierItem.where(:status=> 'active')
            .includes([
              :invoice_supplier,
              material_receiving_item: [
                :material, material_receiving: [:invoice_supplier], 
                purchase_order_supplier_item: [:purchase_order_supplier]
              ]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })
            .where(:invoice_suppliers => {:company_profile_id=> current_user.company_profile_id, :status => 'approved3' })
          puts invoice_items.count()
          puts "-----------------------"
          invoice_items += InvoiceSupplierItem.where(:status=> 'active')
            .includes([
              :invoice_supplier,
              product_receiving_item: [
                :product, product_receiving: [:invoice_supplier], 
                purchase_order_supplier_item: [:purchase_order_supplier]
              ]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })
            .where(:invoice_suppliers => {:company_profile_id=> current_user.company_profile_id, :status => 'approved3' })

          puts invoice_items.count()
          puts "-----------------------"
          invoice_items += InvoiceSupplierItem.where(:status=> 'active')
            .includes([
              :invoice_supplier,
              general_receiving_item: [
                :general, general_receiving: [:invoice_supplier], 
                purchase_order_supplier_item: [:purchase_order_supplier]
              ]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })
            .where(:invoice_suppliers => {:company_profile_id=> current_user.company_profile_id, :status => 'approved3' })


          puts invoice_items.count()
          puts "-----------------------"
          invoice_items += InvoiceSupplierItem.where(:status=> 'active')
            .includes([
              :invoice_supplier,
              consumable_receiving_item: [
                :consumable, consumable_receiving: [:invoice_supplier], 
                purchase_order_supplier_item: [:purchase_order_supplier]
              ]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })
            .where(:invoice_suppliers => {:company_profile_id=> current_user.company_profile_id, :status => 'approved3' })


          puts invoice_items.count()
          puts "-----------------------"
          invoice_items += InvoiceSupplierItem.where(:status=> 'active')
            .includes([
              :invoice_supplier,
              equipment_receiving_item: [
                :equipment, equipment_receiving: [:invoice_supplier], 
                purchase_order_supplier_item: [:purchase_order_supplier]
              ]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })
            .where(:invoice_suppliers => {:company_profile_id=> current_user.company_profile_id, :status => 'approved3' })


          puts invoice_items.count()
          puts "-----------------------"
          grand_total = 0
          PurchaseOrderSupplier.where(:id=> po_selected).order("number asc").each do |po|
            puts "PO number: #{po.number}"
            subtotal_po = 0
            po_number = nil
            invoice_items.each do |inv_item|
              if inv_item.purchase_order_supplier_id == po.id
                puts "inv_item: #{inv_item.id}"
                spg_item = inv_number = spg_number = spg_date = part_name = unit_price = nil
                if inv_item.material_receiving_item.present?
                  spg_item = inv_item.material_receiving_item
                  inv_number = spg_item.material_receiving.invoice_supplier.number
                  spg_number = spg_item.material_receiving.number
                  spg_date   = spg_item.material_receiving.date.strftime("%d/%m/%Y")
                  part_name  = spg_item.material.name
                elsif inv_item.product_receiving_item.present?
                  spg_item = inv_item.product_receiving_item
                  inv_number = spg_item.product_receiving.invoice_supplier.number
                  spg_number = spg_item.product_receiving.number
                  spg_date   = spg_item.product_receiving.date.strftime("%d/%m/%Y")
                  part_name  = spg_item.product.name
                elsif inv_item.general_receiving_item.present?
                  spg_item = inv_item.general_receiving_item
                  inv_number = spg_item.general_receiving.invoice_supplier.number
                  spg_number = spg_item.general_receiving.number
                  spg_date   = spg_item.general_receiving.date.strftime("%d/%m/%Y")
                  part_name  = spg_item.general.name
                elsif inv_item.consumable_receiving_item.present?
                  spg_item = inv_item.consumable_receiving_item
                  inv_number = spg_item.consumable_receiving.invoice_supplier.number
                  spg_number = spg_item.consumable_receiving.number
                  spg_date   = spg_item.consumable_receiving.date.strftime("%d/%m/%Y")
                  part_name  = spg_item.consumable.name
                elsif inv_item.equipment_receiving_item.present?
                  spg_item = inv_item.equipment_receiving_item
                  inv_number = spg_item.equipment_receiving.invoice_supplier.number
                  spg_number = spg_item.equipment_receiving.number
                  spg_date   = spg_item.equipment_receiving.date.strftime("%d/%m/%Y")
                  part_name  = spg_item.equipment.name
                end
                unit_price = spg_item.purchase_order_supplier_item.unit_price
                
                y = pdf.y
                if y < 80
                  pdf.start_new_page 
                  pdf.move_down 90 
                end
                asterix = (unit_price != inv_item.unit_price ? "* " : "") # Beritanda asterix (*) jika harga invoice dgn PO berbeda
                if y < 80
                  borders = [:left, :right, :bottom]
                elsif y > 720
                  pdf.table([[  {:content=>"No."}, {:content=>"No.PO"}, {:content=>"No.Invoice"},
                      {:content=>"No.RCV"}, {:content=>"Tgl.RCV"}, {:content=>"Part Name"},
                      {:content=>"Jumlah"}, {:content=>"Harga ("+my_currency.to_s+")"}, {:content=>"Total Harga ("+my_currency.to_s+")"}
                    ] ], :column_widths => [20, 80, 80, 80, 60, 80, 45, 60, 70], :cell_style => {:align=>:center, :size=>8,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
                  borders = [:left, :right, :top]
                else
                  borders = [:left, :right]
                end
                if po_number == po.number
                  pdf.table([[
                    {:content=> (c.to_s if y > 720), :width=>20, :borders=> borders},
                    {:content=> (po.number.to_s if y > 720), :width=> 80, :borders=> borders},
                    {:content=> inv_number.to_s, :width=> 80},
                    {:content=> spg_number.to_s, :width=> 80},
                    {:content=> spg_date, :width=> 60},
                    {:content=> part_name.to_s, :width=>80} ,
                    {:content=> number_with_precision(spg_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45},
                    {:content=> asterix+number_with_precision(unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>60},
                    {:content=> asterix+number_with_precision(spg_item.quantity * unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>70}
                  ]] )
                else
                  pdf.table([[
                    {:content=> c.to_s, :width=>20, :borders=> [:left, :right, :top]},
                    {:content=> po.number.to_s, :width=> 80, :borders=> [:left, :right, :top]},
                    {:content=> inv_number.to_s, :width=> 80},
                    {:content=> spg_number.to_s, :width=> 80},
                    {:content=> spg_date, :width=> 60},
                    {:content=> part_name.to_s, :width=>80} ,
                    {:content=> number_with_precision(spg_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45},
                    {:content=> asterix+number_with_precision(unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>60},
                    {:content=> asterix+number_with_precision(spg_item.quantity * unit_price , precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=> :right, :width=>70}
                  ]] )
                end
                # pdf.text "spg: #{spg_item.purch_po_item.price}; inv: #{inv_item.price}" if spg_item.purch_po_item.price != inv_item.price
                
                po_number = po.number
                subtotal_po += (unit_price * spg_item.quantity)
              else
                puts "-----------------"
              end
            end
            grand_total += subtotal_po.to_f
            pdf.table([[
              {:content=>"", :borders=>[:left, :bottom]},
              {:content=>"", :borders=>[:left, :bottom]},
              {:content=>"Subtotal Total ("+my_currency.to_s+")", :align=>:right, :borders=>[:bottom, :right]},
              {:content=>number_with_precision(subtotal_po, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
              ]], :column_widths=> [20, 80, 405, 70], :cell_style => {:size=>8})
            c+=1
          end

          # puts "#{grand_total} & #{header.sub_total}"
          # grand_total = (grand_total == header.sub_total ? header.sub_total : "error")
          pdf.table([[
              {:content=>"Grand Total ("+my_currency.to_s+")", :align=>:right},
              {:content=>number_with_precision(grand_total, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
              ]], :column_widths=> [505, 70], :cell_style => {:size=>8})

          if grand_total != header.subtotal
            pdf.move_down 5
            pdf.table([[
                {:content=>"Note: Jika Harga barang pada Invoice berbeda dengan harga pada PO maka diberi simbol asterik (*)"}
                ]], :column_widths=> [575], :cell_style => {:size=>8, :border_color => "ffffff", :padding=>1})
          end

          pdf.move_down 10
          pdf.font_size 9

          pdf.page_count.times do |i|
            pdf.go_to_page i+1
            pdf.table([
              [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
              [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
              :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true) 

            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
              pdf.move_down 50                    
              pdf.draw_text ("Attachment Voucher Payment Request By PO"), :at => [150,5], :size => 14, :style=> :bold                     
              pdf.table([
                ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s[0..15], "", "Cara Pembayaran", ":", (header.supplier_payment_method.name.to_s if header.supplier_payment_method.present?)]
              ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 
              pdf.table([
                ["Tgl. Pengajuan",":", header.created_at.strftime("%Y-%m-%d").to_s,"","Uang sejumlah",":", my_currency+" "+number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ",").to_s, "", "No.Giro/ Cek", ":", header.payment_methode_number.to_s],
                ["Tgl. Realisasi",":", header.date.to_s,"","","", "", "", "Bank", ":", (header.bank_transfer.name if header.bank_transfer.present?)]
              ], :column_widths=> [80,10, 90,30,80,10, 90, 10, 80,10,80], :cell_style => {:size=> 8, :border_color => "ffffff", :padding => 1, :borders=>[:left, :right]}, :header => true) 
            }
        
          end
        when 'vpr_rcv'
          pdf.move_down 70
          
          grand_total = 0
          pdf.font_size 7

          c = 1

          # menampilkan semua GRN dalam PO yg sama
          # yg warna kuning adalah GRN yg dalam invoice ini
          grn_items = prn_items = nil
          grn_items = MaterialReceivingItem.where(:status=> 'active')
            .includes([
              :material,
              material_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })
          
          prn_items = ProductReceivingItem.where(:status=> 'active')
            .includes([
              :product,
              product_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })

          gen_items = GeneralReceivingItem.where(:status=> 'active')
            .includes([
              :general,
              general_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })

          con_items = ConsumableReceivingItem.where(:status=> 'active')
            .includes([
              :consumable,
              consumable_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })

          equ_items = EquipmentReceivingItem.where(:status=> 'active')
            .includes([
              :equipment,
              equipment_receiving: [:invoice_supplier], 
              purchase_order_supplier_item: [:purchase_order_supplier]
            ] )
            .where(:purchase_order_suppliers => {:id => po_selected })

          records = (grn_items+prn_items+gen_items+con_items+equ_items)
          po_number = nil

          records.each do |spg_item|
            # logger.info spg_item
            spg_number = spg_date = part_name = nil
            if spg_item.attributes.has_key? 'material_receiving_id' and spg_item.material_receiving.present?
              items.where(:status=> 'active', :invoice_supplier_id => spg_item.material_receiving.invoice_supplier_id).present? ? bg_color = 'ffff00' : bg_color = 'ffffff'
              spg_number = spg_item.material_receiving.number
              spg_date   = spg_item.material_receiving.date.strftime("%d/%m/%Y")
              part_name  = spg_item.material.name
            elsif spg_item.attributes.has_key? 'product_receiving_id' and spg_item.product_receiving.present?
              items.where(:status=> 'active', :invoice_supplier_id => spg_item.product_receiving.invoice_supplier_id).present? ? bg_color = 'ffff00' : bg_color = 'ffffff'
              spg_number = spg_item.product_receiving.number
              spg_date   = spg_item.product_receiving.date.strftime("%d/%m/%Y")
              part_name  = spg_item.product.name
            elsif spg_item.attributes.has_key? 'general_receiving_id' and spg_item.general_receiving.present?
              items.where(:status=> 'active', :invoice_supplier_id => spg_item.general_receiving.invoice_supplier_id).present? ? bg_color = 'ffff00' : bg_color = 'ffffff'
              spg_number = spg_item.general_receiving.number
              spg_date   = spg_item.general_receiving.date.strftime("%d/%m/%Y")
              part_name  = spg_item.general.name
            elsif spg_item.attributes.has_key? 'consumable_receiving_id' and spg_item.consumable_receiving.present?
              items.where(:status=> 'active', :invoice_supplier_id => spg_item.consumable_receiving.invoice_supplier_id).present? ? bg_color = 'ffff00' : bg_color = 'ffffff'
              spg_number = spg_item.consumable_receiving.number
              spg_date   = spg_item.consumable_receiving.date.strftime("%d/%m/%Y")
              part_name  = spg_item.consumable.name
            elsif spg_item.attributes.has_key? 'equipment_receiving_id' and spg_item.equipment_receiving.present?
              items.where(:status=> 'active', :invoice_supplier_id => spg_item.equipment_receiving.invoice_supplier_id).present? ? bg_color = 'ffff00' : bg_color = 'ffffff'
              spg_number = spg_item.equipment_receiving.number
              spg_date   = spg_item.equipment_receiving.date.strftime("%d/%m/%Y")
              part_name  = spg_item.equipment.name
            end
            # if spg_number.blank?
            #   logger.info "------------------------------- spg blank!"
            # end
            y = pdf.y
            if y < 80
              borders = [:left, :right, :bottom]
            elsif y > 720
              pdf.table([[  
                {:content=>"No."}, {:content=>"No.PO"}, {:content=>"No.RCV"}, {:content=>"Tgl.RCV"},
                {:content=>"Part Name"}, {:content=>"Qty PO"}, {:content=>"Qty Rcv"}, {:content=>"Sisa PO"}
              ]], :column_widths => [20, 80, 80, 60, 195, 45, 45, 45], :cell_style => {:align=>:center, :size=>8,:padding => 2, :border_color=>"000000", :borders=>[:left, :right, :top]})
              borders = [:left, :right, :top]
            else
              borders = [:left, :right]
            end
            if po_number == spg_item.purchase_order_supplier_item.purchase_order_supplier.number
              pdf.table([[
                {:content=> (c.to_s if y > 720), :width=>20, :borders=> borders},
                {:content=> (spg_item.purchase_order_supplier_item.purchase_order_supplier.number.to_s if y > 720), :width=> 80, :borders=> borders},
                {:content=> spg_number.to_s, :width=> 80, :background_color => bg_color},
                {:content=> spg_date.to_s, :width=> 60, :background_color => bg_color},
                {:content=> part_name.to_s, :width=>195, :background_color => bg_color} ,
                {:content=> number_with_precision(spg_item.purchase_order_supplier_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45, :background_color => bg_color},
                {:content=> number_with_precision(spg_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45, :background_color => bg_color},
                {:content=> number_with_precision(spg_item.purchase_order_supplier_item.outstanding , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45, :background_color => bg_color}
              ]])
            else
              pdf.table([[
                {:content=> c.to_s, :width=>20, :borders=> [:left, :right, :top]},
                {:content=> spg_item.purchase_order_supplier_item.purchase_order_supplier.number.to_s, :width=> 80, :borders=> [:left, :right, :top]},
                {:content=> spg_number.to_s, :width=> 80, :background_color => bg_color},
                {:content=> spg_date.to_s, :width=> 60, :background_color => bg_color},
                {:content=> part_name.to_s, :width=>195, :background_color => bg_color} ,
                {:content=> number_with_precision(spg_item.purchase_order_supplier_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45, :background_color => bg_color},
                {:content=> number_with_precision(spg_item.quantity , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45, :background_color => bg_color},
                {:content=> number_with_precision(spg_item.purchase_order_supplier_item.outstanding , precision: 0, delimiter: ".", separator: ",").to_s, :align=> :right,:width=>45, :background_color => bg_color}
              ]]) 
              c+=1
            end               
            if y < 80
              pdf.start_new_page 
              pdf.move_down 70 
            end
            po_number = spg_item.purchase_order_supplier_item.purchase_order_supplier.number
          
          end if records.present?

          pdf.move_down 10
          pdf.page_count.times do |i|
            pdf.go_to_page i+1
            pdf.table([
              [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
              [title,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
              :column_widths => [350, 130, 90], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)  
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
            
            pdf.move_down 50
            pdf.draw_text ("Lampiran Data Penerimaan Barang"), :at => [160,5], :size => 14, :style=> :bold
              
              pdf.table([
                ["No. Voucher",":", header.number.to_s,"","Dibayarkan Kepada",":",header.supplier.name.to_s]
              ], :column_widths=> [80,10, 90,30,80,10, 270], :cell_style => {:size=> 8, :border_color => "000000", :padding => 1, :borders=>[:top]}, :header => true) 

            }
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
    else
      respond_to do |format|
        format.html { redirect_to @payment_request_supplier, alert: 'Cannot be displayed, status must be Approve 2' }
        format.json { render :show, status: :ok, location: @payment_request_supplier }
      end
    end
  
  end


  def approve
    notice_msg = "Payment Request was successfully #{params[:status]}."
    notice_kind = "notice"
    case params[:status]
    when 'approve1'
      @payment_request_supplier.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @payment_request_supplier.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @payment_request_supplier.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @payment_request_supplier.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @payment_request_supplier.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      if @payment_request_supplier.payment_supplier.present? and @payment_request_supplier.payment_supplier.status == 'approved3'
        notice_msg = "Payment Request can't #{params[:status]}, #{@payment_request_supplier.payment_supplier.number} status approved3."
        notice_kind = "alert"
      else
        @payment_request_supplier.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
      end
    end

    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to payment_request_suppliers_url, alert: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to payment_request_supplier_path(:id=> @payment_request_supplier.id), notice_kind.to_sym => notice_msg  }
        format.json { head :no_content }
      end
    end
  end

  # DELETE /payment_request_suppliers/1
  # DELETE /payment_request_suppliers/1.json
  def destroy
    @payment_request_supplier.update_columns({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    
    PaymentRequestSupplierItem.where(:payment_request_supplier_id=> @payment_request_supplier.id, :status=> 'active').each do |payreq_item|
      payreq_item.update_columns(:status=> 'deleted')
      payreq_item.invoice_supplier.update_columns(:payment_request_supplier_id=> nil)
    end
    respond_to do |format|
      format.html { redirect_to payment_request_suppliers_url, notice: 'Payment Request Supplier was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment_request_supplier
      if params[:multi_id].present?
        @payment_request_supplier = PaymentRequestSupplier.where(:id=> params[:multi_id].split(','))
      else
        @payment_request_supplier = PaymentRequestSupplier.find(params[:id])
        @payment_request_supplier_items = PaymentRequestSupplierItem.where(:payment_request_supplier_id=> params[:id], :status=> 'active').includes(:invoice_supplier)
      end
      
      if @payment_request_supplier.present?
        # nothing
      else
        respond_to do |format|
          format.html { redirect_to payment_request_suppliers_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @supplier_payment_methods = SupplierPaymentMethod.where(:status=> 'active')
      @bank_transfers = BankTransfer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @invoice_suppliers = InvoiceSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')

      @material_batch_number = MaterialBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
      @tax_rates = TaxRate.where(:status=> "active").where("end_date >= ?", DateTime.now().strftime("%Y-%m-%d")).order("end_date desc")
      @taxes = Tax.where(:status=> 'active')
      @term_of_payments = TermOfPayment.all
      @currencies = Currency.all
    end

    def check_status      
      noitce_msg = nil 

      if @payment_request_supplier.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          noitce_msg = 'Cannot be edited because it has been approved'
        end
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @payment_request_supplier.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @payment_request_supplier, alert: noitce_msg }
          format.json { render :show, status: :created, location: @payment_request_supplier }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def payment_request_supplier_params
      params.require(:payment_request_supplier).permit(:company_profile_id, :status, :number, :supplier_id, :currency_id, :date, :supplier_payment_method_id, :bank_transfer_id, :payment_methode_number, :subtotal, :ppntotal, :pphtotal, :dptotal, :remarks, :grandtotal, :created_by, :created_at, :updated_by, :updated_at)
    end
end
