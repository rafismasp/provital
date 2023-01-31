class SalesOrder < ApplicationRecord
	extend OrderAsSpecified
	validates :number, uniqueness: { scope: [:company_profile_id], message: "cannot duplicate" }
	validates :po_number, uniqueness: { scope: [:company_profile_id, :customer_id], message: "has already been taken per customer" }

	belongs_to :company_profile
	belongs_to :customer
	belongs_to :term_of_payment
	belongs_to :tax

	has_many :sales_order_items, -> { where status: 'active' }
  has_many :sales_order_files, -> { where status: 'active' }
	has_many :production_order_detail_materials, -> { where status: 'active' }

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true

	def total_amount
		amount = 0
		sales_order_items.each do |item|
			amount += (item.quantity * item.unit_price)
		end
		return amount
	end

	def po_supplier_number
		number = []
		sales_order_items.each do |item|
			item.production_order_items.each do |spp_item|
				spp_item.production_order_used_prves.each do |detail|
					detail.purchase_request_item.purchase_order_supplier_items.each do |po_item|
						number << po_item.purchase_order_supplier.number
					end
				end
			end
		end
		return number.uniq.join(", ")
	end
	def po_currency
		currency = []
		sales_order_items.each do |item|
			item.production_order_items.each do |spp_item|
				spp_item.production_order_used_prves.each do |detail|
					detail.purchase_request_item.purchase_order_supplier_items.each do |po_item|
						currency << po_item.purchase_order_supplier.currency.symbol
					end
				end
			end
		end
		return currency.uniq.join(", ")
	end

	def po_amount
		total_amount = 0
		sales_order_items.each do |item|
			item.production_order_items.each do |spp_item|
				spp_item.production_order_used_prves.each do |detail|
					detail.purchase_request_item.purchase_order_supplier_items.each do |po_item|
						total_amount += po_item.purchase_order_supplier.total_amount
					end
				end
			end
		end
		return total_amount
	end

	def po_amount2
		total_amount = 0
		cost_project = 0
		sales_order_items.each do |item|
			item.production_order_items.each do |spp_item|
				# step 2
				spp_item.production_order_used_prves.each do |detail|
					# step 3
					detail.purchase_request_item.purchase_order_supplier_items.each do |po_item|
						puts " * #{po_item.purchase_order_supplier.number} #{po_item.purchase_order_supplier.kind}"
			      total_amount += check_grn_items(po_item.material_receiving_items, 0) if po_item.material_receiving_items.present?
			      total_amount += check_grn_items(po_item.product_receiving_items, 0) if po_item.product_receiving_items.present?
			      total_amount += check_grn_items(po_item.general_receiving_items, 0) if po_item.general_receiving_items.present?
			      total_amount += check_grn_items(po_item.consumable_receiving_items, 0) if po_item.consumable_receiving_items.present?
			      total_amount += check_grn_items(po_item.equipment_receiving_items, 0) if po_item.equipment_receiving_items.present?
						cost_project += total_amount*po_item.unit_price
					end
				end
			end
		end
		return total_amount
	end

	def check_grn_items(grn_items, total_amount)
		# puts "total_amount: #{total_amount}"
		grn_items.each do | grn_item| 
      # puts "    #{grn_item.material_receiving.number} => quantity: #{grn_item.quantity}; GRN Price: #{grn_item.quantity * po_item.unit_price}"
      sum_spp_quantity = 0
      grn_item.purchase_order_supplier_item.purchase_request_item.production_order_used_prves.each do |detail_spp_by_prf|
        spp_quantity = (detail_spp_by_prf.production_order_detail_material.present? ? detail_spp_by_prf.production_order_detail_material.quantity : 0)
        sum_spp_quantity += spp_quantity
      end
      po_number = grn_item.purchase_order_supplier_item.purchase_order_supplier.number

      grn_item.purchase_order_supplier_item.purchase_request_item.production_order_used_prves.each do |detail_spp_by_prf|
        so_number = detail_spp_by_prf.production_order_item.sales_order_item.sales_order.number
        prf_number = detail_spp_by_prf.purchase_request_item.purchase_request.number
        prf_quantity = detail_spp_by_prf.purchase_request_item.quantity
        spp_quantity = (detail_spp_by_prf.production_order_detail_material.present? ? detail_spp_by_prf.production_order_detail_material.quantity : 0)

        # number << so_number
        if spp_quantity > 0
	        percent_by_spp_qty = spp_quantity/sum_spp_quantity
	        result1 = percent_by_spp_qty*grn_item.quantity

	        if so_number == self.number
	        	total_amount += percent_by_spp_qty*grn_item.quantity 
	        	puts " #{po_number} | #{prf_number} => #{percent_by_spp_qty}*#{grn_item.quantity} => #{percent_by_spp_qty*grn_item.quantity } => #{total_amount}"
	        else
	        	puts "---- > #{so_number} | #{po_number} | #{prf_number}"
	       	end
	      end
      end

    end
    return total_amount
	end

	def grn_amount
		total_amount = 0
		sales_order_items.each do |item|
			item.production_order_items.each do |spp_item|
				spp_item.production_order_used_prves.each do |detail|
					detail.purchase_request_item.purchase_order_supplier_items.each do |po_item|
						po_item.material_receiving_items.each do |grn_item|
							total_amount += grn_item.quantity * grn_item.purchase_order_supplier_item.unit_price.to_f
						end
					end
				end
			end
		end
		return total_amount
	end
	def prn_amount
		total_amount = 0
		sales_order_items.each do |item|
			item.production_order_items.each do |spp_item|
				spp_item.production_order_used_prves.each do |detail|
					detail.purchase_request_item.purchase_order_supplier_items.each do |po_item|
						po_item.product_receiving_items.each do |grn_item|
							total_amount += grn_item.quantity * grn_item.purchase_order_supplier_item.unit_price.to_f
						end
					end
				end
			end
		end
		return total_amount
	end
	def cost_project
    result = nil
		# return total_amount - grn_amount - prn_amount
		so_currency = "#{self.customer.currency.symbol if self.customer.present? and self.customer.currency.present?}"
    po_currency = ""
    
    so_amount = summary_po_amount = summary_grn_amount = 0
    cost_project = 0
    prf_item_group = []
    self.sales_order_items.each do |so_item|
      so_amount += so_item.quantity*so_item.unit_price
      so_item.production_order_items.each do |spp_item|
        prf_item_group+= spp_item.production_order_used_prves.group(:purchase_request_item_id).map { |e| e.purchase_request_item_id }
      end
    end

    c = 0
    c_prf = 0
    spp_used_by_prf = ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item_group.uniq, :status=> 'active').includes(
      purchase_request_item: [
        :purchase_request, 
        product: [:unit], material: [:unit], consumable: [:unit], equipment: [:unit], general: [:unit], 
          purchase_order_supplier_items: [ 
            product_receiving_items: [
              :product_receiving, :purchase_order_supplier_item
            ], material_receiving_items: [
              :material_receiving, :purchase_order_supplier_item
            ], general_receiving_items: [
              :general_receiving, :purchase_order_supplier_item
            ], consumable_receiving_items: [
              :consumable_receiving, :purchase_order_supplier_item
            ], equipment_receiving_items: [
              :equipment_receiving, :purchase_order_supplier_item
            ], purchase_order_supplier: [:currency, :purchase_order_supplier_items]
          ]
        ]
      ) if prf_item_group.present?

    spp_used_by_prf.group(:purchase_request_item_id).each do |spp_used|
      # pdf.text "  production_order_item_id: #{spp_used.production_order_item_id}; purchase_request_item_id: #{spp_used.purchase_request_item_id}; "
      sum_spp_quantity = 0
      sum_po_quantity = 0
      sum_grn_quantity = 0
      prf_quantity = spp_used.purchase_request_item.quantity
      if prf_quantity > 0
        prf_header = spp_used.purchase_request_item.purchase_request 

        if spp_used.purchase_request_item.product.present? 
          part = spp_used.purchase_request_item.product 
        elsif spp_used.purchase_request_item.material.present? 
          part = spp_used.purchase_request_item.material 
        elsif spp_used.purchase_request_item.consumable.present? 
          part = spp_used.purchase_request_item.consumable 
        elsif spp_used.purchase_request_item.equipment.present? 
          part = spp_used.purchase_request_item.equipment 
        elsif spp_used.purchase_request_item.general.present? 
          part = spp_used.purchase_request_item.general 
        end
        unit_name = (part.present? ? part.unit_name : nil)

        c_po = 0
        if spp_used.purchase_request_item.purchase_order_supplier_items.present?
          
          po_amount  = 0
          grn_amount = 0
          spp_used.purchase_request_item.purchase_order_supplier_items.each do |po_item|
            po_currency = "#{po_item.purchase_order_supplier.currency.symbol if po_item.purchase_order_supplier.present? and po_item.purchase_order_supplier.currency.present?}"
            
            sum_po_quantity += po_item.quantity
            po_amount += po_item.unit_price*po_item.quantity

            c_grn = 0
            if po_item.material_receiving_items.present?
              po_item.material_receiving_items.each do |grn_item|
                sum_grn_quantity += grn_item.quantity
                grn_amount += grn_item.quantity*po_item.unit_price
              end
            end
            if po_item.product_receiving_items.present?
              po_item.product_receiving_items.each do |grn_item|
                sum_grn_quantity += grn_item.quantity
                grn_amount += grn_item.quantity*po_item.unit_price
              end
            end
            if po_item.consumable_receiving_items.present?
              po_item.consumable_receiving_items.each do |grn_item|
                sum_grn_quantity += grn_item.quantity
                grn_amount += grn_item.quantity*po_item.unit_price
              end
            end
            if po_item.equipment_receiving_items.present?
              po_item.equipment_receiving_items.each do |grn_item|
                sum_grn_quantity += grn_item.quantity
                grn_amount += grn_item.quantity*po_item.unit_price
              end
            end
            if po_item.general_receiving_items.present?
              po_item.general_receiving_items.each do |grn_item|
                sum_grn_quantity += grn_item.quantity
                grn_amount += grn_item.quantity*po_item.unit_price
              end
            end
          end

          cost_project += grn_amount
          summary_po_amount += po_amount
          summary_grn_amount += grn_amount
        end

        spp_used_by_prf.where(:purchase_request_item_id=> spp_used.purchase_request_item_id).each do |spp_used_from_item|
          # spp_header = spp_used_from_item.production_order_item.production_order
          spp_item = spp_used_from_item.production_order_item

          sum_spp_quantity += spp_item.quantity
        end

      end
    end if spp_used_by_prf.present?

    # if cost_project > 0
      result = {
        :customer_name=> "#{self.customer.name if self.customer.name}",
        :so_number=> "#{self.number}",
        :so_date=> "#{self.date}",
        :project_name=> "#{self.remarks}",
        :so_amount=> so_amount,
        :po_amount=> summary_po_amount,
        :grn_amount=> summary_grn_amount,
        :total=> so_amount - summary_grn_amount,
        :po_currency=> po_currency
      }
    # end
    return result
	end

  def list_service_type
    result = []
    if self.service_type_ddv == 1
      result << "Design, Deevlopment and Validation"
    end
    if self.service_type_mfg == 1
      result << "Manufacturing"
    end
    if self.service_type_str == 1
      result << "Sterilization"
    end
    if self.service_type_lab == 1
      result << "Laboratory Testing"
    end
    if self.service_type_oth == 1
      result << "Other"
    end

    return result
  end
  def list_service_type_short
    result = []
    if self.service_type_ddv == 1
      result << "DDV"
    end
    if self.service_type_mfg == 1
      result << "Mfg"
    end
    if self.service_type_str == 1
      result << "Str"
    end
    if self.service_type_lab == 1
      result << "Lab"
    end
    if self.service_type_oth == 1
      result << "Other"
    end

    return result
  end
end
