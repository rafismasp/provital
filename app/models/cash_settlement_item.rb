class CashSettlementItem < ApplicationRecord
  belongs_to :cash_settlement


  def image
    self.cash_settlement.cash_settlement_files
  end

  def bon_length
    CashSettlementItem.where(:cash_settlement_id=>self.cash_settlement_id,:bon_count=>self.bon_count,:status=>"active").length
  end
end
