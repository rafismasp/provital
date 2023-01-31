// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery-ui
//= require uikit.min
//= require uikit-icons.min
//= require cards
//= require signature_pad.umd.min
//= require signature_pad
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require select2
//= require_tree .

function toggleLeft() {
   var element = document.getElementById("top-head");
   element.classList.toggle("toggleLeft");
   var element1 = document.getElementById("content");
   element1.classList.toggle("toggleLeft");
}

function sales_order_service_type(obj, ctrl, evt) {  
  $('.service_type_non_str:checked').each(function() {
    $('.service_type_str').prop('checked', false);
  }); 
}
function change_product_return_quantity(obj, ctrl, evt) {
  var qty = $(obj).val();
  if (qty > $(obj).attr("max")) {
    var qty = $(obj).attr("max");
    $(obj).val(qty);
  }

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_product_return_quantity", product_return_quantity: qty
    },
    dataType: "script",
    success: function (data){
    }
  }); 
}
function change_shop_floor_order(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_shop_floor_order",
      shop_floor_order_id: $(obj).find(":selected").val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_feature_list(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "load_feature_list",
      permission_base_id: $(obj).find(":selected").val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_material_category(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_material_category",
      material_category_id: $(obj).find(":selected").val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}

function change_product_category(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_product_category",
      product_category_id: $(obj).find(":selected").val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_product_sub_category(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_product_sub_category",
      product_category_id: $(obj).find(":selected").attr("product_category_id"),
      product_sub_category_id: $(obj).find(":selected").val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_product_type(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_product_type",
      product_category_id: $(obj).find(":selected").attr("product_category_id"),
      product_sub_category_id: $(obj).find(":selected").attr("product_sub_category_id"),
      product_type_id: $(obj).find(":selected").val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function filter_select(obj, ctrl, evt) {
  var href = "/"+ctrl+"/export";
  
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "filter_select",
      filter_column: $("#filter_column_name").find(':selected').val(),
      filter_value: $("#filter_value").val(),
      view_kind: $("#select_view_kind").find(':selected').val(),
      q: $(obj).attr("q"),
      q1: $(obj).attr("q1"),
      q2: $(obj).attr("q2")
    },
    dataType: "script",
    success: function (data){
      $(".button_export").attr("href",href+"?"+$("#filter_column_name").find(':selected').val()+"="+$("#filter_value").val());
    }
  });
}
function filter_select_column(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_filter_column",
      filter_column: $(obj).find(':selected').val(),
      view_kind: $("#select_view_kind").find(':selected').val(),
      q: $(obj).attr("q"),
      q1: $(obj).attr("q1"),
      q2: $(obj).attr("q2")
    },
    dataType: "script",
    success: function (data){
    }
  });
}


function export_report(obj, ctrl, evt) {
  if (ctrl == 'inventories' || ctrl == 'temporary_inventories') {
    var my_url = "/"+ctrl+"/export?periode="+$("#periode_yyyy").val()+$("#periode_mm").val()+"&invetory_kind="+$("#invetory_kind").val();
  } else if (ctrl == 'customer_ar_summaries') {
    var my_url = "/"+ctrl+"/export?periode_yyyy="+$("#periode_yyyy").val(); 
  } else if (ctrl == 'supplier_tax_invoices') {
    var my_url = "/"+ctrl+"/export?periode="+$("#periode_yyyy").val()+$("#periode_mm").val();   
  } else if (ctrl == 'production_orders') {
    if ($(obj).attr("view_kind") == 'detail_material') {
      var my_url = "/"+ctrl+"/export?id="+$(obj).attr("record_id");
    } else {
      var my_url = "/"+ctrl+"/export?date_begin="+$("#date_begin").val()+"&date_end="+$("#date_end").val();
    }
  } else if (ctrl == 'employees') {
    var my_url = "/"+ctrl+"/export?select_employee_status="+$("#select_employee_status").find(':selected').val()+"&select_employee_legal_id="+$("#select_employee_legal_id").find(':selected').val();
  } else if (ctrl == 'employee_schedules') {
    var select_period_yyyy = $("#periode_yyyy").find(':selected').val();
    var select_period_yyyymm = $("#periode_mm").find(':selected').val();
    var my_url = "/"+ctrl+"/export?period="+select_period_yyyy+select_period_yyyymm; 
  } else if (ctrl == 'employee_overtimes') {
    var my_url = "/"+ctrl+"/export?department_id="+$("#select_department").val()+"&period="+$("#periode_yyyy").val()+$("#periode_mm").val();
  } else if (ctrl == 'employee_presences'){
    var my_url = "/"+ctrl+"/export?employee_id="+$("#id").val()+"&view_kind="+$("#view_kind").val()+"&period="+$("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val();  
  } else {
    var my_url = "/"+ctrl+"/export?date_begin="+$("#date_begin").val()+"&date_end="+$("#date_end").val();
  }

  if ($("#select_view_kind").find(':selected').val() != null) {
    my_url += "&view_kind="+$("#select_view_kind").find(':selected').val();
  }

  if ($(obj).attr("q") != null) {
    my_url += "&q="+$(obj).attr("q");
  }
  window.open(my_url); 
}


function select_employee_legality(obj, ctrl, evt) {
  // var href = "/"+ctrl+"/export";

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      select_employee_legal_id: $("#select_employee_legal_id").find(':selected').val(),
      select_employee_status: $("#select_employee_status").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
      // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
    }
  });
}
function select_view_kind(obj, ctrl, evt) {
  // var href = "/"+ctrl+"/export";

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      date_begin: $("#date_begin").val(),
      date_end: $("#date_end").val(),
      view_kind: $(obj).find(':selected').val(),
      q: $(obj).attr("q"),
      q1: $(obj).attr("q1"),
      q2: $(obj).attr("q2")
    },
    dataType: "script",
    success: function (data){
      // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
    }
  });
}
function search_by_date(obj, ctrl, evt) {
  // var href = "/"+ctrl+"/export";

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      date_begin: $("#date_begin").val(),
      date_end: $("#date_end").val(),
      tbl_kind: $(obj).attr("tbl_kind"),
      view_kind: $(obj).attr("view_kind"),
      q: $(obj).attr("q"),
      q1: $(obj).attr("q1"),
      q2: $(obj).attr("q2")
    },
    dataType: "script",
    success: function (data){
      // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
    }
  });
}

function search_by_periode(obj, ctrl, evt) {
  if (ctrl == 'employee_schedules') {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        period: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val(),
        department_id: $("#select_department").find(':selected').val(),
        employee_id: $("#employee_id").val(),
        employee_name: $("#select_employee").val()
      },
      dataType: "script",
      success: function (data){
        // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
      }
    });
  } else {
  // inventories
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        periode: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val(),
        select_inventory_kind: $("#invetory_kind").find(':selected').val()
      },
      dataType: "script",
      success: function (data){
        // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
      }
    });
  }
}

function search_by_periode_yyyy(obj, ctrl, evt) {
  // supplier_ap_recaps
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      periode_yyyy: $("#periode_yyyy").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
      // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
    }
  });
}



function search_stock_card(obj, ctrl, evt) {
  // inventories
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "stock_card",
      periode: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val(),
      select_inventory_kind: $("#invetory_kind").find(':selected').val(),
      part: $(".part").val()
    },
    dataType: "script",
    success: function (data){
      // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
    }
  });
}
function change_inventory_kind(obj, ctrl, evt) {
  // inventories
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_inventory_kind",
      periode: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val(),
      select_inventory_kind: $("#invetory_kind").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
      // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
    }
  });
}

function change_efaktur_number(obj, seq, evt) {
  var inv_date = $(".invoice_date"+seq).val();
  var strtDt  = new Date(inv_date);
  var endDt  = new Date("2022-04-01");

  var prefix  = $(".efaktur_number"+seq).val().toString().substring(0, 2);
  var dpp = Number($(".dpp"+seq).val());
      // ppn = Number((dpp*10)/100);
  var ppn = Math.round(dpp * 10) / 100;
      // ppn = Number(dpp*0.1);

  if (strtDt >= endDt){
    ppn = Math.round(dpp * 11) / 100;
  }

  if (prefix=="01") {
    // alert("PPN 10%")
    if(!isNaN(dpp) && dpp!=0) {
      $(".ppn"+seq).val( ppn );
      $(".total"+seq).val( ppn+dpp );
    } else {
      $(".dpp"+seq).focus();  
    }
  } else if (prefix=="07") {
    // alert("PPN Ditangguhkan")
    $(".ppn"+seq).val( ppn );
    $(".total"+seq).val( dpp );
  } else {
    // alert("Tidak ada PPN")
    $(".ppn"+seq).val(0);
    $(".total"+seq).val( dpp );
  }
}

