class InvoiceToolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index]
  before_action :require_permission_edit, only: [:edit]
  before_action :require_permission_create, only: [:create]
  include InvoiceToolsHelper

  # GET /invoice_tools
  # GET /invoice_tools.json
  def index    
    @invoice_tool = InvoiceTool.new
    @invoice_customers = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id).where.not(:status=>"deleted").order("date desc")

    case params[:invoice_tools_kind]
    when "do_move_invoice"
      session[:date_begin] = (params[:start_date].present? ? params[:start_date] : session[:date_begin] )
      session[:date_end] = (params[:end_date].present? ? params[:end_date] : session[:date_end] )

      @delivery_orders = DeliveryOrder.where(:company_profile_id=> current_user.company_profile_id, :customer_id=> params[:customer_id])
      .where("date between ? and ?", session[:date_begin], session[:date_end])
      .includes([:invoice_customer, :customer])
      .order("date desc")
    when "new_invoice"
      if params[:check].present?
        @check_invoice = @invoice_customers.where(:number=>params[:number])

      end
    end    
  end


  def new
    @invoice_tool = InvoiceTool.new
  end

  def create
    type = "success"
    msg = "success #{params[:kind]}"
    # begin
    case params[:kind]
      when "move_invoce_detail"
        invoice = InvoiceCustomer.find_by(:id=>params[:new_invoice_customer_id], :payment_customer_id=>nil)
        if invoice.present?

          DeliveryOrder.where(:invoice_customer_id=> params[:old_invoice_customer_id]).update_all(:invoice_customer_id=> params[:new_invoice_customer_id])
          InvoiceCustomerItem.where(:invoice_customer_id=> params[:old_invoice_customer_id]).update_all(:invoice_customer_id=> params[:new_invoice_customer_id])
          # old_invoice =InvoiceCustomer.find(params[:old_invoice_customer_id])
          # old_invoice.update_columns(:status=>'deleted',
          #   :subtotal=> 0, :discount=> 0, :ppntotal=> 0, :grandtotal=> 0,
          #   :remarks=>"Pindah Item Invoice, #{old_invoice.number} => #{invoice.number}",
          #   :approved1_at=>nil,:approved1_by=>nil,:canceled1_at=>nil,:canceled1_by=>nil,
          #   :approved2_at=>nil,:approved2_by=>nil,:canceled2_at=>nil,:canceled2_by=>nil,
          #   :approved3_at=>nil,:approved3_by=>nil,:canceled3_at=>nil,:canceled3_by=>nil,
          #   :updated_at=> DateTime.now(), :updated_by=> current_user.id, :deleted_by=> current_user.id, :deleted_at=> DateTime.now()               
          # )
          update_invoice_customer_header(params[:old_invoice_customer_id])
          update_invoice_customer_header(params[:new_invoice_customer_id])
        end
      when "change_invoice_number"
        invoice = InvoiceCustomer.find(params[:old_invoice_customer_id])
        if invoice.present?
          invoice.update({
            :number=> params[:new_invoice_customer_number],
            :date=>params[:new_invoice_customer_date], 
            :updated_by=> current_user.id,
            :updated_at=> DateTime.now()
          })
        end
      when "do_move_invoice"
        params[:delivery_orders].each do |key, val|
          delivery_order = DeliveryOrder.find(key['id'])
          if delivery_order.present?
            if delivery_order.invoice_customer.present?
              cus_inv_old = InvoiceCustomer.find(delivery_order.invoice_customer_id)
              if cus_inv_old.present? 
                if cus_inv_old.status == 'approved3'
                  type = "error"
                  msg = "Invoice Lama sudah APP3";                
                else
                  delivery_order.update({:invoice_customer_id=> params[:invoice_customer_id]}) 
                  DeliveryOrderItem.where(:delivery_order_id=> key['id'], :status=> 'active').each do | do_item |
                    old_invoice_items = InvoiceCustomerItem.where(:invoice_customer_id=> cus_inv_old.id, :delivery_order_item_id=> do_item.id, :status=> 'active')
                    if old_invoice_items.present?
                      old_invoice_items.update_all({:status=> 'deleted', :updated_by=> current_user.id, :updated_at=> DateTime.now(), :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
                    end
                    new_invoice_item = InvoiceCustomerItem.where(:invoice_customer_id=> params[:invoice_customer_id], :delivery_order_item_id=> do_item.id, :status=> 'active')
                    if new_invoice_item.present?
                      unit_price = (do_item.sales_order_item.present? ? do_item.sales_order_item.unit_price : 0)
                      total_price = (do_item.sales_order_item.unit_price.to_f*do_item.quantity.to_f)
                      new_invoice_item.update({
                        :invoice_customer_id=> params[:invoice_customer_id],
                        :delivery_order_item_id=> do_item.id,
                        :sales_order_item_id=> do_item.sales_order_item_id,
                        :product_batch_number_id=> do_item.product_batch_number_id,
                        :product_id=> do_item.product_id,
                        :quantity=> do_item.quantity,
                        :unit_price=> unit_price,
                        :total_price=> total_price,
                        :status=> 'active',
                        :created_at=> DateTime.now(), :created_by=> current_user.id,
                        :updated_at=> DateTime.now(), :updated_by=> current_user.id
                      })
                    else
                      unit_price = (do_item.sales_order_item.present? ? do_item.sales_order_item.unit_price : 0)
                      total_price = (do_item.sales_order_item.unit_price.to_f*do_item.quantity.to_f)
                      InvoiceCustomerItem.create({
                        :invoice_customer_id=> params[:invoice_customer_id],
                        :delivery_order_item_id=> do_item.id,
                        :sales_order_item_id=> do_item.sales_order_item_id,
                        :product_batch_number_id=> do_item.product_batch_number_id,
                        :product_id=> do_item.product_id,
                        :quantity=> do_item.quantity,
                        :unit_price=> unit_price,
                        :total_price=> total_price,
                        :status=> 'active',
                        :created_at=> DateTime.now(), :created_by=> current_user.id,
                        :updated_at=> DateTime.now(), :updated_by=> current_user.id
                      })
                    end
                  end

                  
                  update_invoice_customer_header(cus_inv_old.id)
                  update_invoice_customer_header(params[:invoice_customer_id])
                end
              end
            end
          end
        end
      when "new_invoice"
        invoice = InvoiceCustomer.find_by(:number=>params[:new_invoice_customer_number])
        customer = Customer.find(params[:customer_id])
        if invoice.blank? 
          x = InvoiceCustomer.create({
            :company_profile_id=> current_user.company_profile_id,
            :customer_id=>params[:customer_id],
            :number=>params[:new_invoice_customer_number],
            :date=>params[:new_invoice_customer_date],
            :currency_id=>customer.currency_id,
            :term_of_payment_id=>customer.term_of_payment_id,
            :tax_id=>customer.tax_id,
            :top_day=>customer.top_day,
            :created_by=> current_user.id,
            :created_at=> DateTime.now(),
            :updated_by=> current_user.id,
            :updated_at=> DateTime.now()
          })

          logger.info x.errors
        end
      end if params[:kind].present?
    # rescue => e
    #   type = "error"
    #   msg = e
    # end

    respond_to do |format|
      format.html { redirect_to "/invoice_tools?type=#{type}&msg=#{msg}"}
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.

    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invoice_tool_params
      params.require(:invoice_tool).permit(:customer_id, :company_payment_receiving_id, :company_profile_id, :number, :efaktur_number, :due_date, :date, :subtotal, :discount, :ppntotal, :grandtotal, :remarks, :received_at, :received_name, :created_at, :created_by, :updated_at, :updated_by)
    end
end
