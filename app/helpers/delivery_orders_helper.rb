module DeliveryOrdersHelper
	include ApplicationHelper
	def generate_invoice_customer(delivery_order_id)
		delivery_order = DeliveryOrder.find_by(:id=> delivery_order_id)
		if delivery_order.present?
			sales_order = delivery_order.sales_order
			delivery_order_item = DeliveryOrderItem.where(:delivery_order_id=> delivery_order.id, :status=> 'active')
	    customer = Customer.find_by(:id=> delivery_order.customer_id)
	    if customer.present?
	    	top_day = customer.top_day.to_i
	    	term_of_payment_id = customer.term_of_payment_id
	    	tax_id = (sales_order.present? ? sales_order.tax_id : customer.tax_id)

	    	# case current_user.id.to_i
	    	# when 1
	    		# 20210922: aden
		    	# invoice_numbering_period = ['daily','3 day','weekly','2 week','monthly','delivery','po']
		    	case customer.invoice_numbering_period
		    	when 'daily'
		    		# invoice dibuat tiap hari beda
		    		inv_cus = InvoiceCustomer.find_by(
		    			:company_profile_id=> current_user.company_profile_id,
				      :customer_id=> customer.id,
				      :status=> ['new','approved1','canceled1','approved2','canceled2','canceled3'],
				      :date=> delivery_order.date.to_date
				      )
		    		if inv_cus.blank?
					    inv_cus = InvoiceCustomer.create({
					      :company_profile_id=> current_user.company_profile_id,
					      :currency_id=> customer.currency_id,
					      :customer_id=> customer.id, :tax_id=> tax_id,
					      :number=> document_number("invoice_customers", delivery_order.date.to_date, nil, nil, nil),
					      :date=> delivery_order.date.to_date,
					      :due_date=> delivery_order.date.to_date+top_day.days,
					      :top_day=> top_day, :term_of_payment_id=> term_of_payment_id,
					      :status=> 'new', 
					      :created_by=> current_user.id, :created_at=> DateTime.now()
					    })
		    		end
		    	when '3 day', 'weekly', '2 week', 'monthly'
			    	case customer.invoice_numbering_period
			    	when '3 day'
			    		date_begin = "#{delivery_order.date.to_date-3.days}".to_date.strftime("%Y-%m-%d")
			    		date_end   = delivery_order.date.to_date.strftime("%Y-%m-%d")
			    		puts "invoice dibuat tiap 3 hari beda (#{date_begin} .. #{date_end})"
			    	when 'weekly'
			    		date_begin = delivery_order.date.to_date.at_beginning_of_week.strftime("%Y-%m-%d")
			    		date_end = delivery_order.date.to_date.at_end_of_week.strftime("%Y-%m-%d")
		    			puts "invoice dibuat tiap minggu beda (#{date_begin} .. #{date_end})"
			    	when '2 week'
			    		prev_week  = delivery_order.date.to_date.at_beginning_of_week-1.days
			    		date_begin = prev_week.to_date.at_beginning_of_week.strftime("%Y-%m-%d")
			    		date_end = delivery_order.date.to_date.at_end_of_week.strftime("%Y-%m-%d")
		    			puts "invoice dibuat tiap 2 minggu beda (#{date_begin} .. #{date_end})"
		    		when 'monthly'
			    		date_begin = delivery_order.date.to_date.at_beginning_of_month.strftime("%Y-%m-%d")
			    		date_end = delivery_order.date.to_date.at_end_of_month.strftime("%Y-%m-%d")
		    			puts "invoice dibuat tiap bulan beda (#{date_begin} .. #{date_end})"
			    	end

		    		invoice_customers = InvoiceCustomer.where(
		    			:company_profile_id=> current_user.company_profile_id,
				      :customer_id=> customer.id,
				      :status=> ['new','approved1','canceled1','approved2','canceled2','canceled3'],
				      :date=> date_begin..date_end
				      ).order("date desc")
		    		inv_cus = nil
		    		if invoice_customers.present?
		    			inv_cus = invoice_customers.first
		    		end
		    		if inv_cus.blank?
					    inv_cus = InvoiceCustomer.create({
					      :company_profile_id=> current_user.company_profile_id,
					      :currency_id=> customer.currency_id,
					      :customer_id=> customer.id, :tax_id=> tax_id,
					      :number=> document_number("invoice_customers", delivery_order.date.to_date, nil, nil, nil),
					      :date=> delivery_order.date.to_date,
					      :due_date=> delivery_order.date.to_date+top_day.days,
					      :top_day=> top_day, :term_of_payment_id=> term_of_payment_id,
					      :status=> 'new', 
					      :created_by=> current_user.id, :created_at=> DateTime.now()
					    })
		    		end
		    	when 'po'
		    		puts "invoice dibuat tiap PO beda"
		    		invoice_customer_items = InvoiceCustomerItem.where(:status=> 'active')
		    		.includes(:invoice_customer, sales_order_item: [:sales_order])
		    		.where(:invoice_customers => {:company_profile_id=> current_user.company_profile_id, :customer_id=> customer.id, :status=> ['new','approved1','canceled1','approved2','canceled2','canceled3']})
		    		.where(:sales_order_items => {:sales_order_id=> delivery_order.sales_order_id, :status=> 'active'})
		    		.order("invoice_customer_items.invoice_customer_id desc")

		    		inv_cus = nil
		    		if invoice_customer_items.present?
		    			inv_cus = InvoiceCustomer.find_by(:id=> invoice_customer_items.first.invoice_customer_id)
		    		end

		    		if inv_cus.blank?
					    inv_cus = InvoiceCustomer.create({
					      :company_profile_id=> current_user.company_profile_id,
					      :currency_id=> customer.currency_id,
					      :customer_id=> customer.id, :tax_id=> tax_id,
					      :number=> document_number("invoice_customers", delivery_order.date.to_date, nil, nil, nil),
					      :date=> delivery_order.date.to_date,
					      :due_date=> delivery_order.date.to_date+top_day.days,
					      :top_day=> top_day, :term_of_payment_id=> term_of_payment_id,
					      :status=> 'new', 
					      :created_by=> current_user.id, :created_at=> DateTime.now()
					    })
		    		end
		    	else
		    		# invoice dibuat tiap pengiriman beda
				    inv_cus = InvoiceCustomer.create({
				      :company_profile_id=> current_user.company_profile_id,
				      :currency_id=> customer.currency_id,
				      :customer_id=> customer.id, :tax_id=> tax_id,
				      :number=> document_number("invoice_customers", delivery_order.date.to_date, nil, nil, nil),
				      :date=> delivery_order.date.to_date,
				      :due_date=> delivery_order.date.to_date+top_day.days,
				      :top_day=> top_day, :term_of_payment_id=> term_of_payment_id,
				      :status=> 'new', 
				      :created_by=> current_user.id, :created_at=> DateTime.now()
				    })
		    	end
		   #  else
			  #   inv_cus = InvoiceCustomer.create({
			  #     :company_profile_id=> current_user.company_profile_id,
			  #     :currency_id=> customer.currency_id,
			  #     :customer_id=> customer.id,
			  #     :number=> document_number("invoice_customers", delivery_order.date.to_date, nil, nil, nil),
			  #     :date=> delivery_order.date.to_date,
			  #     :due_date=> delivery_order.date.to_date+top_day.days,
			  #     :top_day=> top_day, :term_of_payment_id=> term_of_payment_id,
			  #     :status=> 'new', 
			  #     :created_by=> current_user.id, :created_at=> DateTime.now()
			  #   })
			  # end

		    delivery_order_item.each do |item|
		    	if item.sales_order_item.present?
						unit_price = (item.sales_order_item.present? ? item.sales_order_item.unit_price : 0)
			      total_price = (item.sales_order_item.unit_price.to_f*item.quantity.to_f)
			      
			      inv_cus_item = InvoiceCustomerItem.create({
			        :invoice_customer_id=> inv_cus.id,
			        :delivery_order_item_id=> item.id,
			        :sales_order_item_id=> item.sales_order_item_id,
			        :product_batch_number_id=> item.product_batch_number_id,
			        :product_id=> item.product_id,
			        :quantity=> item.quantity,
			        :unit_price=> unit_price,
			        :total_price=> total_price,
			        :status=> 'active',
			        :created_at=> DateTime.now(), :created_by=> current_user.id

			      })
			    else
			    	puts "[#{item.id}] sales_order_item_id: #{item.sales_order_item_id} not found"
			    end
		      # puts inv_cus_item.inspect
		    end if delivery_order_item.present?

		    delivery_order.update_columns(:invoice_customer_id=> inv_cus.id)
		    update_invoice_customer_header(delivery_order.id, inv_cus.id)

		  else
		  	puts "Customer: #{delivery_order.customer_id} not found!"
		  end
	  end
	end

	def update_invoice_customer(delivery_order_id)
		delivery_order = DeliveryOrder.find_by(:id=> delivery_order_id)
		if delivery_order.present?
			if delivery_order.invoice_customer.present? and delivery_order.invoice_customer.status != 'approved3'
				InvoiceCustomerItem.where(:invoice_customer_id=> delivery_order.invoice_customer_id, :status=> 'active').each do |invoice_item|
					invoice_item.update(:status=> 'deleted')
				end

				DeliveryOrderItem.where(:delivery_order_id=> delivery_order.id, :status=> 'active').each do |do_item|
		    	unit_price = (do_item.sales_order_item.present? ? do_item.sales_order_item.unit_price : 0)
					total_price = (unit_price.to_f*do_item.quantity.to_f)			   

					invoice_item = InvoiceCustomerItem.find_by(
						:invoice_customer_id=> delivery_order.invoice_customer_id, 
						:delivery_order_item_id=> do_item.id, 
						:sales_order_item_id=> do_item.sales_order_item_id,
						:product_batch_number_id=> do_item.product_batch_number_id, 
						:product_id=> do_item.product_id
						)
					if invoice_item.present?
						invoice_item.update({
							:status=> 'active',
							:quantity=> do_item.quantity,
			        :unit_price=> unit_price,
			        :total_price=> total_price
						})
					else
			    	invoice_item = InvoiceCustomerItem.new({
							:invoice_customer_id=> delivery_order.invoice_customer_id, 
							:delivery_order_item_id=> do_item.id, 
							:sales_order_item_id=> do_item.sales_order_item_id,
							:product_batch_number_id=> do_item.product_batch_number_id, 
							:product_id=> do_item.product_id,
							:quantity=> do_item.quantity,
			        :unit_price=> unit_price,
			        :total_price=> total_price,
			        :status=> 'active',
			        :created_at=> DateTime.now(), :created_by=> current_user.id
			      })
						invoice_item.save!
					end
				end

		    update_invoice_customer_header(delivery_order.id, delivery_order.invoice_customer_id)
			end
		end
	end

	def update_invoice_customer_header(delivery_order_id, invoice_customer_id)
		invoice_customer = InvoiceCustomer.find_by(:id=> invoice_customer_id) 
    if invoice_customer.present?

	    top_day 						= invoice_customer.customer.top_day.to_i
	    term_of_payment_id  = invoice_customer.customer.term_of_payment_id
	    sum_total_price = 0
			sum_ppntotal    = 0
			DeliveryOrderItem.where(:delivery_order_id=> delivery_order_id, :status=> 'active').each do |do_item|
	    	so_item     = do_item.sales_order_item
				unit_price 	= (do_item.sales_order_item.present? ? do_item.sales_order_item.unit_price : 0)
				total_price = (unit_price.to_f*do_item.quantity.to_f)
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