function change_internship(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_internship",
      employee_internship_id: $(obj).val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_employee(obj, ctrl, evt) {
  if (ctrl == 'employee_schedules') {  
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        period: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val(),
        department_id: $("#select_department").find(':selected').val(),
        employee_id: $("#employee_id").val(),
        employee_name: $(obj).val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "change_employee",
        employee_id: $(obj).val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}
function change_po_base(obj, ctrl, evt) {  
  // purchase order
  var request_kind = $("#q").val();
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_po_base",
      q: request_kind, po_base: $(obj).find(':selected').val(),
      select_department_id: $("#purchase_order_supplier_department_id").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_purchase_request_id(obj, ctrl, evt) {
  // if ($("#purchase_order_supplier_purchase_request_id").find(':selected').val() == null || $("#purchase_order_supplier_purchase_request_id").find(':selected').val() == '') {
  //  var request_kind = 'material';
  // } else {
  //  var request_kind = $("#purchase_order_supplier_purchase_request_id").find(':selected').attr('request_kind');
  // }
  var request_kind = $("#q").val();

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      id: $("#purchase_order_supplier_id").val(),
      partial: "change_purchase_request",
      purchase_request_id: $("#purchase_order_supplier_purchase_request_id").find(':selected').val(),
      q: request_kind, po_base: $("#po_base").find(':selected').val(),
      select_department_id: $("#purchase_order_supplier_department_id").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_pdm_id(obj, ctrl, evt) {
  var request_kind = 'material';
  
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_pdm",
      pdm_id: $("#purchase_order_supplier_pdm_id").find(':selected').val(),
      q: request_kind,
      select_department_id: $("#purchase_order_supplier_department_id").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}

 $('.myCheckbox').on('change', function(e) {
    if($(this).is(":checked")) {
      alert('checked');
    } else {
      alert('unchecked');
    }
    
  });


function checkbox_row_permission(obj, seq, evt) {
  if ($(this).attr("checked_all") == false ) {
    $(this).attr("checked_all", true);
    $(".rows_"+seq).prop('checked', true);
  } else {
    $(this).attr("checked_all", false);
    $(".rows_"+seq).prop('checked', false);
  }
}
function checkbox_column_permission(obj, column_name, pb_id, evt) {
  if ($(this).attr("checked_all") == false ) {
    $(this).attr("checked_all", true);
    $(".columns_"+column_name+"_"+pb_id).prop('checked', true);
  } else {
    $(this).attr("checked_all", false);
    $(".columns_"+column_name+"_"+pb_id).prop('checked', false);
  }
}
function load_production_order_detail_material(obj, ctrl, evt) {
  // purchase_request
    var select_spp   = [];
    $('.select_spp_id').each(function() {
      if (this.checked == true ) {
        select_spp.push($(this).attr("production_order_id"));
      } else {
        $('#production_order_id'+$(this).attr('production_order_id')).remove();
      } 
    }); 
    $('.production_order_id').each(function() {
      select_spp.push($(this).val());
    });

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "load_production_order_detail_material",
      q: $(obj).attr("q"),
      production_order_id: select_spp
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function load_bom_item(obj, ctrl, evt) {
  // material_outgoing
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "load_bom_item",
      product_id: $("#material_outgoing_product_batch_number_id").find(":selected").attr("product_id"),
      sfo_quantity: $("#material_outgoing_product_batch_number_id").find(":selected").attr("sfo_qty"),
      date: $("#material_outgoing_date").val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function load_material_receiving_id(obj, ctrl, evt) {
  // invoice_suppliers
  var value   = [];
  var diff_ppn = false;
  var tax = 0;
  $('.select_material_receiving_id:checked').each(function() {
    if($("#select_tax").find(':selected').val() == 5){
      if(($(this).attr("receiving_date")) < ("2022-04-01")){
        if(tax!=0 && tax !=2){
          diff_ppn = true
        }
        tax = 2
      }else{
        if(tax!=0 && tax !=5){
          diff_ppn = true
        }
        tax = 5
      }
    } else {
      tax = $("#select_tax").find(':selected').val();
    }
    value.push($(this).attr("material_receiving_id"));
  }); 

  if(diff_ppn==true){
    alert("Oops, Different PPN is not allowed.")
  }else{
    $("#select_tax").val(tax)
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_material_receiving",
        material_receiving_id: value,
        supplier_id: $("#invoice_supplier_supplier_id").find(':selected').val(),
        tax_id: $("#select_tax").find(':selected').val(),
        ppn_percent: $("#select_tax").find(':selected').attr("ppn_percent")
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}
function load_product_receiving_id(obj, ctrl, evt) {
  // invoice_suppliers
  var value   = [];
  var diff_ppn = false;
  var tax = 0;
  $('.select_product_receiving_id:checked').each(function() {
    if($("#select_tax").find(':selected').val() == 5){
      if(($(this).attr("receiving_date")) < ("2022-04-01")){
        if(tax!=0 && tax !=2){
          diff_ppn = true
        }
        tax = 2
      }else{
        if(tax!=0 && tax !=5){
          diff_ppn = true
        }
        tax = 5
      }
    } else {
      tax = $("#select_tax").find(':selected').val();
    }
    value.push($(this).attr("product_receiving_id"));
  }); 

  if(diff_ppn==true){
    alert("Oops, Different PPN is not allowed.")
  }else{
    $("#select_tax").val(tax)
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_product_receiving",
        product_receiving_id: value,
        supplier_id: $("#invoice_supplier_supplier_id").find(':selected').val(),
        tax_id: $("#select_tax").find(':selected').val(),
        ppn_percent: $("#select_tax").find(':selected').attr("ppn_percent")
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}
function load_general_receiving_id(obj, ctrl, evt) {
  // invoice_suppliers
  var value   = [];
  var diff_ppn = false;
  var tax = 0;
  $('.select_general_receiving_id:checked').each(function() {
    if($("#select_tax").find(':selected').val() == 5){
      if(($(this).attr("receiving_date")) < ("2022-04-01")){
        if(tax!=0 && tax !=2){
          diff_ppn = true
        }
        tax = 2
      }else{
        if(tax!=0 && tax !=5){
          diff_ppn = true
        }
        tax = 5
      }
    } else {
      tax = $("#select_tax").find(':selected').val();
    }
    value.push($(this).attr("general_receiving_id"));
  }); 
  if(diff_ppn==true){
    alert("Oops, Different PPN is not allowed.")
  }else{
    $("#select_tax").val(tax)
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_general_receiving",
        general_receiving_id: value,
        supplier_id: $("#invoice_supplier_supplier_id").find(':selected').val(),
        tax_id: $("#select_tax").find(':selected').val(),
        ppn_percent: $("#select_tax").find(':selected').attr("ppn_percent")
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}
function load_consumable_receiving_id(obj, ctrl, evt) {
  // invoice_suppliers
  var value   = [];
  var diff_ppn = false;
  var tax = 0;
  $('.select_consumable_receiving_id:checked').each(function() {
    if($("#select_tax").find(':selected').val() == 5){
      if(($(this).attr("receiving_date")) < ("2022-04-01")){
        if(tax!=0 && tax !=2){
          diff_ppn = true
        }
        tax = 2
      }else{
        if(tax!=0 && tax !=5){
          diff_ppn = true
        }
        tax = 5
      }
    } else {
      tax = $("#select_tax").find(':selected').val();
    }
    value.push($(this).attr("consumable_receiving_id"));
  }); 
  if(diff_ppn==true){
    alert("Oops, Different PPN is not allowed.")
  }else{
    $("#select_tax").val(tax)
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_consumable_receiving",
        consumable_receiving_id: value,
        supplier_id: $("#invoice_supplier_supplier_id").find(':selected').val(),
        tax_id: $("#select_tax").find(':selected').val(),
        ppn_percent: $("#select_tax").find(':selected').attr("ppn_percent")
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}
function load_equipment_receiving_id(obj, ctrl, evt) {
  // invoice_suppliers
  var value   = [];
  var diff_ppn = false;
  var tax = 0;
  $('.select_equipment_receiving_id:checked').each(function() {
    if($("#select_tax").find(':selected').val() == 5){
      if(($(this).attr("receiving_date")) < ("2022-04-01")){
        if(tax!=0 && tax !=2){
          diff_ppn = true
        }
        tax = 2
      }else{
        if(tax!=0 && tax !=5){
          diff_ppn = true
        }
        tax = 5
      }
    } else {
      tax = $("#select_tax").find(':selected').val();
    }
    value.push($(this).attr("equipment_receiving_id"));
  }); 
  if(diff_ppn==true){
    alert("Oops, Different PPN is not allowed.")
  }else{
    $("#select_tax").val(tax)
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_equipment_receiving",
        equipment_receiving_id: value,
        supplier_id: $("#invoice_supplier_supplier_id").find(':selected').val(),
        tax_id: $("#select_tax").find(':selected').val(),
        ppn_percent: $("#select_tax").find(':selected').attr("ppn_percent")
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}
function load_invoice_customer_id(obj, ctrl, evt) {
  if (ctrl == "picking_slips") { 
    // customer_tax_invoice
    var customer_selected = $("#payment_request_supplier_supplier_id").find(':selected').val();
  } else {
    // payment_customers
    var customer_selected = $("#payment_customer_customer_id").val();
  }


  var value   = [];
  $('.select_invoice_customer_id:checked').each(function() {
    value.push($(this).attr("invoice_customer_id"));
  }); 
  if (ctrl == "payment_customers") { 
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_invoice_customer",
        invoice_customer_id: value,
        customer_id: customer_selected,
        kind: $("#invoice_kind").val()
      },
      dataType: "script",
      success: function (data){
      }
    });  
  } else {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_invoice_customer",
        invoice_customer_id: value,
        customer_id: customer_selected
      },
      dataType: "script",
      success: function (data){
      }
    });    
  }
}



function change_payment_amount(obj, ctrl, evt) {
  // payment_customers
    var my_currency     = $("#payment_customer_currency_id").find(':selected').attr("name"),
        total_taxe      = parseFloat($(".total_tax").val().replace(/\./g,'')),
        total_amount    = parseFloat($(".total_amount").val().replace(/\./g,'')),
        adm_fee         = parseFloat($(".adm_fee").val().replace(/\./g,'')),
        other_cut_cost  = parseFloat($(".other_cut_cost").val().replace(/\./g,''));

    if(isNaN(total_taxe) || total_taxe==0 || total_taxe=="") { total_taxe = 0 }
    if(isNaN(total_amount) || total_amount==0 || total_amount=="") { total_amount = 0 }
    if(isNaN(adm_fee) || adm_fee==0 || adm_fee=="") { adm_fee = 0 }
    if(isNaN(other_cut_cost) || other_cut_cost==0 || other_cut_cost=="") { other_cut_cost = 0 }
    var paid            = total_amount+adm_fee-other_cut_cost;
    if (my_currency == "IDR") { mfd = 2 } else { mfd = 4}
    $(".adm_fee").val(adm_fee.toLocaleString('id-ID', {minimumFractionDigits: mfd}))
    $(".other_cut_cost").val(other_cut_cost.toLocaleString('id-ID', {minimumFractionDigits: mfd}))
    $("#payment_customer_paid").val((paid).toLocaleString('id-ID', {minimumFractionDigits: mfd}))
}

function load_invoice_supplier_id(obj, ctrl, evt) {
  // payment_request_supplier
  var value   = [];
  $('.select_invoice_supplier_id:checked').each(function() {
    value.push($(this).attr("invoice_supplier_id"));
  }); 
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "load_invoice_supplier",
      invoice_supplier_id: value,
      supplier_id: $("#payment_request_supplier_supplier_id").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}

// supplier_ap_summary

function addDays(date, days) {
  var result = new Date(date);
  result.setDate(result.getDate() + days);
  return formatDate(result);
}

function formatDate(date) {
  var d = new Date(date),
      month = '' + (d.getMonth() + 1),
      day = '' + d.getDate(),
      year = d.getFullYear();

  if (month.length < 2) month = '0' + month;
  if (day.length < 2) day = '0' + day;

  return [year, month, day].join('-');
}

function diff_date(obj, seq, id) {
  var date1 = new Date($(".due_date_checked"+seq+""+id).val());
  var date2 = new Date($(".date_checked"+seq+""+id).val());

  var timeDiff = Math.abs(date2.getTime() - date1.getTime());
  var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24)); 
  
  if (date2 > date1) {
    $(".diff_date"+seq+""+id).html(diffDays);
  } else {
    $(".diff_date"+seq+""+id).html("");             
  }           
}
function diff_date_payment(obj, id) {
  var date1 = new Date($(".due_date_payment"+id).text());
  var date2 = new Date($(".date_payment"+id).val());
  var timeDiff = Math.abs(date2.getTime() - date1.getTime());
  var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24)); 
  if (date2 > date1) {
    $(".diff_date_payment"+id).html(diffDays);
    $(".diff_date_payment"+id).attr("style", "color:yellow;");
    $(".diff_date_payment"+id).attr("bgcolor", "purple");
  } else {
    $(".diff_date_payment"+id).html("");    
    $(".diff_date_payment"+id).attr("bgcolor", "");   
    $(".diff_date_payment"+id).attr("style", "");   
  }           
}
function change_amount_payment(obj, id) {
  var amount_invoice = $(".amount_invoice"+id).html(),
      amount_payment = $(".amount_payment"+id).val();
  $(".sisa_ap"+id).html(parseFloat(amount_invoice).toFixed(4) - parseFloat(amount_payment).toFixed(4));
}

function load_payment_request_supplier_id(obj, ctrl, evt) {
  // payment_supplier
  var value   = [];
  $('.select_payment_request_supplier_id:checked').each(function() {
    value.push($(this).attr("payment_request_supplier_id"));
  }); 
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "load_payment_request_supplier",
      payment_request_supplier_id: value,
      supplier_id: $("#payment_supplier_supplier_id").val(),
      payment_supplier_kind_dpp: $("#payment_supplier_kind_dpp").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function load_payment_supplier_id(obj, ctrl, evt) {
  // template bank
  var value   = [];
  var value2  = [];
  // $('.select_payment_supplier_id:checked').each(function() {
  //   value.push($(this).attr("payment_supplier_id"));
  // }); 
  $('.select_payment_supplier_id:checked').each(function() {
    if($(this).attr('table_name') == 'payment_suppliers'){
      value.push($(this).attr('val'));
    }else if($(this).attr('table_name') == 'voucher_payments'){
      value2.push($(this).attr('val'));
    }
  });
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "load_payment_supplier",
      // payment_supplier_id: value,
      value: value,
      value2: value2
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_fp_number(obj, ctrl, evt) {
  // supplier_tax_invoice
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_fp_number",
      fp_number: $(obj).val(),
      supplier_id: $("#supplier_tax_invoice_supplier_id").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}


function change_currency_tax_rate(obj, ctrl, seq, evt) {        
  // payment_request_supplier   
  var exchange_rate = $(obj).find(':selected').attr('currency_value'),
      my_tax_rate   = $(obj).find(':selected').val(),
      my_currency = $(obj).attr('currency'),
      my_ppn   = parseFloat($(obj).attr('ppn')); // nilai total ppn sebelum diubah

    if ( $(obj).find(':selected').val() == "" ) {
      $(".currency"+seq).html(my_currency);
      $(".ppntotal"+seq).val( my_ppn );
    } else {
      $(".currency"+seq).html("IDR");
      $(".ppntotal"+seq).val( exchange_rate * my_ppn );
    }
}


function change_unit_price(obj, ctrl, cnt, evt) {
  // invoice supplier
  var qty = parseFloat($(".hidden_quantity"+cnt).val());
  var price = parseFloat($(obj).val());
  var total = qty*price;
  $(".total"+cnt).html(total);
  $(".hidden_total"+cnt).val(total);
  var subtotal = 0
  var ppntotal = 0;
  $('.subtotal_item').each(function() {
    subtotal += parseFloat($(this).val());
  });
  $("#invoice_supplier_subtotal").val(subtotal);
  if (Number($("#invoice_supplier_tax_id").find(":selected").val()) == 2 ){
    // ppn 10%
    var ppntotal = subtotal*0.1;
  }
  var dptotal = parseFloat($("#invoice_supplier_dptotal").val());

  var grandtotal = (subtotal+ppntotal)-dptotal;
  $("#invoice_supplier_ppntotal").val(ppntotal);
  $("#invoice_supplier_grandtotal").val(grandtotal);
}

function change_down_payment(obj, ctrl, evt) {
  // invoice supplier
  var subtotal = parseFloat($("#invoice_supplier_subtotal").val());
  var ppntotal = parseFloat($("#invoice_supplier_ppntotal").val());
  var pphtotal = parseFloat($("#invoice_supplier_pphtotal").val());
  var dptotal  = parseFloat($(obj).val());

  var grandtotal = ((subtotal+ppntotal)-pphtotal)-dptotal;
  $("#invoice_supplier_grandtotal").val(grandtotal);
}

function change_pph_percent(obj, ctrl, evt) {
  // invoice supplier
  var subtotal = parseFloat($("#invoice_supplier_subtotal").val());
  var ppntotal = parseFloat($("#invoice_supplier_ppntotal").val());
  var dptotal = parseFloat($("#invoice_supplier_dptotal").val());
  var pphpercent  = parseFloat($(obj).val());
  var pphtotal = (subtotal*pphpercent)/100;
  
  $("#invoice_supplier_pphtotal").val(pphtotal);
  var grandtotal = ((subtotal+ppntotal)-pphtotal)-dptotal;
  $("#invoice_supplier_grandtotal").val(grandtotal);
}
function change_pph_total(obj, ctrl, evt) {
  // invoice supplier
  var subtotal = parseFloat($("#invoice_supplier_subtotal").val());
  var ppntotal = parseFloat($("#invoice_supplier_ppntotal").val());
  var dptotal = parseFloat($("#invoice_supplier_dptotal").val());
  var pphtotal  = parseFloat($(obj).val());

  var grandtotal = ((subtotal+ppntotal)-pphtotal)-dptotal;
  $("#invoice_supplier_grandtotal").val(grandtotal);
  $("#pphpercent").val((pphtotal/subtotal)*100 );
}



function change_picking_slip_id(obj, ctrl, evt) {
  if (ctrl == "delivery_orders") {
    if ($("#delivery_order_picking_slip_id").find(':selected').val() == null || $("#delivery_order_picking_slip_id").find(':selected').val() == '') {
      UIkit.notification.closeAll();
      UIkit.notification({
        message: 'Please select Picking Slip', status: 'warning', pos: 'top-center', timeout: 10000
      });
      $("#delivery_order_picking_slip_id").focus();
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "change_picking_slip",
          picking_slip_id: $("#delivery_order_picking_slip_id").find(':selected').val(),
          sales_order_id: $("#delivery_order_picking_slip_id").find(':selected').attr("sales_order_id"),
          po_number: $("#delivery_order_picking_slip_id").find(':selected').attr("po_number"),
          month_delivery: $("#delivery_order_picking_slip_id").find(':selected').attr("month_delivery"),
        },
        dataType: "script",
        success: function (data){

        }
      });
    } 
  } else if (ctrl == "outgoing_inspections") {
    if ($("#outgoing_inspection_picking_slip_id").find(':selected').val() == null || $("#outgoing_inspection_picking_slip_id").find(':selected').val() == '') {
      alert("Please select Picking Slip Number");
      $("#outgoing_inspection_picking_slip_id").focus();
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          outgoing_inspection_id: $(obj).attr("outgoing_inspection_id"),
          partial: "change_picking_slip",
          picking_slip_id: $("#outgoing_inspection_picking_slip_id").find(':selected').val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    } 
  }
}

