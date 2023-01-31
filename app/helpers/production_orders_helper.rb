module ProductionOrdersHelper

	def load_bom(production_order_id)
		production_order = ProductionOrder.find_by(:id=> production_order_id)
		if production_order.present?
			ProductionOrderItem.where(:production_order_id=> production_order_id, :status=> 'active').each do |item|
				sales_order_id = (item.production_order.sales_order.present? ? item.production_order.sales_order_id : nil)
				sales_order_item_id = (item.sales_order_item.present? ? item.sales_order_item_id : nil)
				bom = BillOfMaterial.find_by(:product_id=> item.product_id, :status=> 'active')
				if bom.present?
					get_item_bom(production_order.company_profile_id, bom, production_order_id, item.id, sales_order_id, sales_order_item_id, item.product_id, item.quantity)
					
					# bom product WIP
					bom_wip(production_order.company_profile_id, bom.product_wip1, bom.product_wip1_prf, bom.product_wip1_quantity, item, sales_order_id, sales_order_item_id)
					bom_wip(production_order.company_profile_id, bom.product_wip2, bom.product_wip2_prf, bom.product_wip2_quantity, item, sales_order_id, sales_order_item_id)

				end
			end
		end
	end

	def get_item_bom(company_profile_id, bom, production_order_id, production_order_item_id, sales_order_id, sales_order_item_id, product_id, spp_quantity)	
		BillOfMaterialItem.where(:bill_of_material_id=> bom.id).each do |bom_item|
			puts "Status     : #{bom_item.status};"
			puts "Material   : #{bom_item.material.name};"
			puts "Std Qty    : #{bom_item.standard_quantity};"
			puts "Allowance  : #{bom_item.allowance};"
			puts "SPP Qty    : #{spp_quantity};"
			puts "Quantity   : #{bom_item.quantity};"
			puts "Total      : #{(spp_quantity.to_f * bom_item.quantity.to_f)};"
			case bom_item.status
			when 'active'
				record = ProductionOrderDetailMaterial.find_by(
					:company_profile_id=> company_profile_id,
					:production_order_id=> production_order_id,
					:production_order_item_id=> production_order_item_id, 
					:product_id=> product_id,
					:material_id=> bom_item.material_id)
				if record.present?
					# 20201126: aden
						quantity = (spp_quantity.to_f * bom_item.quantity.to_f)
		        prf_relation = ProductionOrderUsedPrf.find_by(:production_order_item_id=> record.production_order_item_id, :production_order_detail_material_id=> record.id, :status=> 'active')
		        if prf_relation.present?
		          prf_outstanding = 0
		          puts "PRF Found"
		        else
		          prf_outstanding = quantity
		        end

					# prf_relation =  ProductionOrderUsedPrf.find_by(:production_order_detail_material_id=> record.id, :status=> 'active')
					# if prf_relation.present?
					# 	prf_quantity = prf_relation.purchase_request_item.quantity.to_f
					# else
					# 	prf_quantity = 0
					# end
					# prf_quantity = ((spp_quantity.to_f * bom_item.quantity.to_f).to_f - record.prf_outstanding.to_f)

					# quantity = (spp_quantity.to_f * bom_item.quantity.to_f)
					# puts "PRF Qty: #{prf_quantity};"
					puts "Qty: #{quantity};"
					record.update_columns({
						:sales_order_id=> sales_order_id, 
						:sales_order_item_id=> sales_order_item_id, 
						:quantity=> quantity, 
						:prf_outstanding=> prf_outstanding,
						:status=> 'active',
						:updated_at=> DateTime.now, :updated_by=> current_user.id
					})
				else
					ProductionOrderDetailMaterial.create({
						:company_profile_id=> company_profile_id,
						:production_order_id=> production_order_id,
						:production_order_item_id=> production_order_item_id, 
						:sales_order_id=> sales_order_id, 
						:sales_order_item_id=> sales_order_item_id, 
						:product_id=> product_id,
						:material_id=> bom_item.material_id,
						:quantity=> (spp_quantity.to_f * bom_item.quantity.to_f), 
						:prf_outstanding=> (spp_quantity.to_f * bom_item.quantity.to_f), 
						:prf_kind=> 'material',
						:status=> 'active',
						:created_at=> DateTime.now, :created_by=> current_user.id
					})
				end
			end
			puts "----------------------------------------"
		end
	end

	def bom_wip(company_profile_id, product_wip, product_wip_prf, product_wip_quantity, production_order_item, sales_order_id, sales_order_item_id)
		if product_wip.present? and product_wip_prf == 'yes'
			product_wip_id  		= product_wip.id
			production_order_id = production_order_item.production_order_id

			bom_wip = BillOfMaterial.find_by(:product_id=> product_wip_id, :status=> 'active')

			# untuk prf jasa
			record = ProductionOrderDetailMaterial.find_by(
				:company_profile_id=> company_profile_id,
				:production_order_id=> production_order_id,
				:production_order_item_id=> production_order_item.id, 
				:product_id=> product_wip_id)
			if record.present?
				# 20201126: aden
					quantity = (production_order_item.quantity.to_f * product_wip_quantity.to_f)
	        prf_relation = ProductionOrderUsedPrf.find_by(:production_order_item_id=> record.production_order_item_id, :production_order_detail_material_id=> record.id, :status=> 'active')
	        if prf_relation.present?
	          prf_outstanding = 0
	          puts "PRF Found"
	        else
	          prf_outstanding = quantity
	        end
				# prf_quantity = (record.quantity.to_f - record.prf_outstanding.to_f)
				# quantity = (production_order_item.quantity.to_f * product_wip_quantity.to_f)
				# puts "PRF Qty: #{prf_quantity};"
				puts "Qty: #{quantity};"
				record.update_columns({
					:sales_order_id=> sales_order_id, 
					:sales_order_item_id=> sales_order_item_id, 
					:quantity=> quantity, 
					:prf_outstanding=> prf_outstanding,
					:status=> 'active',
					:updated_at=> DateTime.now, :updated_by=> current_user.id
				})
			else
				record = ProductionOrderDetailMaterial.new({
					:company_profile_id=> company_profile_id,
					:production_order_id=> production_order_id,
					:production_order_item_id=> production_order_item.id, 
					:sales_order_id=> sales_order_id, 
					:sales_order_item_id=> sales_order_item_id, 
					:product_id=> product_wip_id,
					:material_id=> nil,
					:quantity=> (production_order_item.quantity.to_f * product_wip_quantity.to_f), 
					:prf_outstanding=> (production_order_item.quantity.to_f * product_wip_quantity.to_f), 
					:prf_kind=> 'services',
					:status=> 'active',
					:created_at=> DateTime.now, :created_by=> current_user.id
				})
				record.save!
			end
			get_item_bom(company_profile_id, bom_wip, production_order_id, production_order_item.id, sales_order_id, sales_order_item_id, production_order_item.product_id, production_order_item.quantity)
		end
	end

	def canceled_bom(production_order_id)
		ProductionOrderDetailMaterial.where(:status=> 'active', :production_order_id=> production_order_id).each do |item|
			item.update_columns({
				:status=> 'canceled', :canceled_at=> DateTime.now, :canceled_by=> current_user.id
			})
		end
	end
end
