module InvoiceToolsHelper
    def update_invoice_customer_header(invoice_customer_id)
    invoice_customer = InvoiceCustomer.find_by(:id=> invoice_customer_id) 
    if invoice_customer.present?

      top_day             = invoice_customer.customer.top_day.to_i
      term_of_payment_id  = invoice_customer.customer.term_of_payment_id
      sum_total_price = 0
      sum_ppntotal    = 0
  

      InvoiceCustomerItem.where(:invoice_customer_id=> invoice_customer.id,:status=>"active").each do |invoice_item|
        so_item     = invoice_item.sales_order_item
        unit_price  = (invoice_item.sales_order_item.present? ? invoice_item.sales_order_item.unit_price : 0)
        total_price = (unit_price.to_f*invoice_item.quantity.to_f)
        sum_total_price += total_price.to_f

        if so_item.sales_order.present? 
          top_day = so_item.sales_order.top_day.to_i
          term_of_payment_id = so_item.sales_order.term_of_payment_id

          # jenis pajak berdasarkan SO
          if so_item.sales_order.tax.present?
            tax_name = so_item.sales_order.tax.name 

            if so_item.sales_order.tax.value.present?
              sum_ppntotal += (total_price.to_f * so_item.sales_order.tax.value )
            end
          end
        end
      end

      sum_discount    = 0
      sales_order_item_id = InvoiceCustomerItem.where(:invoice_customer_id=> invoice_customer.id, :status=> 'active' ).group(:sales_order_item_id).select(:sales_order_item_id)
      SalesOrderItem.where(:id=> sales_order_item_id, :status=> 'active').each do |so_item|
        sum_qty_by_so_item = InvoiceCustomerItem.where(:invoice_customer_id=> invoice_customer.id, :status=> 'active', :sales_order_item_id=> so_item.id).sum(:quantity)
        puts "sum_qty_by_so_item: #{sum_qty_by_so_item.to_f}"
        puts "so_item.unit_price: #{so_item.unit_price}"
        puts "(so_item.discount.to_f/100) => #{(so_item.discount.to_f/100)}"
        sum_discount += (sum_qty_by_so_item.to_f * so_item.unit_price)*(so_item.discount.to_f/100)
      end

      puts "sum_ppntotal: #{sum_ppntotal}"
      invoice_customer.update({
        :subtotal=> sum_total_price,
        :ppntotal=> sum_ppntotal,
        :discount=> sum_discount,
        :grandtotal=> (sum_total_price-sum_discount)+sum_ppntotal,
        :top_day=> top_day, :term_of_payment_id=> term_of_payment_id,
      })
    end
  end
end