function change_sales_order_id(obj, ctrl, evt) {
  if (ctrl == "picking_slips") {
    if ($("#picking_slip_sales_order_id").find(':selected').val() == null || $("#picking_slip_sales_order_id").find(':selected').val() == '') {
      UIkit.notification.closeAll();
      UIkit.notification({
        message: 'Please select PO', status: 'warning', pos: 'top-center', timeout: 10000
      });
      $("#picking_slip_sales_order_id").focus();
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "change_sales_order",
          sales_order_id: $("#picking_slip_sales_order_id").find(':selected').val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    } 

  } else if (ctrl == "sterilization_product_receivings") {
    if ($("#sterilization_product_receiving_sales_order_id").find(':selected').val() == null || $("#sterilization_product_receiving_sales_order_id").find(':selected').val() == '') {
      alert("Please select PO");
      $("#sterilization_product_receiving_sales_order_id").focus();
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "change_sales_order",
          sales_order_id: $("#sterilization_product_receiving_sales_order_id").find(':selected').val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    } 

  } 
}

function load_product_batch_number_id(obj, ctrl, form_kind, picking_slip_id, evt) {
  if (ctrl == "picking_slips") {
    var value   = [];
    $('.select_product_batch_number_id').each(function() {
      if (this.checked == true ) {
        value.push($(this).attr("product_batch_number_id"));
      } else {
        $('#product_batch_number_id'+$(this).attr('product_batch_number_id')).remove();
      } 
    }); 
    $('.product_batch_number_id').each(function() {
      value.push($(this).val());
    }); 

    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_product_batch_number",
        sales_order_id: $("#picking_slip_sales_order_id").find(':selected').val(),
        product_batch_number_id: value,
        form_kind: form_kind, date: $("#picking_slip_date").val(),
        id: picking_slip_id
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}


function change_purchase_order_supplier_id(obj, ctrl, evt) {
    if ($(".purchase_order_supplier_id").find(':selected').val() == null || $(".purchase_order_supplier_id").find(':selected').val() == '') {
      alert("Please select PO");
      $(".purchase_order_supplier_id").focus();
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "change_purchase_order_supplier",
          purchase_order_supplier_id: $(".purchase_order_supplier_id").find(':selected').val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    } 

}



function change_supplier(obj, ctrl, evt) {
  // purchase_order_suppliers
  // invoice_suppliers
  // payment_request_suppliers

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_supplier",
      supplier_id: $(obj).find(':selected').val(),
      select_tax_id: $(obj).find(':selected').attr("tax_id"),
      select_currency_id: $(obj).find(':selected').attr("currency_id"),
      select_top_day: $(obj).find(':selected').attr("top_day"),
      select_term_of_payment_id: $(obj).find(':selected').attr("term_of_payment_id")
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_supplier_tax(obj, ctrl, evt) {
  // invoice_suppliers

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_supplier",
      select_tax_id: $(obj).find(':selected').val(),
      supplier_id: $(obj).find(':selected').attr("supplier_id"),
      select_currency_id: $(obj).find(':selected').attr("currency_id"),
      select_top_day: $(obj).find(':selected').attr("top_day"),
      select_term_of_payment_id: $(obj).find(':selected').attr("term_of_payment_id")
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_department(obj, ctrl, evt) {
  if (ctrl == 'employee_schedules' || ctrl == 'employee_presences' || ctrl == 'working_hour_summaries') {
    if ($("#periode_mm").val() == null || $("#periode_mm").val() == '') {
      var dept_id = $("#dept_id").val();
      UIkit.notification.closeAll();
      UIkit.notification({
        message: " Select Period First, Please!", status: 'warning', pos: 'top-center', timeout: 10000
      });
      $("#periode_mm").css('background','yellow');
      $(obj).val(dept_id);
    } else {
      $("#periode_mm").css('background','white');
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          period: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val(),
          department_id: $(obj).find(':selected').val(),
          kind: $("#select_view_kind").find(':selected').val()
        },
        dataType: "script",
        success: function (data){
          $("#employee_id").val(null)
          $("#select_employee").val(null)
          // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
        }
      });
    }
  } else if (ctrl == 'employee_overtimes') {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        year: $("#periode_yyyy").val(),
        month: $("#periode_mm").val(),
        department_id: $(obj).find(':selected').val()
      },
      dataType: "script",
      success: function (data){
        $("#employee_id").val(null)
        $("#select_employee").val(null)
        // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
      }
    });
  } else {
    // purchase_order_suppliers
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "change_department",
        select_department_id: $(obj).find(':selected').val(),     
        q: $("#q").val(), po_base: $("#po_base").find(':selected').val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}


