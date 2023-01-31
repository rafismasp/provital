# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 0) do

  create_table "bank_transfers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "code", limit: 50, null: false
    t.string "name", limit: 50, null: false
    t.string "description", limit: 512, null: false
    t.string "number", limit: 512, null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
  end

  create_table "bill_of_material_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "bill_of_material_id", null: false
    t.integer "material_id", null: false
    t.float "standard_quantity", limit: 53, null: false
    t.decimal "allowance", precision: 4, scale: 2, default: "0.0", null: false
    t.float "quantity", limit: 53, null: false
    t.string "remarks"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "bill_of_materials", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", null: false
    t.integer "product_id", null: false
    t.integer "product_wip1_id"
    t.integer "product_wip2_id"
    t.decimal "product_wip1_quantity", precision: 16, scale: 4
    t.decimal "product_wip2_quantity", precision: 16, scale: 4
    t.string "product_wip1_prf", limit: 3, default: "no", null: false
    t.string "product_wip2_prf", limit: 3, default: "no", null: false
    t.float "wip1_standard_quantity", limit: 53
    t.float "wip2_standard_quantity", limit: 53
    t.decimal "wip1_allowance", precision: 4, scale: 2, default: "0.0"
    t.decimal "wip2_allowance", precision: 4, scale: 2, default: "0.0"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "colors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_payment_receivings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "currency_id", default: 1
    t.string "bank_name", comment: "Nama Bank"
    t.string "bank_account", comment: "Rekening Bank"
    t.string "signature"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "company_profiles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "address_row1"
    t.string "address_row2"
    t.string "address_row3"
    t.string "phone_number"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "consumables", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "name"
    t.integer "unit_id"
    t.integer "color_id"
    t.string "part_id"
    t.string "part_model"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "part_id", unique: true
  end

  create_table "currencies", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "symbol"
    t.integer "precision_digit", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customer_addresses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "office"
    t.string "tax_invoice"
    t.string "delivery1"
    t.string "delivery2"
    t.string "invoice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customer_contacts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "name"
    t.string "telephone"
    t.string "fax"
    t.string "email"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customer_tax_invoices", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: "Faktur Pajak Customer Invoice", force: :cascade do |t|
    t.integer "company_profile_id", default: 1, null: false
    t.integer "customer_id", default: 0, null: false
    t.date "date"
    t.string "number", limit: 64
    t.decimal "subtotal", precision: 16, scale: 4
    t.decimal "amount", precision: 16, scale: 4
    t.decimal "ppntotal", precision: 16, scale: 4
    t.string "city", limit: 64, comment: "Nama Kota Faktur Pajak"
    t.text "remarks"
    t.text "note_void"
    t.text "note_cancel_void"
    t.string "received_by", limit: 50
    t.date "received_at"
    t.integer "approved1_by"
    t.integer "edit_lock_by"
    t.datetime "edit_lock_at"
    t.datetime "approved1_at"
    t.integer "canceled1_by"
    t.datetime "canceled1_at"
    t.integer "approved2_by"
    t.datetime "approved2_at"
    t.integer "canceled2_by"
    t.datetime "canceled2_at"
    t.integer "approved3_by"
    t.datetime "approved3_at"
    t.integer "canceled3_by"
    t.datetime "canceled3_at"
    t.integer "voided_by", unsigned: true
    t.datetime "voided_at"
    t.integer "cancel_void_by"
    t.datetime "cancel_void_at"
    t.string "status", limit: 7, default: "new"
    t.datetime "created_at"
    t.integer "created_by"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.integer "suspend_by"
    t.datetime "suspend_at"
  end

  create_table "customers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "invoice_numbering_period", limit: 8, default: "delivery", null: false
    t.string "number", limit: 5, null: false
    t.integer "currency_id", null: false
    t.integer "top_day", null: false
    t.integer "term_of_payment_id", null: false
    t.integer "tax_id", null: false
    t.string "name"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "delivery_cars", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_drivers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_order_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "delivery_order_id", null: false
    t.integer "sales_order_item_id", null: false
    t.integer "picking_slip_item_id", null: false
    t.integer "product_id", null: false
    t.integer "product_batch_number_id", null: false
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "delivery_order_supplier_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "delivery_order_supplier_id", null: false
    t.integer "material_id", null: false
    t.integer "material_batch_number_id", null: false
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "delivery_order_suppliers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "supplier_id"
    t.string "number", limit: 15
    t.string "transforter_name", limit: 50
    t.string "vehicle_number", limit: 15
    t.string "vehicle_driver_name", limit: 15
    t.integer "tax_id", null: false
    t.integer "term_of_payment_id", null: false
    t.integer "top_day", null: false
    t.integer "currency_id", null: false
    t.string "remarks", limit: 512
    t.date "date"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "delivery_orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "customer_id"
    t.integer "invoice_customer_id"
    t.integer "vehicle_inspection_id"
    t.integer "sales_order_id"
    t.integer "picking_slip_id"
    t.string "number", limit: 15
    t.string "transforter_name", limit: 50
    t.string "vehicle_number", limit: 15
    t.string "vehicle_driver_name", limit: 15
    t.string "remarks", limit: 512
    t.date "date"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "departments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "code", limit: 3, null: false
    t.string "hrd_contract_abbreviation", limit: 2, null: false, collation: "utf8_bin"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "direct_labor_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "direct_labor_id", null: false
    t.integer "product_batch_number_id", null: false
    t.integer "product_id", null: false
    t.integer "direct_labor_price_id", null: false
    t.integer "activity_h1"
    t.integer "activity_h2"
    t.integer "activity_h3"
    t.integer "activity_h4"
    t.integer "activity_h5"
    t.integer "activity_h6"
    t.integer "activity_h7"
    t.integer "activity_h8"
    t.integer "activity_h9"
    t.decimal "quantity", precision: 16, scale: 4
    t.decimal "quantity_h1", precision: 16, scale: 4
    t.decimal "quantity_h2", precision: 16, scale: 4
    t.decimal "quantity_h3", precision: 16, scale: 4
    t.decimal "quantity_h4", precision: 16, scale: 4
    t.decimal "quantity_h5", precision: 16, scale: 4
    t.decimal "quantity_h6", precision: 16, scale: 4
    t.decimal "quantity_h7", precision: 16, scale: 4
    t.decimal "quantity_h8", precision: 16, scale: 4
    t.decimal "quantity_h9", precision: 16, scale: 4
    t.decimal "unit_price", precision: 16, scale: 4
    t.decimal "price_h1", precision: 16, scale: 4
    t.decimal "price_h2", precision: 16, scale: 4
    t.decimal "price_h3", precision: 16, scale: 4
    t.decimal "price_h4", precision: 16, scale: 4
    t.decimal "price_h5", precision: 16, scale: 4
    t.decimal "price_h6", precision: 16, scale: 4
    t.decimal "price_h7", precision: 16, scale: 4
    t.decimal "price_h8", precision: 16, scale: 4
    t.decimal "price_h9", precision: 16, scale: 4
    t.decimal "total_h1", precision: 16, scale: 4
    t.decimal "total_h2", precision: 16, scale: 4
    t.decimal "total_h3", precision: 16, scale: 4
    t.decimal "total_h4", precision: 16, scale: 4
    t.decimal "total_h5", precision: 16, scale: 4
    t.decimal "total_h6", precision: 16, scale: 4
    t.decimal "total_h7", precision: 16, scale: 4
    t.decimal "total_h8", precision: 16, scale: 4
    t.decimal "total_h9", precision: 16, scale: 4
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "direct_labor_outstandings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "direct_labor_id", null: false
    t.integer "direct_labor_price_detail_id", null: false
    t.integer "product_batch_number_id", null: false
    t.integer "product_id", null: false
    t.decimal "max_quantity", precision: 16, scale: 4, null: false
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.decimal "outstanding", precision: 16, scale: 4, null: false
    t.decimal "price", precision: 16, scale: 4, null: false
    t.decimal "total", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "direct_labor_price_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "direct_labor_price_id", null: false
    t.string "activity_name"
    t.integer "target_quantity_perday", null: false
    t.decimal "pay_perday", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "unit_price", precision: 16, scale: 2, default: "0.0", null: false
    t.integer "ratio", default: 1, null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "direct_labor_prices", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "currency_id", default: 1, null: false
    t.decimal "unit_price", precision: 16, scale: 2, default: "0.0", null: false
    t.string "status", limit: 9, default: "new", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
  end

  create_table "direct_labor_workers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "direct_labors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "direct_labor_worker_id", default: 0, null: false
    t.string "number"
    t.date "date"
    t.string "remarks"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "employee_contracts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "employee_id", null: false
    t.integer "work_status_id", null: false
    t.integer "department_id", null: false
    t.integer "position_id", null: false
    t.decimal "basic_salary", precision: 16, scale: 2, default: "0.0"
    t.decimal "meal_and_transport_cost", precision: 16, scale: 2, default: "0.0"
    t.string "number"
    t.string "note"
    t.date "begin_of_contract", null: false
    t.date "end_of_contract", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by"
  end

  create_table "employee_internship_contracts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "employee_internship_id", null: false
    t.integer "employee_id", null: false
    t.string "number"
    t.date "begin_of_contract", null: false
    t.date "end_of_contract", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "employee_internships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "position_id", null: false
    t.string "name"
    t.string "nik"
    t.date "born_date", null: false
    t.string "born_place"
    t.string "last_education", limit: 4, default: "", null: false
    t.string "phone_number"
    t.string "address"
    t.string "gender", limit: 6, default: "", null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "employee_presences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.string "coordinate_latitude", limit: 50, null: false
    t.string "coordinate_langitude", limit: 50, null: false
    t.datetime "clock_in"
    t.datetime "clock_out"
    t.string "status", limit: 7, null: false
    t.string "kind", limit: 3, null: false
    t.datetime "created_at", null: false
  end

  create_table "employee_sections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.integer "department_id", null: false
    t.string "code", limit: 3, null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
  end

  create_table "employee_time_off_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", null: false
    t.integer "leave_type_id", null: false
    t.integer "employee_id", null: false
    t.integer "department_id"
    t.date "beginning_at", null: false
    t.date "ending_at", null: false
    t.string "remarks", limit: 512, null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
  end

  create_table "employees", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "employee_legal_id", default: 1
    t.string "image"
    t.integer "department_id", null: false
    t.integer "position_id", null: false
    t.integer "work_status_id", null: false
    t.string "work_schedule", limit: 3, collation: "utf8_bin"
    t.date "begin_of_contract", null: false
    t.date "end_of_contract", null: false
    t.date "join_date"
    t.date "resign_date"
    t.string "name"
    t.string "nik", limit: 16
    t.date "born_date", null: false
    t.string "born_place"
    t.string "origin_address"
    t.string "ktp"
    t.date "ktp_expired_date"
    t.string "domicile_address"
    t.string "phone_number"
    t.string "email_address"
    t.string "npwp"
    t.string "npwp_address"
    t.string "kpj_number"
    t.string "bpjs"
    t.string "bpjs_hospital"
    t.string "family_card"
    t.string "sim_a_number", limit: 50
    t.date "sim_a_date"
    t.string "sim_a_place"
    t.string "sim_b_number", limit: 50
    t.date "sim_b_date"
    t.string "sim_b_place"
    t.string "sim_c_number", limit: 50
    t.date "sim_c_date"
    t.string "sim_c_place"
    t.string "gender", limit: 9, default: "", null: false
    t.string "married_status", limit: 11, default: "Tidak Kawin", null: false
    t.string "last_education", limit: 4, default: "", null: false
    t.string "vocational_education"
    t.string "blood", limit: 2, default: "", null: false
    t.string "religion", limit: 10, default: "", null: false
    t.string "status", limit: 7, default: "active", null: false
    t.string "employee_status", limit: 13, default: "Aktif", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
  end

  create_table "equipment", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "name"
    t.integer "unit_id"
    t.integer "color_id"
    t.string "part_id"
    t.string "part_model"
    t.string "status", limit: 7, default: "active", null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
    t.index ["part_id"], name: "part_id", unique: true
  end

  create_table "finish_good_receiving_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "finish_good_receiving_id", null: false
    t.integer "product_id"
    t.integer "product_batch_number_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "finish_good_receivings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "kind", limit: 13, default: "production", null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "generals", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "name"
    t.integer "unit_id"
    t.integer "color_id"
    t.string "part_id"
    t.string "part_model"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "part_id", unique: true
  end

  create_table "internal_transfer_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "internal_transfer_id", null: false
    t.integer "product_id"
    t.integer "material_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "internal_transfers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "transfer_kind", limit: 9
    t.string "transfer_from", limit: 22, null: false
    t.string "transfer_to", limit: 22, null: false
    t.string "status", limit: 8, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved_at"
    t.integer "approved_by"
    t.datetime "canceled_at"
    t.integer "canceled_by"
  end

  create_table "inventories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "product_id"
    t.bigint "material_id"
    t.text "periode", limit: 255
    t.decimal "begin_stock", precision: 12, scale: 2, default: "0.0"
    t.decimal "trans_in", precision: 12, scale: 2
    t.decimal "trans_out", precision: 12, scale: 2
    t.decimal "end_stock", precision: 12, scale: 2
    t.string "note", limit: 125
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inventory_adjustment_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inventory_adjustment_id", null: false
    t.integer "product_id"
    t.integer "product_batch_number_id"
    t.integer "material_id"
    t.integer "material_batch_number_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "stock_quantity", precision: 16, scale: 4, default: "0.0", null: false, comment: "Jumlah Stok Saat ini"
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "inventory_adjustments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "kind", limit: 8, default: "product", null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "inventory_batch_numbers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "product_id"
    t.bigint "product_batch_number_id"
    t.bigint "material_id"
    t.bigint "material_batch_number_id"
    t.text "periode", limit: 255
    t.decimal "begin_stock", precision: 12, scale: 2, default: "0.0"
    t.decimal "trans_in", precision: 12, scale: 2
    t.decimal "trans_out", precision: 12, scale: 2
    t.decimal "end_stock", precision: 12, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inventory_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "inventory_id", null: false
    t.bigint "internal_transfer_item_id"
    t.bigint "inventory_adjustment_item_id"
    t.bigint "material_outgoing_item_id"
    t.bigint "material_receiving_item_id"
    t.bigint "finish_good_receiving_item_id"
    t.bigint "sterilization_product_receiving_item_id"
    t.bigint "semi_finish_good_receiving_item_id"
    t.bigint "semi_finish_good_outgoing_item_id"
    t.bigint "delivery_order_item_id"
    t.bigint "product_receiving_item_id"
    t.bigint "delivery_order_supplier_item_id"
    t.text "periode", limit: 255
    t.decimal "quantity", precision: 16, scale: 4
    t.string "kind", limit: 3
    t.string "status", limit: 6, default: "active"
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
  end

  create_table "invoice_customer_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "invoice_customer_id", null: false
    t.integer "delivery_order_item_id", null: false
    t.integer "sales_order_item_id", null: false
    t.integer "product_batch_number_id"
    t.integer "product_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "unit_price", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "total_price", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "invoice_customers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "company_payment_receiving_id", default: 1
    t.integer "customer_id"
    t.integer "customer_tax_invoice_id"
    t.integer "payment_customer_id"
    t.integer "currency_id", null: false
    t.integer "top_day", null: false
    t.integer "term_of_payment_id", null: false
    t.string "number"
    t.string "efaktur_number"
    t.date "date"
    t.date "due_date"
    t.decimal "subtotal", precision: 16, scale: 2
    t.decimal "discount", precision: 16, scale: 2
    t.decimal "ppntotal", precision: 16, scale: 2
    t.decimal "grandtotal", precision: 16, scale: 2
    t.string "remarks", limit: 512
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.datetime "printed_at"
    t.integer "printed_by"
    t.datetime "received_at"
    t.text "received_name", limit: 255
  end

  create_table "invoice_supplier_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "invoice_supplier_id", null: false
    t.integer "purchase_order_supplier_id", null: false
    t.integer "purchase_order_supplier_item_id", null: false
    t.integer "material_receiving_id"
    t.integer "material_receiving_item_id"
    t.integer "material_id"
    t.integer "product_receiving_id"
    t.integer "product_receiving_item_id"
    t.integer "product_id"
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.decimal "unit_price", precision: 16, scale: 4, null: false
    t.decimal "total", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "invoice_supplier_receiving_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "erp_system", comment: "1 = dicatat di ERP"
    t.integer "invoice_supplier_receiving_id", null: false
    t.integer "supplier_tax_invoice_id"
    t.integer "currency_id", null: false
    t.integer "tax_rate_id", null: false
    t.string "index_number", limit: 256
    t.string "invoice_number", limit: 256
    t.date "invoice_date"
    t.string "fp_number", limit: 256
    t.decimal "dpp", precision: 16, scale: 4, default: "0.0"
    t.decimal "ppn", precision: 16, scale: 4, default: "0.0"
    t.decimal "total", precision: 16, scale: 4, default: "0.0"
    t.text "remarks"
    t.date "due_date_checked1", comment: "tanggal selesainya pengecekan pertama"
    t.date "date_checked1"
    t.string "note_checked1", limit: 512
    t.date "due_date_checked2"
    t.date "date_checked2"
    t.date "date_receive_checked2"
    t.string "note_checked2", limit: 512
    t.date "due_date_checked3"
    t.date "date_checked3"
    t.date "date_receive_checked3"
    t.string "note_checked3", limit: 512
    t.date "due_date_checked4"
    t.date "date_checked4"
    t.date "date_receive_checked4"
    t.string "note_checked4", limit: 512
    t.date "due_date_checked5"
    t.date "date_checked5"
    t.date "date_receive_checked5"
    t.string "note_checked5", limit: 512
    t.date "date_payment", comment: "tgl di bayarkan"
    t.decimal "amount_payment", precision: 16, scale: 4, default: "0.0", comment: "amount payment yg di input manual oleh finance"
    t.string "completeness_dc", limit: 50, comment: "kelengkapan dokumen"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "invoice_supplier_receivings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "supplier_id", null: false
    t.string "number"
    t.date "due_date"
    t.date "date"
    t.integer "check_list1", default: 0, comment: "Invoice Asli"
    t.integer "check_list2", default: 0, comment: "Faktur Pajak Asli"
    t.integer "check_list3", default: 0, comment: "Faktur Pajak Copy"
    t.integer "check_list4", default: 0, comment: "Surat Jalan DO asli"
    t.integer "check_list5", default: 0, comment: "SPG asli (Jika PO sistem)"
    t.integer "check_list6", default: 0, comment: "PO Copy"
    t.string "remarks"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "deleted_at"
    t.integer "deleted_by"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.datetime "printed_at"
    t.integer "printed_by"
  end

  create_table "invoice_suppliers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "number"
    t.date "date"
    t.integer "supplier_tax_invoice_id"
    t.integer "invoice_supplier_receiving_item_id"
    t.string "fp_number"
    t.string "sj_number"
    t.integer "supplier_id", null: false
    t.integer "tax_rate_id", null: false
    t.integer "payment_request_supplier_id"
    t.decimal "subtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "ppntotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "pphtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "dptotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "grandtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.integer "tax_id", null: false
    t.integer "term_of_payment_id", null: false
    t.integer "top_day", null: false
    t.integer "currency_id", null: false
    t.string "remarks"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "deleted_at"
    t.integer "deleted_by"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
  end

  create_table "job_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "department_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "job_list_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: "pencata log jika gagal insert ke table sys_job_lists\r\n", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "job_list_id", null: false
    t.text "description", null: false
    t.string "status", limit: 6, default: "failed", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
  end

  create_table "job_list_reminders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: nil, force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "job_list_id", comment: "di proses jika field ini null"
    t.integer "job_list_report_id"
    t.string "send_to", limit: 64, null: false
    t.date "send_date"
    t.string "mail_subject", limit: 512
    t.text "mail_content"
    t.string "status", limit: 7, default: "active", null: false
    t.string "send_status", limit: 13, default: "wait", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "job_list_reports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: nil, force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "job_list_id"
    t.integer "meeting_minute_item_id"
    t.integer "user_id", null: false
    t.integer "job_category_id"
    t.integer "department_id"
    t.text "name", null: false
    t.text "description", null: false
    t.integer "time_required", comment: "menit"
    t.integer "hour_required"
    t.integer "day_required"
    t.string "interval", limit: 7
    t.string "weekly_day", limit: 9
    t.integer "monthly_date"
    t.string "yearly_month", limit: 9
    t.date "due_date"
    t.date "date", comment: "pencatatan tanggal interval daily"
    t.text "note"
    t.string "status", limit: 8, default: "active", null: false
    t.string "reminder_status", limit: 1, default: "N", null: false
    t.boolean "checked", default: false
    t.datetime "checked_at"
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "job_lists", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "user_id", null: false
    t.integer "job_category_id"
    t.integer "department_id"
    t.string "name"
    t.text "description", null: false
    t.datetime "due_date"
    t.string "interval", limit: 7, default: "daily", null: false
    t.string "weekly_day", limit: 9, default: "Sunday"
    t.integer "monthly_date"
    t.string "yearly_month", limit: 9
    t.integer "time_required", comment: "menit"
    t.integer "hour_required"
    t.integer "day_required"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "leave_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", force: :cascade do |t|
    t.string "code", limit: 50, default: "0", null: false
    t.string "name", limit: 64, null: false
    t.string "description"
    t.integer "max_day", null: false
    t.integer "special", limit: 1, comment: "1 => tidak masuk hitungan cuti 12 hari dalam 1 tahun"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by", null: false
  end

  create_table "material_batch_numbers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", comment: "20201105 material_receiving_item_id tidak bisa digunakan, karena 1 grn bisa datang 1 material yg sama tapi dari PDM dan PRF secara bersamaan, \r\nsedangkan itu dianggap 1 batch number", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "material_receiving_id"
    t.bigint "material_receiving_item_id", comment: "ini tidak bisa"
    t.bigint "material_id", null: false
    t.string "number", limit: 50, null: false
    t.string "periode_yyyy", limit: 6, null: false
    t.string "periode_mm", limit: 2, null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "material_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "code", limit: 2, null: false
    t.string "description", limit: 512, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "material_outgoing_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "material_outgoing_id", null: false
    t.integer "material_id"
    t.integer "material_batch_number_id"
    t.integer "product_id", comment: "Product WIP"
    t.integer "product_batch_number_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "material_outgoings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.integer "shop_floor_order_id"
    t.integer "product_batch_number_id"
    t.string "number", limit: 25, null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "material_receiving_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "material_receiving_id", null: false
    t.integer "purchase_order_supplier_item_id"
    t.integer "material_batch_number_id"
    t.string "supplier_batch_number", limit: 256
    t.integer "material_id"
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "material_receivings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.integer "supplier_id"
    t.integer "purchase_order_supplier_id"
    t.integer "invoice_supplier_id", comment: "1 GRN hanya 1 Invoice Supplier"
    t.string "number", limit: 20, null: false
    t.string "remarks", null: false
    t.string "sj_number"
    t.date "sj_date"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "materials", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "vendor_name"
    t.integer "unit_id", default: 1, null: false
    t.integer "material_category_id", default: 1, null: false
    t.integer "color_id"
    t.integer "minimum_order_quantity", default: 0
    t.string "name"
    t.string "part_id"
    t.string "part_model"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.index ["part_id"], name: "part_id", unique: true
  end

  create_table "meeting_minute_attendences", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: nil, force: :cascade do |t|
    t.integer "meeting_minute_id", null: false
    t.integer "user_id", null: false
    t.string "pwd", limit: 64
    t.integer "deleted_by"
    t.datetime "deleted_at"
    t.string "status", limit: 8, default: "active", null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "meeting_minute_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: nil, force: :cascade do |t|
    t.integer "meeting_minute_id", null: false
    t.text "description", null: false
    t.text "action", null: false
    t.date "due_date"
    t.integer "pic1", comment: "PIC 1"
    t.integer "pic2", comment: "PIC 2"
    t.integer "pic3", comment: "PIC 3"
    t.integer "pic4", comment: "PIC 4"
    t.integer "pic5", comment: "PIC 5"
    t.string "status", limit: 7, default: "active", null: false
    t.string "status_job", limit: 11, default: "on progress", null: false
    t.integer "deleted_by"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "meeting_minutes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "subject"
    t.string "venue"
    t.string "note"
    t.date "date"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "outgoing_inspection_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "outgoing_inspection_id", null: false
    t.integer "picking_slip_item_id", null: false
    t.integer "product_batch_number_id", null: false
    t.integer "product_id", null: false
    t.string "inspection_name", limit: 13, null: false
    t.string "inspection_type", limit: 13, null: false
    t.string "inspection_batch", limit: 13, null: false
    t.string "inspection_qty", limit: 13, null: false
    t.string "inspection_expired", limit: 13, null: false
    t.string "inspection_physical", limit: 6, null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "outgoing_inspections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "number", limit: 15
    t.integer "company_profile_id", default: 1
    t.integer "customer_id"
    t.integer "picking_slip_id"
    t.string "remarks", limit: 512
    t.date "date"
    t.date "delivery_date"
    t.string "conclusion", limit: 19
    t.string "reason_hold", limit: 256
    t.string "status", limit: 9, default: "new", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
  end

  create_table "paper_sizes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.decimal "width", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "height", precision: 16, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "payment_customers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "number"
    t.integer "customer_id", null: false
    t.integer "currency_id", null: false
    t.integer "bank_transfer_id", null: false
    t.decimal "total_tax", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "adm_fee", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "other_cut_cost", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "paid", precision: 16, scale: 2, default: "0.0", null: false
    t.date "date"
    t.string "remarks"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.integer "printed_by"
    t.datetime "printed_at"
    t.integer "deleted_by"
    t.datetime "deleted_at"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
  end

  create_table "payment_request_supplier_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "payment_request_supplier_id", null: false
    t.integer "invoice_supplier_id", null: false
    t.integer "tax_rate_id", comment: "jika invoice dalam mata uang asing, ppn nya bisa dipilih (mata uang), di kali berdasarkan kurs pajak yg di invoice."
    t.decimal "ppntotal", precision: 16, scale: 4, null: false, comment: "total PPN tiap invoice"
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "payment_request_suppliers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "number"
    t.string "payment_methode_number"
    t.string "payment_supplier_id"
    t.integer "supplier_id", null: false
    t.integer "currency_id", null: false
    t.integer "supplier_payment_method_id", null: false
    t.integer "bank_transfer_id", null: false
    t.decimal "subtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "ppntotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "pphtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "dptotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "grandtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.date "date"
    t.string "remarks"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "deleted_at"
    t.integer "deleted_by"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
  end

  create_table "payment_supplier_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "payment_supplier_id", null: false
    t.integer "invoice_supplier_id", null: false
    t.integer "payment_request_supplier_id", null: false
    t.integer "payment_request_supplier_item_id", null: false
    t.integer "tax_rate_id", comment: "jika invoice dalam mata uang asing, ppn nya bisa dipilih (mata uang), di kali berdasarkan kurs pajak yg di invoice."
    t.decimal "ppntotal", precision: 16, scale: 4, null: false, comment: "total PPN tiap invoice"
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "payment_suppliers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "number"
    t.string "kind_dpp", limit: 7, default: "DPP", comment: "Jenis Dasar Pengenaan Pajak, tidak digunakan karena payment dapat mencakup dpp+ppn atau ppn, dpp"
    t.string "payment_methode_number"
    t.integer "supplier_id", null: false
    t.integer "currency_id", null: false
    t.integer "supplier_payment_method_id", null: false
    t.integer "bank_transfer_id", null: false
    t.decimal "subtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "ppntotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "pphtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "dptotal", precision: 16, scale: 2, default: "0.0", null: false
    t.decimal "grandtotal", precision: 16, scale: 2, default: "0.0", null: false
    t.date "date"
    t.string "remarks"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "deleted_at"
    t.integer "deleted_by"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
  end

  create_table "pdf_coordinate_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT", force: :cascade do |t|
    t.bigint "pdf_coordinate_id", default: 0, null: false
    t.text "pdf_description", null: false
    t.text "pdf_position_y", null: false
    t.text "pdf_position_x", null: false
    t.text "html_position_y", null: false
    t.text "html_position_x", null: false
    t.text "pdf_value", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.bigint "created_by", default: 0, null: false
    t.datetime "updated_at"
  end

  create_table "pdf_coordinates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "paper_size_id", default: 0, null: false
    t.string "page_layout", limit: 9, default: "landscape", null: false
    t.string "name", limit: 50, null: false
    t.string "filename", limit: 50, null: false
    t.text "base64", limit: 4294967295, null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by", default: 0, null: false
    t.datetime "updated_at"
  end

  create_table "pdm_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "pdm_id", null: false
    t.integer "material_id", null: false
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.decimal "outstanding_prf", precision: 16, scale: 4, null: false, comment: "yang belum dibuatkan PRF Supplier"
    t.decimal "outstanding", precision: 16, scale: 4, null: false, comment: "yang belum dibuatkan PO Supplier"
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "pdms", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "automatic_calculation", default: 0
    t.bigint "purchase_request_id", default: 0
    t.string "number"
    t.string "remarks", limit: 512
    t.string "month_required", limit: 6
    t.date "date", null: false
    t.decimal "outstanding", precision: 16, scale: 4
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.datetime "voided_at"
    t.integer "voided_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "permission_bases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "list_order", default: 1, null: false
    t.integer "parent_id"
    t.string "name"
    t.string "description"
    t.string "icon"
    t.string "link"
    t.string "link_param"
    t.string "tbl_kind"
    t.string "spreadsheet_status", limit: 1, default: "N", null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "picking_slip_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "picking_slip_id", null: false
    t.integer "sales_order_item_id", null: false
    t.integer "product_id", null: false
    t.integer "product_batch_number_id", null: false
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.decimal "outstanding", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "picking_slips", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "customer_id"
    t.integer "sales_order_id"
    t.integer "outgoing_inspection_id"
    t.string "number", limit: 15
    t.string "remarks", limit: 512
    t.date "date"
    t.decimal "outstanding", precision: 16, scale: 4, null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "positions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "product_batch_numbers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "shop_floor_order_item_id"
    t.bigint "sterilization_product_receiving_item_id"
    t.bigint "product_receiving_item_id"
    t.bigint "product_id", null: false
    t.string "number", limit: 50, null: false
    t.string "periode_yyyy", limit: 6, null: false
    t.decimal "outstanding", precision: 16, scale: 4, default: "0.0", comment: "Produk yang belum dibuat FG Receiving, jika FG sudah dibuat pasti outstanding sterilization 0"
    t.decimal "outstanding_sterilization", precision: 16, scale: 4, default: "0.0", comment: "Produk yang belum dibuat Semi FG Receiving"
    t.decimal "outstanding_sterilization_out", precision: 16, scale: 4, default: "0.0", comment: "Produk yg belum dibuat Semi FG for Sterilisasi (keluar gudang)"
    t.decimal "outstanding_direct_labor", precision: 16, scale: 4, default: "0.0", comment: "yang belum dibuatkan laporan dasar pembayaran orang borongan"
    t.decimal "outstanding_material_issue", precision: 16, scale: 4, default: "0.0", comment: "produk WIP yg belum masuk produksi"
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "product_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.string "kind", limit: 19, null: false
    t.string "code", limit: 2, null: false
    t.string "description", limit: 512
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "product_item_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  create_table "product_receiving_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_receiving_id", null: false
    t.integer "purchase_order_supplier_item_id", null: false
    t.integer "product_batch_number_id"
    t.integer "product_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "outstanding", precision: 16, scale: 4, default: "0.0", null: false, comment: "yang belum dibuatkan sterilisasi"
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "product_receivings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.bigint "purchase_order_supplier_id", null: false
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "remarks", limit: 512
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "product_sub_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_category_id", default: 0, null: false
    t.string "name", limit: 512, null: false
    t.string "code", limit: 2, null: false
    t.string "description", limit: 512
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "product_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_sub_category_id", null: false
    t.integer "customer_id"
    t.string "brand", limit: 50, null: false
    t.string "name", limit: 50, null: false
    t.string "code", limit: 2, null: false
    t.string "description", limit: 512
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "production_order_detail_materials", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "production_order_id", null: false
    t.integer "production_order_item_id", null: false
    t.integer "sales_order_id"
    t.integer "sales_order_item_id"
    t.integer "product_id", null: false
    t.integer "material_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "prf_outstanding", precision: 16, scale: 4, default: "0.0", null: false
    t.string "prf_kind", limit: 8, default: "material", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 8, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
    t.datetime "canceled_at"
    t.integer "canceled_by"
  end

  create_table "production_order_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "production_order_id", null: false
    t.integer "sales_order_item_id"
    t.integer "product_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "production_order_used_prves", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", force: :cascade do |t|
    t.integer "company_profile_id"
    t.integer "production_order_detail_material_id", null: false
    t.date "prf_date"
    t.integer "production_order_item_id", null: false
    t.integer "purchase_request_item_id", null: false
    t.string "note", limit: 50
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "production_orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "sales_order_id"
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "remarks", limit: 512
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.datetime "printed_at"
    t.integer "printed_by"
    t.datetime "unlock_printed_at"
    t.integer "unlock_printed_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "products", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "customer_id"
    t.string "kind", limit: 3, default: "FG", null: false
    t.integer "product_category_id", null: false
    t.integer "product_sub_category_id", null: false
    t.integer "product_type_id", null: false
    t.integer "unit_id", null: false
    t.integer "color_id"
    t.integer "max_batch"
    t.string "name", limit: 512
    t.string "part_id", limit: 12
    t.integer "product_item_category_id"
    t.string "part_model"
    t.string "nie_number", comment: "nomor izin edar"
    t.date "nie_expired_date"
    t.string "status", limit: 7, default: "active", null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
    t.index ["part_id"], name: "part_id", unique: true
  end

  create_table "purchase_order_prices", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date"
    t.integer "product_id"
    t.integer "material_id"
    t.integer "consumable_id"
    t.integer "equipment_id"
    t.integer "general_id"
    t.decimal "unit_price", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "purchase_order_supplier_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "purchase_order_supplier_id", null: false
    t.integer "purchase_request_item_id"
    t.integer "pdm_item_id"
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.decimal "outstanding", precision: 16, scale: 4, null: false, comment: "yang belum diterima"
    t.decimal "unit_price", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "purchase_order_suppliers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "department_id", null: false
    t.integer "employee_section_id"
    t.string "kind", limit: 10
    t.string "asset_kind", limit: 9, default: "non-asset"
    t.integer "supplier_id", null: false
    t.integer "tax_id", null: false
    t.integer "term_of_payment_id", null: false
    t.integer "top_day", null: false
    t.integer "purchase_request_id"
    t.integer "pdm_id"
    t.integer "currency_id", null: false
    t.string "number"
    t.decimal "outstanding", precision: 16, scale: 4, null: false, comment: "yang belum diterima"
    t.date "date"
    t.string "remarks"
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "purchase_request_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "purchase_request_id", null: false
    t.date "expected_date"
    t.integer "product_id"
    t.integer "material_id"
    t.integer "consumable_id"
    t.integer "equipment_id"
    t.integer "general_id"
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.decimal "outstanding", precision: 16, scale: 4, null: false, comment: "yang belum dibuatkan PO Supplier"
    t.decimal "summary_production_order", precision: 16, scale: 4
    t.decimal "moq_quantity", precision: 16, scale: 4, comment: "Qty Pembulatan"
    t.decimal "pdm_quantity", precision: 16, scale: 4, comment: "Qty PDM"
    t.string "remarks", limit: 256
    t.string "specification", limit: 256
    t.string "justification_of_purchase", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "purchase_request_used_pdms", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: "\r\nppb menggunakan banyak pdm\r\n\r\npenambahan record berasal dari proses di purch_controller.erb\r\n", force: :cascade do |t|
    t.integer "company_profile_id"
    t.date "prf_date"
    t.integer "pdm_item_id", null: false
    t.integer "purchase_request_item_id", null: false
    t.integer "material_id"
    t.decimal "quantity", precision: 16, scale: 4
    t.string "note", limit: 50
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "purchase_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "request_kind", limit: 10
    t.integer "automatic_calculation", default: 0
    t.integer "department_id"
    t.integer "employee_section_id"
    t.string "number"
    t.string "remarks", limit: 512
    t.date "date", null: false
    t.decimal "outstanding", precision: 16, scale: 4, null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.string "img_created_by", limit: 512
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.string "img_approved3_by", limit: 512
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.datetime "voided_at"
    t.integer "voided_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "quotation_suppliers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rejected_material_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "rejected_material_id", null: false
    t.integer "material_outgoing_item_id"
    t.integer "ng_supplier"
    t.integer "production_process"
    t.integer "documentation"
    t.string "status", limit: 7, default: "active"
    t.datetime "created_at"
    t.integer "created_by"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "rejected_materials", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "material_outgoing_id"
    t.string "number", limit: 17
    t.string "remarks", limit: 512
    t.date "date"
    t.string "status", limit: 9, default: "new", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
  end

  create_table "sales_order_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "sales_order_id", null: false
    t.integer "product_id", null: false
    t.decimal "quantity", precision: 16, scale: 4, null: false
    t.decimal "unit_price", precision: 16, scale: 4, null: false
    t.decimal "discount", precision: 3, null: false, comment: "Persentse 1..100 %"
    t.decimal "outstanding", precision: 16, scale: 4, null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "sales_orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "customer_id"
    t.integer "top_day"
    t.integer "term_of_payment_id", null: false
    t.integer "tax_id", null: false
    t.integer "service_type_ddv", comment: "Design, Deevlopment and Validation"
    t.integer "service_type_mfg", comment: "Manufacturing"
    t.integer "service_type_str", comment: "Sterilization"
    t.integer "service_type_lab", comment: "Laboratory Testing"
    t.integer "service_type_oth", comment: "Other"
    t.string "number", limit: 25
    t.date "date"
    t.integer "outstanding"
    t.string "quotation_number", limit: 25
    t.string "po_number", limit: 25
    t.date "po_received"
    t.string "month_delivery", limit: 6
    t.string "remarks", limit: 512
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "semi_finish_good_outgoing_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "semi_finish_good_outgoing_id", null: false
    t.integer "product_id"
    t.integer "product_batch_number_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "semi_finish_good_outgoings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.integer "shop_floor_order_sterilization_id"
    t.string "number", limit: 25, null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "semi_finish_good_receiving_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "semi_finish_good_receiving_id", null: false
    t.integer "product_id"
    t.integer "product_batch_number_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "semi_finish_good_receivings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.date "date", null: false
    t.string "number", limit: 25, null: false
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "shop_floor_order_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "shop_floor_order_id", null: false
    t.integer "sales_order_id"
    t.integer "product_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "outstanding", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "outstanding_sterilization", precision: 16, scale: 4, default: "0.0", comment: "Produk yang belum dibuat Semi FG Receiving"
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "shop_floor_order_sterilization_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "shop_floor_order_sterilization_id", null: false
    t.integer "product_batch_number_id"
    t.integer "product_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "outstanding", precision: 16, scale: 4, default: "0.0", null: false
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "shop_floor_order_sterilizations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "kind", limit: 8, default: "internal", null: false, comment: "internal = sfo, external = sterilisasi produk receiving "
    t.bigint "sales_order_id"
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "sterilization_batch_number", limit: 20, null: false
    t.string "remarks", limit: 512
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.string "img_approved1_by", limit: 512
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "shop_floor_orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "sales_order_id"
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "kind", limit: 13, default: "production", null: false
    t.string "remarks", limit: 512
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.string "img_approved1_by", limit: 512
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.datetime "printed_at"
    t.integer "printed_by"
    t.datetime "unlock_printed_at"
    t.integer "unlock_printed_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "spreadsheet_contents", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "spreadsheet_report_id", default: 0, null: false
    t.integer "sequence_number", null: false
    t.string "name", limit: 50, null: false
    t.integer "created_by", null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
  end

  create_table "spreadsheet_reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "permission_base_id", null: false
    t.string "name", limit: 50, null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
  end

  create_table "sterilization_product_receiving_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "sterilization_product_receiving_id", null: false
    t.integer "product_batch_number_id"
    t.integer "sales_order_item_id"
    t.integer "product_id"
    t.decimal "quantity", precision: 16, scale: 4, default: "0.0", null: false
    t.decimal "outstanding", precision: 16, scale: 4, default: "0.0", null: false, comment: "yang belum dibuatkan sterilisasi"
    t.string "remarks", limit: 256
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "deleted_at"
    t.integer "deleted_by"
  end

  create_table "sterilization_product_receivings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.bigint "sales_order_id"
    t.date "date", null: false
    t.string "number", limit: 20, null: false
    t.string "remarks", limit: 512
    t.string "status", limit: 9, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "approved2_at"
    t.integer "approved2_by"
    t.datetime "approved3_at"
    t.integer "approved3_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
    t.datetime "canceled2_at"
    t.integer "canceled2_by"
    t.datetime "canceled3_at"
    t.integer "canceled3_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "supplier_ap_recaps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: "RANGKUMAN ACCOUNT PAYABLE \r\n\r\n", force: :cascade do |t|
    t.integer "company_profile_id", null: false
    t.integer "supplier_id", null: false
    t.string "periode", limit: 6, null: false
    t.decimal "debt", precision: 16, scale: 4
    t.decimal "remaining_debt", precision: 16, scale: 4
    t.decimal "payment", precision: 16, scale: 4
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at"
    t.integer "created_by"
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "supplier_payment_methods", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: "Global - Jenis-jenis Cara Pembayaran - aden", force: :cascade do |t|
    t.string "code", limit: 2, default: "0", null: false
    t.string "name", limit: 16, default: "0", null: false
    t.string "description", limit: 64, default: "-", null: false
    t.string "status", limit: 7, default: "active"
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "supplier_tax_invoices", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin", comment: "Faktur Pajak Supplierr Invoice", force: :cascade do |t|
    t.integer "company_profile_id", null: false
    t.integer "supplier_id", null: false
    t.string "periode", limit: 6, comment: "masa pelaporan pajak (\"YYYYMM\")"
    t.date "date"
    t.string "number", limit: 64
    t.decimal "subtotal", precision: 16, scale: 4
    t.decimal "amount", precision: 16, scale: 4
    t.decimal "ppntotal", precision: 16, scale: 4
    t.decimal "dpptotal", precision: 16, scale: 4
    t.decimal "total", precision: 16, scale: 4
    t.string "city", limit: 64, comment: "Nama Kota Faktur Pajak"
    t.text "remarks"
    t.string "status", limit: 9, default: "new", null: false
    t.boolean "checked", default: false
    t.integer "checked_by"
    t.datetime "checked_at"
    t.text "note_void"
    t.text "note_cancel_void"
    t.string "received_by", limit: 50
    t.date "received_at"
    t.integer "edit_lock_by"
    t.datetime "edit_lock_at"
    t.integer "approved1_by"
    t.datetime "approved1_at"
    t.integer "canceled1_by"
    t.datetime "canceled1_at"
    t.integer "approved2_by"
    t.datetime "approved2_at"
    t.integer "canceled2_by"
    t.datetime "canceled2_at"
    t.integer "approved3_by"
    t.datetime "approved3_at"
    t.integer "canceled3_by"
    t.datetime "canceled3_at"
    t.integer "voided_by", unsigned: true
    t.datetime "voided_at"
    t.integer "cancel_void_by"
    t.datetime "cancel_void_at"
    t.datetime "created_at"
    t.integer "created_by"
    t.datetime "updated_at"
    t.integer "updated_by"
    t.integer "suspend_by"
    t.datetime "suspend_at"
  end

  create_table "suppliers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.string "number", limit: 16, default: "0", null: false
    t.string "npwp_number", limit: 16, default: "0", null: false
    t.date "registered_at", null: false
    t.string "name"
    t.integer "tax_id"
    t.integer "currency_id"
    t.integer "top_day", null: false
    t.integer "term_of_payment_id", null: false
    t.string "business_description"
    t.string "address"
    t.string "pic"
    t.string "status", limit: 7, default: "active", null: false
    t.string "telephone"
    t.string "email"
    t.string "remarks"
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.index ["number"], name: "number", unique: true
  end

  create_table "tax_rates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.decimal "currency_value", precision: 16, scale: 4, null: false
    t.integer "currency_id", null: false
    t.date "begin_date", null: false
    t.date "end_date", null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "taxes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "term_of_payments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "units", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_permissions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "user_id", null: false
    t.integer "permission_base_id", null: false
    t.string "name"
    t.integer "access_view", limit: 1, default: 0, null: false
    t.integer "access_export", limit: 1, default: 0, null: false
    t.integer "access_create", limit: 1, default: 0, null: false
    t.integer "access_edit", limit: 1, default: 0, null: false
    t.integer "access_remove", limit: 1, default: 0, null: false
    t.integer "access_approve1", limit: 1, default: 0, null: false
    t.integer "access_cancel_approve1", limit: 1, default: 0, null: false
    t.integer "access_approve2", limit: 1, default: 0, null: false
    t.integer "access_cancel_approve2", limit: 1, default: 0, null: false
    t.integer "access_approve3", limit: 1, default: 0, null: false
    t.integer "access_cancel_approve3", limit: 1, default: 0, null: false
    t.integer "access_void", limit: 1, default: 0, null: false
    t.integer "access_cancel_void", limit: 1, default: 0, null: false
    t.integer "access_unlock_print", limit: 1, default: 0, null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "department_id"
    t.integer "employee_section_id"
    t.string "username"
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "status", limit: 7, default: "active", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "failed_attempts"
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "avatar"
    t.string "signature"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicle_inspection_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "vehicle_inspection_id", null: false
    t.string "kind_doc", limit: 34, null: false
    t.string "condition", limit: 14, null: false
    t.string "description", limit: 64, null: false
    t.string "status", limit: 7, default: "active", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
  end

  create_table "vehicle_inspections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_profile_id", default: 1
    t.integer "delivery_order_id", null: false
    t.string "number", limit: 50, null: false
    t.date "date", null: false
    t.string "vehicle_type", limit: 64, null: false
    t.string "vehicle_no", limit: 12, null: false
    t.string "status", limit: 9, default: "new", null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "approved1_at"
    t.integer "approved1_by"
    t.datetime "canceled1_at"
    t.integer "canceled1_by"
  end

  create_table "work_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "abbreviation", limit: 6, null: false, collation: "utf8_bin"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

end
