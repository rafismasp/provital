namespace :daily_job do
  desc "Rake file 2020-06-20"  

  task :task_virtual_receiving => :environment do |t, args|
    my_array = {}
    VirtualReceivingItem.where(:virtual_receiving_id=> 9).each do |item|
      puts "[#{item.id}] => po_item: #{item.purchase_order_supplier_item_id}"
      if item.material.present?
        item_group(my_array, 'material', item)
      end
      if item.product.present?
        item_group(my_array, 'product', item)
      end
      if item.consumable.present?
        item_group(my_array, 'consumable', item)
      end
      if item.equipment.present?
        item_group(my_array, 'equipment', item)
      end
      if item.general.present?
        item_group(my_array, 'general', item)
      end
    end
    puts JSON.pretty_generate(my_array)
  end

  def item_group(my_array, kind, item)
    id = item.try("#{kind}")&.id
    part_id = item.try("#{kind}")&.part_id

    my_array["#{kind}"] ||={}
    my_array["#{kind}"]["#{id}"] ||= {}
    if my_array["#{kind}"]["#{id}"].present?
      my_array["#{kind}"]["#{id}"][:po_item_id] = item.purchase_order_supplier_item_id
      my_array["#{kind}"]["#{id}"][:prf_item_id] = item.purchase_order_supplier_item.purchase_request_item_id
      my_array["#{kind}"]["#{id}"][:part_id] = part_id
      my_array["#{kind}"]["#{id}"][:quantity] += item.quantity.to_f
    else
      my_array["#{kind}"]["#{id}"][:po_item_id] = item.purchase_order_supplier_item_id
      my_array["#{kind}"]["#{id}"][:prf_item_id] = item.purchase_order_supplier_item.purchase_request_item_id
      my_array["#{kind}"]["#{id}"][:part_id] = part_id
      my_array["#{kind}"]["#{id}"][:quantity] = item.quantity.to_f
    end
    puts "#{kind}_id: #{id}"
  end

  task :task_20220210 => :environment do |t, args|
    VirtualReceivingItem.all.each do |item|
      po_item = item.purchase_order_supplier_item

      if po_item.present?
        prf_item = po_item.purchase_request_item
        pdm_item = po_item.pdm_item

        part = nil
        if prf_item.present?
          if prf_item.product.present?
            part = prf_item.product
            item.update_columns(:product_id=> prf_item.product_id)
          elsif prf_item.material.present?
            part = prf_item.material
            item.update_columns(:material_id=> prf_item.material_id)
          elsif prf_item.consumable.present?
            part = prf_item.consumable
            item.update_columns(:consumable_id=> prf_item.consumable_id)
          elsif prf_item.equipment.present?
            part = prf_item.equipment
            item.update_columns(:equipment_id=> prf_item.equipment_id)
          elsif prf_item.general.present?
            part = prf_item.general
            item.update_columns(:general_id=> prf_item.general_id)
          end 
        end

        if pdm_item.present?
          if pdm_item.material.present?
            part = pdm_item.material
            item.update_columns(:material_id=> pdm_item.material_id)
          end
        end

      end
    end
  end

  task :task_20211220 => :environment do |t, args|
    InvoiceCustomer.where(:tax_id=> nil).order("id desc").limit(100).each do |invoice|
      if invoice.ppntotal.to_f > 0
        set_tax_id = nil
        invoice.invoice_customer_items.where(:status=> 'active').each do |item|
          puts "#{invoice.number} => PPN 10% #{item.sales_order_item.sales_order.tax.name}"
          if item.sales_order_item.sales_order.tax.name == 'PPN 10%'
            set_tax_id = item.sales_order_item.sales_order.tax_id
          end
        end
        if set_tax_id.present?
          invoice.update_columns({:tax_id=> set_tax_id})
        end
        puts "---------------------------------------------"
      else

        set_tax_id = nil
        invoice.invoice_customer_items.where(:status=> 'active').each do |item|
          puts "#{invoice.number} => Non PPN #{item.sales_order_item.sales_order.tax.name}"
          set_tax_id = item.sales_order_item.sales_order.tax_id
        end
        if set_tax_id.present?
          invoice.update_columns({:tax_id=> set_tax_id})
        end
        puts "---------------------------------------------"
      end
    end
  end
  
  task :task_20211122 => :environment do |t, args|
    array = [
      {:name_account=> "ACEP MUHAMAD RAMDAN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "094-0915503", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "ACHMAD YANI EFFENDI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "687-2122211", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "AGARINDO BIOLOGICAL CO P", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "581-0292930", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "ALTORIUM MULTI ANALITIKA", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "092-3000400", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "APACK INTERNATIONAL PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "883-1103108", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "APRIAN HIDAYAT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-1625804", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "ARIF HIDAYAT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "012-0397117", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "BAHTERA ADI JAYA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "353-0184888", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "BAIDI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "486-0321250", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "BERSAUDARA INTI CORPORA", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "287-3093099", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "BINTANG BARISAN TUJUH PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "088-9595959", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "BUSAN JAYA SPUNINDO PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "468-8086777", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "CARE SPUNBOND PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "530-0252003", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "CITRA SATRIAWIDYA ANDHIK", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "553-0237771", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "CRYSTAL SUKSES JAYA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "880-0778884", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "CV SK APPAREL", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "885-0981974", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DAELAMI SANI MUKTI SH", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "406-0799941", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DEDEN HERMAWAN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "406-0983645", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DIANING SRI ASTUTI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "868-0652954", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DIPA PUSPA LABSAINS PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "028-9999444", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DIPTA RUKMANA", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "141-0500848", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DJUNIAR & DJUNIAR PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "529-5027999", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DUNIA LOGISTIK PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "740-1348003", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "DYNAPLAST MANDIRI PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "108-3020320", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "FOREN AXELA NANGIN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "182-0344240", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "HADI MULYONO", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "804-0084429", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "HARAPAN BARU CV", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "157-3078989", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "IRWAN SETIAWAN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "765-1117741", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "JAYA WAHANA TERPADU PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "065-3043616", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "JOHNNY SUTANTO", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "310-7338333", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "JOSUA SITORUS", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "885-0979988", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "KARYA SUKSES SETIA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "171-1975999", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "KHARISMA ESA UNGGUL PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "882-0595000", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "LANGGENG JAYA PLASTINDO", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "263-3667799", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "LEE MOON KAP", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "067-3004285", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "MERRY HANDAYANI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "697-0263690", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "MUHAMAD HUDRI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "542-0869870", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "MULTIREDJEKI KITA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "028-3092027", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "NONO ASEP SAEPUDIN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-0783440", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "NOVELL PHARMACEUTICAL LA", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "178-3018636", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "NUKE APRILIA R", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-0685529", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PARK DONG SIK", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "880-0438200", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PETER", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "702-5777778", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PHILIP SAMUEL WISATA", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "676-5800700", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PLASTIK KARAWANG FLEXIND", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "273-6071263", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PRIMA MAS AGUNG PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-0311190", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PROVITAL PERDANA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "840-0156868", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT INDOKO JAYA CHEMICA", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "379-1708000", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PURA BARUTAMA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "031-1925988", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PURBAYA PACKINDO PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-1234988", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PUTRINDO SUKSES CEMERLAN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-3111199", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SAMATOR TOMOE PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "873-0889900", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SAMSUDIN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-1609035", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SATRIA MUDA AMANAH PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "578-0937752", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SRI HARYANI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "531-5160976", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SUBIYANTO", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "885-0498548", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SUBIYOTO", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-1039395", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SUCI OKTAVIANI PUTRI SAR", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "343-1072601", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SUPARGI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "522-1114885", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SUPARYANTO", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "094-0384125", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SUPRIYADI", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "486-0169377", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "SURYASUKSES MEKAR MAKMUR", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "152-0377979", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "TARAFIS ANUGERAH MEDIKA", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "840-0143332", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "TJANG TJOEK IN", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "644-0002062", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "TRIMITRA SWADAYA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "001-3042311", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "ZI-TECHASIA PT", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "035-3093484", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT ASURANSI MSIG", :currency=> "IDR", :bank_name=> "PT. BANK CENTRAL ASIA, Tbk.", :number_account=> "06433-20180003671", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "Asosiasi Produsen Alat Kesehatan Indonesia", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "0060007988573", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "JOHNNY SUTANTO", :currency=> "IDR", :bank_name=> "PT. BANK CIMB NIAGA TBK", :number_account=> "3565360100002517", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "JOHNNY SUTANTO", :currency=> "IDR", :bank_name=> "CITIBANK N.A.", :number_account=> "4617782090476581", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "JOHNNY SUTANTO", :currency=> "IDR", :bank_name=> "PT. BANK CIMB NIAGA TBK", :number_account=> "704647425400", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "JOHNNY SUTANTO", :currency=> "IDR", :bank_name=> "PT. BANK CIMB NIAGA TBK", :number_account=> "5228660000051942", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT BIROTIKA SEMESTA", :currency=> "IDR", :bank_name=> "STANDARD CHARTERED BANK", :number_account=> "8104041301410859", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT PROLABIOS MITRA ANALITIKA", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1330013566757", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT ST. Morita Industries", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1560003185073", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT TRI EXCELLA HARMONY", :currency=> "IDR", :bank_name=> "PT. BANK KEB HANA INDONESIA", :number_account=> "13680549120", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Abadi Teknik Sehati", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1250007044654", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. AMEERA SILVINDO TEKNIK", :currency=> "IDR", :bank_name=> "PT. BANK RAKYAT INDONESIA (PERSERO), Tbk", :number_account=> "31901001521309", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. ARFINDO BERSINAR", :currency=> "IDR", :bank_name=> "PT. BANK RAKYAT INDONESIA (PERSERO), Tbk", :number_account=> "057801000166300", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Etos Indonusa", :currency=> "IDR", :bank_name=> "PT. BANK NEGARA INDONESIA (PERSERO),Tbk", :number_account=> "8272000000009059", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Flamenco Aircon Mandiri", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1560015980529", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. foursu Mitra Lestari", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1560015343249", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Glomed Adinata Prima", :currency=> "IDR", :bank_name=> "PT. PANIN BANK Tbk.", :number_account=> "0035000799", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. HYERAA GARMENT INDONESIA", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1330018708677", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Intralab Ekatama", :currency=> "IDR", :bank_name=> "PT. BANK DANAMON INDONESIA, Tbk", :number_account=> "000004086500", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Jaya Swastika Garmindo", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1640003186345", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. KOMARK LABELS AND LABELLING INDONESIA", :currency=> "IDR", :bank_name=> "PT. BANK MAYBANK INDONESIA TBK", :number_account=> "2185529735", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. KOMARK LABELS AND LABELLING INDONESIA", :currency=> "IDR", :bank_name=> "PT. BANK CIMB NIAGA TBK", :number_account=> "800113833600", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Medika Amaliah Sejahtera", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1150007221155", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Multi Spunindo Jaya", :currency=> "IDR", :bank_name=> "PT. BANK MAYBANK INDONESIA TBK", :number_account=> "2091788880", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. NORITA FLEXINDO", :currency=> "IDR", :bank_name=> "PT. PANIN BANK Tbk.", :number_account=> "2555000678", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. PUTRA DAFARA LESTARINDO", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1310001705674", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Putra Mustika", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1560009846876", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. SARANA MULTI SOLUSINDO", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1230007091681", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. SEIGO SELARAS INDONESIA", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1560015182159", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Sentral Tehnologi Managemen", :currency=> "IDR", :bank_name=> "PT. BANK OCBC NISP, Tbk.", :number_account=> "6889201980000488", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. SRI TITA MEDIKA", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "1560015518477", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Sucofindo Laboratorium", :currency=> "IDR", :bank_name=> "PT. BANK NEGARA INDONESIA (PERSERO),Tbk", :number_account=> "0016244123", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. SUNNI MULTI SEJAHTERA", :currency=> "IDR", :bank_name=> "PT. BANK CIMB NIAGA TBK", :number_account=> "800167749300", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Tirta Sari Nirmala", :currency=> "IDR", :bank_name=> "PT. BANK NATIONALNOBU", :number_account=> "8885070015638382", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. Trisaudara Sentosa Industri", :currency=> "IDR", :bank_name=> "PT. BANK RESONA PERDANIA", :number_account=> "01034488009", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. TUV Rheinland Indonesia", :currency=> "IDR", :bank_name=> "DEUTSCHE BANK AG", :number_account=> "787050060116705", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "PT. YUNI INTERNATIONAL", :currency=> "IDR", :bank_name=> "PT. BANK MAYBANK INDONESIA TBK", :number_account=> "2242001838", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "Sutadi Matyani", :currency=> "IDR", :bank_name=> "PT. BANK MANDIRI (PERSERO), Tbk", :number_account=> "9000001298919", :branch_bank=> "Jakarta", :address_bank=> "Jakarta"},
      {:name_account=> "ASSURE TECH LIMITED", :currency=> "USD", :bank_name=> "PING AN BANK CO., LTD. (FORMERLY SH", :number_account=> "OSA15000097184697", :branch_bank=> "CHINA", :address_bank=> "(HEAD OFFICE) 5047 SHEN NAN ROAD EAST SHENZHEN CHINA"},
      {:name_account=> "HAORUI TECH CO., LIMITED", :currency=> "USD", :bank_name=> "CHINA MERCHANTS BANK", :number_account=> "792900861332701", :branch_bank=> "CHINA", :address_bank=> "(NANCHANG BRANCH) 46 FUZHOU ROAD NANCHANG CHINA"},
      {:name_account=> "Sanichem Resources Sdn. Bhd", :currency=> "USD", :bank_name=> "MALAYAN BANKING BERHAD (MAYBANK)", :number_account=> "505103002741", :branch_bank=> "MALAYSIA", :address_bank=> "100 JALAN TUN PERAK  POB 12010 KUALA LUMPUR MALAYSIA"},
      {:name_account=> "Wuhan Huawei Technology Co., Lt", :currency=> "USD", :bank_name=> "PT. Bank China Construction Bank Indonesia, Tbk", :number_account=> "42050111620800000861", :branch_bank=> "CHINA", :address_bank=> "(HUBEI BRANCH) HUBEI CHINA"},
      {:name_account=> "Zhenjiang Hongda Commodity Co., Ltd", :currency=> "USD", :bank_name=> "BANK OF CHINA (HONG KONG) LIMITED", :number_account=> "497558232770", :branch_bank=> "CHINA", :address_bank=> "(ZHENJIANG BRANCH)  235 ZHONGSHANDONG ROAD ZHENJIANG CHINA"},

    ]

    array.each do |a|
      dom_bank = DomBank.find_by(:bank_name=> a[:bank_name])
      puts "#{dom_bank.present? ? nil : "dom bank #{a[:bank_name]} not exist XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}"
      currency = Currency.find_by(:name=> a[:currency])
      puts "#{currency.present? ? nil : "currency #{a[:currency]} not exist XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}"

      if dom_bank.present? and currency.present?
        check = ListInternalBankAccount.find_by(:number_account=> a[:number_account])
        if check.present?
          puts "#{a[:number_account]} exist"
        else
          ListInternalBankAccount.create({
            :company_profile_id=> 1, 
            :dom_bank_id=> dom_bank.id,
            :currency_id=> currency.id,
            :name_account=> a[:name_account],
            :branch_bank=> a[:branch_bank],
            :number_account=> a[:number_account],
            :code_voucher=> '',
            :address_bank=> a[:address_bank],
            :new_status=> 'active',
            :status=> 'new',
            :created_by=> 1, :created_at=> DateTime.now()
          })
          puts "#{a[:number_account]} Created!"
        end
      end
    end 
  end

  task :test_timeout => :environment do |t, args|
    require 'timeout'
    begin
      puts "start"
      status = Timeout::timeout(5) {
        # code block that should be terminated if it takes more than 5 seconds...
      }
      puts status
    rescue Timeout::Error
      puts 'Taking long to execute, exiting...'
    end
  end

  task :task_20211011 => :environment do |t, args|
    InventoryBatchNumber.where(:periode=> '202104', :material_id=> 450).each do |item|
      puts "#{item.id}"
      item.update({:updated_at=> DateTime.now()})
    end
  end
  task :perbaikan_task_20211008 => :environment do |t, args|
    InvoiceCustomerItem.where("remarks like ?", "DO pindah invoice,%").each do |item|
      # puts item.remarks
      # puts item.remarks.split()[4]
      old_invoice = item.remarks.split()[4].tr(';','')
      old_invoice_check = InvoiceCustomer.find_by(:number=> old_invoice)
      if old_invoice_check.present?
        puts old_invoice_check.id
        item.update(:invoice_customer_id=> old_invoice_check.id)
        item.delivery_order_item.delivery_order.update(:invoice_customer_id=> old_invoice_check.id)
      else
        puts "kosong"
      end
    end
  end

  task :task_20211008_change_invoice_customer => :environment do |t, args|
    array = ['21I044', '21I018', '21I049', '21I036', '21I037', '21I017', '21I045', '21I046']
    array.each do |a|
      InvoiceCustomer.where(:number=> a).each do |invoice|
        invoice.invoice_customer_items.where(:status=> 'active').each do |invoice_item|
          invoice.update(:customer_id=> invoice_item.delivery_order_item.delivery_order.customer_id) if invoice.customer_id != invoice_item.delivery_order_item.delivery_order.customer_id
        end
      end
    end

  end
  task :task_20211008 => :environment do |t, args|
    array = [{:old_invoice=> "21I001", :new_invoice=> "21I044", :do_number=> "DO21090071"},
            {:old_invoice=> "21I011", :new_invoice=> "21I008", :do_number=> "DO21090011"},
            {:old_invoice=> "21I016", :new_invoice=> "21I014", :do_number=> "DO21090016"},
            {:old_invoice=> "21I016", :new_invoice=> "21I016", :do_number=> "DO21090073"},
            {:old_invoice=> "21I016", :new_invoice=> "21I016", :do_number=> "DO21090077"},
            {:old_invoice=> "21I017", :new_invoice=> "21I009", :do_number=> "DO21090017"},
            {:old_invoice=> "21I018", :new_invoice=> "21I009", :do_number=> "DO21090018"},
            {:old_invoice=> "21I036", :new_invoice=> "21I017", :do_number=> "DO21090036"},
            {:old_invoice=> "21I036", :new_invoice=> "21I017", :do_number=> "DO21090036"},
            {:old_invoice=> "21I037", :new_invoice=> "21I018", :do_number=> "DO21090037"},
            {:old_invoice=> "21I042", :new_invoice=> "21I009", :do_number=> "DO21090059"},
            {:old_invoice=> "21I042", :new_invoice=> "21I008", :do_number=> "DO21090070"},
            {:old_invoice=> "21I044", :new_invoice=> "21I009", :do_number=> "DO21090044"},
            {:old_invoice=> "21I044", :new_invoice=> "21I009", :do_number=> "DO21090044"},
            {:old_invoice=> "21I044", :new_invoice=> "21I009", :do_number=> "DO21090044"},
            {:old_invoice=> "21I045", :new_invoice=> "21I042", :do_number=> "DO21090045"},
            {:old_invoice=> "21I046", :new_invoice=> "21I042", :do_number=> "DO21090046"},
            {:old_invoice=> "21I046", :new_invoice=> "21I042", :do_number=> "DO21090046"},
            {:old_invoice=> "21I048", :new_invoice=> "21I045", :do_number=> "DO21090048"},
            {:old_invoice=> "21I048", :new_invoice=> "21I045", :do_number=> "DO21090062"},
            {:old_invoice=> "21I048", :new_invoice=> "21I046", :do_number=> "DO21090061"},
            {:old_invoice=> "21I048", :new_invoice=> "21I046", :do_number=> "DO21090061"},
            {:old_invoice=> "21I049", :new_invoice=> "21I046", :do_number=> "DO21090049"},
            {:old_invoice=> "21I058", :new_invoice=> "21I049", :do_number=> "DO21090064"},
            {:old_invoice=> "21I058", :new_invoice=> "21I058", :do_number=> "DO21090065"},
            {:old_invoice=> "21I061", :new_invoice=> "21I062", :do_number=> "DO21090076"},
            {:old_invoice=> "21J002", :new_invoice=> "21J009", :do_number=> "DO21100002"},
            {:old_invoice=> "21J002", :new_invoice=> "21J010", :do_number=> "DO21100003"},
            {:old_invoice=> "21J002", :new_invoice=> "21J011", :do_number=> "DO21100012"},
            {:old_invoice=> "21J002", :new_invoice=> "21J011", :do_number=> "DO21100012"},
            {:old_invoice=> "21J002", :new_invoice=> "21J011", :do_number=> "DO21100012"},
            {:old_invoice=> "21J002", :new_invoice=> "21J011", :do_number=> "DO21100012"},
            {:old_invoice=> "21J002", :new_invoice=> "21J011", :do_number=> "DO21100012"},
            {:old_invoice=> "21J002", :new_invoice=> "21J012", :do_number=> "DO21100013"},
            {:old_invoice=> "21J004", :new_invoice=> "21J013", :do_number=> "DO21100007"}
            ]

    array2 = [{:old_invoice=> "21I042", :new_invoice=> "21I011", :do_number=> "DO21090067"},
      {:old_invoice=> "21I042", :new_invoice=> "21I036", :do_number=> "DO21090042"},
      {:old_invoice=> "21I042", :new_invoice=> "21I037", :do_number=> "DO21090069"},
      {:old_invoice=> "21I042", :new_invoice=> "21I063", :do_number=> "DO21090068"},
      {:old_invoice=> "21I042", :new_invoice=> "21I009", :do_number=> "DO21090059"},
      {:old_invoice=> "21I042", :new_invoice=> "21I064", :do_number=> "DO21090066"},
      {:old_invoice=> "21I042", :new_invoice=> "21I008", :do_number=> "DO21090070"},
      {:old_invoice=> "21I042", :new_invoice=> "21I065", :do_number=> "DO21090078"}]

    array2.each do |a|
      # if a[:do_number] == 'DO21100002'
        invoice_items = InvoiceCustomerItem.where(:status=> 'active').includes(:invoice_customer, delivery_order_item: [:delivery_order])
        .where(:invoice_customers => {:company_profile_id=> 1, :number=> a[:old_invoice]})
        .where(:delivery_orders => {:company_profile_id=> 1, :number=> a[:do_number]})

        puts "#{a[:do_number]}: #{a[:old_invoice]} => #{a[:new_invoice]}"
        old_invoice = InvoiceCustomer.find_by(:company_profile_id=> 1, :number=> a[:old_invoice])
        new_invoice = InvoiceCustomer.find_by(:company_profile_id=> 1, :number=> a[:new_invoice])
        if new_invoice.blank?
          new_invoice = InvoiceCustomer.new({
            :company_profile_id=> old_invoice.company_profile_id,
            :currency_id=> old_invoice.currency_id,
            :customer_id=> old_invoice.customer_id,
            :number=> a[:new_invoice],
            :date=> old_invoice.date.to_date,
            :due_date=> old_invoice.due_date,
            :top_day=> old_invoice.top_day, :term_of_payment_id=> old_invoice.term_of_payment_id,
            :status=> 'new', 
            :created_by=> old_invoice.created_by, :created_at=> DateTime.now()
          })
          new_invoice.save!
        end

        do_record = DeliveryOrder.find_by(:company_profile_id=> 1, :number=> a[:do_number])
        invoice_items.each do |item|
          puts "[#{a[:new_invoice]}] new_invoice.present? #{new_invoice.present?}"
          puts "[#{a[:do_number]}] do_record.present? #{do_record.present?}"
          # puts item
          if new_invoice.present? and do_record.present?
            item.update(:invoice_customer_id=> new_invoice.id, :remarks=> "DO pindah invoice, old: #{a[:old_invoice]}; new: #{a[:new_invoice]}")
            do_record.update(:invoice_customer_id=> new_invoice.id)
          end
        end
        new_invoice.update(:subtotal=> 0) if new_invoice.present?
        old_invoice.update(:subtotal=> 0) if old_invoice.present?
      # end
    end
  end
  task :task_20211007 => :environment do |t, args|
    InvoiceCustomerItem.where(:invoice_customer_id=> 530, :status=> 'active').each do |item|
      if item.delivery_order_item.status == 'deleted'
        item.update(:status=> 'deleted', :remarks=> 'ubah item DO')
      end
    end
  end
  task :task_20210927 => :environment do |t, args|
    puts "=> #{VirtualReceivingItem.where(:status=> 'active').count()}"
    prf_record = nil
    VirtualReceiving.where(:company_profile_id=> 1).each do |header|
      puts header.number
      if header.prf_create_status == 'Y' 
        if header.status == 'approved3'
          case header.purchase_order_supplier.kind
          when 'product','material','consumable','equipment','general'
            if header.purchase_request.present?
              prf_record = header.purchase_request
            else
              prf_record = PurchaseRequest.new({
                :company_profile_id=> header.company_profile_id,
                :request_kind=> header.purchase_order_supplier.kind,
                :automatic_calculation=> 0,
                :department_id=> 4, # Material Management
                :employee_section_id=> 10, # Purchasing
                :number=> document_number("purchase_requests", DateTime.now(), 10, nil, nil),
                :date=> DateTime.now(),
                :remarks=> "Create from Virtual Receiving",
                :outstanding=> 0, 
                :status=> 'approved3',
                :created_at=> DateTime.now(), :created_by=> header.approved3_by,
                :approved1_at=> DateTime.now(), :approved1_by=> header.approved3_by,
                :approved2_at=> DateTime.now(), :approved2_by=> header.approved3_by,
                :approved3_at=> DateTime.now(), :approved3_by=> header.approved3_by
              })
              prf_record.save!
              header.update(:purchase_request_id=> prf_record.id)
            end

            header.virtual_receiving_items.each do |item|
              po_item = PurchaseOrderSupplierItem.find_by(:id=> item["purchase_order_supplier_item_id"])
              if po_item.present? and po_item.purchase_request_item.present?
                prf_item_old = po_item.purchase_request_item
                puts "create prf"
                prf_item = PurchaseRequestItem.find_by(
                    :purchase_request_id=> prf_record.id, 
                    :product_id=> prf_item_old.product_id,
                    :material_id=> prf_item_old.material_id,
                    :consumable_id=> prf_item_old.consumable_id,
                    :equipment_id=> prf_item_old.equipment_id,
                    :general_id=> prf_item_old.general_id,
                    :quantity=> prf_item_old.quantity
                  )
                if prf_item.present?
                  puts "new prf item updated!"
                  prf_item.update(:status=> 'active', :updated_at=> DateTime.now(), :updated_by=> header.approved3_by)
                else
                  puts "new prf item created!"
                  prf_item = PurchaseRequestItem.new(
                    :expected_date=> prf_item_old.expected_date,
                    :purchase_request_id=> prf_record.id, 
                    :product_id=> prf_item_old.product_id,
                    :material_id=> prf_item_old.material_id,
                    :consumable_id=> prf_item_old.consumable_id,
                    :equipment_id=> prf_item_old.equipment_id,
                    :general_id=> prf_item_old.general_id,
                    :quantity=> item.quantity, :outstanding=> item.quantity,
                    :summary_production_order=> prf_item_old.summary_production_order,
                    :moq_quantity=> prf_item_old.moq_quantity,
                    :pdm_quantity=> prf_item_old.pdm_quantity,
                    :specification=> prf_item_old.specification,
                    :justification_of_purchase=> prf_item_old.justification_of_purchase,
                    :status=> prf_item_old.status,
                    :created_at=> DateTime.now(), :created_by=> header.approved3_by
                    )
                  prf_item.save!
                end

                ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item_old.id, :status=> 'active').each do |spp_detail|
                  # puts spp_detail.as_json
                  new_spp_detail = ProductionOrderUsedPrf.find_by(:company_profile_id=> spp_detail.company_profile_id, 
                    :production_order_detail_material_id=> spp_detail.production_order_detail_material_id, 
                    :production_order_item_id=> spp_detail.production_order_item_id, 
                    :purchase_request_item_id=> prf_item.id )
                  if new_spp_detail.present?
                    new_spp_detail.update(:status=> 'active', :updated_at=> DateTime.now(), :updated_by=> header.approved3_by)
                  else
                    new_spp_detail = ProductionOrderUsedPrf.new(
                      :company_profile_id=> spp_detail.company_profile_id, 
                      :production_order_detail_material_id=> spp_detail.production_order_detail_material_id, 
                      :production_order_item_id=> spp_detail.production_order_item_id, 
                      :purchase_request_item_id=> prf_item.id,
                      :prf_date=> spp_detail.prf_date,
                      :note=> "Create from Virutal Receiving",
                      :status=> 'active',
                      :created_at=> DateTime.now(), :created_by=> header.approved3_by
                      )
                    new_spp_detail.save!
                  end
                end
              end
              if po_item.present? and po_item.pdm_item_id.present?
                puts "create pdm"
              end
            end
          end
        end
      else
        puts "selain PO 'product','material','consumable','equipment','general' tidak bisa dibuatin PRF otomatis dari Virtual Receiving!"
      end
      header.purchase_order_supplier.update(:outstanding=> 0)
    end
  end

  def document_number(ctrl_name, period, kind, kind2, kind3)
    case ctrl_name
    when "inventory_adjustments"
      prefix_code = "ADJ"
      i = 10
      ctrl = "inventory_adjustment"
    when "internal_transfers"

      # WHFG-PRD/20/06/0028
      # WHFG-2ND/20/06/0028
      # WHFG-QCT/20/06/0028

      # WHRM-PRD/20/06/0028
      # WHRM-2ND/20/06/0028
      # WHRM-QCT/20/06/0028

      # PRD-WHFG/20/06/0028
      # QCT-WHFG/20/06/0028

      # WH-INT/20/06/0028


      prefix_code = "#{internal_transfer_kind_defined(kind2)}-#{internal_transfer_kind_defined(kind3)}"
      ctrl = "internal_transfer"
      i = 15
    when "delivery_order_suppliers"
      prefix_code = "DS"
      ctrl = "delivery_order_supplier"
      i = 6
    when "delivery_orders"
      prefix_code = "DO"
      ctrl = "delivery_order"
      i = 6
      # DO2006001
    when "direct_labors"
      prefix_code = "BR"
      ctrl = "direct_labor"
      i = 6
      # BR20060001
    when "production_orders"
      prefix_code = "SPP"
      ctrl = "production_order"
      i = 6
      # SPP20060001
    when "pdms"
      prefix_code = "PDM"
      ctrl = "pdm"
      i = 6
      # PDM20060001
    when "picking_slips"
      prefix_code = "PS"
      ctrl = "picking_slip"
      i = 6
      # PS20060001
    when "purchase_requests"
      # PRF/01A/20/VI/001
      section = EmployeeSection.find_by(:id=> kind)
      if section.present?
        section_code = "#{section.department.code}#{section.code}"
        prefix_code = "PRF/#{section_code}"
      else
        prefix_code = "PRF/03B"
      end
      ctrl = "purchase_request"
      i = 14
    when "purchase_order_suppliers"
      # PP/PO/20/VI/012
      prefix_code = "PP/PO"
      ctrl = "purchase_order_supplier"
      i = 12
    when "sales_orders"
      prefix_code = "PP/PIF"
      ctrl = "sales_order"
      i = 7
      # PP/PIF/01/VI/2020
    when "sterilization_product_receivings"
      prefix_code = "SPR"
      i = 10
      ctrl = "sterilization_product_receiving"
    when "product_receivings"
      prefix_code = "PR"
      i = 6
      ctrl = "product_receiving"
    when "general_receivings"
      prefix_code = "SR"
      i = 6
      ctrl = "general_receiving"
    when "equipment_receivings"
      prefix_code = "ER"
      i = 6
      ctrl = "equipment_receiving"
    when "consumable_receivings"
      prefix_code = "CR"
      i = 6
      ctrl = "consumable_receiving"
    when "shop_floor_orders"
      prefix_code = "SFO"
      i = 10
      ctrl = "shop_floor_order"
    when "shop_floor_order_sterilizations"
      prefix_code = "SFOS"
      i = 11
      ctrl = "shop_floor_order_sterilization"
      # SFOS/AA/BB/XXX
    when "material_outgoings"
      prefix_code = "MI"
      i = 9

      ctrl = "material_outgoing"
      # MI/20/06/001
    when "virtual_receivings"
      prefix_code = "VRN"
      i = 10

      ctrl = "virtual_receiving"
      # VRN/20/06/001
    when "material_receivings"
      prefix_code = "GRN"
      i = 10

      ctrl = "material_receiving"
      # GRN/20/06/001
    when "finish_good_receivings"
      prefix_code = "FGR"
      i = 10
      ctrl = "finish_good_receiving"
      # FGR/20/01/001
    when "semi_finish_good_receivings"
      prefix_code = "SFG"
      i = 10
      ctrl = "semi_finish_good_receiving"
      # SFG/20/01/001
    when "semi_finish_good_outgoings"
      prefix_code = "SFS"
      i = 10
      ctrl = "semi_finish_good_outgoing"
      # SFS/20/01/001
    when "invoice_customers"
      prefix_code = ""
      ctrl = "invoice_customer"   
      i = 3   
      # 16B123
    when "invoice_supplier_receivings"
      prefix_code = "1"
      ctrl = "invoice_supplier_receiving"   
      i = 4
      # 1/18/05/0003
    when "payment_request_suppliers"
      prefix_code = "VPR.SUP"
      ctrl = "payment_request_supplier"   
      i = 3
      # VPR.SUP/2016/H/001
    when "vehicle_inspections"
      #VI/YY/MM/xxxx
      prefix_code = "VI"
      ctrl = "vehicle_inspection"
      i = 9
    when "outgoing_inspections"
      #OI/YY/MM/xxxx
      prefix_code = "OI"
      ctrl = "outgoing_inspection"
      i = 9
    when "rejected_materials"
      #NG-RM/YY/MM/xxxx
      prefix_code = "NG-RM"
      ctrl = "rejected_material"
      i = 9
    when 'routine_costs'
      ctrl = 'routine_cost'
      prefix_code = "RE"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'routine_cost_payments'
      ctrl = 'routine_cost_payment'
      prefix_code = "BPKBR"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'cash_submissions'
      ctrl = 'cash_submission'
      prefix_code = "KASBON"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'cash_settlements'
      ctrl = 'cash_settlement'
      prefix_code = "KASBON-#{kind2}"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'proof_cash_expenditures'

      ctrl = 'proof_cash_expenditure'
      prefix_code = "BPK"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    end

    month_to_letter = {}
    ('A'..'Z').each_with_index{|w, i| month_to_letter[i+1] = w } 
    year_yyyy = period.strftime("%Y")
    year_yy = period.strftime("%y")
    month_mm = period.strftime("%m")
    records = ctrl.camelize.constantize.where(:company_profile_id=> 1).where("date between ? and ?", period.to_date.at_beginning_of_month(), period.to_date.at_end_of_month())
  
    case ctrl 
      # 20200701 : sfo dipisah table
      # when "shop_floor_order"
      #   records = records.where(:kind=> kind)
      # 20200623 : PO Supplier penomorannya tidak pisah berdasarkan request_kind
    when "purchase_request"
      records = records.where(:employee_section_id=> kind)
    when "internal_transfer"
      records = records.where(:transfer_kind=> kind, :transfer_from=> kind2, :transfer_to=> kind3)
    end

    case ctrl
    when "purchase_request","material_outgoing","virtual_receiving","material_receiving","sterilization_product_receiving","finish_good_receiving","invoice_supplier_receiving"
      search = "#{prefix_code}/#{year_yy}/#{month_mm}/" 
      records = records.where("number LIKE ?", "#{search}%")
    when "delivery_order","picking_slip","direct_labor", "production_order","pdm","product_receiving","delivery_order_supplier","general_receiving","consumable_receiving","equipment_receiving"
      search = "#{prefix_code}#{year_yy}#{month_mm}"
      records = records.where("number LIKE ?", "#{search}%") 
    when 'routine_cost','routine_cost_payment','cash_submission','proof_cash_expenditure'
      search = "#{prefix_code}/#{dept_prefix}/#{year_yy}/#{month_mm}/"
      records = records.where("number LIKE ?", "#{search}%")
    when 'cash_settlement' 
      search = "/#{dept_prefix}/#{year_yy}/#{month_mm}/"
      records = records.where("number LIKE ?", "%#{search}%").order("id asc")
    end
    records = records.order("number asc")

    case ctrl 
    when "sales_order"
      # seq 2 digit
      seq = (records.present? ? records.last.number.to_s[i,2].to_i+1 : 1)
      length_seq = seq.to_s.length

      if length_seq == 1 
        number = "0"+seq.to_s
      else
        number = seq.to_s
      end
    when "payment_request_supplier", "inventory_adjustment","sterilization_product_receiving","virtual_receiving","material_receiving","material_outgoing", "finish_good_receiving", "semi_finish_good_receiving", "semi_finish_good_outgoing", "shop_floor_order", "shop_floor_order_sterilization", "invoice_customer","purchase_order_supplier", "purchase_request","routine_cost",'routine_cost_payment','cash_submission','cash_settlement','proof_cash_expenditure'
      # seq 3 digit
      case ctrl
      when "purchase_order_supplier", "payment_request_supplier","routine_cost",'routine_cost_payment','cash_submission','cash_settlement','proof_cash_expenditure'
        seq = (records.present? ? "#{records.last.number}".last(3).to_i+1 : 1)
      else
        seq = (records.present? ? records.last.number.to_s[i,3].to_i+1 : 1)
      end

      length_seq = seq.to_s.length

      if length_seq == 1 
        number = "00"+seq.to_s
      elsif length_seq == 2 
        number = "0"+seq.to_s
      else
        number = seq.to_s
      end
    else
      # seq 4 digit
      case ctrl
      when "invoice_supplier_receiving", "direct_labor", "production_order","pdm"
        seq = (records.present? ? "#{records.last.number}".last(4).to_i+1 : 1)
      else
        seq = (records.present? ? records.last.number.to_s[i,4].to_i+1 : 1)
      end
      length_seq = seq.to_s.length

      if length_seq == 1 
        number = "000"+seq.to_s
      elsif length_seq == 2 
        number = "00"+seq.to_s
      elsif length_seq == 3 
        number = "0"+seq.to_s
      else
        number = seq.to_s
      end
    end

    case ctrl 
    when "delivery_order","picking_slip","direct_labor", "production_order","pdm","product_receiving","delivery_order_supplier","general_receiving","consumable_receiving","equipment_receiving"
      seq_number = "#{prefix_code}#{year_yy}#{month_mm}#{number}"
    when "purchase_request","material_outgoing","virtual_receiving","material_receiving","sterilization_product_receiving","finish_good_receiving","invoice_supplier_receiving"
      seq_number = "#{prefix_code}/#{year_yy}/#{month_mm}/#{number}" 
    when "purchase_order_supplier"
      seq_number = "#{prefix_code}/#{year_yy}/#{RomanNumerals.to_roman(period.strftime("%m").to_i)}/#{number}" 
    when "invoice_customer"
      case period.strftime("%m")
      when '01'
        alphabet_month = 'A'
      when '02'
        alphabet_month = 'B'
      when '03'
        alphabet_month = 'C'
      when '04'
        alphabet_month = 'D'
      when '05'
        alphabet_month = 'E'
      when '06'
        alphabet_month = 'F'
      when '07'
        alphabet_month = 'G'
      when '08'
        alphabet_month = 'H'
      when '09'
        alphabet_month = 'I'
      when '10'
        alphabet_month = 'J'
      when '11'
        alphabet_month = 'K'
      when '12'
        alphabet_month = 'L'
      end
      seq_number = "#{year_yy}#{alphabet_month}#{number}" 
    when "sales_order"
      seq_number = "#{prefix_code}/#{number}/#{RomanNumerals.to_roman(period.strftime("%m").to_i)}/#{year_yyyy}"
    when "payment_request_supplier"
      seq_number = "#{prefix_code}/#{year_yyyy}/#{month_to_letter[month_mm.to_i]}/#{number}"
    when 'routine_cost','routine_cost_payment','cash_submission','cash_settlement','proof_cash_expenditure'
      seq_number = "#{prefix_code}/#{dept_prefix}/#{year_yy}/#{month_mm}/#{number}"
    else
      seq_number = prefix_code+"/"+year_yy+"/"+month_mm+"/"+number
    end
    puts "new number: #{seq_number}"
    return seq_number
  end

  task :task_update_outstanding => :environment do |t, args|
    PurchaseOrderSupplier.where(:note_system=> nil).each do |po|
      po.update(:note_system=> 'perbaikan outstanding') if po.note_system == nil
      puts "#{po.number} => #{po.outstanding}"
    end
  end

  task :task_20210921 => :environment do |t, args|

    # material_receiving_items = MaterialReceivingItem.where(:status=> 'active').includes(:material_receiving).where(:material_receivings=> {:company_profile_id=> 1, :status=> 'approved3'})
    # product_receiving_items  = ProductReceivingItem.where(:status=> 'active').includes(:product_receiving).where(:product_receivings=> {:company_profile_id=> 1, :status=> 'approved3'})
    # consumable_receiving_items  = ConsumableReceivingItem.where(:status=> 'active').includes(:consumable_receiving).where(:consumable_receivings=> {:company_profile_id=> 1, :status=> 'approved3'})
    # equipment_receiving_items  = EquipmentReceivingItem.where(:status=> 'active').includes(:equipment_receiving).where(:equipment_receivings=> {:company_profile_id=> 1, :status=> 'approved3'})
    # general_receiving_items  = GeneralReceivingItem.where(:status=> 'active').includes(:general_receiving).where(:general_receivings=> {:company_profile_id=> 1, :status=> 'approved3'})
    

    purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:status=> 'active')
    .includes(:purchase_order_supplier, 
      purchase_request_item: [:purchase_request, product: [:unit], material: [:unit], consumable:[:unit], general:[:unit], equipment:[:unit]], 
      pdm_item: [:pdm, material: [:unit]],
      material_receiving_items: [:material_receiving], 
      product_receiving_items: [:product_receiving], 
      consumable_receiving_items: [:consumable_receiving], 
      equipment_receiving_items: [:equipment_receiving], 
      general_receiving_items: [:general_receiving]
    ).where(:purchase_order_suppliers=> {:company_profile_id=> 1, :status=> 'approved3'})

    # puts purchase_order_supplier_items
    purchase_order_supplier_items.each do |po_item|
      sum_grn = 0
      if po_item.purchase_request_item.present? 
        record_item = po_item.purchase_request_item 
        if record_item.present? 
           if record_item.product.present? 
             part = record_item.product 
           elsif record_item.material.present? 
             part = record_item.material 
           elsif record_item.consumable.present? 
             part = record_item.consumable 
           elsif record_item.equipment.present? 
             part = record_item.equipment 
           elsif record_item.general.present? 
             part = record_item.general 
           end 
        end 
        unit_name = (part.present? ? part.unit_name : nil)
        prf_number =  record_item.purchase_request.number 
        prf_date =  record_item.purchase_request.date 
      elsif po_item.pdm_item.present? 
        record_item = po_item.pdm_item 
        if record_item.present? 
          if record_item.material.present? 
            part = record_item.material 
          end 
          prf_number =  record_item.pdm.number 
          prf_date =  record_item.pdm.date 
        end 
      end 
      sum_grn_material = 0
      po_item.material_receiving_items.each do |grn_item| 
        sum_grn_material += grn_item.quantity if grn_item.material_receiving.status == 'approved3'
      end
      sum_grn += sum_grn_material

      sum_grn_product = 0
      po_item.product_receiving_items.each do |grn_item| 
        sum_grn_product += grn_item.quantity if grn_item.product_receiving.status == 'approved3'
      end
      sum_grn += sum_grn_product

      sum_grn_consumable = 0
      po_item.consumable_receiving_items.each do |grn_item| 
        sum_grn_consumable += grn_item.quantity if grn_item.consumable_receiving.status == 'approved3'
      end
      sum_grn += sum_grn_consumable

      sum_grn_equipment = 0
      po_item.equipment_receiving_items.each do |grn_item| 
        sum_grn_equipment += grn_item.quantity if grn_item.equipment_receiving.status == 'approved3'
      end
      sum_grn += sum_grn_equipment

      sum_grn_general = 0
      po_item.general_receiving_items.each do |grn_item| 
        sum_grn_general += grn_item.quantity if grn_item.general_receiving.status == 'approved3'
      end
      sum_grn += sum_grn_general

      outstanding = po_item.quantity.to_f - sum_grn.to_f
      if outstanding != po_item.outstanding
        puts "#{po_item.purchase_order_supplier.number} => #{po_item.id} "
        puts "  sum material_receiving_items: #{sum_grn_material}"
        puts "  sum product_receiving_items: #{sum_grn_product}"
        puts "  sum consumable_receiving_items: #{sum_grn_consumable}"
        puts "  sum equipment_receiving_items: #{sum_grn_equipment}"
        puts "  sum general_receiving_items: #{sum_grn_general}"
        puts "PO qty: #{po_item.quantity}; outstanding: #{po_item.outstanding} => #{outstanding}"
        po_item.update(:outstanding=> outstanding)
        puts "----------------------------------------------------------------"
      end
    end
  end

  task :task_20210915 => :environment do |t, args|
    array = [
      {:invoice_number=> "21H044", :part_id=> "SGAA", :product_name=> "Sterilisasi Rutin PT Maesindo", :product_type=> "Medical Apparel", :currency=> "IDR", :value_old=> "1083333.33", :value_new=> "1083333.333333330000"},
      {:invoice_number=> "21H042", :part_id=> "SGAA", :product_name=> "Sterilisasi Rutin PT Maesindo", :product_type=> "Medical Apparel", :currency=> "IDR", :value_old=> "1083333.33", :value_new=> "1083333.333333330000"},
      {:invoice_number=> "21H035", :part_id=> "SGAA", :product_name=> "Sterilisasi Rutin PT Maesindo", :product_type=> "Medical Apparel", :currency=> "IDR", :value_old=> "1083333.33", :value_new=> "1083333.333333330000"},
      {:invoice_number=> "21H034", :part_id=> "SGAA", :product_name=> "Sterilisasi Rutin PT Maesindo", :product_type=> "Medical Apparel", :currency=> "IDR", :value_old=> "1083333.33", :value_new=> "1083333.333333330000"},
      {:invoice_number=> "21H021", :part_id=> "SGAA", :product_name=> "Sterilisasi Rutin PT Maesindo", :product_type=> "Medical Apparel", :currency=> "IDR", :value_old=> "1083333.33", :value_new=> "1083333.333333330000"},
      {:invoice_number=> "21H009", :part_id=> "AABC", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size L", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21H008", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21H007", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21H006", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21H001", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21H001", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21G057", :part_id=> "AABU", :product_name=> "B-Safe Sterile Isolation Gown", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "23320.00", :value_new=> "21200.000000000000"},
      {:invoice_number=> "21G029", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21G028", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21G010", :part_id=> "AABD", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size XL", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21F032", :part_id=> "AABC", :product_name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :product_type=> "Size L", :currency=> "IDR", :value_old=> "77272.73", :value_new=> "77272.727272727300"},
      {:invoice_number=> "21F029", :part_id=> "AABW", :product_name=> "BIOCARE Sterile Disposable Protective Coverall", :product_type=> "All Size", :currency=> "IDR", :value_old=> "68181.82", :value_new=> "68181.818181818200"},
      {:invoice_number=> "21E031", :part_id=> "AABW", :product_name=> "BIOCARE Sterile Disposable Protective Coverall", :product_type=> "All Size", :currency=> "IDR", :value_old=> "68181.82", :value_new=> "70000.000000000000"},
      {:invoice_number=> "21E014", :part_id=> "AABW", :product_name=> "BIOCARE Sterile Disposable Protective Coverall", :product_type=> "All Size", :currency=> "IDR", :value_old=> "68181.82", :value_new=> "68181.818181818200"},
      {:invoice_number=> "21E013", :part_id=> "AABW", :product_name=> "BIOCARE Sterile Disposable Protective Coverall", :product_type=> "All Size", :currency=> "IDR", :value_old=> "68181.82", :value_new=> "68181.818181818200"},
      {:invoice_number=> "21D029", :part_id=> "AABW", :product_name=> "BIOCARE Sterile Disposable Protective Coverall", :product_type=> "All Size", :currency=> "IDR", :value_old=> "68181.82", :value_new=> "68181.818181818200"},
      {:invoice_number=> "21D004", :part_id=> "AABW", :product_name=> "BIOCARE Sterile Disposable Protective Coverall", :product_type=> "All Size", :currency=> "IDR", :value_old=> "68181.82", :value_new=> "68181.818181818200"},
      {:invoice_number=> "21C016", :part_id=> "AUCE", :product_name=> "SFG - Overboot Cover Bulk PP Size Besar (with Plastic Bag)", :product_type=> "PP with plastic bag", :currency=> "IDR", :value_old=> "5455.00", :value_new=> "5454.545454545450"},
      {:invoice_number=> "20L006", :part_id=> "KAAA", :product_name=> "PRK Sterile Eye Shield", :product_type=> "Universal", :currency=> "IDR", :value_old=> "3755.00", :value_new=> "3413.636363636360"},
      {:invoice_number=> "20L006", :part_id=> "KAAA", :product_name=> "PRK Sterile Eye Shield", :product_type=> "Universal", :currency=> "IDR", :value_old=> "3755.00", :value_new=> "3413.636363636360"},
      {:invoice_number=> "20L006", :part_id=> "KAAA", :product_name=> "PRK Sterile Eye Shield", :product_type=> "Universal", :currency=> "IDR", :value_old=> "3755.00", :value_new=> "3413.636363636360"},
      {:invoice_number=> "20L006", :part_id=> "KAAA", :product_name=> "PRK Sterile Eye Shield", :product_type=> "Universal", :currency=> "IDR", :value_old=> "3755.00", :value_new=> "3413.636363636360"},
      {:invoice_number=> "20L006", :part_id=> "KAAA", :product_name=> "PRK Sterile Eye Shield", :product_type=> "Universal", :currency=> "IDR", :value_old=> "3755.00", :value_new=> "3413.636363636360"},
      {:invoice_number=> "20K014", :part_id=> "AAAW", :product_name=> "B-Safe Sterile Surgical Gown", :product_type=> "Size L", :currency=> "IDR", :value_old=> "25960.00", :value_new=> "23600.000000000000"},
      {:invoice_number=> "20J025", :part_id=> "AAAW", :product_name=> "B-Safe Sterile Surgical Gown", :product_type=> "Size L", :currency=> "IDR", :value_old=> "25960.00", :value_new=> "23600.000000000000"},
      {:invoice_number=> "20G006", :part_id=> "SGAA", :product_name=> "Sterilisasi Rutin PT Maesindo", :product_type=> "Medical Apparel", :currency=> "IDR", :value_old=> "46428.60", :value_new=> "46428.571428571400"},

    ]
    array.each do |item|
      invoice = InvoiceCustomer.find_by(:number=> item[:invoice_number], :company_profile_id=> 1)
      if invoice.present?
        product = Product.find_by(:part_id=> item[:part_id])
        if product.present?
          invoice_item = InvoiceCustomerItem.find_by(:invoice_customer_id=> invoice.id, :product_id=> product.id)
          if invoice_item.present?
            selisih = (item[:value_new].to_f - invoice_item.unit_price.to_f)
            if selisih == 0
            else
              puts "[#{invoice.status}] old: #{invoice_item.unit_price} => new: #{item[:value_new]} (#{selisih})"
              price_log = InvoiceCustomerPriceLog.find_by({
                :company_profile_id=> invoice.company_profile_id,
                :invoice_customer_id=> invoice.id,
                :invoice_customer_item_id=> invoice_item.id,
                :status=> 'active'
              })
              if price_log.present?
                price_log.update({:status=> 'deleted', :deleted_at=> DateTime.now(), :deleted_by=> 1, :remarks=> "dihapus karena ada pengajuan harga baru"})
              end

              InvoiceCustomerPriceLog.create({
                :company_profile_id=> invoice.company_profile_id,
                :invoice_customer_id=> invoice.id,
                :invoice_customer_item_id=> invoice_item.id,
                :old_price=> invoice_item.unit_price,
                :new_price=> item[:value_new],
                :status=> 'active',
                :created_at=> DateTime.now(), 
                :created_by=> 1
              })
            end
          else
            puts "invoice_customer_id: #{invoice.id}"
            puts "product_id: #{product.id}"
            puts "invoice item not found!"
            puts "------------------------"
          end
        else
          puts "product #{item[:part_id]} not found!"
        end
      else
        puts "invoice #{item[:invoice_number]} not found!"
      end
    end
  end

  task :sales_order_check => :environment do |t, args|
    # PP/PIF/01/I/2021','PP/PIF/15/I/2021
    # PP/PIF/23/III/2021
    SalesOrder.where(:number=> ['PP/PIF/01/I/2021']).each do |so|
      puts "SO: #{so.number}"
      puts "po_amount2: #{so.po_amount2}"
      puts "po_amount: #{so.po_amount}"
      
      # step_1(so.sales_order_items, 1)
      puts "==================================="
    end

  end
  
  def step_4(so_number, count_check)
    # SalesOrder.where(:number=> so_number).each do |so|
    #   puts "SO: #{so.number} => count_check: #{count_check}"
    #   step_1(so.sales_order_items, count_check)
    #   puts "==================================="
    # end
  end

  def step_3(po_items, count_check)
    number = []
    po_items.each do |po_item|
      puts "   PO: #{po_item.purchase_order_supplier.number} -> total_price: #{po_item.total_price}; quantity: #{po_item.quantity}; outstanding PO: #{po_item.outstanding}"
      puts "   GRN: "
      po_item.material_receiving_items.each do | grn_item| 
        puts "    #{grn_item.material_receiving.number} => quantity: #{grn_item.quantity}; GRN Price: #{grn_item.quantity * po_item.unit_price}"
        sum_spp_quantity = 0
        grn_item.purchase_order_supplier_item.purchase_request_item.production_order_used_prves.each do |detail_spp_by_prf|
          spp_quantity = detail_spp_by_prf.production_order_detail_material.quantity
          sum_spp_quantity += spp_quantity
        end
        puts "Sum SPP: #{sum_spp_quantity}"

        po_number = grn_item.purchase_order_supplier_item.purchase_order_supplier.number
        po_amount = grn_item.purchase_order_supplier_item.total_price
        po_by_spp_amount = 0
        result2  = 0
        grn_item.purchase_order_supplier_item.purchase_request_item.production_order_used_prves.each do |detail_spp_by_prf|
          spp_number = detail_spp_by_prf.production_order_item.production_order.number
          so_number = detail_spp_by_prf.production_order_item.sales_order_item.sales_order.number
          prf_number = detail_spp_by_prf.purchase_request_item.purchase_request.number
          prf_quantity = detail_spp_by_prf.purchase_request_item.quantity
          spp_quantity = detail_spp_by_prf.production_order_detail_material.quantity

          number << so_number

          percent_by_spp_qty = spp_quantity/sum_spp_quantity
          result1 = percent_by_spp_qty*grn_item.quantity
          result2 += result1

          puts "   SO: #{so_number};"
          puts "   PRF: #{prf_number} Qty: #{prf_quantity}; => #{prf_quantity-result1}"
          puts "   SPP: #{spp_number} Qty: #{spp_quantity};"
          puts "   PO: #{po_number} Amount: #{po_amount};"
          puts "   PO by SPP: #{spp_quantity*po_item.unit_price}"
          po_by_spp_amount += spp_quantity*po_item.unit_price
          puts "   (#{percent_by_spp_qty} %)"
          puts "   (#{spp_quantity}/#{sum_spp_quantity})*#{grn_item.quantity} => #{result1} "
          puts "  "
        end
        puts "result2: #{result2}"
        # puts po_by_spp_amount
        # puts po_by_spp_amount-po_amount
        puts "   ------------------------------- <<"
      end
      # if count_check > 2
        count_check = 0
      # end
      # po_item.so_selected.each do |so_check|
      #   step_4(so_check[:so_number], count_check)
      # end
      # puts "   SO: #{po_item.so_selected.map { |e| e[:so_number] }}"
      # number += po_item.so_selected
    end
    puts number.uniq.count
    puts "-------------------------"
  end

  def step_2(spp_records, count_check)
    spp_records.each do |detail|
      puts "   purchase_request_item_id: #{detail.purchase_request_item_id} => #{detail.purchase_request_item.material.part_id if detail.purchase_request_item.material.present?}"
      
      step_3(detail.purchase_request_item.purchase_order_supplier_items, count_check)
    end
  end

  def step_1(so_items, count_check)
    so_items.each do |item|
      puts "part_id: #{item.product.part_id}"
      puts "  SO Qty : #{item.quantity}"
      item.production_order_items.each do |spp_item|
        puts "  SPP Qty: #{spp_item.quantity}"
        puts "  spp item id: #{spp_item.id}"

        step_2(spp_item.production_order_used_prves, count_check+1)
      end
    end if count_check > 0
  end

  task :check_spp_items => :environment do |t, args|
    # ga bisa
    ProductionOrderItem.where(:status=> 'active').includes(:production_order)
    .where(:production_orders=> {:company_profile_id=> 1, :status=> 'approved3', :number=> 'SPP21020011'}).order("production_orders.date asc").each do |item|
      puts item.production_order.number
      puts "old so_item_id: #{item.sales_order_item_id}"
      new_so_item_id = nil
      SalesOrderItem.where(:sales_order_id=> item.sales_order_item.sales_order_id, :product_id=> item.product_id, :quantity=> item.quantity).each do |so_item|
        puts "  so_item: #{so_item.id}; => #{so_item.status}"
        new_so_item_id = so_item.id if so_item.status == 'active'
      end
      if new_so_item_id.present? and item.sales_order_item_id != new_so_item_id
        puts "so_item updated! #{new_so_item_id}" 
        # item.update_columns(:sales_order_item_id=> new_so_item_id)
        x
      end
      puts "-------------------------------------------"
    end
  end

  task :perbaikan_stock_20210813_material => :environment do |t, args|
    material = Material.find_by(:part_id=> 'B321')
    prev_stock = prev_periode = nil
    InventoryBatchNumber.where(:material_id=> material.id).where("periode like ? ", '2021%').order("periode asc").includes(:material).each do |bn|
      if bn.material.present?
        puts "#{bn.material.part_id} => #{bn.material_batch_number.number}"
        bn.update({:updated_at=> DateTime.now()})
      end
    end
    puts "------------------"
    Inventory.where(:material_id=> material.id).where("periode like ? ", '202101').order("periode asc").includes(:material).each do |bn|
      if bn.material.present?
        puts bn.material.part_id
        bn.update({:updated_at=> DateTime.now()})
      end
    end
  end

  task :perbaikan_stock_20210813 => :environment do |t, args|
    product = Product.find_by(:part_id=> 'AUGM')
    prev_stock = {}
    prev_periode = nil

    ( DateTime.now().at_beginning_of_year.strftime("%Y%m") .. DateTime.now().at_end_of_month.strftime("%Y%m") ).each do |periode|
      ProductBatchNumber.where(:company_profile_id=> 1, :product_id=> product.id, :status=> 'active', :periode_yyyy=> periode.to_s[0..3]).each do |bn|
        ibn = InventoryBatchNumber.find_by(:product_id=> product.id, :periode=> periode, :product_batch_number_id=> bn.id, :company_profile_id=> 1)
        if ibn.present?
          puts "[#{ibn.periode}] #{ibn.product.part_id} => #{ibn.product_batch_number.number} => created_at: #{bn.created_at}"
          puts "#{prev_stock[ibn.id][:stock]}" if prev_stock.present? and prev_stock[ibn.id].present?
          ibn.update({:updated_at=> DateTime.now()})
          prev_stock[ibn.id] ||= {}
          prev_stock[ibn.id][:stock] = ibn.end_stock
        else
          ibn = InventoryBatchNumber.new({
            :product_id=> product.id, 
            :product_batch_number_id=> bn.id,
            :periode=> periode, 
            :company_profile_id=> 1,
            :begin_stock=> prev_stock[ibn.id][:stock], 
            :trans_in=> 0, 
            :trans_out=> 0, 
            :end_stock=> prev_stock, 
            :created_at=> DateTime.now()
          })
          ibn.save!
        puts "create!"
        end
      end
      puts "----------------------------- #{periode}"
    end

    puts "------------------"
    Inventory.where(:product_id=> product.id).where("periode like ? ", '202101').order("periode asc").includes(:product).each do |bn|
      if bn.product.present?
        puts bn.product.part_id
        bn.update({:updated_at=> DateTime.now()})
      end
    end
    # Inventory.where(:product_id=> product.id).order("periode asc").limit(1).each do |inventory|
    #   # if prev_stock.present?
    #   #   if prev_stock != inventory.begin_stock
    #   #     puts "prev periode: #{prev_periode}"
    #   #     puts "  -> #{prev_stock}"
    #   #     puts "current periode: #{inventory.periode}"
    #   #     puts "  -> #{inventory.begin_stock}"
    #   #     puts "---------------"
    #       inventory.update({:note=> 'Open stock otomatis'})
    #       # bn_prev_stock = bn_prev_periode = nil
    #       # InventoryBatchNumber.where(:product_id=> inventory.product_id, :periode=> inventory.periode).order("periode asc").each do |bn|
    #       #   if prev_stock.present?
    #       #     if prev_stock != inventory.begin_stock
    #       #       puts bn.product_batch_number.number
    #       #     end
    #       #   end
    #       #   bn_prev_periode = bn.periode
    #       #   bn_prev_stock = bn.end_stock
    #       # end
    #     # end
    #     # puts "#{prev_stock} - periode: #{inventory.periode}; begin: #{inventory.begin_stock}; in: #{inventory.trans_in}; out: #{inventory.trans_out}; end: #{inventory.end_stock}"
    #   # end

    #   # prev_periode = inventory.periode
    #   # prev_stock = inventory.end_stock
    # end
  end
  task :perbaikan_material_outgoing => :environment do |t, args|
    MaterialOutgoing.where("shop_floor_order_id > 0").order("created_at asc").each do |record|
      puts "Material Issue: #{record.number};"
      puts "SFO: #{record.shop_floor_order.number};"
      record.shop_floor_order.update_columns(:material_outgoing_id=> record.id)
      puts "------------------------------------"
    end
  end


  task :perbaikan_sfo => :environment do |t, args|
    subject_mail = "SFO Provital #{DateTime.now()}"
    content_mail = ""
    ShopFloorOrderItem.where("sales_order_id is null").where(:status=> 'active').order("created_at asc, product_id asc").each do |item|
      # if item.shop_floor_order.number == 'SFO/21/02/004'
        header_remarks = item.shop_floor_order.remarks
        # content_mail += "<div><div>SFO: #{item.shop_floor_order.number} </div>"
        # content_mail += "<div>Remarks: #{header_remarks} </div>"
        puts "SFO id: #{item.shop_floor_order_id}; item id: #{item.id}"
        puts "SFO: #{item.shop_floor_order.number}"
        puts "Product: #{item.product.part_id if item.product.present?}"
        puts "remarks: #{header_remarks}"

        header_remarks = header_remarks.gsub(/[()]/, "") if header_remarks.present?
        header_remarks = header_remarks.gsub(/[,]/, " ") if header_remarks.present?
        po_numbers = header_remarks.split(" ") if header_remarks.present?
        c =1
        po_numbers.each do |po_number|
          sales_order = SalesOrder.find_by(:po_number=> po_number) if po_number.present?
          if sales_order.present?
            sales_order_item = SalesOrderItem.find_by(:sales_order_id=> sales_order.id, :product_id=> item.product_id, :quantity=> item.quantity) 
            if sales_order_item.present?
              puts "[#{c}] SO: #{sales_order.number}; PO:#{sales_order.po_number}"
              puts "   SO Item: #{sales_order_item.quantity}"
              item.update_columns({
                :remark_system=> 'rake perbaikan_sfo',
                :sales_order_id=> sales_order.id
              })
              c+=1
            end
          end
        end if po_numbers.present?
        puts "-----------------------------------------"

        # content_mail += "<div>Split by remarks: #{po_number} </div></div>"

        # content_mail += "<div>-------------------------------</div>"
      # end
    end
    # puts content_mail
    # UserMailer.tiki("aden.pribadi@gmail.com", subject_mail, content_mail.html_safe, nil).deliver!
  end

  task :stock_calculation, [:plant] => :environment do |t, args|
    periode = DateTime.now().strftime("%Y%m")  
    prev_periode = "#{DateTime.now()-1.month}".to_datetime.strftime("%Y%m")

    prev_stock = 0
    Inventory.where(:material_id=> 181).where('periode >= ?', '202101').order("periode asc").each do |stock|
      trans_in = trans_out = 0
      InventoryLog.where(:inventory_id=> stock.id, :status=> 'active').order("created_at asc").each do |log|
        case log.kind
        when 'in'
          trans_in += log.quantity
        when 'out'
          trans_out += log.quantity
        end
        # puts "   [#{log.id}] log: #{log.kind} => #{log.quantity}"
      end
      check_trans_in = (trans_in.to_f == stock.trans_in.to_f)
      check_trans_out = (trans_out.to_f == stock.trans_out.to_f)
      puts "periode  : #{stock.periode}"
      puts "begin    : #{stock.begin_stock}; #{prev_stock == stock.begin_stock}"
      puts "stock in : #{stock.trans_in}; #{check_trans_in}"
      puts "stock out: #{stock.trans_out}; #{check_trans_out ? nil : trans_out}"
      puts "end stock: #{stock.end_stock};"
      prev_stock = stock.end_stock
      puts "------------------------------"
    end
  end
  task :perbaikan_stock, [:plant, :prefix] => :environment do |t, args|
    periode = DateTime.now().strftime("%Y%m")  
    prev_periode = "#{DateTime.now()-1.month}".to_datetime.strftime("%Y%m")

    case args[:prefix]
    when 'P'
      prefix = 'P'
      eng_parts = Product.where(:company_profile_id=> args[:plant], :status=> 'active')
    when 'M'
      prefix = 'M'
      eng_parts = Material.where(:company_profile_id=> args[:plant], :status=> 'active', :part_id=> 'B281')
    end

    eng_parts.each do |part|
      puts part.part_id
      
      case args[:prefix]
      when 'P'
        stock = Inventory.find_by(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> periode)
        stocks = Inventory.where(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode).order("periode desc").limit(1)
        stock_bm_prev = InventoryBatchNumber.where(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode)
      when 'M'
        stock = Inventory.find_by(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> periode)
        stocks = Inventory.where(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode).order("periode desc").limit(1)
        stock_bm_prev = InventoryBatchNumber.where(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode)
      end
      
      if stock.present?
        puts "[#{stock.periode}] begin: #{stock.begin_stock}; trans_in: #{stock.trans_in}; trans_out: #{stock.trans_out}; End: #{stock.end_stock}"
        
        last_qty = (stocks.present? ? stocks.first.end_stock : 0)
        puts "inventory_id: #{stock.id}"
        sum_trans_in = 0
        sum_trans_out = 0
        InventoryLog.where(:inventory_id=> stock.id, :status=> 'active').each do |log|
          puts "#{log.kind} => #{log.quantity}"
          case log.kind
          when 'in'
            sum_trans_in += log.quantity
          when 'out'
            sum_trans_out += log.quantity
          end
        end
        stock.update_columns({:begin_stock=> last_qty, :trans_in=> sum_trans_in, :trans_out=> sum_trans_out})
      end
    end
  end
  task :update_bn_grn => :environment do |t, args|
    MaterialBatchNumber.where(:material_receiving_item_id=> nil).each do |item|
      MaterialReceivingItem.where(:material_receiving_id=> item.material_receiving_id, :material_id=> item.material_id).each do |grn_item|
        puts "grn item id #{item.material_receiving_item_id} => #{grn_item.id} "
        puts "batch_number_id #{grn_item.material_batch_number_id} => #{item.id}"
        item.update_columns({
          :material_receiving_item_id=> grn_item.id
        })
        grn_item.update_columns({
          :material_batch_number_id=> item.id
        })
      end
    end
  end
  
  task :get_account_tele => :environment do |t, args|
    
    ActiveRecord::Base.establish_connection :development
    require 'telegram/bot'
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|        
        case message.text
        when '/start'
          bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.chat.first_name}")
          puts "#{message.chat.id} - #{message.chat.first_name}"
          ActiveRecord::Base.establish_connection :production 
          check_tele = AppTelegram.find_by(:telegram_id=> message.chat.id)
          if check_tele.blank?
            AppTelegram.create({
              :telegram_id=> message.chat.id,
              :first_name=> message.chat.first_name,
              :last_name=> message.chat.last_name,
              :status=> 'active',
              :created_by=> 1, 
              :created_at=> DateTime.now()
            })
          else
            check_tele.update_columns({
              :first_name=> message.chat.first_name,
              :last_name=> message.chat.last_name, :description=> nil})
          end
        end if message.present?
      end
    end
  end

  task :send_notif_approval_bpk => :environment do |t, args|
    require 'telegram/bot' 
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
    ActiveRecord::Base.establish_connection :development
    periode_begin = DateTime.now().strftime("%Y-%m-%d")
    periode_end   = DateTime.now().strftime("%Y-%m-%d")
    chat_account = [1355531784]
    
    ProofCashExpenditure.where(:status=> 'approved2').order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/proof_cash_expenditures/#{record.id}?"
      msg = "Bukti Pengeluaran Kas: #{record.number} butuh approve 3 \n"
      
      Telegram::Bot::Client.run(token) do |bot|
        chat_account.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
          puts msg
        end
      end if chat_account.present?
    end 
    CashSubmission.where(:status=> 'approved2').order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/cash_submissions/#{record.id}?"
      msg = "Pengajuan Kasbon: #{record.number} butuh approve 3 \n"
      
      Telegram::Bot::Client.run(token) do |bot|
        chat_account.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
          puts msg
        end
      end if chat_account.present?
    end 
    CashSettlement.where(:status=> 'approved2').order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/cash_settlements/#{record.id}?"
      msg = "Penyelesaian Kasbon: #{record.number} butuh approve 3 \n"
      
      Telegram::Bot::Client.run(token) do |bot|
        chat_account.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
          puts msg
        end
      end if chat_account.present?
    end    
  end
  task :send_notif_approval_so => :environment do |t, args|
    require 'telegram/bot' 
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
    ActiveRecord::Base.establish_connection :development
    periode_begin = DateTime.now().strftime("%Y-%m-%d")
    periode_end   = DateTime.now().strftime("%Y-%m-%d")
    SalesOrder.where(:status=> ['new','approved1','canceled1','approved2','canceled2','canceled3','approved3']).where("date between ? and ?", periode_begin, periode_end).order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/sales_orders/#{record.id}?"
      msg = nil
      chat_account = nil
      
      case record.status
      when 'approved2','canceled3'
        # butuh approve 3
        msg = "#{record.number} butuh approve 3 \n"
        # suci
        chat_account = [1101758047]
      when 'approved1','canceled2'
        # butuh approve 2
        msg = "#{record.number} butuh approve 2 \n"
        # samsudin, dipta
        chat_account = [1374188580, 655277738]
      when 'approved3'
        # setelah approve 3 
        msg = "#{record.number} sudah approve 3 \n"
        # samsudin
        chat_account = [1374188580]
      end
      Telegram::Bot::Client.run(token) do |bot|
        chat_account.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
          puts msg
        end
      end if chat_account.present?
    end    
  end

  task :send_notif_approval_prf => :environment do |t, args|
    require 'telegram/bot' 
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
    ActiveRecord::Base.establish_connection :development
    periode_begin = (DateTime.now()-3.month).strftime("%Y-%m-%d")
    periode_end   = DateTime.now().strftime("%Y-%m-%d")
    PurchaseRequest.where(:status=> ['new','approved1','canceled1','approved2','canceled2','canceled3']).where("date between ? and ?", periode_begin, periode_end).order("date asc, status asc").each do |prf|
      url_link = "https://erp.tri-saudara.com/purchase_requests/#{prf.id}?q=#{prf.request_kind}"
      msg = nil
      chat_id = nil
      case prf.status
      when 'approved2','canceled3'
        # butuh approve 3
        msg = "#{prf.number} butuh approve 3 \n"
        # pak johnny
        chat_id = 1355531784
      when 'approved1','canceled2'
        # butuh approve 2
        msg = "#{prf.number} butuh approve 2 \n"
        chat_id = 655277738
      end
      Telegram::Bot::Client.run(token) do |bot|
        bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
      end if chat_id.present?
    end    
  end

  task :send_notif_approval_po => :environment do |t, args|
    require 'telegram/bot' 
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
    ActiveRecord::Base.establish_connection :development
    periode_begin = (DateTime.now()-3.month).strftime("%Y-%m-%d")
    # periode_end   = DateTime.now().strftime("%Y-%m-%d")
    # 2022-03-23 request pak johnny
    periode_end   = (DateTime.now()+2.weeks).strftime("%Y-%m-%d")
    puts "between #{periode_begin} and #{periode_end}"
    PurchaseOrderSupplier.where(:status=> ['new','approved1','canceled1','approved2','canceled2','canceled3']).where("date between ? and ?", periode_begin, periode_end).order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/purchase_order_suppliers/#{record.id}?q=#{record.kind}"
      msg = nil
      chat_id = nil
      case record.status
      when 'approved2','canceled3'
        # butuh approve 3
        msg = "#{record.number} butuh approve 3 \n"
        # pak johnny
        chat_id = 1355531784
      when 'approved1','canceled2'
        # butuh approve 2
        msg = "#{record.number} butuh approve 2 \n"
        chat_id = 655277738
      end
      Telegram::Bot::Client.run(token) do |bot|
        bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
      end if chat_id.present?
    end    
  end

  task :send_notif_approval_grn => :environment do |t, args|
    # pada jam 06:58 dan 11:58 dan 17:58 akan kirim reminder kepada approval1, 2 dan3 jika ada GRN/PRN yg belum di approve1 (baru dibuat)
    require 'telegram/bot' 
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
    ActiveRecord::Base.establish_connection :development
    periode_begin = (DateTime.now()-3.month).strftime("%Y-%m-%d")
    periode_end   = DateTime.now().strftime("%Y-%m-%d")
    chat_id_collects = [303683673, 1374188580, 1464129287, 1698497988]
    MaterialReceiving.where(:status=> ['new', 'canceled1']).where("date between ? and ?", periode_begin, periode_end).order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/material_receivings/#{record.id}"
      
      msg = "#{record.number} belum approve1 \n"
        
      Telegram::Bot::Client.run(token) do |bot|
        chat_id_collects.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
        end
      end if chat_id_collects.present?
    end  
    ProductReceiving.where(:status=> ['new', 'canceled1']).where("date between ? and ?", periode_begin, periode_end).order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/product_receivings/#{record.id}"
           
      msg = "#{record.number} belum approve1 \n"
        
      Telegram::Bot::Client.run(token) do |bot|
        chat_id_collects.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
        end
      end if chat_id_collects.present?
    end    
  end
  task :send_notif_approval_grn_approve2 => :environment do |t, args|
    require 'telegram/bot' 
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
    ActiveRecord::Base.establish_connection :development
    periode_begin = (DateTime.now()-3.days).strftime("%Y-%m-%d")
    periode_end   = DateTime.now().strftime("%Y-%m-%d")
    # 303683673 aden
    # 1374188580 samsudin
    # 1464129287 dianing
    # 5425916494 agit
    send_message_status = false
    content_mail = "<table cellspacing='0' cellpadding='0' border='1'>
      <tr>
        <th>GRN Number</th>
        <th>GRN Date</th>
        <th>status</th>
        <th>approved2 at</th>
        <th>LINK</th>
      </tr>"
    chat_id_collects = [303683673, 1374188580, 1464129287, 5425916494]
    MaterialReceiving.where(:status=> ['approved2', 'canceled3']).where("date between ? and ?", periode_begin, periode_end).order("date asc, status asc").each do |record|
      send_message_status = true
      url_link = "https://erp.tri-saudara.com/material_receivings/#{record.id}"
      content_mail += "<tr>
          <td>#{record.number}</td>
          <td>#{record.date}</td>
          <td>#{record.status}</td>
          <td>#{record.approved2_at.strftime("%Y-%m-%d %H:%M:%S")}</td>
          <td>#{url_link}</td>
        </tr>
        "
      msg = "#{record.number} approved2 \n"
        
      Telegram::Bot::Client.run(token) do |bot|
        chat_id_collects.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
        end
      end if chat_id_collects.present?
    end  
    ProductReceiving.where(:status=> ['approved2', 'canceled3']).where("date between ? and ?", periode_begin, periode_end).order("date asc, status asc").each do |record|
      send_message_status = true
      url_link = "https://erp.tri-saudara.com/product_receivings/#{record.id}"
      content_mail += "<tr>
        <td>#{record.number}</td>
        <td>#{record.date}</td>
        <td>#{record.status}</td>
        <td>#{record.approved2_at.strftime("%Y-%m-%d %H:%M:%S")}</td>
        <td>#{url_link}</td>
      </tr>
      "
      msg = "#{record.number} approved2 \n"
        
      Telegram::Bot::Client.run(token) do |bot|
        chat_id_collects.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
        end
      end if chat_id_collects.present?
    end   
    subject_mail = "[ERP] Provital - List GRN approved2 - #{DateTime.now().strftime("%Y-%m-%d %H:%M:%S")}"
    mail_lists = ['aden.pribadi@gmail.com','purchasing@provitalperdana.com', 'samsudin@provitalperdana.com', 'dianing.astuti@provitalperdana.com']
    mail_lists.each do |mail|
      UserMailer.tiki(mail, subject_mail, content_mail.html_safe, nil).deliver! if send_message_status == true
    end
  end

  task :send_notif_approval_payreq => :environment do |t, args|
    require 'telegram/bot' 
    token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
    ActiveRecord::Base.establish_connection :development
    periode_begin = (DateTime.now()-3.month).strftime("%Y-%m-%d")
    periode_end   = DateTime.now().strftime("%Y-%m-%d")
    chat_id_collects = [1355531784]
    PaymentRequestSupplier.where(:status=> 'approved2').order("date asc, status asc").each do |record|
      url_link = "https://erp.tri-saudara.com/payment_request_suppliers/#{record.id}"
      
      msg = "#{record.number} butuh approve3 \n"
        
      Telegram::Bot::Client.run(token) do |bot|
        chat_id_collects.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
        end
      end if chat_id_collects.present?
    end  

  end

  task :open_stock, [:plant, :prefix] => :environment  do |t, args|  
    periode = DateTime.now().strftime("%Y%m")  
    prev_periode = "#{DateTime.now()-1.month}".to_datetime.strftime("%Y%m")

    # periode = '202107'
    # prev_periode = '202106'
    ActiveRecord::Base.establish_connection :development
    case args[:prefix]
    when 'E'
      prefix = 'E'
      eng_parts = Equipment.where(:company_profile_id=> args[:plant], :status=> 'active')
    when 'C'
      prefix = 'C'
      eng_parts = Consumable.where(:company_profile_id=> args[:plant], :status=> 'active')
    when 'G'
      prefix = 'G'
      eng_parts = General.where(:company_profile_id=> args[:plant], :status=> 'active')
    when 'P'
      prefix = 'P'
      eng_parts = Product.where(:company_profile_id=> args[:plant], :status=> 'active')
    when 'M'
      prefix = 'M'
      eng_parts = Material.where(:company_profile_id=> args[:plant], :status=> 'active')
      puts eng_parts.to_sql
    end
    c = 1

    path    = "#{Rails.root}/public/plant"+args[:plant].to_s+"_open_stock_bermasalah.txt"
    File.open(path, "a") do |f|
      f.puts "==========================================================================================================="
      f.puts "Daily JOBs - #{args[:prefix]} - #{args[:plant]} - #{periode} - vzveda - #{DateTime.now()}" 
      f.puts "-----------------------------------------------------------------------------------------------------------"
    end
    puts "Daily JOBs- #{args[:plant]} - #{periode} - vzveda"

    # for send mail
    filename_original = "open_stock_#{args[:plant]}_#{args[:prefix]}_#{periode}.txt"
    path2    = "#{Rails.root}/public/#{filename_original}"
    subject_mail = "Open Stock #{args[:prefix]}; plant: #{args[:plant]}; periode: #{periode};"
    content_mail = "Terlampir"

    eng_parts.each do |part|
      puts part.part_id
      retries = 0
      begin
      	case args[:prefix]
        when 'E'
          stock = Inventory.find_by(:equipment_id=> part.id, :company_profile_id=> args[:plant], :periode=> periode)
          stock_bm_prev = InventoryBatchNumber.where(:equipment_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode)
        
        when 'C'
          stock = Inventory.find_by(:consumable_id=> part.id, :company_profile_id=> args[:plant], :periode=> periode)
          stock_bm_prev = InventoryBatchNumber.where(:consumable_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode)
        
        when 'G'
          stock = Inventory.find_by(:general_id=> part.id, :company_profile_id=> args[:plant], :periode=> periode)
          stock_bm_prev = InventoryBatchNumber.where(:general_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode)
        when 'P'
          stock = Inventory.find_by(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> periode)
      		stock_bm_prev = InventoryBatchNumber.where(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode)
      	when 'M'
          stock = Inventory.find_by(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> periode)
      		stock_bm_prev = InventoryBatchNumber.where(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode)
      	end

        if stock.blank?
	      	case args[:prefix]
          when 'E'
            stocks = Inventory.where(:equipment_id=> part.id, :company_profile_id=> args[:plant]).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            Inventory.create({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :equipment_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :equipment_batch_number_id=> bm.equipment_batch_number_id, 
                :equipment_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :equipment_batch_number_id=> bm.equipment_batch_number_id, 
                  :equipment_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
          when 'C'
            stocks = Inventory.where(:consumable_id=> part.id, :company_profile_id=> args[:plant]).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            Inventory.create({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :consumable_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :consumable_batch_number_id=> bm.consumable_batch_number_id, 
                :consumable_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :consumable_batch_number_id=> bm.consumable_batch_number_id, 
                  :consumable_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
          when 'G'
            stocks = Inventory.where(:general_id=> part.id, :company_profile_id=> args[:plant]).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            Inventory.create({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :general_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :general_batch_number_id=> bm.general_batch_number_id, 
                :general_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :general_batch_number_id=> bm.general_batch_number_id, 
                  :general_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
	      	when 'P'
	      		stocks = Inventory.where(:product_id=> part.id, :company_profile_id=> args[:plant]).order("periode desc").limit(1)
		      	last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
	    			Inventory.create({
	    				:company_profile_id=> args[:plant], 
	    				:periode=> periode, :product_id=> part.id,
	    				:begin_stock=> last_qty,
	    				:trans_in=> 0, :trans_out=> 0,
	    				:end_stock=> last_qty,
            	:note=> 'Open stock otomatis',
	    				:created_at=> DateTime.now()
	    			})
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :product_batch_number_id=> bm.product_batch_number_id, 
                :product_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :product_batch_number_id=> bm.product_batch_number_id, 
                  :product_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
    			when 'M'
            stocks = Inventory.where(:material_id=> part.id, :company_profile_id=> args[:plant]).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
	    			Inventory.create({
	    				:company_profile_id=> args[:plant], 
	    				:periode=> periode, :material_id=> part.id,
	    				:begin_stock=> last_qty,
	    				:trans_in=> 0, :trans_out=> 0,
	    				:end_stock=> last_qty,
            	:note=> 'Open stock otomatis',
	    				:created_at=> DateTime.now()
	    			})
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :material_batch_number_id=> bm.material_batch_number_id, 
                :material_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :material_batch_number_id=> bm.material_batch_number_id, 
                  :material_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
	      	end

          notice_ok = "create stok #{part.part_id} periode #{periode} => stok awal: #{last_qty}"
          File.open(path2, "a") do |f|
            f.puts notice_ok
          end
          puts notice_ok
        else
          case args[:prefix]
          when 'E'
            stocks = Inventory.where(:equipment_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            stock.update_columns({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :equipment_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :equipment_batch_number_id=> bm.equipment_batch_number_id, 
                :equipment_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :equipment_batch_number_id=> bm.equipment_batch_number_id, 
                  :equipment_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
          when 'C'
            stocks = Inventory.where(:consumable_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            stock.update_columns({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :consumable_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :consumable_batch_number_id=> bm.consumable_batch_number_id, 
                :consumable_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :consumable_batch_number_id=> bm.consumable_batch_number_id, 
                  :consumable_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
          when 'G'
            stocks = Inventory.where(:general_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            stock.update_columns({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :general_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :general_batch_number_id=> bm.general_batch_number_id, 
                :general_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :general_batch_number_id=> bm.general_batch_number_id, 
                  :general_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
          
          when 'P'
            stocks = Inventory.where(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            stock.update_columns({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :product_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :product_batch_number_id=> bm.product_batch_number_id, 
                :product_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :product_batch_number_id=> bm.product_batch_number_id, 
                  :product_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
          when 'M'
            stocks = Inventory.where(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> prev_periode).order("periode desc").limit(1)
            last_qty = (stocks.present? ? stocks.first.end_stock : 0)
            puts "#{stocks.first.periode}: #{last_qty}" if stocks.present?
            stock.update_columns({
              :company_profile_id=> args[:plant], 
              :periode=> periode, :material_id=> part.id,
              :begin_stock=> last_qty,
              :trans_in=> 0, :trans_out=> 0,
              :end_stock=> last_qty,
              :note=> 'Open stock otomatis',
              :created_at=> DateTime.now()
            })
            stock_bm_prev.each do |bm|
              stock_bm_now = InventoryBatchNumber.find_by(
                :material_batch_number_id=> bm.material_batch_number_id, 
                :material_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode)
              if stock_bm_now.blank?
                InventoryBatchNumber.create(
                  :material_batch_number_id=> bm.material_batch_number_id, 
                  :material_id=> part.id, :company_profile_id=> args[:plant], 
                  :periode=> periode,
                  :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                  :created_at=> DateTime.now()
                  )
              end
            end
          end
          notice_ng = "stok #{part.part_id} periode #{periode} => awal: #{stock.begin_stock}; in: #{stock.trans_in}; out: #{stock.trans_out}; akhir: #{stock.end_stock}"
          File.open(path2, "a") do |f|
            f.puts notice_ng
          end
          puts notice_ng
        end

        case args[:prefix]
        when 'E'
          stock_bm_prev.each do |bm|
            stock_bm_now = InventoryBatchNumber.find_by(
              :equipment_batch_number_id=> bm.equipment_batch_number_id, 
              :equipment_id=> part.id, :company_profile_id=> args[:plant], 
              :periode=> periode)
            if stock_bm_now.present?
              stock_bm_now.update_columns({
                :begin_stock=> bm.end_stock, 
                :end_stock=> ((bm.end_stock.to_f+stock_bm_now.trans_in.to_f)-stock_bm_now.trans_out.to_f),
                :updated_at=> DateTime.now()
              })
            else
              InventoryBatchNumber.create(
                :equipment_batch_number_id=> bm.equipment_batch_number_id, 
                :equipment_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode,
                :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                :created_at=> DateTime.now()
                )
            end
          end
        when 'C'
          stock_bm_prev.each do |bm|
            stock_bm_now = InventoryBatchNumber.find_by(
              :consumable_batch_number_id=> bm.consumable_batch_number_id, 
              :consumable_id=> part.id, :company_profile_id=> args[:plant], 
              :periode=> periode)
            if stock_bm_now.present?
              stock_bm_now.update_columns({
                :begin_stock=> bm.end_stock, 
                :end_stock=> ((bm.end_stock.to_f+stock_bm_now.trans_in.to_f)-stock_bm_now.trans_out.to_f),
                :updated_at=> DateTime.now()
              })
            else
              InventoryBatchNumber.create(
                :consumable_batch_number_id=> bm.consumable_batch_number_id, 
                :consumable_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode,
                :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                :created_at=> DateTime.now()
                )
            end
          end
        when 'G'
          stock_bm_prev.each do |bm|
            stock_bm_now = InventoryBatchNumber.find_by(
              :general_batch_number_id=> bm.general_batch_number_id, 
              :general_id=> part.id, :company_profile_id=> args[:plant], 
              :periode=> periode)
            if stock_bm_now.present?
              stock_bm_now.update_columns({
                :begin_stock=> bm.end_stock, 
                :end_stock=> ((bm.end_stock.to_f+stock_bm_now.trans_in.to_f)-stock_bm_now.trans_out.to_f),
                :updated_at=> DateTime.now()
              })
            else
              InventoryBatchNumber.create(
                :general_batch_number_id=> bm.general_batch_number_id, 
                :general_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode,
                :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                :created_at=> DateTime.now()
                )
            end
          end
        when 'P'
          stock_bm_prev.each do |bm|
            stock_bm_now = InventoryBatchNumber.find_by(
              :product_batch_number_id=> bm.product_batch_number_id, 
              :product_id=> part.id, :company_profile_id=> args[:plant], 
              :periode=> periode)
            if stock_bm_now.present?
              stock_bm_now.update_columns({
                :begin_stock=> bm.end_stock, 
                :end_stock=> ((bm.end_stock.to_f+stock_bm_now.trans_in.to_f)-stock_bm_now.trans_out.to_f),
                :updated_at=> DateTime.now()
              })
            else
              InventoryBatchNumber.create(
                :product_batch_number_id=> bm.product_batch_number_id, 
                :product_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode,
                :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                :created_at=> DateTime.now()
                )
            end
          end
        when 'M'
          stock_bm_prev.each do |bm|
            stock_bm_now = InventoryBatchNumber.find_by(
              :material_batch_number_id=> bm.material_batch_number_id, 
              :material_id=> part.id, :company_profile_id=> args[:plant], 
              :periode=> periode)
            if stock_bm_now.present?
              stock_bm_now.update_columns({
                :begin_stock=> bm.end_stock, 
                :end_stock=> ((bm.end_stock.to_f+stock_bm_now.trans_in.to_f)-stock_bm_now.trans_out.to_f),
                :updated_at=> DateTime.now()
              })
              puts "ada bm: id: #{stock_bm_now.id}"
            else
              InventoryBatchNumber.create(
                :material_batch_number_id=> bm.material_batch_number_id, 
                :material_id=> part.id, :company_profile_id=> args[:plant], 
                :periode=> periode,
                :begin_stock=> bm.end_stock, :trans_in=> 0, :trans_out=> 0, :end_stock=> bm.end_stock,
                :created_at=> DateTime.now()
                )
            end
          end
        end
      rescue StandardError => error
        puts "#{part.part_id} gagal => #{error}"
        File.open(path, "a") do |f|
          f.puts part.part_id
        end
      end
    end

    # list_mail = ["aden.pribadi@gmail.com"]   
    
    # list_mail.each {|amail| UserMailer.tiki(amail, subject_mail, content_mail, filename_original).deliver! }

    # puts "berhasil kirim"
    ActiveRecord::Base.connection.close
  end

  task :check_stock, [:plant, :prefix] => :environment do |t, args|
    # periode = DateTime.now().strftime("%Y%m")  
    # prev_periode = "#{DateTime.now()-1.month}".to_datetime.strftime("%Y%m")
    periode = '202102'
    prev_periode = '202101'
    ActiveRecord::Base.establish_connection :development

    case args[:prefix]
    when 'P'
      prefix = 'P'
      eng_parts = Product.where(:company_profile_id=> args[:plant], :status=> 'active', :part_id=> 'SEAB')
    when 'M'
      prefix = 'M'
      eng_parts = Material.where(:company_profile_id=> args[:plant], :status=> 'active')
    end
    c = 1
    eng_parts.each do |part|
      puts "part id: #{part.part_id}"
      case args[:prefix]
      when 'P'
        inventories = Inventory.where(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> [prev_periode, periode])
        inventory_batch_number = InventoryBatchNumber.where( :product_id=> part.id, :company_profile_id=> args[:plant], :periode=> [prev_periode, periode])
      when 'M'
        inventories = Inventory.where(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> [prev_periode, periode])
        inventory_batch_number = InventoryBatchNumber.where( :material_id=> part.id, :company_profile_id=> args[:plant], :periode=> [prev_periode, periode])
      end
      inventories.each do |stock|
        sum_trans_in = 0
        sum_trans_out = 0
        InventoryLog.where(:inventory_id=> stock.id, :status=> 'active').each do |stock_log|
          sum_trans_in += stock_log.quantity if stock_log.kind == 'in'
          sum_trans_out += stock_log.quantity if stock_log.kind == 'out'
          # product_batch_number_id = nil

          # if stock_log.sterilization_product_receiving_item.present?
          #     # product_batch_number_id = stock_log.sterilization_product_receiving_item.product_batch_number_id
          #     # inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> stock.company_profile_id, :product_batch_number_id => product_batch_number_id, :product_id=> part.id, :periode=> stock.periode)
        
          # elsif stock_log.material_receiving_item.present?
          # elsif stock_log.finish_good_receiving_item.present?
          # elsif stock_log.semi_finish_good_receiving_item.present?
          # elsif stock_log.semi_finish_good_outgoing_item.present?
          #   puts "out"
          # elsif stock_log.delivery_order_item.present?
          #   puts "out"
          # elsif stock_log.material_outgoing_item.present?
          #   puts "out"
          # elsif stock_log.inventory_adjustment_item.present?
          #   puts "out / IN"
          # end
        end

        case args[:prefix]
        when 'P'
          check_stock = Inventory.find_by(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> stock.periode)
          check_stock_prev = Inventory.find_by(:product_id=> part.id, :company_profile_id=> args[:plant], :periode=> ("#{stock.periode}01".to_date-1.month).strftime("%Y%m"))
        when 'M'
          check_stock = Inventory.find_by(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> stock.periode)
          check_stock_prev = Inventory.find_by(:material_id=> part.id, :company_profile_id=> args[:plant], :periode=> ("#{stock.periode}01".to_date-1.month).strftime("%Y%m"))
        end

        if check_stock.present?
          if check_stock_prev.present? and check_stock.begin_stock.to_f != check_stock_prev.end_stock.to_f 
            puts "   periode: #{stock.periode}; begin_stock: #{check_stock.begin_stock} != #{check_stock_prev.end_stock}" 
            check_stock.update_columns(:begin_stock=> check_stock_prev.end_stock)
          end

          if check_stock.trans_in.to_f != sum_trans_in 
            puts "   periode: #{stock.periode}; trans_in: #{check_stock.trans_in} != #{sum_trans_in}" 
            check_stock.update_columns(:trans_in=> sum_trans_in)
          end
          if check_stock.trans_out.to_f != sum_trans_out 
            puts "   periode: #{stock.periode}; trans_out: #{check_stock.trans_out} != #{sum_trans_out}" 
            check_stock.update_columns(:trans_out=> sum_trans_out)
          end
        else
          puts "   periode: #{stock.periode} tidak ada"
        end
      end

      inventory_batch_number.each do | ibm |
        case args[:prefix]
        when 'P'
          puts "[#{ibm.periode}] #{ibm.product_batch_number.number}"
          sum_trans_in = 0
          sum_trans_out = 0
          SterilizationProductReceivingItem.where(:product_batch_number_id=> ibm.product_batch_number_id, :status=> 'active').each do |a|
            if a.sterilization_product_receiving.status == "approved3" and a.sterilization_product_receiving.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.sterilization_product_receiving.status}] #{a.sterilization_product_receiving.number} => IN #{a.quantity}" 
              sum_trans_in += a.quantity
            end
          end
          FinishGoodReceivingItem.where(:product_batch_number_id=> ibm.product_batch_number_id, :status=> 'active').each do |a|
            if a.finish_good_receiving.status == "approved3" and a.finish_good_receiving.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.finish_good_receiving.status}] #{a.finish_good_receiving.number} => IN #{a.quantity}"
              sum_trans_in += a.quantity
            end
          end
          SemiFinishGoodReceivingItem.where(:product_batch_number_id=> ibm.product_batch_number_id, :status=> 'active').each do |a|
            if a.semi_finish_good_receiving.status == "approved3" and a.semi_finish_good_receiving.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.semi_finish_good_receiving.status}] #{a.semi_finish_good_receiving.number} => IN #{a.quantity}" 
              sum_trans_in += a.quantity
            end
          end
          SemiFinishGoodOutgoingItem.where(:product_batch_number_id=> ibm.product_batch_number_id, :status=> 'active').each do |a|
            if a.semi_finish_good_outgoing.status == "approved3" and a.semi_finish_good_outgoing.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.semi_finish_good_outgoing.status}] #{a.semi_finish_good_outgoing.number} => OUT #{a.quantity}"
              sum_trans_out += a.quantity
            end
          end
          DeliveryOrderItem.where(:product_batch_number_id=> ibm.product_batch_number_id, :status=> 'active').each do |a|
            if a.delivery_order.status == "approved3" and a.delivery_order.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.delivery_order.status}] #{a.delivery_order.number} => OUT #{a.quantity}" 
              sum_trans_out += a.quantity
            end
          end
          InventoryAdjustmentItem.where(:product_batch_number_id=> ibm.product_batch_number_id, :status=> 'active').each do |a|
            if a.inventory_adjustment.status == "approved3" and a.inventory_adjustment.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.inventory_adjustment.status}] #{a.inventory_adjustment.number} => ADJ #{a.quantity}" 
              
              if a.quantity > 0 
                puts "Positive number: #{item.quantity}"
                sum_trans_in += a.quantity.abs
              else 
                if a.quantity == 0
                  puts "Zero"
                else
                  puts "Negative number: #{item.quantity}"
                  sum_trans_out += a.quantity.abs
                end
              end
            end
          end
          prev_inventory_batch_number = InventoryBatchNumber.where( :product_batch_number_id=> ibm.product_batch_number_id, :product_id=> part.id, :company_profile_id=> args[:plant], :periode=> ("#{ibm.periode}01".to_date-1.month).strftime("%Y%m"))
          prev_end_stock = (prev_inventory_batch_number.present? ? prev_inventory_batch_number.last.end_stock : 0)
        when 'M'
          puts "[#{ibm.periode}] #{ibm.material_batch_number.number}"
          sum_trans_in = 0
          sum_trans_out = 0
          MaterialReceivingItem.where(:material_batch_number_id=> ibm.material_batch_number_id, :status=> 'active').each do |a|
            if a.material_receiving.status == "approved3" and a.material_receiving.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.material_receiving.status}] #{a.material_receiving.number} => IN #{a.quantity}" 
              sum_trans_in += a.quantity
            end
          end
          MaterialOutgoingItem.where(:material_batch_number_id=> ibm.material_batch_number_id, :status=> 'active').each do |a|
            if a.material_outgoing.status == "approved3" and a.material_outgoing.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.material_outgoing.status}] #{a.material_outgoing.number} => IN #{a.quantity}" 
              sum_trans_out += a.quantity
            end
          end
          InventoryAdjustmentItem.where(:material_batch_number_id=> ibm.material_batch_number_id, :status=> 'active').each do |a|
            if a.inventory_adjustment.status == "approved3" and a.inventory_adjustment.date.to_date.strftime("%Y%m") == ibm.periode
              puts "  [#{a.inventory_adjustment.status}] #{a.inventory_adjustment.number} => ADJ #{a.quantity}" 
              
              if a.quantity > 0 
                puts "Positive number: #{item.quantity}"
                sum_trans_in += a.quantity.abs
              else 
                if a.quantity == 0
                  puts "Zero"
                else
                  puts "Negative number: #{item.quantity}"
                  sum_trans_out += a.quantity.abs
                end
              end
            end
          end
          prev_inventory_batch_number = InventoryBatchNumber.where( :material_batch_number_id=> ibm.material_batch_number_id, :material_id=> part.id, :company_profile_id=> args[:plant], :periode=> ("#{ibm.periode}01".to_date-1.month).strftime("%Y%m"))
          prev_end_stock = (prev_inventory_batch_number.present? ? prev_inventory_batch_number.last.end_stock : 0)
        end
        
        puts " begin_stock: #{prev_end_stock}; in: #{sum_trans_in}; out: #{sum_trans_out};"
        ibm.update_columns(:begin_stock=> prev_end_stock, :trans_in=> sum_trans_in, :trans_out=> sum_trans_out)
          # if stock_log.sterilization_product_receiving_item.present?
          #     # product_batch_number_id = stock_log.sterilization_product_receiving_item.product_batch_number_id
          #     # inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> stock.company_profile_id, :product_batch_number_id => product_batch_number_id, :product_id=> part.id, :periode=> stock.periode)
        
          # elsif stock_log.material_receiving_item.present?
          # elsif stock_log.finish_good_receiving_item.present?
          # elsif stock_log.semi_finish_good_receiving_item.present?
          # elsif stock_log.semi_finish_good_outgoing_item.present?
          #   puts "out"
          # elsif stock_log.delivery_order_item.present?
          #   puts "out"
          # elsif stock_log.material_outgoing_item.present?
          #   puts "out"
          # elsif stock_log.inventory_adjustment_item.present?
          #   puts "out / IN"
          # end
      end
    end

  end

  task :check_batch_number => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    ShopFloorOrder.where(:number=> 'SFO/21/06/004').each do |header|
      puts "SFO: #{header.number}"
      ShopFloorOrderItem.where(:shop_floor_order_id=> header.id, :status=> 'active').each do |item|
        outstanding = item.quantity
        if item.product.present? and item.product.sterilization
          outstanding_sterilization = item.quantity
          outstanding_sterilization_out = item.quantity
        else
          outstanding_sterilization = 0
          outstanding_sterilization_out = 0
        end
        ProductBatchNumber.where(:shop_floor_order_item_id=> item.id, :status=> 'active').each do |bn|

          puts "   #{bn.product.part_id} | #{bn.number} | #{item.quantity}    | sterilization #{bn.product.sterilization} => #{bn.outstanding} and #{bn.outstanding_sterilization} and #{bn.outstanding_sterilization_out}"
          ShopFloorOrderSterilizationItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfos|
            puts "   sfos: #{sfos.shop_floor_order_sterilization.number} => #{sfos.quantity}"
          end
          FinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |whfg|
            puts "   fg: #{whfg.finish_good_receiving.number} => #{whfg.quantity}"
            if item.product.present? and whfg.finish_good_receiving.status == 'approved3'
              outstanding -= whfg.quantity
            end
          end
          SemiFinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgin|
            puts "   semi fg: #{sfgin.semi_finish_good_receiving.number} => #{sfgin.quantity}"
            if item.product.present? and item.product.sterilization and sfgin.semi_finish_good_receiving.status == 'approved3'
              outstanding_sterilization -= sfgin.quantity
            end
          end
          SemiFinishGoodOutgoingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgout|
            puts "   sterilization: #{sfgout.semi_finish_good_outgoing.number} => #{sfgout.quantity}"
            if item.product.present? and item.product.sterilization and sfgout.semi_finish_good_outgoing.status == 'approved3'
              outstanding_sterilization_out -= sfgout.quantity
            end
          end
          puts "Qty SFO: #{item.quantity}"
          puts "outstanding_sterilization_in: #{outstanding_sterilization}"
          puts "outstanding_sterilization_out: #{outstanding_sterilization_out}"
          puts "outstanding: #{outstanding}"

          # ga boleh di 0 kan, karena dokumen Semi FG receving partial pembuatan dokumennya
          # kasus ini terjadi pada tanggal 2020/09/03
          # outstanding_sterilization_out = 0 if outstanding < item.quantity
          # outstanding_sterilization = 0 if outstanding < item.quantity

          puts "  outstanding whfg: seharusnya #{outstanding} | actual #{bn.outstanding} => #{outstanding == bn.outstanding}"
          puts "  outstanding semi fg receiving note: seharusnya #{outstanding_sterilization} | actual #{bn.outstanding_sterilization} => #{outstanding_sterilization == bn.outstanding_sterilization}"
          puts "  outstanding semi fg for sterilization: seharusnya #{outstanding_sterilization_out} | actual #{bn.outstanding_sterilization_out} => #{outstanding_sterilization_out == bn.outstanding_sterilization_out}"

          puts "--------------------------------------------------------------------"
          bn.update_columns(:outstanding=> outstanding, :outstanding_sterilization=> outstanding_sterilization, :outstanding_sterilization_out=> outstanding_sterilization_out)
          
          # if header.status == 'approved3'
          #   periode = header.approved3_at.strftime("%Y%m")
          #   inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> bn.company_profile_id, 
          #     :product_batch_number_id => bn.id, 
          #     :product_id=> bn.product_id, :periode=> periode)

          #   if inventory_batch_number.blank?
          #     inventory_batch_number = InventoryBatchNumber.create({
          #       :company_profile_id=> bn.company_profile_id, 
          #       :product_batch_number_id=> bn.id,
          #       :product_id=> bn.product_id,
          #       :periode=> periode,
          #       :trans_in => trans_in,
          #       :created_at=> DateTime.now()
          #     })
          #   end
          # end

        end

      end
    end
  end

  task :check_batch_number_spr => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    SterilizationProductReceiving.where(:number=> 'SPR/21/08/011').each do |header|
      puts "SPR: #{header.number}"
      SterilizationProductReceivingItem.where(:sterilization_product_receiving_id=> header.id, :status=> 'active').each do |item|
        outstanding = item.quantity

        # SPR tanpa dibuatkan Semi FG receiving
        outstanding_sterilization = 0
        if item.product.present? and item.product.sterilization
          # outstanding_sterilization = item.quantity
          outstanding_sterilization_out = item.quantity
        else
          # outstanding_sterilization = 0
          outstanding_sterilization_out = 0
        end
        ProductBatchNumber.where(:sterilization_product_receiving_item_id=> item.id, :status=> 'active').each do |bn|
          puts "   #{bn.product.part_id} | #{bn.number} | #{item.quantity}    | sterilization #{bn.product.sterilization} => #{bn.outstanding} and #{bn.outstanding_sterilization} and #{bn.outstanding_sterilization_out}"
          ShopFloorOrderSterilizationItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfos|
            puts "   sfos: #{sfos.shop_floor_order_sterilization.number} => #{sfos.quantity}"
          end
          SemiFinishGoodOutgoingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgout|
            puts "   sterilization: #{sfgout.semi_finish_good_outgoing.number} => #{sfgout.quantity}"
            if item.product.present? and item.product.sterilization and sfgout.semi_finish_good_outgoing.status == 'approved3'
              outstanding_sterilization_out -= sfgout.quantity
            end
          end
          FinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |whfg|
            puts "   fg: #{whfg.finish_good_receiving.number} => #{whfg.quantity}"
            if item.product.present? and whfg.finish_good_receiving.status == 'approved3'
              outstanding -= whfg.quantity
            end
          end
          # SemiFinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgin|
          #   puts "   semi fg: #{sfgin.semi_finish_good_receiving.number} => #{sfgin.quantity}"
          #   if item.product.present? and item.product.sterilization and sfgin.semi_finish_good_receiving.status == 'approved3'
          #     outstanding_sterilization -= sfgin.quantity
          #   end
          # end


          puts "  outstanding whfg: seharusnya #{outstanding} | actual #{bn.outstanding} => #{outstanding == bn.outstanding}"
          # puts "  outstanding semi fg receiving note: seharusnya #{outstanding_sterilization} | actual #{bn.outstanding_sterilization} => #{outstanding_sterilization == bn.outstanding_sterilization}"
          puts "  outstanding semi fg for sterilization: seharusnya #{outstanding_sterilization_out} | actual #{bn.outstanding_sterilization_out} => #{outstanding_sterilization_out == bn.outstanding_sterilization_out}"

          puts "--------------------------------------------------------------------"
          bn.update_columns(:outstanding=> outstanding, :outstanding_sterilization_out=> outstanding_sterilization_out, :outstanding_sterilization=> outstanding_sterilization)
          
        end

      end
    end
  end

  task :update_outstanding_prf => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    PurchaseRequest.where(:number=> 'PRF/03A/21/09/026').each do |header|
      PurchaseRequestItem.where(:purchase_request_id=> header.id, :status=> 'active').each do |item|
        outstanding = (item.quantity.to_f > 0 ? item.quantity : 0)
        PurchaseOrderSupplierItem.where(:purchase_request_item_id=> item.id, :status=> 'active').each do |po_item|
          if po_item.purchase_order_supplier.status == 'approved3'
            outstanding -= item.quantity
          end
        end
        item.update_columns(:outstanding=> outstanding)
      end
      header.update_columns(:outstanding=> PurchaseRequestItem.where(:purchase_request_id=> header.id, :status=> 'active').sum(:outstanding))
    end
  end
  task :update_outstanding_pdm => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    Pdm.where(:number=> 'PDM20120010').each do |header|
      PdmItem.where(:pdm_id=> header.id, :status=> 'active').each do |item|
        outstanding = (item.quantity.to_f > 0 ? item.quantity : 0)
        PurchaseOrderSupplierItem.where(:pdm_item_id=> item.id, :status=> 'active').each do |po_item|
          if po_item.purchase_order_supplier.status == 'approved3'
            outstanding -= po_item.quantity
          end
        end
        puts "[#{item.material.part_id}] outstanding: #{outstanding}; sip: #{item.outstanding} => #{item.outstanding.to_f == outstanding.to_f}"
        item.update_columns(:outstanding=> outstanding)
      end
      outstanding = PdmItem.where(:pdm_id=> header.id, :status=> 'active').sum(:outstanding)
      
      puts "outstanding: #{outstanding}" 
      header.update_columns(:outstanding=> outstanding)
    end
  end
  task :update_outstanding_po => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    PurchaseOrderSupplier.where(:number=> ['PP/PO/21/IX/027','PP/PO/21/IX/028','PP/PO/21/IX/048','PP/PO/21/X/007'] ).each do |header|
      PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> header.id, :status=> 'active').each do |item|
        outstanding = (item.quantity.to_f > 0 ? item.quantity.to_f : 0)
        case header.kind
        when 'product','general'
          ProductReceivingItem.where(:purchase_order_supplier_item_id=> item.id, :status=> 'active').each do |grn_item|
            if grn_item.product_receiving.status == 'approved3'
              puts "#{grn_item.product_receiving.number} [#{grn_item.product.part_id}]--- #{item.quantity.to_f}"
              outstanding -= grn_item.quantity.to_f
            end
          end
        when 'material'
          MaterialReceivingItem.where(:purchase_order_supplier_item_id=> item.id, :status=> 'active').each do |grn_item|
            if grn_item.material_receiving.status == 'approved3'
              puts "#{grn_item.material_receiving.number} [#{grn_item.material.part_id}]--- #{item.quantity.to_f}"
              outstanding -= grn_item.quantity.to_f
            end
          end
        end
        puts "po_item_id: #{item.id} ; outstanding: #{outstanding}; sip: #{item.outstanding} => #{item.outstanding.to_f == outstanding.to_f}"
        item.update_columns(:outstanding=> outstanding)
        puts "--------------------------------"
      end
      outstanding = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> header.id, :status=> 'active').sum(:outstanding)
      
      puts "outstanding: #{outstanding}" 
      header.update_columns(:outstanding=> outstanding)
    end
  end
  task :update_outstanding_so => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    SalesOrder.where(:po_number=> ['API/PO-PP/X-20/002', 'API/PO-PP/IX-20/003']).each do |header|
      puts "SO: #{header.number}; PO Customer: #{header.po_number}"
      SalesOrderItem.where(:sales_order_id=> header.id, :status=> 'active').each do |item|
        PickingSlipItem.where(:sales_order_item_id=> item.id, :status=> 'active').each do |pck_item|
          if pck_item.picking_slip.status == 'approved3'
            puts "  PickingSlip: #{pck_item.picking_slip.number} => [#{pck_item.product_batch_number.number}] #{pck_item.quantity}"
          end
        end
        outstanding = item.quantity
        DeliveryOrderItem.where(:sales_order_item_id=> item.id, :status=> 'active').each do |do_item|
          if do_item.delivery_order.status == 'approved3'
            outstanding -= do_item.quantity
            puts "  DO: #{do_item.delivery_order.number} => [#{do_item.product_batch_number.number}] #{do_item.quantity}"
          end
        end
        puts "  #{item.product.part_id} outstanding: #{item.outstanding} seharusnya => #{outstanding}"
        puts "  -------------------------------"
        item.update_columns(:outstanding=> outstanding)
      end
      header.update_columns(:outstanding=> SalesOrderItem.where(:sales_order_id=> header.id, :status=> 'active').sum(:outstanding))
    
      puts "--------------------------------------------"
    end
  end
  task :update_outstanding_picking_slip => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    PickingSlip.where(:number=> 'PS20110026').each do |header|
      PickingSlipItem.where(:picking_slip_id=> header.id, :status=> 'active').each do |item|
        outstanding = item.quantity
        DeliveryOrderItem.where(:picking_slip_item_id=> item.id, :status=> 'active').each do |do_item|
          if do_item.delivery_order.status == 'approved3'
            outstanding -= do_item.quantity
          end
        end
        item.update_columns(:outstanding=> outstanding)
      end
      sum_outstanding = PickingSlipItem.where(:picking_slip_id=> header.id, :status=> 'active').sum(:outstanding)
      if header.outstanding != sum_outstanding
        puts "[#{header.number}] outstanding: #{header.outstanding} => #{sum_outstanding}; tidak sesuai"
        header.update_columns(:outstanding=> sum_outstanding)
      end
    end
  end

  task :routine_jobs => :environment do
    ActiveRecord::Base.establish_connection :production 

    JobList.where(:status=> 'active').order("user_id asc").each do |record|
      if record.user.present? 
        if record.user.status == 'active'
          time_now = DateTime.now()
          case record.interval
          when 'daily'
            r = JobListReport.where("created_at between ? and ?", time_now.to_date.at_beginning_of_day,  time_now.to_date.at_end_of_day).find_by(:user_id=> record.user_id, :job_list_id=> record.id)
          when 'weekly'
            r = JobListReport.where("created_at between ? and ?", time_now.to_date.at_beginning_of_week,  time_now.to_date.at_end_of_week).find_by(:user_id=> record.user_id, :job_list_id=> record.id)
          when 'monthly'
            r = JobListReport.where("created_at between ? and ?", time_now.to_date.at_beginning_of_month,  time_now.to_date.at_end_of_month).find_by(:user_id=> record.user_id, :job_list_id=> record.id)
          when 'yearly'
            r = JobListReport.where("created_at between ? and ?", time_now.to_date.at_beginning_of_year,  time_now.to_date.at_end_of_year).find_by(:user_id=> record.user_id, :job_list_id=> record.id)
          end
          if r.present?
            # kirim email
            puts " ==> udah ada"
            r.update_columns({:date=> r.created_at})
          else
            begin
              list_report = JobListReport.new({
                :job_list_id=> record.id,
                :job_category_id=> record.job_category_id,
                :interval=> record.interval,
                :user_id=> record.user_id,
                :company_profile_id=> record.company_profile_id,
                :name=> record.name, :description=> record.description,
                :department_id=> record.department_id,
                :day_required=> record.day_required,
                :hour_required=> record.hour_required,
                :time_required=> record.time_required,
                :weekly_day=> record.weekly_day,
                :monthly_date=> record.monthly_date,
                :yearly_month=> record.yearly_month,
                :due_date=> record.due_date,
                :date=> time_now,
                :created_at=> time_now, :created_by=> record.created_by
                })
              list_report.save

              puts "created interval: #{record.interval}; #{record.user.first_name if record.user_id.present?}"
              case record.interval
              when 'monthly'
                puts record.monthly_date
                if record.monthly_date.present?
                  md_length = "#{record.monthly_date}".length

                  md_day = (md_length == 1 ? "0#{record.monthly_date}" : "#{record.monthly_date}")
                  md_yyyy_mm_dd = "#{time_now.to_date.strftime("%Y-%m")}-#{md_day}"
                  send_date = md_yyyy_mm_dd.to_date-3.days

                  JobListReminder.where(:status=> 'active', :job_list_id=> record.id).each do |job_list|
                    JobListReminder.create({
                      :job_list_id=> nil,
                      :job_list_report_id=> list_report.id,
                      :send_to=> job_list.send_to,
                      :send_date=> send_date,
                      :send_status=> 'wait',
                      :created_by=> job_list.created_by,
                      :created_at=> job_list.created_at
                    })
                  end
                end
              end
            rescue StandardError => error
               JobListLog.create({
                :job_list_id=> record.id,
                :description=> error,
                :status=> 'failed',
                :created_at=> time_now, :created_by=> record.created_by
              })
               puts "#{error}"
            end
          end
        else
          puts " ==> #{record.user.first_name} status non-aktif"
          record.update_columns(:status=> 'suspend', :note=> "Data karyawan non-aktif" )
        end
      else
        puts " ==> user_id #{record.user_id} not found"
        record.update_columns(:status=> 'suspend', :note=> "User not found" )
      end
    end
    ActiveRecord::Base.connection.close
  end

  task :update_outstanding_spp => :environment do
    ActiveRecord::Base.establish_connection :production 
    records = ProductionOrderDetailMaterial.where(:status=> 'active').includes(:production_order, :production_order_item, :sales_order, :sales_order_item, :product, :material)
    records.each do |record|
      if record.production_order.number =='SPP22040010'
      # if record.material.present? and record.material.name == 'Plastic OPP Seal 30 x 40 cm, 25 micron (Coverall & Protection Gown)'
        puts "id: #{record.id}"
        case record.prf_kind
        when 'material'
          puts "SPP: #{record.production_order.number}"
          puts "part id: #{record.material.part_id}"
          puts "Material: #{record.material.name}"
          puts "Quantity: #{record.quantity}"
          puts "outstanding: #{record.prf_outstanding}"
        when 'services'
          puts "SPP: #{record.production_order.number}"
          puts "part id: #{record.product.part_id}"
          puts "product: #{record.product.name}"
          puts "Quantity: #{record.quantity}"
          puts "outstanding: #{record.prf_outstanding}"
        end
        item = ProductionOrderUsedPrf.find_by(:production_order_item_id=> record.production_order_item_id, :production_order_detail_material_id=> record.id, :status=> 'active')
        if item.present?
          prf_outstanding = 0
          puts "PRF Found"
          puts "purchase_request_item_id: #{item.purchase_request_item_id}"
        else
          prf_outstanding = record.quantity
        end
        if prf_outstanding != record.prf_outstanding.to_f
          puts " ::: tidak sesuai :::"
          puts " seharusnya: #{prf_outstanding}"
          record.update_columns(:prf_outstanding=> prf_outstanding)
        end
        puts "____________________________________________-"
      end
    end
  end

  task :routine_cost => :environment do
    ActiveRecord::Base.establish_connection :production 
    # jangan kasih parameter yg lain, ini dipake scheduler
      RoutineCost.where(:number=> 'RE/FA/21/09/004').each do |record|
      # RoutineCost.where(:status=> 'approved3').where("end_contract > ?", DateTime.now()).each do |record|
        interval_date = nil
        cari_interval = RoutineCostInterval.where(:routine_cost_id => record.id).order("date asc").last
        puts record.id
        if cari_interval.present?
          case record.interval.to_s
          when 'annual'
            tanggal = (cari_interval.date + 1.year).to_date
            if (tanggal - DateTime.now.to_date).to_i <= 365
              interval_date = tanggal
            end
          when 'monthly'
            tahun = (cari_interval.date + 1.month).strftime("%Y-%m")
            hari = record.payment_time
            if hari.to_i >= 28 and (cari_interval.date + 1.month).strftime("%m").to_i == 2
              puts tanggal
              tanggal = ("#{tahun}-01").to_date.end_of_month
            elsif hari.to_i >= 30
              puts tanggal
              tanggal = ("#{tahun}-01").to_date.end_of_month
            else
              puts tanggal
              tanggal = ("#{tahun}-#{hari}").to_date
            end
            if (tanggal - DateTime.now.to_date).to_i < 40
              interval_date = tanggal
            end  
          when 'weekly'
            tanggal  = (cari_interval.date+1.week).to_date
            if (tanggal - DateTime.now.to_date).to_i <= 7
              interval_date = tanggal
            end
          end

          if interval_date.present?
            RoutineCostInterval.create({
                :routine_cost_id=>record.id,
                :company_profile_id => record.company_profile_id,
                :date=> interval_date,
                :status=> "open",
                :created_at=> DateTime.now(),
                :updated_at=> DateTime.now()
              }) 
            puts 'create'
          end

        end
      end
    ActiveRecord::Base.connection.close
  end

  task :send_notif_approval_spl => :environment do |t, args|

    puts "Current: #{DateTime.now().strftime("%Y-%m-%d")}"
    ActiveRecord::Base.establish_connection :development
    period = DateTime.now().strftime("%Y-%m-%d")
    if DateTime.now().strftime("%d") <= '20'
      period_begin = period.to_date.beginning_of_month()-1.month+20.day #if period.present?
      period_end =  period.to_date.beginning_of_month()+20.day #if period.present?     
    else
      period_begin = period.to_date.beginning_of_month()+20.day #if period.present?
      period_end = period.to_date.beginning_of_month()+1.month+20.day #if period.present?    
    end 

    puts period_begin
    puts period_end

    account_mail = ['aden@techno.co.id','drukmana@provitalperdana.com','dianing.astuti@provitalperdana.com']
    subject_mail = "[ERP] - Employee Overtimes Status Not Approved 3"
    note_mail    = "Periode #{period_begin} s/d #{period_end}"
    content_mail = "Employee Overtimes: #{note_mail} <br />"

    puts content_mail
    overtime_id  = []
    # EmployeeOvertime.where.not("status in ('approved3','deleted')").where("date between ? and ?", period_begin, period_end).order("status asc").each do |ot|
    EmployeeOvertime.where(:status=> ['new','approved1','canceled1','approved2','canceled2','canceled3'], :date=> period_begin .. period_end).includes(:employee).order("status asc").each do |ot|
      puts "id: #{ot.id}, employee: #{ot.employee.name}, date: #{ot.date}, desc: #{ot.description}, status: #{ot.status}"
      @url = "https://erp.tri-saudara.com/employee_overtimes/#{ot.id}?department_id#{ot.employee.department_id}=&month=#{DateTime.now().strftime('%m')}&year=#{DateTime.now().strftime('%Y')}"
      content_mail += "
        Name : #{ot.employee.name}, Overtime Date : #{ot.date}, Overtime Description : #{ot.description}, Status : #{ot.status}, <a href=#{@url}>Click to approve document</a> <br />
      "
        overtime_id << ot.id
    end
    # content_mail += "overtime_id: #{overtime_id}"

    if overtime_id.present?
      UserMailer.tiki(account_mail, subject_mail, content_mail.html_safe, nil).deliver!
    end   
  end


end