function change_kind_adjustment(obj, ctrl, evt) {
  // adjustment
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_kind",
      select_kind: $(obj).find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_kind_fg_rcv(obj, ctrl, evt) {
  // finish_good_receiving_note
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_kind",
      select_kind: $(obj).find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function change_kind_sfos(obj, ctrl, evt) {
  // shop_floor_order_sterilizations
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_kind",
      select_kind: $(obj).find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}



function change_customer(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_customer",
      customer_id: $(obj).val()
    },
    dataType: "script",
    success: function (data){
      $("#top_day").val($(obj).find(":selected").attr("top_day"));
      $("#top_kind").val($(obj).find(":selected").attr("top_kind"));
      $(".select_ppn").val($(obj).find(":selected").attr("ppn"));
    }
  });
}
function change_interval_job_list(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_interval",
      interval: $(obj).val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}
function show_form(obj, evt) { 
  window.location = $(obj).data("link")
}



function add_attendence(obj, ctrl, evt) {
  var counter = Number($('.attendence_list tr:last .counter').text());
    if (counter == "") {
      counter = 1
    } else {
      counter +=1
    }
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "add_attendence",
      c: counter
    },
    dataType: "script",
    success: function (data){
    }
  });
}

function add_meeting_minute_item(obj, ctrl, evt) {
  var counter = Number($('.meeting_minute_item_list tr:last .counter').text());
    if (counter == "") {
      counter = 1
    } else {
      counter +=1
    }
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "add_meeting_minute_item",
      c: counter
    },
    dataType: "script",
    success: function (data){
    }
  });
}



function add_pic_meeting_minute_item(obj, ctrl, evt) {
  var c = $(obj).parent().attr("add_pic_counter");
  var btnc = Number($(obj).parent().attr("counter"))+1;
  $(obj).parent().attr("counter", btnc);
  var account_id = [];
  $('.select_accounts').each(function() {
    account_id.push($(obj).val());      
  });
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "add_pic",
      c: c, btnc: btnc, account_id: account_id
    },
    dataType: "script",
    success: function (data){
    }
  });
}

function change_activity_labor(obj, ctrl, evt) {
  // direct_labor
  var c = $(obj).attr("c");
  var activity_c = $(obj).attr("activity_c");
  var quantity = $('.'+c+'quantity_h'+activity_c).val();
  var price = $('.'+c+'activity_h'+activity_c).find(':selected').attr('price');
  var ratio = $('.'+c+'activity_h'+activity_c).find(':selected').attr('ratio');
  var activity_id = $('.'+c+'activity_h'+activity_c).find(':selected').val();
  var direct_labor_price_detail_id = $('.'+c+'activity_h'+activity_c).find(':selected').val();

  $('.'+c+'price_h'+activity_c).val(price);
  $('.'+c+'quantity_h'+activity_c).attr("activity_id", activity_id);
  $('.'+c+'total_h'+activity_c).val(quantity*price);

  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_activity_labor",
      c: c,
      activity_c: activity_c, activity_id: activity_id,
      product_batch_number_id: $(".product_batch_number_id"+c).val(),
      direct_labor_price_detail_id: direct_labor_price_detail_id,
      ratio: ratio
    },
    dataType: "script",
    success: function (data){
    }
  });
  
}

function load_product_by_sales_order_id(obj, ctrl, so_id) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_sales_order", sales_order_id: so_id,
      c: $(obj).attr("c"), job: $(obj).attr("job")
    },
    dataType: "script",
    success: function (data){
    }
  });
}

function add_item(obj, ctrl, evt) {
  var counter = Number($('#item tr:last .counter').text());
    if (counter == "") {
      counter = 1
    } else {
      counter +=1
    }
  if (ctrl == "internal_transfers") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item",
        c: counter,
        transfer_kind: $(".transfer_kind").val(),
        q: $("#q").val(),
        q1: $("#q1").val(),
        q2: $("#q2").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "inventory_adjustments") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item",
        c: counter,
        kind: $("#inventory_adjustment_kind").find(":selected").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "finish_good_receivings") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item",
        c: counter,
        kind: $("#finish_good_receiving_kind").find(":selected").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "purchase_requests") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item",
        c: counter,
        request_kind: $(".request_kind").val(),
        q: $("#q").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "delivery_orders") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item", sales_order_id: $(obj).attr("sales_order_id"),
        c: counter
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "shop_floor_orders") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item", sales_order_id: $(obj).attr("sales_order_id"),
        c: counter,
        q: $(obj).attr("q")
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "shop_floor_order_sterilizations") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item", 
        c: counter,
        select_kind: $(obj).attr("select_kind")
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "sales_orders") {
    if ($(".service_type_str").prop('checked') == false && $(".service_type_non_str").prop('checked') == false) {
      $("#sales_order_service_type_mfg").prop('checked', true);
    }
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item", c: counter,
        service_type_str: $("#sales_order_service_type_str").prop('checked')
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == "voucher_payments") {
    var counter = Number($('#item .tbody_item tr:last .counter').text());
      if (counter == "") {
        counter = 1
      } else {
        counter +=1
      }
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item", c: counter
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item",
        c: counter,
        q: $(obj).attr("q")
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}

function open_tab_spp(obj, ctrl, evt) {
  if (ctrl == "purchase_requests") {
    var counter = Number($('#item tr:last .counter').text());
    if (counter == "") {
      counter = 1
    } else {
      counter +=1
    }
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "tab_spp",
        c: counter,
        request_kind: $(".request_kind").val(),
        q: $("#q").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}

function add_item_spp(obj, ctrl, evt) {
  if (ctrl == "purchase_requests") {
    var spp_item_id = $(obj).attr("production_order_item_id");
    var counter = Number($('#item_'+spp_item_id+' tr:last .counter').text());
    if (counter == "") {
      counter = 1
    } else {
      counter +=1
    }
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_item_spp",
        c: counter,
        production_order_item_id: spp_item_id,
        request_kind: $(".request_kind").val(),
        q: $("#q").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}

function load_spp_by_prf(obj, ctrl, evt) {
  if (ctrl == "purchase_requests") {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_spp_by_prf",
        purchase_request_id: $(obj).attr("purchase_request_id"),
        production_order_id: $(obj).attr("production_order_id"),
        request_kind: $(".request_kind").val(),
        q: $("#q").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}

function change_batch_number(obj, ctrl, counter, evt) {
  $('.product_id'+counter).val($(obj).find(':selected').attr('product_id'));
  $('.part_name'+counter).val($(obj).find(':selected').attr('part_name'));
  $('.part_id'+counter).val($(obj).find(':selected').attr('part_id'));
  $('.unit_name'+counter).val($(obj).find(':selected').attr('unit_name'));
  $('.part_model'+counter).val($(obj).find(':selected').attr('part_model'));
}
function change_product_id(obj, ctrl, counter, evt) {
  $('.part_id'+counter).val($(obj).find(':selected').attr('part_id'));
  $('.unit_name'+counter).val($(obj).find(':selected').attr('unit_name'));
  $('.part_model'+counter).val($(obj).find(':selected').attr('part_model'));
}
function change_material_batch_number(obj, ctrl, counter, evt) {
  $('.material_id'+counter).val($(obj).find(':selected').attr('material_id'));
  $('.part_name'+counter).val($(obj).find(':selected').attr('part_name'));
  $('.part_id'+counter).val($(obj).find(':selected').attr('part_id'));
  $('.unit_name'+counter).val($(obj).find(':selected').attr('unit_name'));
  $('.part_model'+counter).val($(obj).find(':selected').attr('part_model'));

  $('.quantity'+counter).attr('max', $(obj).find(':selected').attr('end_stock'));
  $('.quantity'+counter).attr('title', 'Stock untuk Batch Number adalah: '+$(obj).find(':selected').attr('end_stock'));
}
function change_material_id(obj, ctrl, counter, evt) {
  $('.part_id'+counter).val($(obj).find(':selected').attr('part_id'));
  $('.unit_name'+counter).val($(obj).find(':selected').attr('unit_name'));
  $('.part_model'+counter).val($(obj).find(':selected').attr('part_model'));
}
function change_consumable_id(obj, ctrl, counter, evt) {
  $('.part_id'+counter).val($(obj).find(':selected').attr('part_id'));
  $('.unit_name'+counter).val($(obj).find(':selected').attr('unit_name'));
  $('.part_model'+counter).val($(obj).find(':selected').attr('part_model'));
}
function change_general_id(obj, ctrl, counter, evt) {
  $('.part_id'+counter).val($(obj).find(':selected').attr('part_id'));
  $('.unit_name'+counter).val($(obj).find(':selected').attr('unit_name'));
  $('.part_model'+counter).val($(obj).find(':selected').attr('part_model'));
}
function change_equipment_id(obj, ctrl, counter, evt) {
  $('.part_id'+counter).val($(obj).find(':selected').attr('part_id'));
  $('.unit_name'+counter).val($(obj).find(':selected').attr('unit_name'));
  $('.part_model'+counter).val($(obj).find(':selected').attr('part_model'));
}



function check_outstanding_po(obj, sales_order_item_id, quantity_max, evt) {
  // picking slip
  var quantity = 0;
  $('.quantity'+sales_order_item_id).each(function() {
    var s = $(this).val();
    var num = parseFloat(s) || 0;
    quantity += num;
    if (quantity > quantity_max) {
      UIkit.notification.closeAll();
      UIkit.notification({
        message: 'tidak boleh lebih besar dari Outstanding PO', status: 'warning', pos: 'top-center', timeout: 10000
      });
      $(this).val(0);
      return false;
    }
  });
}

function change_bom_quantity(obj, seq, evt) {
  // bill of material
  var std_qty = parseFloat($(".standard_quantity"+seq).val());
  var allowance = parseFloat($(".allowance"+seq).val())/100;

  $(".quantity"+seq).val((std_qty*allowance)+std_qty);
}
function change_bom_wip_quantity(obj, seq, evt) {
  // bill of material
  var std_qty = parseFloat($(".wip"+seq+"_standard_quantity").val());
  var allowance = parseFloat($(".wip"+seq+"_allowance").val())/100;

  $(".wip_quantity"+seq).val((std_qty*allowance)+std_qty);
}

function change_material_outgoing_id(obj, ctrl, evt) {
  // rejected material
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_material_outgoing",
      material_outgoing_id: $("#rejected_material_material_outgoing_id").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
      //$("#top_day").val($(obj).find(":selected").attr("top_day"));
      //$("#top_kind").val($(obj).find(":selected").attr("top_kind"));
     }
  });
}

function change_print_contract(obj, id) {

  var work_time  = $("#work_time").val();
  var salary     = $("#salary").val();

  // if(position =="supervisor_up"){
  //   $(".div_work_time").attr("style","display:none;");
  //   $(".div_salary").attr("style","display:none;");
  //   $("#salary").val('exclude');
  //   $("#work_time").val('non_shift');
  // }else{
  //   $(".div_work_time").removeAttr("style");
  //   $(".div_salary").removeAttr("style");
  // }

    // work_time  = $("#work_time").val();
    // salary     = $("#salary").val();
    $(".button_print_contract").attr("href","/employee_contracts/"+id+".pdf?work_time="+work_time+"&salary="+salary);
  // change_print_type_contract Position
}

