class ProofCashExpenditureItem < ApplicationRecord
	belongs_to :proof_cash_expenditure

	def image
    self.proof_cash_expenditure.proof_cash_expenditure_files
  end

  def bon_length
    ProofCashExpenditureItem.where(:proof_cash_expenditure_id=>self.proof_cash_expenditure_id,:bon_count=>self.bon_count,:status=>"active").length
  end

end



