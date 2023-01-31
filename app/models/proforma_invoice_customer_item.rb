class ProformaInvoiceCustomerItem < ApplicationRecord
  belongs_to :proforma_invoice_customer
  belongs_to :sales_order, optional: true
  belongs_to :sales_order_item, optional: true
end