function select_absence_type(obj, ctrl, evt) {
  if ($("#employee_absence_employee_absence_type_id").val() != '') {
    $("#employee_absence_employee_absence_type_id").filter(function(){return this}).css('background','white');
    var attachment_required = $('.select_absence_type').find(':selected').attr('attachment_required'),
    max_day             = $('.select_absence_type').find(':selected').attr('max');
    $("#employee_absence_end_date").val(null);
    $("#days").val('0 Hari');
    $("#employee_absence_day").val(0);
    if ($('.select_absence_type').find(':selected').val() !="") {   
      $('.notif_max_day').html("Maksimal "+max_day+" Hari");
    } else {
      $('.notif_max_day').html("");
    }
    if (attachment_required == '1') {
      $(".employee_absence_file").show();
      $(".employee_file").show();
      $(".employee_absence_file").prop('required',true);

    } else {
      $(".employee_absence_file").hide();
      $(".employee_file").hide();
      $(".employee_absence_file").prop('required',false);
    }
  }
}

function load_approve(obj, ctrl, evt) {
  if (ctrl == 'employee_presences') {
    if ($("#periode_mm").val() == null || $("#periode_mm").val() == '') {
      UIkit.notification.closeAll();
      UIkit.notification({
        message: " Select Period First, Please!", status: 'warning', pos: 'top-center', timeout: 10000
      });
      $('#periode_mm').filter(function(){return this}).css('background','yellow');
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "approve_all",
          period: $("#periode_yyyy").val()+$("#periode_mm").val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    }
  } else {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "approve_all"
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}

function load_absence(obj, ctrl, evt) {
  if (ctrl == 'employee_absences') {
    var department = $('#select_department').val();
    var period_yyyy = $('#select_period_yyyy').val();
    var period_yyyymm = $('#select_period_yyyymm').val();
    var status = $('#select_status').val();
    var absence_type = $('#select_absence_type').val();
    var period_now = period_yyyy+period_yyyymm;
    if ($('#select_period_yyyy').val() == '' ) {
      alert('Tahun periode tidak boleh kosong');
      $('#select_period_yyyy').focus();
      $('#select_period_yyyy').filter(function(){return this}).css('background','yellow');
    } else if ($('#select_period_yyyymm').val() == '') {
      alert('Periode cuti tidak boleh kosong');
      $('#select_period_yyyymm').focus();
      $('#select_period_yyyymm').filter(function(){return this}).css('background','yellow');
    } else if ($('#select_status').val() == '') {
      alert('Status approve tidak boleh kosong');
      $('#select_status').focus();
      $('#select_status').filter(function(){return this}).css('background','yellow');
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "approve_all",
          kind_tbl: 'approve',
          job: 'edit',
          period: period_now, select_status: status,
          select_department: department,
          select_absence_type: absence_type
         },
        dataType: "script",
        success: function(data){
        }
      });
    }
  } else if (ctrl == 'employee_presences') {
    var period_yyyy = $('#periode_yyyy').val();
    var period_yyyymm = $('#periode_mm').val();
    var status = $('#select_status').val();
    var period_now = period_yyyy+period_yyyymm;
    if ($('#select_period_yyyy').val() == '' ) {
      alert('Tahun periode tidak boleh kosong');
      $('#select_period_yyyy').focus();
      $('#select_period_yyyy').filter(function(){return this}).css('background','yellow');
    } else if ($('#select_period_yyyymm').val() == '') {
      alert('Periode absen tidak boleh kosong');
      $('#select_period_yyyymm').focus();
      $('#select_period_yyyymm').filter(function(){return this}).css('background','yellow');
    } else if ($('#select_status').val() == '') {
      alert('Status approve tidak boleh kosong');
      $('#select_status').focus();
      $('#select_status').filter(function(){return this}).css('background','yellow');
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "approve_all",
          kind_tbl: 'manual',
          job: 'edit',
          period: period_now, select_status: status
         },
        dataType: "script",
        success: function(data){
        }
      });
    }
  } else if (ctrl == 'employee_overtimes') {
    var period_yyyy = $('#select_period_yyyy').val();
    var period_yyyymm = $('#select_period_yyyymm').val();
    var status = $('#select_status').val();
    var period_now = period_yyyy+period_yyyymm;
    if ($('#select_period_yyyy').val() == '' ) {
      alert('Tahun periode tidak boleh kosong');
      $('#select_period_yyyy').focus();
      $('#select_period_yyyy').filter(function(){return this}).css('background','yellow');
    } else if ($('#select_period_yyyymm').val() == '') {
      alert('Periode tidak boleh kosong');
      $('#select_period_yyyymm').focus();
      $('#select_period_yyyymm').filter(function(){return this}).css('background','yellow');
    } else if ($('#select_status').val() == '') {
      alert('Status approve tidak boleh kosong');
      $('#select_status').focus();
      $('#select_status').filter(function(){return this}).css('background','yellow');
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "approve_all",
          kind_tbl: 'approve',
          job: 'edit',
          period: period_now, select_status: status
         },
        dataType: "script",
        success: function(data){
        }
      });
    }
  }
}
function change_begin_date(obj, ctrl, evt) {
  if ($("#employee_absence_employee_absence_type_id").val() == '') {
    alert("Please absence types");
    $("#employee_absence_employee_absence_type_id").focus();
    $("#employee_absence_employee_absence_type_id").filter(function(){return this}).css('background','yellow');
  } else {
    var bdate = new Date($("#employee_absence_begin_date").val());
    var edate = new Date($("#employee_absence_end_date").val());
    var max_day = $('.select_absence_type').find(':selected').attr('max');
    var diffDays = Math.round(Math.abs((edate - bdate) / (24 * 60 * 60 * 1000)) +1);
    if ((diffDays) > max_day) {
      alert('Tidak boleh lebih '+max_day+' hari');
      $("#employee_absence_end_date").val(null);
    } else {
      if (edate > bdate) {
        $("#days").val((diffDays) + " Hari");
        $("#employee_absence_day").val(diffDays);
      } else if (edate < bdate){
        alert('Date end cannot be less than the date begin');
        $("#employee_absence_end_date").val(null);
      } else {
        $("#days").val("1 Hari");
        $("#employee_absence_day").val(1);
      }            
    }
  } 
}

function change_end_date(obj, ctrl, evt) {
  var bdate = new Date($("#employee_absence_begin_date").val());
  var edate = new Date($("#employee_absence_end_date").val());
  var max_day = $('.select_absence_type').find(':selected').attr('max');
  var absence_type = $('.select_absence_type').find(':selected').val();
  var os_leave = $("#leave_os").attr('value');
  var diffDays = Math.round(Math.abs((edate - bdate) / (24 * 60 * 60 * 1000)) +1);

  if ($("#employee_absence_begin_date").val() == null || $("#employee_absence_begin_date").val() == '') {
    alert("Please select begin date first");
    $("#employee_absence_end_date").val(null);
    $("#employee_absence_begin_date").focus();
  } else if (edate < bdate) {
    alert('Date end cannot be less than the date begin');
    $("#days").val('0 Hari');
    $("#employee_absence_day").val(null);
    $("#employee_absence_end_date").val(null);;
  } else {
    switch (absence_type) {
      case '9':
        if (diffDays > os_leave) {
          alert('Pengajuan cuti melebihi sisa cuti');
          $("#employee_absence_end_date").val(null);
        } else if (diffDays > max_day) {
          alert('Pengajuan cuti melebihi maksimal cuti');
          $("#employee_absence_end_date").val(null);
        }
        $("#days").val(diffDays+" Hari");
        $("#employee_absence_day").val(diffDays); 
        break;
      case '10':
      case '11':
        $("#days").val(diffDays+" Hari");
        $("#employee_absence_day").val(diffDays);
        break;
      default:
        if (diffDays > max_day) {
          alert('Pengajuan ketidakhadiran melebihi maksimal hari');
          $("#employee_absence_end_date").val(null);
        }
        $("#days").val(diffDays+" Hari");
        $("#employee_absence_day").val(diffDays);
    }
  } 
}

// Akpiiz Start (Routine Cost , Kasbon)
function select_interval(obj, ctrl, evt) {
  if (ctrl == "routine_costs") {
    // Routine Cost
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "change_interval",
        interval_type: $("#routine_cost_interval").find(':selected').val()
      },
      dataType: "script",
      success: function (data){
        //$("#top_day").val($(obj).find(":selected").attr("top_day"));
        //$("#top_kind").val($(obj).find(":selected").attr("top_kind"));
       }
    });
  };
}


function select_routine_cost(obj, ctrl, evt) {
  if (ctrl == "routine_cost_payments") { 
    // Routine Cost

    $(".select2-selection__rendered").html("<li class='select2-selection__choice'>Selected "+$(".select_routine_cost").val().length+" Items</li>")
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "select_routine_cost",
        interval_id: $(".select_routine_cost").val()
      },
      dataType: "script",
      success: function (data){
        //$("#top_day").val($(obj).find(":selected").attr("top_day"));
        //$("#top_kind").val($(obj).find(":selected").attr("top_kind"));
       }
    });
  };
}

function delete_routine(id,ctrl,evt){
  if (ctrl == "routine_cost_payments") { 
    // Routine Cost
    var array = $(".select_routine_cost").val();
    // console.log(array);
    var index = array.indexOf(id);
    if (index > -1) {
      array.splice(index, 1);
    }

    $(".select_routine_cost").val(array)
    length = 0;
    if ($(".select_routine_cost").val() != null) {
      length = $(".select_routine_cost").val().length
    }

     $(".select2-selection__rendered").html("<li class='select2-selection__choice'>Selected "+length+" Items</li>");
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "select_routine_cost",
        interval_id: $(".select_routine_cost").val()
      },
      dataType: "script",
      success: function (data){
        //$("#top_day").val($(obj).find(":selected").attr("top_day"));
        //$("#top_kind").val($(obj).find(":selected").attr("top_kind"));
       }
    });
  };
}

function routine_price_change() {
  var total_val = 0;

  $(".tbody_item tr").each(function(index, tr){
    if(typeof $(tr).find('#record_item__status').val() !== "undefined"){
      if($(tr).find('#record_item__status').val()=="active"){
        if(typeof $(tr).find('#record_item__amount').val() !== "undefined"){
          total_val += parseFloat($(tr).find('#record_item__amount').val()) 
        }
      }
    }
    if(typeof $(tr).find('#new_record_item__amount').val() !== "undefined"){
      total_val += parseFloat($(tr).find('#new_record_item__amount').val()) 
    }
  })

  $("#routine_cost_payment_grand_total").val(total_val);
}

function calculation_amount(id,ctrl,evt){
  if (ctrl == "cash_settlements") { 
    var total_val = 0;
    var status_bon = 'suspend';
    $(".tbody_item tr").each(function(index, tr){
        if(typeof $(tr).find('#record_item__status').val() !== "undefined"){
          if($(tr).find('#record_item__status').val()=="active"){
            status_bon = "active";
          }else{
            status_bon = "suspend";
          }
        }

        if(status_bon=="active"){
          if(typeof $(tr).find('#record_item__amount').val() !== "undefined"){
            total_val += parseFloat($(tr).find('#record_item__amount').val()) 
          }
        }

      if(typeof $(tr).find('#cash_settlement_item__amount').val() !== "undefined"){
        total_val += parseFloat($(tr).find('#cash_settlement_item__amount').val()) 
      }
    });

    $("#cash_settlement_expenditure_total").val(total_val);
    $("#show_expenditure_total").val(Number((total_val).toFixed(2)).toLocaleString('id-ID'));

    var settlement = Number($("#cash_settlement_expenditure_total").val())

    if($("#cash_settlement_settlement_total").val()!=""){
      var bon = Number($("#cash_settlement_settlement_total").val())
      $("#cash_settlement_advantage").val(bon-settlement)
      $("#show_advantage").val(Number((bon-settlement).toFixed(2)).toLocaleString('id-ID'))
    }else{
      $("#cash_settlement_advantage").val(0-settlement)
      $("#show_advantage").val(Number((0-settlement).toFixed(2)).toLocaleString('id-ID'))
    }
  } else if (ctrl == "proof_cash_expenditures") { 
    var total_val = 0;
    var status_bon = 'suspend';
      $(".tbody_item tr").each(function(index, tr){
          if(typeof $(tr).find('#record_item__status').val() !== "undefined"){
            if($(tr).find('#record_item__status').val()=="active"){
              status_bon = 'active';
            }else{
              status_bon = "suspend";
            }
          }

          if(status_bon=="active"){
            if(typeof $(tr).find('#record_item__nominal').val() !== "undefined"){
              total_val += parseFloat($(tr).find('#record_item__nominal').val()) 
            }
          }

        if(typeof $(tr).find('#proof_cash_expenditure_item__nominal').val() !== "undefined"){
          total_val += parseFloat($(tr).find('#proof_cash_expenditure_item__nominal').val()) 
        }
      });

      $("#proof_cash_expenditure_grand_total").val(total_val);
      $("#show_grand_total").val(Number((total_val).toFixed(2)).toLocaleString('id-ID'));

      var grand_total = Number($("#proof_cash_expenditure_grand_total").val())
  };
}

function add_bon(id,ctrl,evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "GET",
    data: {
      partial: "add_bon"
    },
    dataType: "script",
    success: function (data){
     }
  });
}

function add_new_routine(id,ctrl,evt) {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "change_department",
        select_department_id: $("#routine_cost_payment_department_id").find(':selected').val(),      
        q: $("#q").val(), po_base: $("#po_base").find(':selected').val()
      },
      dataType: "script",
      success: function (data){
       }
    });
}

function add_new_item(id,ctrl,evt) {
    var count = 1;
    if(typeof $(".new_tbody_item tr:last").attr("trid") !== "undefined"){
      count = (Number($(".new_tbody_item tr:last").attr("trid")) + 1);
    }
    // alert(count)
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "add_new_item",
        count: count
      },
      dataType: "script",
      success: function (data){
       }
    });
}

function delete_new_item(id,ctrl,evt){
  if (ctrl == "cash_settlements") { 
    $(".new_tbody_item tr[trid="+id+"]").remove();
  } else if (ctrl == "proof_cash_expenditures") { 
    $(".new_tbody_item tr[trid="+id+"]").remove();
  };
}

function delete_bon(id,ctrl,evt){
  if (ctrl == "cash_settlements") { 
    $(".tbody_item tr[bon_count="+id+"]").remove();
  } else if (ctrl == "proof_cash_expenditures") { 
    $(".tbody_item tr[bon_count="+id+"]").remove();
  };
  calculation_amount("any",ctrl)
}

function load_bon(id,ctrl,evt) {
  var count = 1;
  if(typeof $(".tbody_item tr:last").attr("trid") !== "undefined"){
    count = (Number($(".tbody_item tr:last").attr("trid")) + 1);
  }

  var bon_count = 1;
  if(typeof $(".tbody_item tr:last").attr("bon_count") !== "undefined"){
    bon_count = (Number($(".tbody_item tr:last").attr("bon_count")) + 1);
  }

  if (ctrl == "cash_settlements") { 

    var save = 1;
    $(".new_tbody_item tr").each(function(index, tr){

      if($(tr).find('#payment_name').val()==""){
        save=0;
        return false;
      }
      if($(tr).find('#amount').val()==""){
        save=0;
        return false;
      }

      c++;
    });

    if(save==0){
      alert("please check form input, Payment Name & Amount is Mandatory");
    }else{
      
      var c = 1;
      var payment_type = 0;
      var coa_name = 0;
      var payment_name = 0;
      var description = 0;
      var amount = 0;

      var arr = [];

      $(".new_tbody_item tr").each(function(index, tr){
        var obj = {};
        obj.payment_type = ($(tr).find('#payment_type').val());
        obj.coa_name = ($(tr).find('#coa_name').val());
        obj.payment_name = ($(tr).find('#payment_name').val());
        obj.description = ($(tr).find('#description').val());
        obj.amount = ($(tr).find('#amount').val());
        console.log(obj);
        arr.push(obj)
        c++;
      });
    }
  } else if (ctrl == "proof_cash_expenditures") { 

    var save = 1;
    $(".new_tbody_item tr").each(function(index, tr){

      if($(tr).find('#remarks').val()==""){
        save=0;
        return false;
      }
      if($(tr).find('#nominal').val()==""){
        save=0;
        return false;
      }

      c++;
    });

    if(save==0){
      alert("please check form input, Payment Name & Amount is Mandatory");
    }else{
      
      var c = 1;
      var type_cost = 0;
      var no_coa = 0;
      var remarks = 0;
      var nominal = 0;

      var arr = [];

      $(".new_tbody_item tr").each(function(index, tr){
        var obj = {};
        obj.type_cost = ($(tr).find('#type_cost').val());
        obj.no_coa = ($(tr).find('#no_coa').val());
        obj.remarks = ($(tr).find('#remarks').val());
        obj.nominal = ($(tr).find('#nominal').val());
        console.log(obj);
        arr.push(obj)
        c++;
      });
    }
  };

  // GET
  $.ajax({
    url: "/"+ctrl,
    type: "GET",
    data: {
      partial: "load_bon",
      count: count,
      bon_count: bon_count,
      obj: arr,
    },
    dataType: "script",
    success: function (data){
     }
  });
}

function dataURItoBlob(dataURI) {
  var byteString = window.atob(dataURI);
  var arrayBuffer = new ArrayBuffer(byteString.length);
  var int8Array = new Uint8Array(arrayBuffer);
  for (var i = 0; i < byteString.length; i++) {
    int8Array[i] = byteString.charCodeAt(i);
  }
  var blob = new Blob([int8Array], { type: 'application/pdf'});
  return blob;
}

function showFiles(element){
  var ext = $(element).attr("base64");

  if(ext.substring(0,10)=="data:image"){
    var newTab = window.open();
    newTab.document.body.innerHTML = '<img src="'+ext+'">';

  }else if(ext.substring(0,20)=="data:application/pdf"){
    var blob = dataURItoBlob(ext.replace("data:application/pdf;base64,",""));
    var url = URL.createObjectURL(blob);
    window.open(url,"_blank");
  }else{

  }
}

function readFile(element) {
  if (element.files && element.files[0]) {
    
    var FR= new FileReader();
    
    FR.addEventListener("load", function(e) {
      $('.files_base64').val(e.target.result)
    }); 
    
    FR.readAsDataURL( element.files[0] );
  } 
}

function change_cash_submission(id,ctrl,evt){
  $("#cash_settlement_settlement_total").val($(id).find(":selected").attr("amount"))
  $(".currency_name").val($(id).find(":selected").attr("currency_name"))
  $("#cash_settlement_currency_id").val($(id).find(":selected").attr("currency_id"))
  $("#show_settlement_total").val(Number($(id).find(":selected").attr("amount")).toLocaleString('id-ID'))
}

function app3_multiple_select_all(ctrl){
  if(ctrl=="invoice_customer_price_logs"){

    if($("#list_approve_all").is(':checked')) {
      // Iterate each checkbox
      $('.list_approve_selected').each(function() {
        if(this.disabled == false){
          this.checked = true;                        
        }
      });
    } else {
      $('.list_approve_selected').each(function() {
        if(this.disabled == false){
          this.checked = false;                       
        }
      });
    }
  }else{
    if($('.select-all').is(':checked')) {
        // Iterate each checkbox
        $('.approve_cek').each(function() {
          if(this.disabled == false){
            this.checked = true;                        
          }
        });
    } else {
        $('.approve_cek').each(function() {
          if(this.disabled == false){
            this.checked = false;                       
          }
        });
    }
    app3_multiple_select(ctrl)
  }
};

function app3_multiple_select(ctrl){
  var id = "";
  $('.approve_cek').each(function() {
    if(this.checked == true){
      id += ""+$(this).attr('record_id')+","                      
    }
  });

  if (ctrl == "employee_absences" || ctrl == "employee_presences") {
    var set_status = $('#select_status').val();
    var period = $("#period").val();
  } else {
     var set_status = "approve3"
  } 

  if (ctrl == "purchase_requests" || ctrl == "purchase_order_suppliers" ) {
    $(".app3click").attr("href","/"+ctrl+"/"+id+"/approve?q="+$(".app3click").attr("kind")+"&status="+set_status+"&multi_id="+id); 
  } else if (ctrl=="employee_presences") {
    $(".app3click").attr("href","/"+ctrl+"/"+id+"/approve?status="+set_status+"&multi_id="+id+"&period="+period); 
  } else {
    $(".app3click").attr("href","/"+ctrl+"/"+id+"/approve?status="+set_status+"&multi_id="+id); 
  }
}

// Price Log Aja
$(document).off('click','#approve_selected')
$(document).on('click','#approve_selected', function(evt){
  var log_id = "";
  var invoice_selected = [];
  $('.list_approve_selected').each(function() {
    if(this.checked == true){
      log_id = $(this).attr('log_id');
      invoice_selected.push({
        "log_id": $(this).attr('log_id'),
        "invoice_id": $(this).attr('invoice_id'),
        "invoice_item_id": $(this).attr('invoice_item_id'),
      })        
    }
  });
  // alert(JSON.stringify(invoice_selected))
  var patch = {
        "data" : invoice_selected
      } 
  $.ajax({
     type: 'PUT',
     url: '/invoice_customer_price_logs/'+log_id,
     data: patch

     /* success and error handling omitted for brevity */
  });   
 evt.stopImmediatePropagation();
});

function select_payment_method(id,ctrl,evt){
  // alert(count)
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "select_payment_method"
    },
    dataType: "script",
    success: function (data){
     }
  });
}

// dk=====>
function vr_price_change(obj, ctrl, cnt, evt) {
  var total_val = 0;
  if (ctrl == "voucher_payment_receivings") { 
    $(".tbody_item tr").each(function(index, tr){
      if(typeof $(tr).find('#record_item__status').val() !== "undefined"){
        if($(tr).find('#record_item__status').val()=="active"){
          if(typeof $(tr).find('#record_item__amount').val() !== "undefined"){
            total_val += parseFloat($(tr).find('#record_item__amount').val().replaceAll(",","")) 
          };
        };
      };
      // add new
      if(typeof $(tr).find("#new_record_item__amount").val() !== "undefined"){
        total_val += parseFloat($(tr).find("#new_record_item__amount").val().replaceAll(",",""));
      };
    });

    $("#total_amount").val(total_val.toLocaleString('id-ID', {minimumFractionDigits: 2}));
    $("#voucher_payment_receiving_total_amount").val(total_val);

  }else if (ctrl == "voucher_payments") {
    var old_nominal,new_nominal;
    var tax_id = $("#voucher_payment_tax_id").val() || 1;
    var pph_percent = parseFloat($("#voucher_payment_pph_percent").val()) || 0;
    var cut_fee = parseFloat($("#voucher_payment_other_cut_fee").val()) || 0;
    $(".tbody_item tr").each(function(index, tr){
      old_nominal = $(tr).find('#record_item__nominal').val();
      new_nominal = $(tr).find('#new_record_item__nominal').val(); 
      // old
      if(typeof old_nominal !== "undefined"){
        total_val += parseFloat(old_nominal.replaceAll(".","").replaceAll(",",".")) 
      };
      // add new
      if(typeof new_nominal !== "undefined"){
        total_val += parseFloat(new_nominal.replaceAll(".","").replaceAll(",","."));
      };
    });

    // Sub TOtal
    if( total_val==0 ){
      total_val = parseFloat($("#voucher_payment_sub_total").val().replaceAll(".","").replaceAll(",",".")) || 0;
    }
    var subtotal = total_val;
    $("#voucher_payment_sub_total").val(subtotal.toLocaleString('id-ID', {minimumFractionDigits: 2}));

    // Tax type
    var ppn_percent = 0;
    if(tax_id=="2"){ 
      //10%
      ppn_percent = 0.1
    }else if(tax_id=="4"){ 
      //1%
      ppn_percent = 0.01
    }else if(tax_id=="5"){ 
      //11%
      ppn_percent = 0.11
    }

    // total PPN
    var total_ppn = parseFloat(subtotal*ppn_percent);
    $("#voucher_payment_ppn_total").val(total_ppn.toLocaleString('id-ID', {minimumFractionDigits: 2}));
    total_val += total_ppn

    // pph_percent and total pph
    var total_pph = parseFloat(subtotal*(pph_percent/100))
    $("#voucher_payment_pph_total").val(total_pph.toLocaleString('id-ID', {minimumFractionDigits: 2}));
    total_val -= total_pph

    // CUT FEE
    total_val -= cut_fee

    // Grand Total
    $("#voucher_payment_grand_total").val(total_val.toLocaleString('id-ID', {minimumFractionDigits: 2}));

    console.log(subtotal);
    console.log(tax_id);
    console.log(total_ppn);
    console.log(pph_percent);
    console.log(total_pph);
    console.log(cut_fee);
    console.log(total_val);
  }

  $(".grandtotal_td").html(total_val.toLocaleString('id-ID', {minimumFractionDigits: 2}));

}

function remove_row(id,ctrl,evt){
  if (ctrl == "voucher_payment_receivings","voucher_payments") { 
    $(".tbody_item tr[row_id="+id+"]").remove();
    vr_price_change()
  };

}

function new_record_item__amount(id,ctrl,evt){
  if (ctrl == "voucher_payment_receivings") { 
    $(this).mask('#,##0.00', {reverse: true});
  };

}

function new_record_item__nominal(id,ctrl,evt){
  if (ctrl == "voucher_payments") { 
    $('.nominal_td').mask('#,##0.00', {reverse: true});
    // $(".grandtotal_td").mask('#,##0.00', {reverse: true});
  };

}

function search_periode_voucher(obj, ctrl, evt) {
  // vr
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      periode: $("#periode_recap").find(':selected').val(),
      bank_type: $("#bank_type").find(':selected').val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}

// checked all
function cek_all_petty(ctrl){
  if($('#checked_all_pettycash').is(':checked')) {
      // Iterate each checkbox
      $('.select_bpk_list').each(function() {
        if(this.disabled == false){
          this.checked = true;                        
        }
      });
  } else {
      $('.select_bpk_list').each(function() {
        if(this.disabled == false){
          this.checked = false;                       
        }
      });
  }
};

function load_bpk_list(obj, ctrl, evt) {
  // vp pettycash
  var stuff1 = [];
  var stuff2 = [];
  var stuff3 = [];
  $('.select_bpk_list:checked').each(function() {
    if($(this).attr('table_name') == 'proof_cash_expenditures'){
      stuff1.push($(this).attr('val'));
    }else if($(this).attr('table_name') == 'routine_cost_payments'){
      stuff2.push($(this).attr('val'));
    }else if($(this).attr('table_name') == 'cash_settlements'){
      stuff3.push($(this).attr('val'));
    }
    // value.push($(this).attr("bpk_list"));
  }); 
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "load_bpk_list",
      stuff1: stuff1,
      stuff2: stuff2,
      stuff3: stuff3
    },
    dataType: "script",
    success: function (data){
    }
  });
}

function change_bpk(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_bpk",
    },
    dataType: "script",
    success: function (data){
    }
  });
}


// 16112021 - Danny
function load_pi_list(obj, ctrl, evt) {
  var stuff1 = [];
  var term_id = 0;
  var top = -1;
  var tops = -1;
  var stop = "no";
  $('.select_pi_list:checked').each(function() {
    if($(this).attr('table_name') == 'sales_orders'){
      stuff1.push($(this).attr('val'));

      if (top != $(this).attr('top_day') ){
        if (top != -1){
          stop = "yes";
        }
      }

      if (term_id != $(this).attr('term_of_payment_id') ){
        if (term_id > 0 ){
          stop = "yes";
        }
      }

      top = Number($(this).attr('top_day'));
      term_id = Number($(this).attr('term_of_payment_id'));
    }
    // alert();
  }); 
  var sales_order_id = $("#proforma_invoice_customer_sales_order_id").val();
  if ($("#proforma_invoice_customer_down_payment").val() == "") {
    var dptotal = 0;
  } else {
    var dptotal = $("#proforma_invoice_customer_down_payment").val();
  }
  var customer_id = $("#proforma_invoice_customer_customer_id").val();

  if (stop == "yes") {
    UIkit.notification({
      message: 'Term berbeda & tidak bisa buat invoice', status: 'warning', pos: 'top-center', timeout: 10000
    });
    $('.select_pi_list').focus();
  } else {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "load_pi_list",
        stuff1: stuff1,
        dptotal: dptotal,
        select_top_day: $('.select_pi_list:checked').attr("top_day"),
        select_term_of_payment_id: $('.select_pi_list:checked').attr("term_of_payment_id"),
        select_tax_id: $('.select_pi_list:checked').attr("tax_id"),
        select_sales_order_id: $('.select_pi_list:checked').attr("id"),
        select_dp: $('.selected:checked').attr("down_payment"),
        cs_id: customer_id
      },
      dataType: "script",
      success: function (data){
        UIkit.notification({
          message: 'Success loaded!', status: 'success', pos: 'bottom-right', timeout: 10000
        });
      }
    });
  }
}

function change_pi(obj, ctrl, evt) {
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_pi",
      cs_id: $(obj).find(':selected').val(),
    },
    dataType: "script",
    success: function (data){

    }
  });
}

function change_dp(obj, ctrl, evt) {
  // var aa = $(obj).val();
  // alert(aa);
  $.ajax({
    url: "/"+ctrl,
    type: "Get",
    data: {
      partial: "change_dp",
      select_dp: $(obj).val()
    },
    dataType: "script",
    success: function (data){
    }
  });
}

function change_attachment(bon_count, ctrl, evt) {

    if(ctrl == 'proof_cash_expenditures'){
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "change_attachment",
          bon_count: bon_count
        },
        dataType: "script",
        success: function (data){
        }
      });
    }

}

function load_attachment(bon_count, ctrl, evt) {
    if(ctrl == 'proof_cash_expenditures'){
        $.ajax({
          url: "/"+ctrl,
          type: "GET",
          data: {
            partial: "load_attachment",
            bon_count: bon_count
          },
          dataType: "script",
          success: function (data){
           }
        });
    }

}

function change_period_yyyy(obj, ctrl, evt) {
  // var href = "/"+ctrl+"/export";
  if (ctrl == 'employee_overtimes') {
    var job = $("#job").val();
    if (job == null || job == '') {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          department_id: $("#select_department").find(':selected').val(),
          year: $(obj).find(':selected').val(),
          month: $("#periode_mm").find(':selected').val(),
           employee_id: $("#employee_id").val(),
          employee_name : $("#select_employee").val()
        },
        dataType: "script",
        success: function (data){
          // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
        }
      });
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "change_period",
          year: $(obj).val(),
          period_id: $("#select_period").val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    }
  } else if (ctrl == 'employee_schedules') {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: 'change_employee',
        employee_id: $("#employee_id").val(),
        department_id: $("#select_department").find(':selected').val(),
        period: $(obj).find(':selected').val()+$("#periode_mm").find(':selected').val(),
        view_kind: $("#select_view_kind").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == 'employee_presences') {
    var view_kind = $("#select_view_kind").val();
    if (view_kind == 'header') {
      var partial = 'change_list';
      var kind = $("#select_view_kind").val();
      var department_id = $("#select_department").find(':selected').val();
    } else {
      var partial = 'change_employee';
      var kind = $("#view_kind").val();
      var department_id = $("#department_id").val();
    };
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: partial,
        employee_id: $("#employee_id").val(),
        department_id: department_id,
        period: $(obj).find(':selected').val()+$("#periode_mm").find(':selected').val(),
        view_kind: kind
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == 'working_hour_summaries') {
    var view_kind = $("#select_view_kind").val();
    if (view_kind == 'header') {
      var partial = 'change_list';
      var kind = $("#select_view_kind").val();
      var department_id = $("#select_department").find(':selected').val();
    } else {
      var partial = 'change_employee';
      var kind = $("#view_kind").val();
      var department_id = $("#department_id").val();
    };
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: partial,
        department_id: department_id,
        employee_id: $("#employee_id").val(),
        period: $(obj).find(':selected').val()+$("#periode_mm").find(':selected').val(),
        view_kind: kind
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        department_id: $("#select_department").find(':selected').val(),
        period: $(obj).find(':selected').val()+$("#periode_mm").find(':selected').val()
      },
      dataType: "script",
      success: function (data){
        // $(".button_export").attr("href",href+"?q="+$(obj).attr("q"));
      }
    });
  }
}

// 2022-04-08 Zulvan
function change_period_yymm(obj, ctrl, evt) {
  if (ctrl == 'employee_overtimes') {
    var job = $("#job").val();
    if (job == null || job == '') {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          department_id: $("#select_department").find(':selected').val(),
          year: $("#periode_yyyy").find(':selected').val(),
          month: $(obj).find(':selected').val(),
          employee_id: $("#employee_id").val(),
          employee_name : $("#select_employee").val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "change_period",
          year: $("#year").val(),
          period_id: $(obj).val()
        },
        dataType: "script",
        success: function (data){
        }
      });
    }
  } else if (ctrl == 'employee_schedules') {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: 'change_employee',
        employee_id: $("#employee_id").val(),
        department_id: $("#select_department").find(':selected').val(),
        period: $("#periode_yyyy").find(':selected').val()+$(obj).find(':selected').val(),
        view_kind: $("#select_view_kind").val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == 'employee_presences') {
    var view_kind = $("#select_view_kind").val();
    if (view_kind == 'header') {
      var partial = 'change_list';
      var kind = $("#select_view_kind").val();
      var department_id = $("#select_department").find(':selected').val();
    } else {
      var partial = 'change_employee';
      var kind = $("#view_kind").val();
      var department_id = $("#department_id").val();
    };
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: partial,
        employee_id: $("#employee_id").val(),
        department_id: department_id,
        period: $("#periode_yyyy").find(':selected').val()+$(obj).find(':selected').val(),
        view_kind: kind
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else if (ctrl == 'working_hour_summaries') {
    var view_kind = $("#select_view_kind").val();
    if (view_kind == 'header') {
      var partial = 'change_list';
      var kind = $("#select_view_kind").val();
      var department_id = $("#select_department").find(':selected').val();
    } else {
      var partial = 'change_employee';
      var kind = $("#view_kind").val();
      var department_id = $("#department_id").val();
    };
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: partial,
        department_id: department_id,
        employee_id: $("#employee_id").val(),
        period: $("#periode_yyyy").find(':selected').val()+$(obj).find(':selected').val(),
        view_kind: kind
      },
      dataType: "script",
      success: function (data){
      }
    });
  } else {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        department_id: $("#select_department").find(':selected').val(),
        period: $("#periode_yyyy").find(':selected').val()+$(obj).find(':selected').val()
      },
      dataType: "script",
      success: function (data){
      }
    });
  }
}

function change_date(obj, ctrl, evt){
  if (ctrl == 'employee_overtimes') {
    var input_date = $(obj).val();
    var month = input_date.substring(5,2);
    var date = input_date.substring(8,2);
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: 'get_date',
        input_date: $(obj).val()
       },
      dataType: "script",
      success: function(data){
      }
    });    
  }
}

function overtime_in(obj, seq, evt) {
  var ot_begin = ($("#trid"+seq+" .overtime_begin").val());
      ot_end = ($("#trid"+seq+" .overtime_end").val());
      name = $("#trid"+seq+" #select_employee_"+seq).val();
      sched = $("trid"+seq+" #new_record_item__schedule").val();
      sched_in = ($("#trid"+seq+" #schedule_in").val());
      sched_out = ($("#trid"+seq+" #schedule_out").val());
    
    if (ot_begin > ot_end) {
      var ot_begin_second = ((parseInt(ot_begin.substr(0, 2)) * 3600) + (parseInt(ot_begin.substr(3, 2)) * 60));
        ot_end_second = ((parseInt(ot_end.substr(0, 2)) * 3600) + (parseInt(ot_end.substr(3, 2)) * 60) + 86400);
    } else {
      var ot_begin_second = ((parseInt(ot_begin.substr(0, 2)) * 3600) + (parseInt(ot_begin.substr(3, 2)) * 60));
        ot_end_second = ((parseInt(ot_end.substr(0, 2)) * 3600) + (parseInt(ot_end.substr(3, 2)) * 60));
    }
    
  var total = (parseFloat(ot_end_second - ot_begin_second) / 3600).toFixed(2);
  if (total >= "4.00" && total < "5.00") {
    var total = (parseFloat(total - 0.50)).toFixed(2);
  } else if (total >= "5.00") {
    var total = (parseFloat(total - 1.00)).toFixed(2);
  }

  if (sched != '' || sched != null)
    if (sched_in == '' || sched_in == null) {
      $("#trid"+seq+" #total_overtime").val(total);
    } else if (sched_in <= "16:00") {
      if (ot_begin >= sched_in && ot_begin < sched_out) {
        UIkit.notification.closeAll();
        UIkit.notification({
          message: "Overtime "+name+", overlap dengan schedule Masuk "+sched_in+" dan Pulang "+sched_out+" nya", status: 'warning', pos: 'top-center', timeout: 10000
        });
        $("#trid"+seq+" .overtime_begin").val(null);
      } else {
        $("#trid"+seq+" #total_overtime").val(total);
      }
    } else if (sched_in >= "18:00" && sched_in <= "23:59" ) {
      if (ot_begin >= sched_in || ot_begin < sched_out) {
        UIkit.notification.closeAll();
        UIkit.notification({
          message: "Overtime "+name+", overlap dengan schedule Masuk "+sched_in+" dan Pulang "+sched_out+" nya", status: 'warning', pos: 'top-center', timeout: 10000
        });
      $("#trid"+seq+" .overtime_begin").val(null);
      } else {
        $("#trid"+seq+" #total_overtime").val(total);
      }
    } else {
      $("#trid"+seq+" #total_overtime").val(total);
    }
  else {
    UIkit.notification.closeAll();
    UIkit.notification({
      message: name+" tidak punya data schedule di periode ini", status: 'warning', pos: 'top-center', timeout: 10000
    });
    $("#trid"+seq+" #new_record_item__schedule").css('background','yellow');
    $("#trid"+seq+" .overtime_begin").val(null);
  } 
};

function overtime_out(obj, seq, evt) {
  var ot_begin = ($("#trid"+seq+" .overtime_begin").val());
    ot_end = ($("#trid"+seq+" .overtime_end").val());
    name = $("#trid"+seq+" #select_employee_"+seq).val();
    sched = $("trid"+seq+" #new_record_item__schedule").val();
    sched_in = ($("#trid"+seq+" #schedule_in").val());
    sched_out = ($("#trid"+seq+" #schedule_out").val());

    if (ot_begin > ot_end) {
      var ot_begin_second = ((parseInt(ot_begin.substr(0, 2)) * 3600) + (parseInt(ot_begin.substr(3, 2)) * 60));
        ot_end_second = ((parseInt(ot_end.substr(0, 2)) * 3600) + (parseInt(ot_end.substr(3, 2)) * 60) + 86400);
    } else {
      var ot_begin_second = ((parseInt(ot_begin.substr(0, 2)) * 3600) + (parseInt(ot_begin.substr(3, 2)) * 60));
        ot_end_second = ((parseInt(ot_end.substr(0, 2)) * 3600) + (parseInt(ot_end.substr(3, 2)) * 60));
    }
  var total = (parseFloat(ot_end_second - ot_begin_second) / 3600).toFixed(2);
  if (total >= "4.00" && total < "5.00") {
    var total = (parseFloat(total - 0.50)).toFixed(2);
  } else if (total >= "5.00") {
    var total = (parseFloat(total - 1.00)).toFixed(2);
  }


  if (sched != '' || sched != null) {
    if (sched_out == '' || sched_out == null) {
      $("#trid"+seq+" #total_overtime").val(total);
    } else if (sched_out >= "15:00" && sched_out <= "23:00") {
      if (ot_end >= sched_in && ot_end <= sched_out) {
        UIkit.notification.closeAll();
        UIkit.notification({
          message: "Overtime "+name+", overlap dengan schedule Masuk "+sched_in+" dan Pulang "+sched_out+" nya", status: 'warning', pos: 'top-center', timeout: 10000
        });
        $("#trid"+seq+" .overtime_end").val(null);
      } else {
        $("#trid"+seq+" #total_overtime").val(total);
      }
    } else if (sched_out <= "07:00") {
      if (ot_end <= ot_begin) {
        UIkit.notification.closeAll();
        UIkit.notification({
          message: "Selesai lembur "+name+", overlap dengan schedule kerjanya di jam masuk : "+sched_in+" dan jam pulang : "+sched_out+". Tolong pastikan lagi inputnya ! ", status: 'warning', pos: 'top-center', timeout: 10000
        });
        $("#trid"+seq+" .overtime_end").val(null);
      } else if (ot_end >= sched_in || ot_end <= sched_out) {
        UIkit.notification.closeAll();
        UIkit.notification({
          message: "Overtime "+name+", overlap dengan schedule Masuk "+sched_in+" dan Pulang "+sched_out+" nya", status: 'warning', pos: 'top-center', timeout: 10000
        });
        $("#trid"+seq+" .overtime_end").val(null);
      } else {
        $("#trid"+seq+" #total_overtime").val(total);
      }
    } else {
      $("#trid"+seq+" #total_overtime").val(total);
    }
  } else {
    UIkit.notification.closeAll();
    UIkit.notification({
      message: name+" tidak punya data schedule di periode ini", status: 'warning', pos: 'top-center', timeout: 10000
    });
    $("#trid"+seq+" #new_record_item__schedule").css('background','yellow');
    $("#trid"+seq+" .overtime_begin").val(null);
  }
};

function show_list(obj, ctrl, evt){
  if (ctrl == 'employee_presences') {
    var id = $(obj).attr("multiple_employee");
    var title = $(obj).attr("title");
    var kind =  $(obj).attr("kind_tbl");
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "show_list",
        multiple_id: id,
        kind_tbl: kind,
        department_id: $("#select_department").find(':selected').val(),
        period: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val()
      },
      dataType: "script",
      success: function (data){
      }
    }); 
  }
}

function refresh_view(obj, ctrl, evt){
  if (ctrl == 'employee_presences') {
    $.ajax({
      url: "/"+ctrl,
      type: "Get",
      data: {
        partial: "show_list",
        job: $("#job").val(),
        id: $("#id").val(),
        multiple_employee: $("#multiple_employee").val(),
        kind_tbl: $("#select_kind_employee_presence").find(':selected').val(),
        department_id: $("#select_department").find(':selected').val(),
        period: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val()
      },
      dataType: "script",
      success: function (data){
      }
    }); 
  }
}

function button_precompile(obj, ctrl, evt){
  if (ctrl == 'employee_presences' || ctrl == 'working_hour_summaries') {
    if ($("#periode_mm").val() == null || $("#periode_mm").val() == '') {
      UIkit.notification.closeAll();
      UIkit.notification({
        message: " Select Period First, Please!", status: 'warning', pos: 'top-center', timeout: 10000
      });
      $("#periode_mm").css('background','yellow');
    } else {
      $("#periode_mm").css('background','white');
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "precompile",
          view_kind: 'precompile',
          kind_tbl: $("#kind_tbl").val(),
          department_id: $("#select_department").find(':selected').val(),
          period: $("#periode_yyyy").find(':selected').val()+$("#periode_mm").find(':selected').val()
        },
        dataType: "script",
        success: function (data){
        }
      }); 
    }      
  }
}

function precompile_process(obj, ctrl, evt){
  if (ctrl == 'employee_presences' || ctrl == 'working_hour_summaries') {
    var status = $(obj).attr('status');
    if (status == null || status == '') {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "precompile_process",
          view_kind: 'precompile',
          status: status,
          kind_tbl: $("#kind_tbl").val(),
          department_id: $("#select_department").find(':selected').val(),
          period: $("#period").val(),
          precompile_process: "start"
        },
        dataType: "script",
        success: function (data){
        }
      });
    } else {
      $.ajax({
        url: "/"+ctrl,
        type: "Get",
        data: {
          partial: "precompile_process",
          view_kind: 'precompile',
          status: status,
          id: $(obj).attr('id'),
          department_id: $("#department_id").val(),
          period: $("#period").val(),
        },
        dataType: "script",
        success: function (data){
        }
      }); 
    }
  }
}


