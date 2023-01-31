namespace :rake20200620 do
  desc "Rake file 2020-06-20" 

  task :inject_customer => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
  end


  task :inject_category => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
  	myarray = [	{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size M", :product_type_code=> "AA", :part_id=> "AAAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size L", :product_type_code=> "AB", :part_id=> "AAAB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size XL", :product_type_code=> "AC", :part_id=> "AAAC"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "PrideMed", :product_type=> "Size M", :product_type_code=> "AD", :part_id=> "AAAD"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "PrideMed", :product_type=> "Size L", :product_type_code=> "AE", :part_id=> "AAAE"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "PrideMed", :product_type=> "Size XL", :product_type_code=> "AF", :part_id=> "AAAF"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size M", :product_type_code=> "AG", :part_id=> "AAAG"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size L", :product_type_code=> "AH", :part_id=> "AAAH"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size XL", :product_type_code=> "AI", :part_id=> "AAAI"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown (Non-Towel)", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size M", :product_type_code=> "AJ", :part_id=> "AAAJ"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown (Non-Towel)", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size L", :product_type_code=> "AK", :part_id=> "AAAK"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown (Non-Towel)", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size XL", :product_type_code=> "AL", :part_id=> "AAAL"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown with Mask", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size M", :product_type_code=> "AM", :part_id=> "AAAM"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown with Mask", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size L", :product_type_code=> "AN", :part_id=> "AAAN"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Single Surgical Gown with Mask", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size XL", :product_type_code=> "AO", :part_id=> "AAAO"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Surgical Gown Non-Sterile", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size M", :product_type_code=> "AP", :part_id=> "AAAP"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Surgical Gown Non-Sterile", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size L", :product_type_code=> "AQ", :part_id=> "AAAQ"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Surgical Gown Non-Sterile", :product_sub_category_code=> "A", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "Size XL", :product_type_code=> "AR", :part_id=> "AAAR"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHITex", :product_type=> "Size M", :product_type_code=> "AS", :part_id=> "AAAS"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHITex", :product_type=> "Size L", :product_type_code=> "AT", :part_id=> "AAAT"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHITex", :product_type=> "Size XL", :product_type_code=> "AU", :part_id=> "AAAU"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe", :product_type=> "Size M", :product_type_code=> "AV", :part_id=> "AAAV"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe", :product_type=> "Size L", :product_type_code=> "AW", :part_id=> "AAAW"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Surgical Gown", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe", :product_type=> "Size XL", :product_type_code=> "AX", :part_id=> "AAAX"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size M", :product_type_code=> "AY", :part_id=> "AAAY"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size L", :product_type_code=> "AZ", :part_id=> "AAAZ"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size XL", :product_type_code=> "BA", :part_id=> "AABA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall with Shoes Cover", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe", :product_type=> "Size M", :product_type_code=> "BB", :part_id=> "AABB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall with Shoes Cover", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe", :product_type=> "Size L", :product_type_code=> "BC", :part_id=> "AABC"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall with Shoes Cover", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe", :product_type=> "Size XL", :product_type_code=> "BD", :part_id=> "AABD"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall with Seal", :product_sub_category_code=> "A", :customer=> "PT Trigels Indonesia", :brand=> "TRIGI APD ", :product_type=> "Size S", :product_type_code=> "BE", :part_id=> "AABE"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall with Seal", :product_sub_category_code=> "A", :customer=> "PT Trigels Indonesia", :brand=> "TRIGI APD ", :product_type=> "Size M", :product_type_code=> "BF", :part_id=> "AABF"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall with Seal", :product_sub_category_code=> "A", :customer=> "PT Trigels Indonesia", :brand=> "TRIGI APD ", :product_type=> "Size L", :product_type_code=> "BG", :part_id=> "AABG"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Sam Jaya Perkasa", :brand=> "Sam+", :product_type=> "Size M", :product_type_code=> "BH", :part_id=> "AABH"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Sam Jaya Perkasa", :brand=> "Sam+", :product_type=> "Size L", :product_type_code=> "BI", :part_id=> "AABI"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Sam Jaya Perkasa", :brand=> "Sam+", :product_type=> "Size XL", :product_type_code=> "BJ", :part_id=> "AABJ"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHITex", :product_type=> "Size M", :product_type_code=> "BK", :part_id=> "AABK"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHITex", :product_type=> "Size L", :product_type_code=> "BL", :part_id=> "AABL"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHITex", :product_type=> "Size XL", :product_type_code=> "BM", :part_id=> "AABM"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Disposable Overboot Cover", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHITex", :product_type=> "All size", :product_type_code=> "BN", :part_id=> "AABN"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Titan Alkesindo", :brand=> "HermonMed", :product_type=> "Size M", :product_type_code=> "BO", :part_id=> "AABO"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Titan Alkesindo", :brand=> "HermonMed", :product_type=> "Size L", :product_type_code=> "BP", :part_id=> "AABP"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Titan Alkesindo", :brand=> "HermonMed", :product_type=> "Size XL", :product_type_code=> "BQ", :part_id=> "AABQ"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Asis Mitra Andalan", :brand=> "BestQ", :product_type=> "All size", :product_type_code=> "BR", :part_id=> "AABR"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Isolation Gown", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe ", :product_type=> "Size M", :product_type_code=> "BS", :part_id=> "AABS"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Isolation Gown", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe ", :product_type=> "Size L", :product_type_code=> "BT", :part_id=> "AABT"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Isolation Gown", :product_sub_category_code=> "A", :customer=> "PT Sumber Riang Sejati", :brand=> "B-Safe ", :product_type=> "Size XL", :product_type_code=> "BU", :part_id=> "AABU"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Disposable Overboot Cover", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec ", :product_type=> "All size", :product_type_code=> "BV", :part_id=> "AABV"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Disposable Protective Coverall", :product_sub_category_code=> "A", :customer=> "PT Biocare Sejahtera", :brand=> "Biocare ", :product_type=> "All size", :product_type_code=> "BW", :part_id=> "AABW"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Protection Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size M", :product_type_code=> "BX", :part_id=> "AABX"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Protection Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size L", :product_type_code=> "BY", :part_id=> "AABY"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Sterile Protection Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size XL", :product_type_code=> "BZ", :part_id=> "AABZ"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Non Sterile Protection Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size M", :product_type_code=> "CA", :part_id=> "AACA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Non Sterile Protection Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size L", :product_type_code=> "CB", :part_id=> "AACB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Non Sterile Protection Gown", :product_sub_category_code=> "A", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "Size XL", :product_type_code=> "CC", :part_id=> "AACC"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "C-Section", :product_sub_category_code=> "B", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "1 size", :product_type_code=> "AA", :part_id=> "ABAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Microscope Drape", :product_sub_category_code=> "C", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "1 size", :product_type_code=> "AA", :part_id=> "ACAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Plain Drape", :product_sub_category_code=> "D", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "750 x 750 mm", :product_type_code=> "AA", :part_id=> "ADAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Plain Drape", :product_sub_category_code=> "D", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "1000 x 1000 mm", :product_type_code=> "AB", :part_id=> "ADAB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Plain Drape", :product_sub_category_code=> "D", :customer=> "PT ASIS Mitra Andalan", :brand=> "BestQ", :product_type=> "1200 x 1200 mm", :product_type_code=> "AC", :part_id=> "ADAC"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Ophthalmic Drape", :product_sub_category_code=> "E", :customer=> "PT Pancaraya Krisnamandiri", :brand=> "PRK", :product_type=> "101 x 81 cm", :product_type_code=> "AA", :part_id=> "AEAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Ophthalmic Drape", :product_sub_category_code=> "E", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHI", :product_type=> "", :product_type_code=> "AB", :part_id=> "AEAB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Bedah Umum dan Bedah Plastik", :product_category_code=> "A", :product_sub_category=> "Non Sterile Colonoscopy Pants", :product_sub_category_code=> "F", :customer=> "PT Tarafis Anugerah Medika", :brand=> "FirstProtec", :product_type=> "All size", :product_type_code=> "AA", :part_id=> "AFAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Hematologi dan Patologi", :product_category_code=> "B", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Imunologi dan Mikrobiologi", :product_category_code=> "C", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Anestesi", :product_category_code=> "D", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Kardiologi", :product_category_code=> "E", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Gigi", :product_category_code=> "F", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Telinga, Hidung, dan Tenggorokan", :product_category_code=> "G", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Gastroenterologi-Urologi", :product_category_code=> "H", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Medtek", :brand=> "Medtromed", :product_type=> "Vol 5 L", :product_type_code=> "AA", :part_id=> "IAAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Medtek", :brand=> "Medtromed", :product_type=> "Vol 8 L", :product_type_code=> "AB", :part_id=> "IAAB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Medtek", :brand=> "Medtromed", :product_type=> "Vol 12 L", :product_type_code=> "AC", :part_id=> "IAAC"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Medtek", :brand=> "Medtromed", :product_type=> "Vol 20 L", :product_type_code=> "AD", :part_id=> "IAAD"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHI", :product_type=> "Vol 5 L", :product_type_code=> "AE", :part_id=> "IAAE"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHI", :product_type=> "Vol 8 L", :product_type_code=> "AF", :part_id=> "IAAF"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHI", :product_type=> "Vol 12 L", :product_type_code=> "AG", :part_id=> "IAAG"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Rumah Sakit Umum dan Perorangan", :product_category_code=> "I", :product_sub_category=> "Safety Box", :product_sub_category_code=> "A", :customer=> "PT Ardia Perdana Indonesia", :brand=> "SAHI", :product_type=> "Vol 20 L", :product_type_code=> "AH", :part_id=> "IAAH"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Neurologi", :product_category_code=> "J", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Mata", :product_category_code=> "K", :product_sub_category=> "Eye Shield", :product_sub_category_code=> "A", :customer=> "PT Pancaraya Krisnamandiri", :brand=> "PRK", :product_type=> "", :product_type_code=> "AA", :part_id=> "KAAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Ortopedi", :product_category_code=> "L", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Kesehatan Fisik", :product_category_code=> "M", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Obstetrik dan Ginekologi", :product_category_code=> "N", :product_sub_category=> "TeleCTG", :product_sub_category_code=> "A", :customer=> "PT Zetta Telecetege Internasional", :brand=> "TeleCTG", :product_type=> "TCTG001", :product_type_code=> "AA", :part_id=> "NAAA"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Obstetrik dan Ginekologi", :product_category_code=> "N", :product_sub_category=> "TeleCTG", :product_sub_category_code=> "A", :customer=> "PT Zetta Telecetege Internasional", :brand=> "TeleCTG", :product_type=> "TCTG002", :product_type_code=> "AB", :part_id=> "NAAB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Obstetrik dan Ginekologi", :product_category_code=> "N", :product_sub_category=> "TeleEKG", :product_sub_category_code=> "B", :customer=> "Swiss German University", :brand=> "TeleEKG", :product_type=> "", :product_type_code=> "AA", :part_id=> "NBAB"},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Radiologi", :product_category_code=> "O", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Medical Devices", :product_category => "Peralatan Kimia Klinik dan Toksikologi Klinik", :product_category_code=> "P", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Non Medical Devices", :product_category => "Vacant", :product_category_code=> "Q", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Non Medical Devices", :product_category => "Vacant", :product_category_code=> "R", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Sterilization", :product_category => "Sterilization", :product_category_code=> "S", :product_sub_category=> "Balloon Catheter", :product_sub_category_code=> "A", :customer=> "PT Dipa Global Medtek", :brand=> "Finch Fistula, Finch Pheripheral, HarrierDB", :product_type=> "Attached", :product_type_code=> "Attached", :part_id=> "Attached"},
								{:product_category_kind=> "Sterilization", :product_category => "Sterilization", :product_category_code=> "S", :product_sub_category=> "Plastic Cap", :product_sub_category_code=> "B", :customer=> "PT Pfizer Indonesia", :brand=> "Visine", :product_type=> "1 size", :product_type_code=> "AA", :part_id=> "SBAA"},
								{:product_category_kind=> "Sterilization", :product_category => "Sterilization", :product_category_code=> "S", :product_sub_category=> "Set Sunat", :product_sub_category_code=> "C", :customer=> "PT Medika Inovasi Kreatif", :brand=> "Set Sunat", :product_type=> "-", :product_type_code=> "AA", :part_id=> "SCAA"},
								{:product_category_kind=> "Sterilization", :product_category => "Sterilization", :product_category_code=> "S", :product_sub_category=> "Coverall", :product_sub_category_code=> "D", :customer=> "PT Maesindo Indonesia", :brand=> "Solida", :product_type=> "-", :product_type_code=> "AA", :part_id=> "SDAA"},
								{:product_category_kind=> "Sterilization", :product_category => "Sterilization", :product_category_code=> "S", :product_sub_category=> "Surgical Gown", :product_sub_category_code=> "E", :customer=> "PT Maesindo Indonesia", :brand=> "Med99", :product_type=> "-", :product_type_code=> "AA", :part_id=> "SEAA"},
								{:product_category_kind=> "Household (PKRT)", :product_category => "Tissue dan Kapas", :product_category_code=> "T", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Household (PKRT)", :product_category => "Sediaan untuk Mencuci", :product_category_code=> "U", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Household (PKRT)", :product_category => "Pembersih", :product_category_code=> "V", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Household (PKRT)", :product_category => "Produk Perawatan Bayi dan Ibu", :product_category_code=> "W", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Household (PKRT)", :product_category => "Antiseptika dan Desinfektan", :product_category_code=> "X", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Household (PKRT)", :product_category => "Pewangi", :product_category_code=> "Y", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
								{:product_category_kind=> "Household (PKRT)", :product_category => "Pestisida Rumah Tangga", :product_category_code=> "Z", :product_sub_category=> "", :product_sub_category_code=> "", :customer=> "", :brand=> "", :product_type=> "", :product_type_code=> "", :part_id=> ""},
			]

		myarray.each do |record|
			# puts record		
			if record[:product_category_code].present?
	    	product_category = ProductCategory.find_by(:code=> record[:product_category_code])
	    	if product_category.present?
	    		if record[:product_sub_category_code].present?
			    	product_sub_category = ProductSubCategory.find_by(:product_category_id=> product_category.id, :code=> record[:product_sub_category_code])
			    	if product_sub_category.present?
			    		if record[:product_type_code].present?
				    		product_type = ProductType.find_by(:product_sub_category_id=> product_sub_category.id, :code=> record[:product_type_code].first(2))
								if product_type.present?
								else
									customer = Customer.find_by(:name=> record[:customer])
									if customer.present?
										puts "[#{record[:part_id]}] product_type_code: #{record[:product_type_code]} tidak ada"
										ProductType.create({
											:product_sub_category_id=> product_sub_category.id, 
											:customer_id=> customer.id,
											:code=> record[:product_type_code].first(2),
											:brand=> record[:brand],
											:name=> record[:product_type],
											:created_by=> 1, :created_at=> DateTime.now()
										})
									else
										puts "#{record[:customer]} tidak ada"
									end
								end
							end
						else
							puts "[#{record[:part_id]}] product_sub_category_code: #{record[:product_sub_category_code]} tidak ada"
							ProductSubCategory.create({
								:product_category_id=> product_category.id, 
								:code=> record[:product_sub_category_code].first(2),
								:name=> record[:product_sub_category],
								:created_by=> 1, :created_at=> DateTime.now()
							})
						end
					end
				else
					puts "[#{record[:part_id]}] product_category_code: #{record[:product_category_code]} tidak ada"
				end
			end
		end
  end

  task :inject_product => :environment do | t, args|   
    ActiveRecord::Base.establish_connection :development
    myarray = [
    # 		{:part_id=> "NAAA", :name=> "Zetta TeleCTG TCTG001", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21101810911", :item_category=> "Elektromedik Non Radiasi", :id_nie=> "Elektromedik Non Radiasi", :ed_nie=> "21-11-2023"},
				# {:part_id=> "IAAA", :name=> "Medtromed Safety Box", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 20903910216", :item_category=> "Non Elektromedik Non Steril", :id_nie=> "Non Elektromedik Non Steril", :ed_nie=> "26-10-2023"},
				# {:part_id=> "IAAB", :name=> "Medtromed Safety Box", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 20903910216", :item_category=> "Non Elektromedik Non Steril", :id_nie=> "Non Elektromedik Non Steril", :ed_nie=> "26-10-2023"},
				# {:part_id=> "IAAC", :name=> "Medtromed Safety Box", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 20903910216", :item_category=> "Non Elektromedik Non Steril", :id_nie=> "Non Elektromedik Non Steril", :ed_nie=> "26-10-2023"},
				# {:part_id=> "IAAD", :name=> "Medtromed Safety Box", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 20903910216", :item_category=> "Non Elektromedik Non Steril", :id_nie=> "Non Elektromedik Non Steril", :ed_nie=> "26-10-2023"},
				# {:part_id=> "NAAB", :name=> "TeleCTG TCTG002", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21101910418", :item_category=> "Elektromedik Non Radiasi", :id_nie=> "Elektromedik Non Radiasi", :ed_nie=> "18 Juni 2024"},
				# {:part_id=> "AAAA", :name=> "First Protec Sterile Single Surgical Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603910544", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "19-01-2021"},
				# {:part_id=> "AAAB", :name=> "First Protec Sterile Single Surgical Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603910544", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "19-01-2021"},
				# {:part_id=> "AAAC", :name=> "First Protec Sterile Single Surgical Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603910544", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "19-01-2021"},
				# {:part_id=> "NAAB", :name=> "TeleCTG TCTG002", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21101910418", :item_category=> "Elektromedik Non Radiasi", :id_nie=> "Elektromedik Non Radiasi", :ed_nie=> "31-10-2024"},
				# {:part_id=> "AABK", :name=> "SAHITex Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020293", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "30-03-2025"},
				# {:part_id=> "AABL", :name=> "SAHITex Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020293", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "30-03-2025"},
				# {:part_id=> "AABM", :name=> "SAHITex Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020293", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "30-03-2025"},
				# {:part_id=> "AAAY", :name=> "First Protec Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020354", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "06-04-2025"},
				# {:part_id=> "AAAZ", :name=> "First Protec Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020354", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "06-04-2025"},
				# {:part_id=> "AABA", :name=> "First Protec Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020354", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "06-04-2025"},
				# {:part_id=> "AABN", :name=> "SAHITex Disposable Overboot Cover", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020421", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "14-04-2025"},
				# {:part_id=> "AAAV", :name=> "B-Safe Sterile Surgical Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020428", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "14-04-2021"},
				# {:part_id=> "AAAW", :name=> "B-Safe Sterile Surgical Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020428", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "14-04-2021"},
				# {:part_id=> "AAAX", :name=> "B-Safe Sterile Surgical Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020428", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "14-04-2021"},
				# {:part_id=> "AABB", :name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020409", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "14-04-2021"},
				# {:part_id=> "AABC", :name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020409", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "14-04-2021"},
				# {:part_id=> "AABD", :name=> "B-Safe Sterile Disposable Protective Coverall with Shoes Cover", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020409", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "14-04-2021"},
				# {:part_id=> "AABS", :name=> "B-Safe Sterile Isolation Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020514", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "24-04-2021"},
				# {:part_id=> "AABT", :name=> "B-Safe Sterile Isolation Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020514", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "24-04-2021"},
				# {:part_id=> "AABU", :name=> "B-Safe Sterile Isolation Gown", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020514", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "24-04-2021"},
				# {:part_id=> "AABO", :name=> "HERMONMED Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020529", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "26-04-2021"},
				# {:part_id=> "AABP", :name=> "HERMONMED Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020529", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "26-04-2021"},
				# {:part_id=> "AABQ", :name=> "HERMONMED Sterile Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020529", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "26-04-2021"},
				# {:part_id=> "AABR", :name=> "BestQ Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020631", :item_category=> "Non Elektromedik Non Steril", :id_nie=> "Non Elektromedik Non Steril", :ed_nie=> "11-05-2025"},
				# {:part_id=> "AABV", :name=> "FirstProtec Disposable Overboot Cover", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 11603020649 ", :item_category=> "Non Elektromedik Non Steril", :id_nie=> "Non Elektromedik Non Steril", :ed_nie=> "14-05-2025"},
				# {:part_id=> "AABH", :name=> "Sam+ Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020679 ", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "15-05-2025"},
				# {:part_id=> "AABI", :name=> "Sam+ Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020679 ", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "15-05-2025"},
				# {:part_id=> "AABJ", :name=> "Sam+ Disposable Protective Coverall", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020679 ", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "15-05-2025"},
				# {:part_id=> "AABE", :name=> "TRIGI APD Sterile Disposable Protective Coverall with Seal", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020758", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "26-05-2021"},
				# {:part_id=> "AABF", :name=> "TRIGI APD Sterile Disposable Protective Coverall with Seal", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020758", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "26-05-2021"},
				# {:part_id=> "AABG", :name=> "TRIGI APD Sterile Disposable Protective Coverall with Seal", :registered=> "Yes", :manufacturer=> "PT Provital Perdana", :nie_number=> "AKD 21603020758", :item_category=> "Non Elektromedik Steril", :id_nie=> "Non Elektromedik Steril", :ed_nie=> "26-05-2021"},
				{:part_id=> "AAAJ", :name =>"First Protec Single Surgical Gown  Size M"},
				{:part_id=> "AAAK", :name =>"First Protec Single Surgical Gown Size L"},
				{:part_id=> "AFAA", :name =>"Colonoscopy Pants"},
				{:part_id=> "AAAZ", :name =>"Sterile Disposable Protective Coverall Size L"},
				{:part_id=> "AAAV", :name =>"B-Safe Sterile Surgical Gown Size M"},
				{:part_id=> "AAAW", :name =>"B-Safe Sterile Surgical Gown Size L"},
				{:part_id=> "AABC", :name =>"B-Safe Sterile Disposable Protective Coverall with Shoe Cover Size L"},
				{:part_id=> "AABD", :name =>"B-Safe Sterile Disposable Protective Coverall with Shoe Cover Size XL"},
				{:part_id=> "AABV", :name =>"First Protec Disposable Overboot Cover"},
				{:part_id=> "AABF", :name =>"TRIGI APD Sterile Disposable Protective Coverall Size M"},
				{:part_id=> "AABI", :name =>"Sam+ Sterile Disposable Protective Coverall Size L"},
				{:part_id=> "AABJ", :name =>"Sam+ Sterile Disposable Protective Coverall Size XL"},
				{:part_id=> "AABL", :name =>"Sahitex Sterile Disposable Protective Coverall Size L"},
				{:part_id=> "AABS", :name =>"B-Safe Sterile Isolation Gown Size M"},
				{:part_id=> "AABT", :name =>"B-Safe Sterile Isolation Gown Size L"},
				{:part_id=> "AABY", :name =>"First Protec Sterile Protection Gown Size L"},

		]


    myarray.each do |product|
    	
    	check = Product.find_by(:part_id=> product[:part_id])
    	product_category = ProductCategory.find_by(:code=> product[:part_id].to_s[0])
    	if product_category.present?
    		puts "product_category: #{product_category.code} => #{product_category.id}"
	    	product_sub_category = ProductSubCategory.find_by(:product_category_id=> product_category.id, :code=> product[:part_id].to_s[1])
	    	if product_sub_category.present?
    			puts "product_sub_category: #{product_sub_category.code} => #{product_sub_category.id}"
	    		product_type = ProductType.find_by(:product_sub_category_id=> product_sub_category.id, :code=> product[:part_id].to_s[2,2])
		    	if product_type.present?
		    		customer_id = product_type.customer_id
	    			puts "product_type: #{product_type.code} => #{product_type.id}"
	    			product_item_category = ProductItemCategory.find_by(:name=> product[:item_category])
	    			if product_item_category.present?
	    			else
	    				puts "product_item_category: #{product[:item_category]} tidak ada"
	    			end
	    		end
	    	end
	    end
    	if check.present?
    		puts "#{product[:part_id]} exist"
    		check.update_columns({
    			:updated_at=> DateTime.now()
    		})
    	else
    		record = Product.create({
    			:customer_id=> customer_id,
    			:product_category_id=> product_category.id,
    			:product_sub_category_id=> product_sub_category.id,
    			:product_type_id=> product_type.id,
    			:unit_id=> 1, :color_id=> 1, :max_batch=> 1, :part_model=> nil, 
    			:name=> product[:name],
    			:part_id=> product[:part_id],
    			# :product_item_category_id=> product_item_category.id,
    			# :nie_number=> product[:nie_number], :nie_expired_date=> product[:ed_nie].to_date,
    			:status=> 'active',
    			:created_by=> 1, :created_at=> DateTime.now()
    		})
    		puts record.inspect
    		puts "#{product[:part_id]} not found"
    	end
    end
  end

  task :inject_stock => :environment do | t, args|   
    ActiveRecord::Base.establish_connection :development
    myarray = [
    			# 		{:part_id=> "AAAY", :batch_number=> "AAAY20001", :quantity=> "164"},
							# {:part_id=> "AAAZ", :batch_number=> "AAAZ20001", :quantity=> "2966"},
							# {:part_id=> "AAAZ", :batch_number=> "AAAZ20002", :quantity=> "20"},
							# {:part_id=> "AABA", :batch_number=> "AABA20002", :quantity=> "11"},
							# {:part_id=> "AABB", :batch_number=> "AABB20001", :quantity=> "137"},
							# {:part_id=> "AABC", :batch_number=> "AABC20001", :quantity=> "87"},
							# {:part_id=> "AABC", :batch_number=> "AABC20006", :quantity=> "264"},
							# {:part_id=> "AABC", :batch_number=> "AABC20007", :quantity=> "500"},
							# {:part_id=> "AABD", :batch_number=> "AABD20001", :quantity=> "11"},
							# {:part_id=> "AABD", :batch_number=> "AABD20005", :quantity=> "380"},
							# {:part_id=> "AABK", :batch_number=> "AABK20001", :quantity=> "63"},
							# {:part_id=> "AABL", :batch_number=> "AABL20001", :quantity=> "14"},
							# {:part_id=> "AABN", :batch_number=> "AABN20001", :quantity=> "279"},
							# {:part_id=> "AABP", :batch_number=> "AABP20001", :quantity=> "1"},
							# {:part_id=> "AABQ", :batch_number=> "AABQ20001", :quantity=> "4"},
							# {:part_id=> "AABT", :batch_number=> "AABT20010", :quantity=> "38"},
							# {:part_id=> "AABT", :batch_number=> "AABT20012", :quantity=> "149"},
							{:part_id=> "AAAJ", :batch_number=> "AAAJ20001", :quantity=> "0"},
							{:part_id=> "AAAJ", :batch_number=> "AAAJ20002", :quantity=> "0"},
							{:part_id=> "AAAK", :batch_number=> "AAAK20001", :quantity=> "0"},
							{:part_id=> "AAAK", :batch_number=> "AAAK20002", :quantity=> "0"},
							{:part_id=> "AFAA", :batch_number=> "AFAA20001", :quantity=> "0"},
							{:part_id=> "AAAZ", :batch_number=> "AAAZ20003", :quantity=> "0"},
							{:part_id=> "AAAZ", :batch_number=> "AAAZ20004", :quantity=> "0"},
							{:part_id=> "AAAV", :batch_number=> "AAAV20001", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20001", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20002", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20003", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20004", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20005", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20006", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20007", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20008", :quantity=> "0"},
							{:part_id=> "AAAW", :batch_number=> "AAAW20009", :quantity=> "0"},
							{:part_id=> "AABC", :batch_number=> "AABC20008", :quantity=> "0"},
							{:part_id=> "AABD", :batch_number=> "AABD20006", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20001", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20002", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20003", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20004", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20005", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20006", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20007", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20008", :quantity=> "0"},
							{:part_id=> "AABV", :batch_number=> "AABV20009", :quantity=> "0"},
							{:part_id=> "AABF", :batch_number=> "AABF20001", :quantity=> "0"},
							{:part_id=> "AABF", :batch_number=> "AABF20002", :quantity=> "0"},
							{:part_id=> "AABF", :batch_number=> "AABF20003", :quantity=> "0"},
							{:part_id=> "AABF", :batch_number=> "AABF20004", :quantity=> "0"},
							{:part_id=> "AABI", :batch_number=> "AABI20001", :quantity=> "0"},
							{:part_id=> "AABI", :batch_number=> "AABI20002", :quantity=> "0"},
							{:part_id=> "AABJ", :batch_number=> "AABJ20001", :quantity=> "0"},
							{:part_id=> "AABJ", :batch_number=> "AABJ20002", :quantity=> "0"},
							{:part_id=> "AABL", :batch_number=> "AABL20002", :quantity=> "0"},
							{:part_id=> "AABT", :batch_number=> "AABT20011", :quantity=> "0"},
							{:part_id=> "AABY", :batch_number=> "AACB20001", :quantity=> "0"},
							{:part_id=> "AABY", :batch_number=> "AACB20002", :quantity=> "0"},
							{:part_id=> "AABY", :batch_number=> "AACB20003", :quantity=> "0"}

				]
		periode_yyyy = "2020"
		periode_yyyymm = "202006"
		myarray.each do |record|
			product = Product.find_by(:part_id=> record[:part_id])
			if product.present?
				sfo_items = ShopFloorOrderItem.where(:shop_floor_order_id=>1, :product_id=> product.id, :quantity=> record[:quantity])
				if sfo_items.blank?

					shop_floor_order_item = ShopFloorOrderItem.create({
						:shop_floor_order_id=> 1,
						:product_id=> product.id,
						:quantity=> record[:quantity],
						:remarks=> "", :status=> 'active',
						:created_by=> 1, :created_at=> DateTime.now()
					})

          product_batch_number = ProductBatchNumber.find_by(:shop_floor_order_item_id=> shop_floor_order_item.id, :product_id=> product.id, :periode_yyyy=> periode_yyyy)
          if product_batch_number.blank?
            product_batch_number = ProductBatchNumber.create(
              :shop_floor_order_item_id=> shop_floor_order_item.id, 
              :product_id=> product.id, 
              :number=>  record[:batch_number],
              :periode_yyyy=> periode_yyyy
              )
          end 

          stock = Inventory.find_by(:product_id=> product.id, :periode=> periode_yyyymm)
          if stock.present?
          	stock.update_columns({
          		:begin_stock=> stock.begin_stock.to_f+record[:quantity].to_f
          	})
          else
          	stock = Inventory.create({
          		:product_id=> product.id, :periode=> periode_yyyymm,
          		:begin_stock=> record[:quantity].to_f,
          		:created_at=> DateTime.now()

          	})
          end

          stock_bn = InventoryBatchNumber.find_by(:product_id=> product.id, :product_batch_number_id=>product_batch_number.id, :periode=> periode_yyyymm)
          if stock_bn.present?
          	stock_bn.update_columns({
          		:begin_stock=> stock_bn.begin_stock.to_f+record[:quantity].to_f
          	})
          else
          	InventoryBatchNumber.create({
          		:product_id=> product.id, :product_batch_number_id=>product_batch_number.id, :periode=> periode_yyyymm,
          		:begin_stock=> record[:quantity].to_f,
          		:created_at=> DateTime.now()

          	})
          end
				end
			else
				puts "#{record[:part_id]} tidak ada"
			end
		end
  end

  task :inject_supplier => :environment do | t, args|
    ActiveRecord::Base.establish_connection :development
    myarray = [
    					{:supplier_number=> "PS-2017-001", :name=> "PT Global Instrument", :address=> "Kompleks ITC Duta Mas Fatmawati, Jalan Rs. Fatmawati, South Jakarta", :business_description=> "alat kalibrasi", :pic=> "", :phone=> "021-72791867", :email=> ""},
							{:supplier_number=> "PS-2017-002", :name=> "PT Antero Agung Jaya", :address=> "ITC Mangga Dua Lt 1 Blok E1 87", :business_description=> "stationary", :pic=> "", :phone=> "021-62300311", :email=> "anteroagungjaya@yahoo.com"},
							{:supplier_number=> "PS-2017-003", :name=> "PT Berkatmas Mulia Guna", :address=> "Taman Techno BSD Sektor XI Blok M No. 30 Serpong", :business_description=> "HVAC", :pic=> "Pak Priyo Suhartono", :phone=> "021-70956809 / 085324019266", :email=> ""},
							{:supplier_number=> "PS-2017-004", :name=> "PT Pratama Mandiri Prima", :address=> "Jl. Raya Cibarusah Blok B1F1, Ruko Cikarang", :business_description=> "alat dan bahan bangunan", :pic=> "", :phone=> "021-8971077", :email=> ""},
							{:supplier_number=> "PS-2017-005", :name=> "PT Linde Indonesia", :address=> "Jl. Raya Bekasi KM 21 Pulogadung Jakarta", :business_description=> "Gas ethylene oxide", :pic=> "Bu Elida", :phone=> "021-4601793", :email=> "elida.christine@linde.com"},
							{:supplier_number=> "PS-2017-006", :name=> "Terminix", :address=> "Taman Sentosa Blok B4 No 3 Cikarang", :business_description=> "pest control", :pic=> "Fatichi", :phone=> "021-89906588", :email=> "sales.cikarang@terminix.co.id"},
							{:supplier_number=> "PS-2017-007", :name=> "PT Abadi Baru Teknikatama", :address=> "Komplek Harmoni Mas Blok D No 43 Jakarta Utara", :business_description=> "hand pallet", :pic=> "Ibu Nunu Nensi", :phone=> "021-33228857", :email=> "jakarta@abadibaru.com"},
							{:supplier_number=> "PS-2017-008", :name=> "PD Citra Aman", :address=> "Jl Jababeka VI Blok J No 76 Kawasan Industri Jababeka", :business_description=> "APAR", :pic=> "", :phone=> "021-8934526", :email=> ""},
							{:supplier_number=> "PS-2017-009", :name=> "Sucofindo", :address=> "Jl Arteri Tol Cibitung Bekasi", :business_description=> "jasa kalibrasi", :pic=> "Lintang", :phone=> "021-88321176", :email=> "lintang@sucofindo-laboratory.co.id"},
							{:supplier_number=> "PS-2017-010", :name=> "PT Tuv Nord Indonesia", :address=> "Jl Science Timur 1 Blok B3-F1 Jababeka", :business_description=> "jasa kalibrasi", :pic=> "Pak Dhermawan", :phone=> "021-29574720", :email=> "dhermawan@tuv-nord.com"},
							{:supplier_number=> "PS-2017-011", :name=> "CV Berkah Tri Indonesia Kreator", :address=> "Vila Mutiara Cikarang Ruko Roxy No RB33 Ciksel", :business_description=> "percetakan", :pic=> "Mas Ryan", :phone=> "085222506685", :email=> "carakadesain@gmail.com"},
							{:supplier_number=> "PS-2017-012", :name=> "PT Multi Indojaya Makmur", :address=> "Jl raya Cikeas Bojong Nangka Kp. Tiajung RT 3/11", :business_description=> "pass box", :pic=> "", :phone=> "021-8671777", :email=> "sales.multindojayamakmur@gmail.com"},
							{:supplier_number=> "PS-2017-013", :name=> "CV Green Wirata", :address=> "Grand Residence Cluster Tirtayasa Blok AC12 No 18 Setu", :business_description=> "perlengkapan cleanroom", :pic=> "", :phone=> "021-36476011", :email=> "green.wirata@gmail.com"},
							{:supplier_number=> "PS-2017-014", :name=> "PT Octa Prima Lestari", :address=> "Jl Matraman Raya no 148", :business_description=> "horizontal laminar flow cabinet", :pic=> "", :phone=> "021-85918154", :email=> "sales@octaprimalestari.com"},
							{:supplier_number=> "PS-2017-015", :name=> "PT Dua Berlian", :address=> "Kawasan Industri Pulo Gadung Jakarta Timur", :business_description=> "new complete", :pic=> "Bu Avis", :phone=> "021-4602666", :email=> ""},
							{:supplier_number=> "PS-2017-016", :name=> "PT Home Center Indonesia", :address=> "Mal Metropolitan Bekasi", :business_description=> "meja kantor", :pic=> "", :phone=> "021-29315000", :email=> "mgr.metropolitan@homecenter.co.id"},
							{:supplier_number=> "PS-2017-017", :name=> "PT Sanic Jaya Chemical Industry", :address=> "Jl Prof Dr Latumenten No 19 Kota Grogol Permai Blok B36", :business_description=> "mesin jahit dan welding", :pic=> "Pak Yukani", :phone=> "021-5668441", :email=> "yukani@yahoo.co.id"},
							{:supplier_number=> "PS-2017-018", :name=> "PT Trikarsa Indoinstrument", :address=> "Rukan Hexa Green Kalimalang Blok B 5-7", :business_description=> "mesin laboratorium", :pic=> "Pak Soni S S", :phone=> "021-88351000", :email=> "sales@trikarsa.co.id"},
							{:supplier_number=> "PS-2017-019", :name=> "PT Cahayatiara Mustika scientific Indonesia", :address=> "Jl Jababeka IXB Blok BP 6H", :business_description=> "perlengkapan laboratorium", :pic=> "", :phone=> "021-89853111", :email=> "sales@cmsi-id.com"},
							{:supplier_number=> "PS-2017-020", :name=> "Shellindo Pratama", :address=> "Jl Kalianyar raya No 1 Tambora Jakbar", :business_description=> "CCTV", :pic=> "", :phone=> "021-60406060", :email=> "sp.shellindo@yahoo.com"},
							{:supplier_number=> "PS-2017-021", :name=> "PT Sinar Sejahtera Teknik", :address=> "Griya Bintara Indah Blok BB 5 No 7 Bekasi Barat", :business_description=> "ink jet printer mesin domino", :pic=> "", :phone=> "021-22100529", :email=> "ptsstbekasi@gmail.com"},
							{:supplier_number=> "PS-2017-022", :name=> "PT Altorium Multi Analitika", :address=> "Jl Prof Dr Soepomo No 44 Jakarta", :business_description=> "Bioindicator", :pic=> "", :phone=> "021-8294367", :email=> "altorium@yahoo.com"},
							{:supplier_number=> "PS-2017-023", :name=> "PT Ramesia Mesin Indoneisa", :address=> "Jl Boulevard Selatan Blok UB 20 Summarecon Bekasi", :business_description=> "pedal sealer machine", :pic=> "", :phone=> "021-29620477", :email=> "bekasi@ramesiamesin.com"},
							{:supplier_number=> "PS-2017-024", :name=> "PT Fosroc Indonesia", :address=> "Jl Akasia IIB No 1A Delta Silicon Lippo Cikarang", :business_description=> "epoxy", :pic=> "Bu Riza", :phone=> "021-8972103", :email=> "riza.rachmawati@fosroc.com"},
							{:supplier_number=> "PS-2017-025", :name=> "PT Kenko Elektrik Indonesia", :address=> "Jl Cibarusah Bumi Cikarang Makmur blok E22", :business_description=> "timbangan", :pic=> "", :phone=> "021-29520101", :email=> "info@kenkopanasonic.com"},
							{:supplier_number=> "PS-2017-026", :name=> "PT Ace Hardware Indonesia", :address=> "Mall Lippo Cikarang Jl MH Thamrin BF62 Cikarang", :business_description=> "home living", :pic=> "", :phone=> "021-8855025", :email=> "cs.lippocikarang@acehardware.co.id"},
							{:supplier_number=> "PS-2018-001", :name=> "Zhende Medical Co. Ltd", :address=> "NO. 3 Weilai Road, Industry Cluster District, Yanling County, 461200 Xuchang City, Henan Province, RRC NO. 3 Weilai Road, Industry Cluster District, Yanling County, 461200 Xuchang City, Henan Province, RRC", :business_description=> "Nonwoven 45 gsm SSMMMS Blue 1,6 m width", :pic=> "Gavin Tsui", :phone=> "+863747185552 dan '+8618237457857", :email=> "cgx@xczhende.com"},
							{:supplier_number=> "PS-2018-002", :name=> "PT. Eka Dharma International", :address=> "Jl. Samsung 2A Blok C2 G Kawasan Segitiga Emas, Cikarang Utara, Bekasi", :business_description=> "OPP Tape Clear ", :pic=> "Pak Triyono Wibowo", :phone=> "08128273893", :email=> "bm@ckr.ekadharma.com"},
							{:supplier_number=> "PS-2018-003", :name=> "PT. Ekasurya Inout Indonesia", :address=> "Komplek Multiguna Niaga 2 Jl. Tanjung  No. 9, Lippo Cikarang, Bekasi", :business_description=> "Hand Towel Tissue Wypall L20", :pic=> "Ibu Shella", :phone=> "08111902929", :email=> "shella@ekasurya.co.id"},
							{:supplier_number=> "PS-2018-004", :name=> "PT. Dayacipta Kemasindo", :address=> "Jl Inspeksi Kalimalang, Desa Karang Mulya, Kampung Calung, Karawang", :business_description=> "Carton Box  B/C Flute 540x540x340 cm", :pic=> "Pak Agung Riyanto", :phone=> "082111881346", :email=> "agungriyantoart@gmail.com"},
							{:supplier_number=> "PS-2018-005", :name=> "PT. Citra Satriawidya Andhika", :address=> "Jl. Swatantra 1 Kav 1 No 10-11, Jatirasa, Jatiasih, Bekasi", :business_description=> "Transfer Card Art Carton 230 gr; Carton Label Sticker HVS 21 x 12 cm", :pic=> "Pak Yasir", :phone=> "081294313830", :email=> "adevsolution23@gmail.com"},
							{:supplier_number=> "PS-2018-006", :name=> "PT. I Flex Indonesia", :address=> "Jl. Industri, 4 Blok 1 No 5-7, Pasir Jaya, Jatiuwung, Tangerang Banten, Banten 15135", :business_description=> "Sterile Pouch 25x40 cm", :pic=> "Pak Rama", :phone=> "081381960262", :email=> "rama@iflexgroups.com"},
							{:supplier_number=> "PS-2018-007", :name=> "CV. Graceful Grantika", :address=> "Jl. Kepu Timur No. 278 B, RT 13/15, Kel. Kemayoran – Kec. Kemayoran, DKI Jakarta", :business_description=> "Pouch Label Art Paper A5 120 gr printed 2 colour", :pic=> "Bu Dini", :phone=> "081295237667", :email=> "dinianatelia@gmail.com"},
							{:supplier_number=> "PS-2018-008", :name=> "CV. Harapan Baru", :address=> "Jl. Raya Cijerah No.27, Cibuntu, Bandung Kulon, Kota Bandung, Jawa Barat", :business_description=> "Cuff (Rib knit PE 5x7 cm)", :pic=> "Bu Lusi", :phone=> "085102909818", :email=> "harapanbarupds@gmail.com"},
							{:supplier_number=> "PS-2018-009", :name=> "Hao Rui Industry Co., Ltd", :address=> "Jinjingcheng Industrial Zone, Jiujiang City, Jiangxi Pro, China", :business_description=> "non woven", :pic=> "Sophy Ye", :phone=> "00867928502999", :email=> "info@jjhaorui.com"},
							{:supplier_number=> "PS-2018-010", :name=> "PT Intralab Ekatama", :address=> "Jl Terapi Raya No AD 2 Bumi Menteng Asri Bogor", :business_description=> "peralatan laboratorium", :pic=> "", :phone=> "0251-8359110", :email=> "intralab@indo.net.id"},
							{:supplier_number=> "PS-2018-011", :name=> "PT Arfindo Bersinar", :address=> "Perkantoran Kranggan RT 16 No 25-26 Jl Alternatif Cibubur", :business_description=> "kalibarasi alat", :pic=> "Rio", :phone=> "021-8456737", :email=> "ysr.rio11@gmail.com"},
							{:supplier_number=> "PS-2018-012", :name=> "PT Wirakarya Kencana Sakti", :address=> "Niaga Kalimas B6 Jl Inspeksi Kalimalang Bekasi", :business_description=> "peralatan laboratorium", :pic=> "", :phone=> "021-88357531", :email=> "sales@wikesa.com"},
							{:supplier_number=> "PS-2018-013", :name=> "PT Yokogawa Indonesia", :address=> "Plaza Oleos, Lantai 3 Blok A-H, Jalan Letjen TB. Simatupang Kav. 53, ", :business_description=> "chart dan ribbon cassete", :pic=> "", :phone=> "021-29712600", :email=> "Landung.Kautsar@id.yokogawa.com"},
							{:supplier_number=> "PS-2018-014", :name=> "PT Anugrah Putra Kencana", :address=> "Ruko Permata Junction Blok B3 Jl Raya Jababeka I Cikarang", :business_description=> "bahan kimia", :pic=> "", :phone=> "021-89833430", :email=> "anugrah.pk@gmail.com"},
							{:supplier_number=> "PS-2018-015", :name=> "PT Multi Redjeki Kita", :address=> "Jl Kebayoran lama No 28 Grogol Utara", :business_description=> "bakteri", :pic=> "", :phone=> "021-5348161", :email=> "info@mrk.co.id"},
							{:supplier_number=> "PS-2018-016", :name=> "PT Dipa Puspa", :address=> "Jl raya Kebayoran lama No 28 Grogol Utara Jakarta", :business_description=> "peralatan laboratorium", :pic=> "Pradyna", :phone=> "021-8255181", :email=> "pradyna.niata@dipa.co.id"},
							{:supplier_number=> "PS-2018-017", :name=> "PT. Trasti Global Konverta", :address=> "Ruko Sentra Niaga Kalimas Blok A-15, Bekasi", :business_description=> "perlengkapan cleanroom", :pic=> "", :phone=> "021-88394848", :email=> "zen@trastibiz.com"},
							{:supplier_number=> "PS-2018-018", :name=> "PT Inti sumber Hasil Sempurna", :address=> "Ruko Mega Grosir Cempaka Mas Blok M/58, JL. Letjen Suprapto, Jakarta", :business_description=> "perlengkapan produksi alkes", :pic=> "", :phone=> "021-42900301", :email=> ""},
							{:supplier_number=> "PS-2018-019", :name=> "PT Kawan Lama Sejahtera", :address=> "Jl Industri Selatan Blok BB 4 Jababeka II Cikarang", :business_description=> "peralatan laboratorium", :pic=> "", :phone=> "021-89832706", :email=> "counter4ckr@kawanlama.com"},
							{:supplier_number=> "PS-2018-020", :name=> "Contec Medical Systems Co. Ltd", :address=> "112 Qinhuang West Street, Qinhuangdao, China", :business_description=> "transducers", :pic=> "Lorraine", :phone=> "+86-3358015472", :email=> "lorraine.zeng@contecmed.com"},
							{:supplier_number=> "PS-2018-021", :name=> "PT Swan Angsa Putih", :address=> "Gedung Graha Anugerah ,Jl. Kartini Raya No. 25 A, RT.13/RW.4, Kartini, Sawah Besar, Jakarta Selatan", :business_description=> "kompresor", :pic=> "", :phone=> "021-62309678", :email=> "swantc@swanair.com"},
							{:supplier_number=> "PS-2018-022", :name=> "Kirana D'Sign", :address=> "Jl Delima V Blok A No 82 Duren Jaya Bekasi", :business_description=> "carton box, sticker", :pic=> "Pak Bambang", :phone=> "081519177899", :email=> "brbambang66@gmail.com"},
							{:supplier_number=> "PS-2018-023", :name=> "Sanichem Resource Sdn Bhd", :address=> "No 7 & 7A, Jalan Timur 6/1A Mercato @Enstek, Bandar Enstek, Negeri Sembilan, Malaysia", :business_description=> "jasa testing residual sterilisasi", :pic=> "Dr. Sani/Dr. Diyana", :phone=> "+606-7947606", :email=> "sanichem@gmail.com"},
							{:supplier_number=> "PS-2018-024", :name=> "PT Inlab Solusindo Jaya", :address=> "Ruko Topaz Commercial Block TC/B22 Bekasi", :business_description=> "perlengkapan laboratorium", :pic=> "mirza", :phone=> "021-28519919", :email=> "mirza@inlabsolusindo.com"},
							{:supplier_number=> "PS-2018-025", :name=> "PT. Logwin Ocean & Air Indonesia", :address=> "Soewarna Business Park Blok J Lot 10, Tangerang", :business_description=> "jasa forwarder", :pic=> "Bu Rossa", :phone=> "021-55911741", :email=> ""},
							{:supplier_number=> "PS-2018-026", :name=> "PT Catur Sentosa Berhasil", :address=> "Jl Cikarang Cibarusah No 68 Cikarang Selatan", :business_description=> "furniture", :pic=> "Pak Wawan", :phone=> "021-89915015", :email=> "sm.cikarang@atria.co.id"},
							{:supplier_number=> "PS-2018-027", :name=> "PT AGX Logistics Indonesia", :address=> "Wisma Soewarna Suite 1 Q, Jakarta", :business_description=> "jasa forwarder", :pic=> "Bu Iis", :phone=> "021-55912920", :email=> ""},
							{:supplier_number=> "PS-2018-028", :name=> "PT Mitra batavia Semesta", :address=> "Komplek Wahana Pondok Gede Blok D623, Bekasi", :business_description=> "anak timbang", :pic=> "Pak Budiman", :phone=> "021-29062206", :email=> "sales1@batavialab.com"},
							{:supplier_number=> "PS-2018-029", :name=> "PT Proton Gumilang ", :address=> "Taman Sentosa K 2/9, Cikarang Baru ", :business_description=> "pest control", :pic=> "Pak Deddy Hasan", :phone=> "021-29088999", :email=> "proton_cikarang@yahoo.com"},
							{:supplier_number=> "PS-2018-030", :name=> "PT. Berkat Niaga Dunia", :address=> "Jl. Cideng Barat No 47D, Jakarta", :business_description=> "gas detector", :pic=> "Pak Heru", :phone=> "021-6327060", :email=> "info@bndsafety.net"},
							{:supplier_number=> "PS-2018-031", :name=> "PT Jababeka Infrastruktur", :address=> "Jl. Jababeka IV Blok B No 12, Cikarang", :business_description=> "jasa analisa limbah", :pic=> "", :phone=> "081212241033", :email=> "  "},
							{:supplier_number=> "PS-2018-032", :name=> "PT Tirta Sari Nirmala (Lippo Cikarang Town Man.)", :address=> "Easton Commercial Centre, Jl. Gunung Panderman Kav. 05", :business_description=> "instalasi manajemen limbah", :pic=> "", :phone=> "(021) 8972484", :email=> "info@lippokarawaci.co.id"},
							{:supplier_number=> "PS-2018-033", :name=> "CV. Permata Tehnik", :address=> "Jl Raya Kartini no 30, Bekasi", :business_description=> "AC", :pic=> "Bu Dewi", :phone=> "021-8801947", :email=> "permatatehnik@yahoo.com"},
							{:supplier_number=> "PS-2018-034", :name=> "PT Osmo Indonesia", :address=> "Jl. Kampung Pekopen No.2, Lambangjaya, Tambun", :business_description=> "carton box", :pic=> "Pak Agung Riyanto", :phone=> "085886656256", :email=> "adm.osmoindonesia@gmail.com atau agungriyantoart@gmail.com"},
							{:supplier_number=> "PS-2018-035", :name=> "PT. Trimitra Swadaya", :address=> "Jln Kruing III Blok L7 No. 11, Delta Silicon I, Lippo Cikarang", :business_description=> "inner foam", :pic=> "Bu Yeni", :phone=> "021-89117520", :email=> "yeni.asriatin@trimitraswadaya.com"},
							{:supplier_number=> "PS-2018-036", :name=> "TUV Rheinland", :address=> "Menara Karya 10th floor, JL. HR Rasuna Said X-5/1-2 Jkt", :business_description=> "training dan sertifikasi ISO", :pic=> "Pak Wargono", :phone=> "021-57944579", :email=> "wargono@tuv.com"},
							{:supplier_number=> "PS-2018-037", :name=> "CV. Sharma Indotama", :address=> "Kirana Cibitung Blok D6 No 31, Cibitung", :business_description=> "jasa kalibrasi", :pic=> "Pak Rio", :phone=> "081299312663", :email=> "sharma.indotama1@gmail.com"},
							{:supplier_number=> "PS-2018-038", :name=> "PT. Kirana Pacifik Luas", :address=> "Jl. Pluit Karang Karya Blok A Selatan No. 28", :business_description=> "keranjang tressa untuk electromedic", :pic=> "Bu Mimi", :phone=> "021-6682891", :email=> "direct_sales1@clarishome.com"},
							{:supplier_number=> "PS-2018-039", :name=> "PT Pura Barutama", :address=> "Jl AKBP R Agil Kusumadya 203 Kudus", :business_description=> "offset printing", :pic=> "Pak Ferry", :phone=> "021-79193585-1633", :email=> "ferry-dc@kudus.puragroup.com"},
							{:supplier_number=> "PS-2018-040", :name=> "CV Lydia Jaya", :address=> "Kp.Prapatan Neih RT 007/004 Desa Sukadanau Cikarang ", :business_description=> "palet plastik", :pic=> "Pak Ummi", :phone=> "081285168456", :email=> "ummikomputer2@gmail.com"},
							{:supplier_number=> "PS-2018-041", :name=> "LFIndonesia", :address=> "LTC Glodok Lt. GF1 Blok C32 No. 6 ", :business_description=> "exhaust portable", :pic=> "Bu Silvia", :phone=> "0817168228", :email=> "lfindonesiashop@yahoo.com"},
							{:supplier_number=> "PS-2018-042", :name=> "Mitra10 Cibarusah Cikarang", :address=> "Jl Raya Cibarusah No.68 G Cikarang", :business_description=> "bahan bangunan", :pic=> "Pak Rodin", :phone=> "021-89915001", :email=> "ecommerce@mitra10.com"},
							{:supplier_number=> "PS-2018-043", :name=> "Ikea Indonesia", :address=> "Alam Sutera, Tangerang", :business_description=> "furniture", :pic=> "Bu Ulfa", :phone=> "021-29853900", :email=> "Ikea_Business@ikea.co.id"},
							{:supplier_number=> "PS-2018-044", :name=> "Toko Laboratorium ", :address=> "jl arif rahman hakim rt 8 rw 19 no 25 kel depok kec pancoranmas kota depok 16431", :business_description=> "perlengkapan laboratorium", :pic=> "Bu Nurmalia", :phone=> "+62 877-1454-3210", :email=> ""},
							{:supplier_number=> "PS-2018-045", :name=> "Pak Subiyoto", :address=> "Sukaresmi, Cikarang Selatan", :business_description=> "pekerjaan bangunan", :pic=> "Pak Subiyoto", :phone=> "081294145978", :email=> "subiyoto_44@yahoo.co.id"},
							{:supplier_number=> "PS-2018-046", :name=> "CV. Karya Tech Environment", :address=> "Jl Poras RT 4/4 Nomor 113, Bogor", :business_description=> "cube set", :pic=> "Pak Teguh", :phone=> "081296221982", :email=> "karyatechenvironment@gmail.com"},
							{:supplier_number=> "PS-2018-047", :name=> "PT. Sixmurs Perdana", :address=> "Gading Bukit Indah Blok SB No. 21, Kelapa Gading, Jakarta 14240 ", :business_description=> "jasa registrasi dan prodev", :pic=> "Mbak Maya", :phone=> "021-29078797", :email=> "info@sixmurs.com"},
							{:supplier_number=> "PS-2019-001", :name=> "PT Insekta Fokustama", :address=> "Taman Aster Blok A1/96, Cikarang Barat, Bekasi", :business_description=> "pest control", :pic=> "Pak Wahyu", :phone=> "021-29088851", :email=> "insekta_cikarang@yahoo.co.id"},
							{:supplier_number=> "PS-2019-002", :name=> "PT Draegerindo Jaya", :address=> "Alamanda Tower Lt 32, Jl TB Simatupang Kav 23-24, Jaksel", :business_description=> "Gas detector", :pic=> "Bu Yana", :phone=> "021-80669030", :email=> "suryana.halim@draeger.com"},
							{:supplier_number=> "PS-2019-003", :name=> "PT Indonusa System Integrator Prima", :address=> "Plaza Kelapa Dua, Jl Panjang arteri, Kebon Jeruk, Jakbar", :business_description=> "Internet provider", :pic=> "Pak Andre ", :phone=> "021-5332556", :email=> "billing@indonusa.net.id"},
							{:supplier_number=> "PS-2019-004", :name=> "PT Flamenco Aircon Mandiri", :address=> "Ruko Kp. Pengkolan RT 4/4, Desa Kalijaya, Cikarang ", :business_description=> "Service AC", :pic=> "Pak Taufik", :phone=> "08161131780", :email=> "office@flamenco.co.id"},
							{:supplier_number=> "PS-2019-005", :name=> "PT Kalingga Tataraya", :address=> "Komplek Pergudangan Tambun City Blok C7 Tambun", :business_description=> "3M product", :pic=> "Bu Ima", :phone=> "021-89510100", :email=> "customer-care@tataraya.com"},
							{:supplier_number=> "PS-2019-006", :name=> "Pandawa Media Protection", :address=> "Jl RE Martadinata No 37 RT 3/8 Cikarang", :business_description=> "APAR", :pic=> "Bu Dini", :phone=> "021-89121770", :email=> "pandawamedia.p@gmail.com"},
							{:supplier_number=> "PS-2019-007", :name=> "PT Intangading Kencanapersada", :address=> "Gading Bukit Inah Blok G/17, Jakarta Utara", :business_description=> "Kartu Nama", :pic=> "", :phone=> "021-45847321", :email=> ""},
							{:supplier_number=> "PS-2019-008", :name=> "PT Sumber Aneka Karya Abadi", :address=> "Jl Batu Ceper No 2, Gambir, Jakarta Pusat", :business_description=> "alat laboratorium", :pic=> "Bu Puput", :phone=> "021-3854444", :email=> "saka@saka.co.id"},
							{:supplier_number=> "PS-2019-009", :name=> "PT Prahasta Kreasi Teknologi Internasional (Praxistem)", :address=> "Ruko Graha Ciawi Blok 7, Jl raya Banjarwaru No 47 RT1/2, Bogor", :business_description=> "cube set", :pic=> "Juan Patmos", :phone=> "0251-7563724", :email=> "info@praxistem.com"},
							{:supplier_number=> "PS-2019-010", :name=> "PT Mursmedic", :address=> "Gading Bukit Indah Blok SB No 22, Jakarta", :business_description=> "jasa logistik", :pic=> "Mbak Martha", :phone=> "021-29078970", :email=> "'martha.kusuma@sixmurs.com'"},
							{:supplier_number=> "PS-2019-011", :name=> "Bilqis Furniture", :address=> "Jl Haji Awi Gg Lahin RT 1/3, Jatiluhur, Bekasi", :business_description=> "furniture", :pic=> "Pak Hamid", :phone=> "081291213423", :email=> "infobilqisfurniture@gmail.com"},
							{:supplier_number=> "PS-2019-012", :name=> "PT Zeta Utama Satya", :address=> "Jl Panjang Nomor 808, Kampung Baru, Jakarta Barat", :business_description=> "jumpsuit lab", :pic=> "Bu Tri", :phone=> "021-53677328", :email=> "info@zetautama.com"},
							{:supplier_number=> "PS-2019-013", :name=> "PT Sentral Tehnologi Managemen", :address=> "Cikarang Square Blok B/11, Jl Cibarusah, Cikarang Selatan", :business_description=> "jasa kalibrasi", :pic=> "Pak Yani", :phone=> "021-89321314", :email=> "cs@sentralkalibrasi.co.id"},
							{:supplier_number=> "PS-2019-014", :name=> "PT Endo Indonesia", :address=> "Jl Raya Menganti No 14, Kedurus, Surabaya", :business_description=> "baloon catheter", :pic=> "Bu Eka", :phone=> "031 - 7673636", :email=> "info@endo.id"},
							{:supplier_number=> "PS-2019-015", :name=> "PT. Excelindo Sejahtera", :address=> "Jl Mangga Dua Raya Blok K no 7, Jakarta", :business_description=> "laptop", :pic=> "Pak Budi", :phone=> "021-6498391", :email=> "sales@excelindocomputer.com"},
							{:supplier_number=> "PS-2019-016", :name=> "RS. Hosana Medica", :address=> "Thamrin Square C3, Jalan Utama BIIE No. 01, Cikarang", :business_description=> "medical check up", :pic=> "", :phone=> "021-8972472", :email=> "lippocikarang@hosana-medica.com"},
							{:supplier_number=> "PS-2019-017", :name=> "PT Sahabat Selamat Indonesia", :address=> "Jl Raya Cikarang-Cibarusah No 21, Industri Lippo Cikarang", :business_description=> "pemeriksaan mesin", :pic=> "Bu Husnul", :phone=> "08118848551", :email=> "sahabatsafety.ssi@gmail.com"},
							{:supplier_number=> "PS-2019-018", :name=> "CV Desire Inovasi Teknologi ", :address=> "Jl Antilop 3 Blok E2 No 5 Cikarang Baru RT 6/7 ", :business_description=> "access door", :pic=> "Bu Riris", :phone=> "021-29453766", :email=> "desireinovasiteknologi@gmail.com"},
							{:supplier_number=> "PS-2019-019", :name=> "PT Zi-Tech-Asia", :address=> "Jl Jend. Gatot Subroto No 38, Jakarta 12710 - Indonesia", :business_description=> "mesin domino", :pic=> "Bu Warsi", :phone=> "021 2526075", :email=> "warsi.mirakanti@zi-tec.com"},
							{:supplier_number=> "PS-2019-020", :name=> "PT Birotika Semesta (DHL)", :address=> "Jl MT Haryono Kav 58-60 Jakarta", :business_description=> "logistic service", :pic=> "Pak Reza Satria", :phone=> "021-29537151", :email=> "reza.satria@dhl.com"},
							{:supplier_number=> "PS-2019-021", :name=> "PT LGS", :address=> "Ruko Kalimas Blok D 12A, Jl Chairil Anwar, Bekasi", :business_description=> "logistic service", :pic=> "Pak Hendri", :phone=> "+62 821-1138-1231", :email=> "customer.service@ptlgs.com"},
							{:supplier_number=> "PS-2019-022", :name=> "PT Agarindo Biological Company ", :address=> "KP Cilongkok RT 4/3 Sukamantri, Tangerang", :business_description=> "lab needs", :pic=> "Bu Heri", :phone=> "021-56951805", :email=> "marketing@agarindo-biological.com"},
							{:supplier_number=> "PS-2019-023", :name=> "PT Certindonesia", :address=> "Cibubur Times Square Madison Blok C2 No.21 Bekasi", :business_description=> "training", :pic=> "Bu Yanih", :phone=> "0822-1177-2209 / 021-286 772 55", :email=> "certindo@gmail.com"},
							{:supplier_number=> "PS-2019-024", :name=> "PT Samator Tomoe", :address=> "Jl. Industri Selatan 4 Blok PP No. 4A, Bekasi", :business_description=> "gas ETO", :pic=> "Pak Nurmashuri", :phone=> "021 893 7930", :email=> "marketing@samator-tomoe.com"},
							{:supplier_number=> "PS-2019-025", :name=> "PT Etos Indonusa", :address=> "Tambun City Blok RG-15 Tambun, Bekasi", :business_description=> "pest control", :pic=> "Bu Dwi", :phone=> "021-5606688", :email=> "bekasi@etos-online.com"},
							{:supplier_number=> "PS-2019-026", :name=> "Printaholic", :address=> "Ruko Notredame Blok A No.2-3, Kota Deltamas, Cikarang Pusat, Indonesia,, 17530, Sukamahi, Kec. Cikarang Pusat, Cikarang Pusat, Jawa Barat 17530", :business_description=> "percetakan", :pic=> "Mas Ivan", :phone=> "021-89971016", :email=> "deltamas@printaholic.co.id"},
							{:supplier_number=> "PS-2019-027", :name=> "Balai Besar Kimia dan Kemasan Kemenperin", :address=> "Jl Balai Kimia No 1, pekayon Pasar Rebo, Jakarta", :business_description=> "uji kemasan", :pic=> "Pak Roni", :phone=> "021-8714928", :email=> "bbkk@cbn.net.id"},
							{:supplier_number=> "PS-2019-028", :name=> "PT Maja Bintang Indonesia", :address=> "Grand Unedo Jl Raya Bina Marga No 94G, Jaktim", :business_description=> "peralatan lab", :pic=> "Bu Elsha", :phone=> "021-84304918", :email=> "mbi@majabintang.com"},
							{:supplier_number=> "PS-2019-029", :name=> "Masis Embatama Engineering", :address=> "Jl. Cisarantem Wetan I No 143, Bandung", :business_description=> "peralatan lab", :pic=> "Pak Istiyanto", :phone=> "022-7811889", :email=> "masis_63@yahoo.com"},
							{:supplier_number=> "PS-2019-030", :name=> "PT Banyu Surya Abadi", :address=> "Komplek Perkantoran Mangga Dua Square, Jl Gunung Sahari Raya, Lt 1/A219, Jakarta Utara", :business_description=> "jasa kalibrasi", :pic=> "Pak Oki", :phone=> "021-22620591", :email=> "info.labkalibrasi@gmail.com"},
							{:supplier_number=> "PS-2020-001", :name=> "Toko Mesin Maksindo", :address=> "Jl Boulevard Selatan Ruko Emerald Blok UG/52, Bekasi", :business_description=> "continous band sealer", :pic=> "Pak Brata", :phone=> "021-29620593", :email=> "bekasi@tokomesin.com, citra@alphasains.com"},
							{:supplier_number=> "PS-2020-002", :name=> "PT Harapan Baja Sajati", :address=> "Angke Square Blok C No 38 Jakarta Barat", :business_description=> "mesin pemotong kain", :pic=> "Pak Dian", :phone=> "+62 817-0885-549", :email=> "hbspisaupond@gmail.com"},
							{:supplier_number=> "PS-2020-003", :name=> "PT Rachmathutama Pratamamandiri", :address=> "Ruko Grand Prima Bintara No 32 Bekasi", :business_description=> "logistik untuk sampel ", :pic=> "Bu Dini", :phone=> "021-88863360", :email=> "dini@airparcel-express.com"},
							{:supplier_number=> "PS-2020-004", :name=> "Balai Besar Tekstil", :address=> "Jl. Jenderal Ahmad Yani No. 390 Bandung", :business_description=> "uji tekstil", :pic=> "Pak Taufik (CS)", :phone=> "022-7206214", :email=> "pemasaran@bbt.kemenperin.go.id"},
							{:supplier_number=> "PS-2020-005", :name=> "PT Efata Sukses Abadi", :address=> "Jl Salembaran Raya No 3, Kosambi, Tangerang 15124, Indonesia", :business_description=> "pH meter ohaus", :pic=> "Bu Sheila", :phone=> "021-55933755", :email=> "efatasuksesabadi@gmail.com"},
							{:supplier_number=> "PS-2020-006", :name=> "Rabils Konveksi", :address=> "Jln Raya Jonggol, Perum Nila Alam Permai Blok B3/18", :business_description=> "Konveksi", :pic=> "Pak Ujang", :phone=> "+62 878-7860-2199", :email=> "ujangaziz79@gmail.com"},
							{:supplier_number=> "PS-2020-007", :name=> "Pak Deden", :address=> "Perumahan Griya Pratama Cileungsi Blok A3 No6, Ds. Gandoang ", :business_description=> "Konveksi", :pic=> "Pak Deden", :phone=> "082112092628", :email=> ""},
							{:supplier_number=> "PS-2020-008", :name=> "Bandar Creativity", :address=> "Citra Indah City Bukit Palem Blok S15/7, Jonggol", :business_description=> "Konveksi", :pic=> "Ibu Maria", :phone=> "081219992919", :email=> "mariaargaretha17@gmail.com"},
							{:supplier_number=> "PS-2020-009", :name=> "PT. Foursu Mitra Lestari", :address=> "Jl Antilop Raya Blok F2, Cikarang Barat", :business_description=> "Master Box", :pic=> "Pak Agung Riyanto", :phone=> "021-89324368", :email=> "foursumitralestari.pt@gmail.com"},
							{:supplier_number=> "PS-2020-010", :name=> "PT EMKA PUTRA PRATAMA", :address=> "Jl Banda No.88 Gadingrejo, Pasuruan Indonesia", :business_description=> "Laminasi Spunbond", :pic=> "Ibu Yenyen", :phone=> "0343-5643188", :email=> "yenyen.indrawati@gmail.com"},
							{:supplier_number=> "PS-2020-011", :name=> "PT.Seigo Selaras Indonesia", :address=> "Jl. Mataram Block A-018 Lippo Cikarang", :business_description=> "Plastick Polybag", :pic=> "Ibu Jenita", :phone=> "8996573731", :email=> "Jenita Seigo <jenita@seigoindonesia.com>"},
						]
		myarray.each do |record|
			supplier = Supplier.find_by(:number=> record[:supplier_number])
			if supplier.present?
			else
				puts "create: #{record[:supplier_number]}"
				Supplier.create({
					:registered_at => "#{record[:supplier_number].to_s[3,4]}-01-01",
					:number=> record[:supplier_number],
					:name=> record[:name],
					:tax_id=> 1, :currency_id=> 1, :top_day=> 0, :term_of_payment_id=> 1,
					:business_description=> record[:business_description],
					:address=> record[:address], :pic=> record[:pic], :telephone=> record[:phone], :email=> record[:email],
					:status=> 'active', :created_at=> DateTime.now(), :created_by=> 1
				})
			end
		end
  end

  task :inject_material => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
  	myarray = [
  						{:name=> "Nonwoven 45 gsm SSMMMS Blue 1,6 m width", :vendor_name=> "Zhende Medical Co., Ltd.", :material_category_code=> "A", :material_code=> "A001"},
							{:name=> "Nonwoven 25 gsm SMS Blue 1,6 m width", :vendor_name=> "Hao Rui Industry Co., Ltd.", :material_category_code=> "A", :material_code=> "A002"},
							{:name=> "Hand Towel Tissue Wypall L20", :vendor_name=> "PT. Ekasurya Inout Indonesia", :material_category_code=> "A", :material_code=> "A003"},
							{:name=> "Cube Tele CTG A016", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A004"},
							{:name=> "Cuff ", :vendor_name=> "CV. Harapan Baru", :material_category_code=> "A", :material_code=> "A005"},
							{:name=> "Velcrow", :vendor_name=> "CV. Green Wirata", :material_category_code=> "A", :material_code=> "A006"},
							{:name=> "Collar", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A007"},
							{:name=> "Battery 700 mAh Zetta A019", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A008"},
							{:name=> "Manual Book Tele CTG A022", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A009"},
							{:name=> "Transfer Card ", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "A", :material_code=> "A010"},
							{:name=> "Adaptor USB Zetta A017", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A011"},
							{:name=> "Kabel Data USB Zetta A018", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A012"},
							{:name=> "Regulatory Label Tele CTG A025", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A013"},
							{:name=> "Probe Zetta", :vendor_name=> "Contec Medical System Co., Ltd.", :material_category_code=> "A", :material_code=> "A014"},
							{:name=> "Belt Zetta", :vendor_name=> "Contec Medical System Co., Ltd.", :material_category_code=> "A", :material_code=> "A015"},
							{:name=> "Cube Tele CTG", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A016"},
							{:name=> "Adaptor USB Zetta", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A017"},
							{:name=> "Kabel Data USB Zetta", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A018"},
							{:name=> "Battery 800 mAh Zetta", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A019"},
							{:name=> "Sticker Serial Number Cube Tele CTG", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A020"},
							{:name=> "Sticker MAC address Tele CTG", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A021"},
							{:name=> "Manual Book Tele CTG", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A022"},
							{:name=> "Transfer Card Pride Med", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "A", :material_code=> "A023"},
							{:name=> "Caution Charging Label Zetta", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A024"},
							{:name=> "Regulatory Label Tele CTG", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A025"},
							{:name=> "Safety Box 5L", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A026"},
							{:name=> "Safety Box 8L", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A027"},
							{:name=> "Safety Box 12.5L", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A028"},
							{:name=> "Safety Box 20L", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A029"},
							{:name=> "Safety Box 5L", :vendor_name=> "PT. Pura Barutama", :material_category_code=> "A", :material_code=> "A030"},
							{:name=> "Safety Box 8L", :vendor_name=> "PT. Pura Barutama", :material_category_code=> "A", :material_code=> "A031"},
							{:name=> "Safety Box 12.5L", :vendor_name=> "PT. Pura Barutama", :material_category_code=> "A", :material_code=> "A032"},
							{:name=> "Safety Box 20L", :vendor_name=> "PT. Pura Barutama", :material_category_code=> "A", :material_code=> "A033"},
							{:name=> "Cube Label Tele CTG", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A034"},
							{:name=> "Sticker Daftar Isi", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A035"},
							{:name=> "Sticker Content", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A036"},
							{:name=> "Ethylene Oxide Gas 30:70", :vendor_name=> "PT. Linde Indonesia", :material_category_code=> "A", :material_code=> "A037"},
							{:name=> "Sticker cover manual book", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A038"},
							{:name=> "Sticker manual book page 2", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A039"},
							{:name=> "Sticker manual book page 10", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A040"},
							{:name=> "Sticker manual book page 26", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A041"},
							{:name=> "Sticker Serial Number dan MAC Address TCTG002", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "A", :material_code=> "A042"},
							{:name=> "Nonwoven 45 gsm 1,6 m ASIS", :vendor_name=> "PT. ASIS Mitra Andalan", :material_category_code=> "A", :material_code=> "A043"},
							{:name=> "C-section label pembuka", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A044"},
							{:name=> "C-section label ", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "A", :material_code=> "A045"},
							{:name=> "Nonwoven 45 gsm SMMMS", :vendor_name=> "Hao Rui Industry Co., Ltd.", :material_category_code=> "A", :material_code=> "A046"},
							{:name=> "Ethylene Oxide Gas 30:70", :vendor_name=> "PT. Samator Tomoe", :material_category_code=> "A", :material_code=> "A047"},
							{:name=> "Transfer Card BestQ ASIS", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "A", :material_code=> "A048"},
							{:name=> "Liquid Pouch 20x30 cm", :vendor_name=> "Tokopedia", :material_category_code=> "A", :material_code=> "A049"},
							{:name=> "Adhesive Single Tape PU", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A050"},
							{:name=> "Tin Tie", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A051"},
							{:name=> "Double Tape", :vendor_name=> "PT. St Morita Industries", :material_category_code=> "A", :material_code=> "A052"},
							{:name=> "white spunbound 70 gsm PP", :vendor_name=> "PT. Karya Sukses Setia", :material_category_code=> "A", :material_code=> "A053"},
							{:name=> "Eye socket", :vendor_name=> "PT. Tri Saudara Sentosa Industri", :material_category_code=> "A", :material_code=> "A054"},
							{:name=> "Seam seal", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A055"},
							{:name=> "Adhesive Single Tape PU", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A056"},
							{:name=> "Plastic Liquid Pouch 28x18 cm", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A057"},
							{:name=> "Tin Tie", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A058"},
							{:name=> "Double Tape 24 mm Ophtalmic", :vendor_name=> "PT. St Morita Industries", :material_category_code=> "A", :material_code=> "A059"},
							{:name=> "white spunbound 70 gsm PP Trimitra", :vendor_name=> "PT. Trimitra Swadaya", :material_category_code=> "A", :material_code=> "A060"},
							{:name=> "white spunbound 60 gsm", :vendor_name=> "PT. Multi Spunindo Jaya", :material_category_code=> "A", :material_code=> "A061"},
							{:name=> "Cloth tape morita", :vendor_name=> "PT. St Morita Industries", :material_category_code=> "A", :material_code=> "A062"},
							{:name=> "Cloth tape daimaru", :vendor_name=> "Pratama", :material_category_code=> "A", :material_code=> "A063"},
							{:name=> "Spunbound PP 45 gsm Karya", :vendor_name=> "PT Karya Sukses Setia", :material_category_code=> "A", :material_code=> "A064"},
							{:name=> "spunbound PP laminated PE", :vendor_name=> "PT. Multi Spunindo Jaya", :material_category_code=> "A", :material_code=> "A065"},
							{:name=> "white spunbound 70 gsm", :vendor_name=> "PT. Multi Spunindo Jaya", :material_category_code=> "A", :material_code=> "A066"},
							{:name=> "spunbound PP surya", :vendor_name=> "PT Surya Sukses Mekar Makmur", :material_category_code=> "A", :material_code=> "A067"},
							{:name=> "LEGING 75X120", :vendor_name=> "PT. Tarafis Anugerah Medika", :material_category_code=> "A", :material_code=> "A068"},
							{:name=> "Coverall Bulk PP Size M", :vendor_name=> "PT. Najagra Mulia Abadi", :material_category_code=> "A", :material_code=> "A069"},
							{:name=> "Coverall Bulk PP Size L", :vendor_name=> "PT. Najagra Mulia Abadi", :material_category_code=> "A", :material_code=> "A070"},
							{:name=> "Coverall Bulk PP Size XL", :vendor_name=> "PT. Najagra Mulia Abadi", :material_category_code=> "A", :material_code=> "A071"},
							{:name=> "BestQ Coverall Bulk", :vendor_name=> "PT. Anugerah Sinergi Solustama", :material_category_code=> "A", :material_code=> "A072"},
							{:name=> "Coverall Bulk PE Size M", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A073"},
							{:name=> "Coverall Bulk PE Size L", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A074"},
							{:name=> "Coverall Bulk PE Size XL", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A075"},
							{:name=> "Kimono Bulk Size M", :vendor_name=> "PT. Najagra Mulia Abadi", :material_category_code=> "A", :material_code=> "A076"},
							{:name=> "Kimono Bulk Size L", :vendor_name=> "PT. Najagra Mulia Abadi", :material_category_code=> "A", :material_code=> "A077"},
							{:name=> "Kimono Bulk Size XL", :vendor_name=> "PT. Najagra Mulia Abadi", :material_category_code=> "A", :material_code=> "A078"},
							{:name=> "Shoe cover bulk", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A079"},
							{:name=> "Surgical SMS Bulk Size M", :vendor_name=> "PT. Tarafis Anugerah Medika", :material_category_code=> "A", :material_code=> "A080"},
							{:name=> "Surgical SMS Bulk Size L", :vendor_name=> "PT. Tarafis Anugerah Medika", :material_category_code=> "A", :material_code=> "A081"},
							{:name=> "Surgical SMS Bulk Size XL", :vendor_name=> "PT. Tarafis Anugerah Medika", :material_category_code=> "A", :material_code=> "A082"},
							{:name=> "Cloth Tape Morita 24 x 10 ", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A083"},
							{:name=> "Nonwoven Biru Terang 42Gsm", :vendor_name=> "", :material_category_code=> "A", :material_code=> "A084"},
							{:name=> "B = Bahan Kemas	", :material_category_code=> "", :material_code=> ""},
							{:name=> "Sterile Pouch 25x40 cm", :vendor_name=> "PT. I Flex Indonesia", :material_category_code=> "B", :material_code=> "B001"},
							{:name=> "Carton Box Gowning", :vendor_name=> "PT. Dayacipta Kemasindo", :material_category_code=> "B", :material_code=> "B002"},
							{:name=> "OPP Tape Clear ", :vendor_name=> "Ekadharma International, Tbk.", :material_category_code=> "B", :material_code=> "B003"},
							{:name=> "Carton Label Gowning Size M", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B004"},
							{:name=> "Carton Label Gowning Size L", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B005"},
							{:name=> "Carton Label Gowning Size XL", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B006"},
							{:name=> "Pouch Label Gowning Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B007"},
							{:name=> "Pouch Label Gowning Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B008"},
							{:name=> "Pouch Label Gowning Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B009"},
							{:name=> "Sterile Pouch 15x25 cm", :vendor_name=> "PT. I Flex Indonesia", :material_category_code=> "B", :material_code=> "B010"},
							{:name=> "Inner Foam Zetta", :vendor_name=> "PT. Trimitra Swadaya", :material_category_code=> "B", :material_code=> "B011"},
							{:name=> "Cover Foam Zetta", :vendor_name=> "PT. Trimitra Swadaya", :material_category_code=> "B", :material_code=> "B012"},
							{:name=> "Masterbox Zetta", :vendor_name=> "PT. Osmo Indonesia", :material_category_code=> "B", :material_code=> "B013"},
							{:name=> "Masterbox Label Tele CTG", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B014"},
							{:name=> "Individual Box Zetta", :vendor_name=> "Kirana D'Sign", :material_category_code=> "B", :material_code=> "B015"},
							{:name=> "OPP Tape Clear Zetta", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B016"},
							{:name=> "Plastik Pengemas Cube Zetta", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "B", :material_code=> "B017"},
							{:name=> "Plastik Pengemas Charger Zetta", :vendor_name=> "Tokopedia", :material_category_code=> "B", :material_code=> "B018"},
							{:name=> "Seal Label Tele CTG", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B019"},
							{:name=> "Individual Box Zetta B015", :vendor_name=> "Kirana D'Sign", :material_category_code=> "B", :material_code=> "B020"},
							{:name=> "Pouch Label Gowning Pride Med Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B021"},
							{:name=> "Carton Label Gowning Pride Med Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B022"},
							{:name=> "Sticker Master Box Pride Med", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B023"},
							{:name=> "Code Sticker TCTG002", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B024"},
							{:name=> "Logo ISO 13485 Certified by TUV", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B025"},
							{:name=> "What's New Label Tele CTG", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B026"},
							{:name=> "Masterbox Label Tele CTG B014", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B027"},
							{:name=> "Carton Label Gowning Size XL B006", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B028"},
							{:name=> "Foam Pengemas Cube Zetta", :vendor_name=> "PT. Prahasta Kreasi Teknologi Internasional (Praxistem)", :material_category_code=> "B", :material_code=> "B029"},
							{:name=> "Plastik Cube TCTG002", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B030"},
							{:name=> "Box Label Medtromed 5 L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B031"},
							{:name=> "Box Label Medtromed 8 L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B032"},
							{:name=> "Box Label Medtromed 12 L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B033"},
							{:name=> "Box Label Medtromed 20 L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B034"},
							{:name=> "Master Box Safety Box 5 Liter", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B035"},
							{:name=> "Master Box Safety Box 8 Liter", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B036"},
							{:name=> "Master Box Safety Box 12 Liter", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B037"},
							{:name=> "Master Box Safety Box 20 Liter", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B038"},
							{:name=> "Carton Box ASIS", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B039"},
							{:name=> "Carton label gowning BestQ size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B040"},
							{:name=> "Carton label gowning BestQ size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B041"},
							{:name=> "Carton label gowning BestQ size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B042"},
							{:name=> "Carton label gowning BestQ with mask size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B043"},
							{:name=> "Carton label gowning BestQ with mask size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B044"},
							{:name=> "Carton label gowning BestQ with mask size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B045"},
							{:name=> "Pouch label gowning BestQ size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B046"},
							{:name=> "Pouch label gowning BestQ size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B047"},
							{:name=> "Pouch label gowning BestQ size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B048"},
							{:name=> "Pouch label gowning BestQ with mask size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B049"},
							{:name=> "Pouch label gowning BestQ with mask size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B050"},
							{:name=> "Pouch label gowning BestQ with mask size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B051"},
							{:name=> "Plastik ASIS", :vendor_name=> "Tokopedia", :material_category_code=> "B", :material_code=> "B052"},
							{:name=> "Plastik 25x40 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B053"},
							{:name=> "Carton label gowning BestQ non sterile size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B054"},
							{:name=> "Carton label gowning BestQ non sterile size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B055"},
							{:name=> "Carton label gowning BestQ non sterile size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B056"},
							{:name=> "Pouch label gowning BestQ non sterile size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B057"},
							{:name=> "Pouch label gowning BestQ non sterile size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B058"},
							{:name=> "Pouch label gowning BestQ non sterile size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B059"},
							{:name=> "Sterile Pouch (25 cm x 29 cm)", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B060"},
							{:name=> "Leaflet Ophthalmic Drape", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B061"},
							{:name=> "Sticker Open Pouch", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B062"},
							{:name=> "Box Drape Pancaraya", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B063"},
							{:name=> "Box Label Drape Pancaraya", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B064"},
							{:name=> "Kartu Garansi TCTG", :vendor_name=> "CV. Graceful Grantika", :material_category_code=> "B", :material_code=> "B065"},
							{:name=> "Plastik 30x45 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B066"},
							{:name=> "Leaflet Colonoscopy Pants", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B067"},
							{:name=> "Carton Box 54x34x54 cm", :vendor_name=> "PT. Foursu Mitra Lestari", :material_category_code=> "B", :material_code=> "B068"},
							{:name=> "Box Label colonoscopy", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B069"},
							{:name=> "Pouch label first protec coverall Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B070"},
							{:name=> "Pouch label first protec coverall Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B071"},
							{:name=> "Pouch label first protec coverall Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B072"},
							{:name=> "Cover Label first protec coverall Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B073"},
							{:name=> "Cover Label first protec coverall Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B074"},
							{:name=> "Cover Label first protec coverall Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B075"},
							{:name=> "Sterile Pouch 12x15 cm printed", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B076"},
							{:name=> "Sterile Pouch 25 x 29 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B077"},
							{:name=> "Sticker Pouch Label Opthalmic ", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B078"},
							{:name=> "Sticker Open Pouch", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B079"},
							{:name=> "Box Label Ophtalmic 15 x 10 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B080"},
							{:name=> "Carton Box 50x47x52 cm", :vendor_name=> "PT. Foursu Mitra Lestari", :material_category_code=> "B", :material_code=> "B081"},
							{:name=> "Double tape 12 mm", :vendor_name=> "PT. St. Morita Industries", :material_category_code=> "B", :material_code=> "B082"},
							{:name=> "Pouch label sahitex coverall Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B083"},
							{:name=> "Pouch label sahitex coverall Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B084"},
							{:name=> "Pouch label sahitex coverall Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B085"},
							{:name=> "Cover Label sahitex coverall Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B086"},
							{:name=> "Cover Label sahitex coverall Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B087"},
							{:name=> "Cover Label sahitex coverall Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B088"},
							{:name=> "Pouch label B-safe SG Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B089"},
							{:name=> "Pouch label B-safe SG Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B090"},
							{:name=> "Pouch label B-safe SG Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B091"},
							{:name=> "Cover Label B-safe SG Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B092"},
							{:name=> "Cover Label B-safe SG Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B093"},
							{:name=> "Cover Label B-safe SG Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B094"},
							{:name=> "Pouch label Sam Med Coverall Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B095"},
							{:name=> "Pouch label Sam Med Coverall Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B096"},
							{:name=> "Pouch label Sam Med Coverall Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B097"},
							{:name=> "Cover Label Sam Med Coverall Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B098"},
							{:name=> "Cover Label Sam Med Coverall Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B099"},
							{:name=> "Cover Label Sam Med Coverall Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B100"},
							{:name=> "Pouch label Trigi Coverall Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B101"},
							{:name=> "Pouch label Trigi Coverall Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B102"},
							{:name=> "Cover Label Trigi Coverall Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B103"},
							{:name=> "Cover Label Trigi Coverall Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B104"},
							{:name=> "Pouch label B-safe Coverall Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B105"},
							{:name=> "Pouch label B-safe Coverall Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B106"},
							{:name=> "Pouch label B-safe Coverall Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B107"},
							{:name=> "Cover Label B-safe Coverall Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B108"},
							{:name=> "Cover Label B-safe Coverall Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B109"},
							{:name=> "Cover Label B-safe Coverall Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B110"},
							{:name=> "Pouch label shoe cover sahitex", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B111"},
							{:name=> "Cover label shoe cover sahitex", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B112"},
							{:name=> "Pouch label shoe cover first protec", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B113"},
							{:name=> "Cover label shoe cover first protec", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B114"},
							{:name=> "Plastik Seal 20x30 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B115"},
							{:name=> "Steril Pouch Sigma 30x48 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B116"},
							{:name=> "Platik Seal 30 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B117"},
							{:name=> "Pouch label B-safe Isolation Gown Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B118"},
							{:name=> "Pouch label B-safe Isolation Gown Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B119"},
							{:name=> "Pouch label B-safe Isolation Gown Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B120"},
							{:name=> "Cover Label B-safe Isolation Gown Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B121"},
							{:name=> "Cover Label B-safe Isolation Gown Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B122"},
							{:name=> "Cover Label B-safe Isolation Gown Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B123"},
							{:name=> "Pouch label shoe cover B-SAFE", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B124"},
							{:name=> "Cover label shoe cover B-SAFE", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B125"},
							{:name=> "Pouch label BestQ coverall", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B126"},
							{:name=> "Cover Label BestQ coverall", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B127"},
							{:name=> "Pouch label Hermonmed Coverall Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B128"},
							{:name=> "Pouch label Hermonmed Coverall Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B129"},
							{:name=> "Pouch label Hermonmed Coverall Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B130"},
							{:name=> "Cover Label Hermonmed Coverall Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B131"},
							{:name=> "Cover Label Hermonmed Coverall Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B132"},
							{:name=> "Cover Label Hermonmed Coverall Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B133"},
							{:name=> "Pouch label Biocare Coverall ", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B134"},
							{:name=> "Cover Label Biocare Coverall ", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B135"},
							{:name=> "Plastik Seal 25 cm", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B136"},
							{:name=> "Pouch Label B-Safe Coverall+Shoe Size M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B137"},
							{:name=> "Pouch Label B-Safe Coverall+Shoe Size L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B138"},
							{:name=> "Pouch Label B-Safe Coverall+Shoe Size XL", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B139"},
							{:name=> "Cover Label B-Safe Coverall+Shoe Size M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B140"},
							{:name=> "Cover Label B-Safe Coverall+Shoe Size L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B141"},
							{:name=> "Cover Label B-Safe Coverall+Shoe Size XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B142"},
							{:name=> "Carton Box First Protec Non-Steril", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B143"},
							{:name=> "Pouch Label Trigi Coverall S", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B144"},
							{:name=> "Pouch Label Trigi Coverall M", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B145"},
							{:name=> "Pouch Label Trigi Coverall L", :vendor_name=> "PT. Citra Satriawidya Andhika ", :material_category_code=> "B", :material_code=> "B146"},
							{:name=> "Cover Label Trigi Coverall S", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B147"},
							{:name=> "Cover Label Trigi Coverall M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B148"},
							{:name=> "Cover Label Trigi Coverall L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B149"},
							{:name=> "Pouch Label Protection Gown M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B150"},
							{:name=> "Pouch Label Protection Gown L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B151"},
							{:name=> "Pouch Label Protection Gown XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B152"},
							{:name=> "Cover Label Protection Gown M", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B153"},
							{:name=> "Cover Label Protection Gown L", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B154"},
							{:name=> "Cover Label Protection Gown XL", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B155"},
							{:name=> "Carton Box 65x40x20 cm Single Fluet", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B156"},
							{:name=> "Plastik LDPE 25x29x0.008", :vendor_name=> "", :material_category_code=> "B", :material_code=> "B157"},
							{:name=> "BI (Bacillus atrophaeus ATCC 9372)", :vendor_name=> "PT Altorium Multi Analitika", :material_category_code=> "C", :material_code=> "C001"},
							{:name=> "Bacillus atrophaeus Crosstex", :vendor_name=> "PT Altorium Multi Analitika", :material_category_code=> "C", :material_code=> "C002"},
							{:name=> "Bacillus subtilis ATCC 6633", :vendor_name=> "PT Multiredjeki Kita", :material_category_code=> "C", :material_code=> "C003"},
							{:name=> "Clostridium sporogenes ATCC 11437", :vendor_name=> "PT Multiredjeki Kita", :material_category_code=> "C", :material_code=> "C004"},
							{:name=> "Candida albicans ATCC 10231", :vendor_name=> "PT Multiredjeki Kita", :material_category_code=> "C", :material_code=> "C005"},
							{:name=> "Staphylococcus aureus ATCC 6538", :vendor_name=> "PT Multiredjeki Kita", :material_category_code=> "C", :material_code=> "C006"},
							{:name=> "Pseudomonas aeruginosa ATCC 9027", :vendor_name=> "PT Multiredjeki Kita", :material_category_code=> "C", :material_code=> "C007"},
							{:name=> "Aspergillus brasiliensis ATCC 16404", :vendor_name=> "PT Multiredjeki Kita", :material_category_code=> "C", :material_code=> "C008"},
							{:name=> "Chemical Indicator Etigam", :vendor_name=> "PT Altorium Multi Analitika", :material_category_code=> "C", :material_code=> "C009"},
							{:name=> "Sodium Chloride", :vendor_name=> "Himedia", :material_category_code=> "C", :material_code=> "C010"},
							{:name=> "Tween 80", :vendor_name=> "Vivantis", :material_category_code=> "C", :material_code=> "C011"},
							{:name=> "Peptone, Bacteriogical", :vendor_name=> "Himedia", :material_category_code=> "C", :material_code=> "C012"},
							{:name=> "McFarland Standard Set", :vendor_name=> "Himedia", :material_category_code=> "C", :material_code=> "C013"},
							{:name=> "Sabouraud Dextrose Agar", :vendor_name=> "PT Intralab Ekatama - Himedia", :material_category_code=> "C", :material_code=> "C014"},
							{:name=> "Gram Stain Kit", :vendor_name=> "PT Intralab Ekatama - Himedia", :material_category_code=> "C", :material_code=> "C015"},
							{:name=> "Soyabean Casein Digest Medium (TSB)", :vendor_name=> "PT Intralab Ekatama - Himedia", :material_category_code=> "C", :material_code=> "C016"},
							{:name=> "Soyabean Casein Digest Agar (TSA)", :vendor_name=> "PT Intralab Ekatama - Himedia", :material_category_code=> "C", :material_code=> "C017"},
							{:name=> "Fluid Thioglycollate Medium", :vendor_name=> "PT Intralab Ekatama - Himedia", :material_category_code=> "C", :material_code=> "C018"},
							{:name=> "Reinforced Clostridia Agar", :vendor_name=> "PT Intralab Ekatama - Himedia", :material_category_code=> "C", :material_code=> "C019"},
							{:name=> "Anaerogen", :vendor_name=> "Thermo Scientific", :material_category_code=> "C", :material_code=> "C020"},
							{:name=> "Anaerobic Indicator", :vendor_name=> "Thermo Scientific", :material_category_code=> "C", :material_code=> "C021"},
							{:name=> "Buffer pH 4", :vendor_name=> "", :material_category_code=> "C", :material_code=> "C022"},
							{:name=> "Buffer pH 7", :vendor_name=> "", :material_category_code=> "C", :material_code=> "C023"},
							{:name=> "Buffer pH 9", :vendor_name=> "", :material_category_code=> "C", :material_code=> "C024"},
							{:name=> "Buffer pH 10", :vendor_name=> "", :material_category_code=> "C", :material_code=> "C025"},
							{:name=> "BI (Geobacillus stearothermophilus ATC 7953)", :vendor_name=> "", :material_category_code=> "C", :material_code=> "C026"},
							{:name=> "BI spore strips Etigam", :vendor_name=> "", :material_category_code=> "C", :material_code=> "C027"},
							{:name=> "Anak Timbang M2 5g", :vendor_name=> "PT Mitra Batavia Semesta", :material_category_code=> "D", :material_code=> "D001"},
							{:name=> "Anak Timbang M2 2 kg", :vendor_name=> "PT Mitra Batavia Semesta", :material_category_code=> "D", :material_code=> "D002"},

							]
  	myarray.each do |record|
  		material = Material.find_by(:part_id=> record[:material_code])
  		material_category = MaterialCategory.find_by(:code=> record[:material_category_code])
  		if material_category.present?
	  		if material.present?
	  			puts "#{record[:material_code]} exist"
	  		else
	  			puts "#{record[:material_code]} not found"
	  			Material.create({
	  				:vendor_name=> record[:vendor_name],
	  				:unit_id=> 1, 
	  				:material_category_id=> material_category.id,
	  				:color_id=> nil, :name=> record[:name],
	  				:part_id=> record[:material_code], :part_model=> nil,
	  				:status=> 'active', :created_at=> DateTime.now(), :created_by=> 1
	  			})

	  		end
	  	end
  	end
  end

  task :inject_stock_material => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
  	myarray = [{:part_id=> "A071", :batch_number=> "A071-20D01", :quantity=> "25"},
				{:part_id=> "A075", :batch_number=> "A075-20E04", :quantity=> "45"},
				{:part_id=> "A079", :batch_number=> "A079-20E13", :quantity=> "5722"},
				{:part_id=> "A079", :batch_number=> "A079-20E17", :quantity=> "1998"},
				{:part_id=> "A079", :batch_number=> "A079-20E19", :quantity=> "1130"},
				{:part_id=> "A079", :batch_number=> "A079-20E16", :quantity=> "3330"},
				{:part_id=> "A079", :batch_number=> "A079-20E18", :quantity=> "2632"},
				{:part_id=> "A079", :batch_number=> "A079-20E12", :quantity=> "1276"},
				{:part_id=> "A079", :batch_number=> "A079-20E10", :quantity=> "655"},
				{:part_id=> "A079", :batch_number=> "A079-20E04", :quantity=> "418"},
				{:part_id=> "A072", :batch_number=> "A072-20D01", :quantity=> "266"},
				{:part_id=> "A071", :batch_number=> "A071-20F01", :quantity=> "365"},
				{:part_id=> "B013", :batch_number=> "B013-18J02", :quantity=> "521"},
				{:part_id=> "B013", :batch_number=> "B013-18J03", :quantity=> "674"},
				{:part_id=> "B068", :batch_number=> "B068-20E01", :quantity=> "54"},
				{:part_id=> "B082", :batch_number=> "B082-20E02", :quantity=> "1680"},
				{:part_id=> "B097", :batch_number=> "B097-20D01", :quantity=> "945"},
				{:part_id=> "B072", :batch_number=> "B072-20D02", :quantity=> "5278"},
				{:part_id=> "B071", :batch_number=> "B071-20D02", :quantity=> "4056"},
				{:part_id=> "B070", :batch_number=> "B070-20D02", :quantity=> "5500"},
				{:part_id=> "B002", :batch_number=> "B002-20E03", :quantity=> "99"},
				{:part_id=> "B137", :batch_number=> "B137-20E01", :quantity=> "475"},
				{:part_id=> "B139", :batch_number=> "B139-20E02", :quantity=> "1866"},
				{:part_id=> "A067", :batch_number=> "A067-20E02", :quantity=> "114"},
				{:part_id=> "A067", :batch_number=> "A067-20E01", :quantity=> "12"},
				{:part_id=> "A060", :batch_number=> "A060-20E01", :quantity=> "100"},
				{:part_id=> "ABAA", :batch_number=> "ABAA19001", :quantity=> "48"},
				{:part_id=> "NAAB", :batch_number=> "NAAB-19001-R", :quantity=> "24"},
				{:part_id=> "B002", :batch_number=> "B002-20E02", :quantity=> "530"},
				{:part_id=> "B002", :batch_number=> "B002-20E01", :quantity=> "481"},
				{:part_id=> "B068", :batch_number=> "B068-20E03", :quantity=> "190"},
				{:part_id=> "B068", :batch_number=> "B068-20E02", :quantity=> "440"},
				{:part_id=> "B001", :batch_number=> "B001-20E02", :quantity=> "40000"},
				{:part_id=> "B011", :batch_number=> "B011-19J01", :quantity=> "1038"},
				{:part_id=> "B011", :batch_number=> "B011-18L01", :quantity=> "178"},
				{:part_id=> "B012", :batch_number=> "B012-18J02", :quantity=> "223"},
				{:part_id=> "B001", :batch_number=> "B001-20E01", :quantity=> "19000"},
				{:part_id=> "B138", :batch_number=> "B138-20E02", :quantity=> "2746"},
				{:part_id=> "B116", :batch_number=> "B116-20D02", :quantity=> "1622"},
				{:part_id=> "B134", :batch_number=> "B134-20D01", :quantity=> "2000"},
				{:part_id=> "B111", :batch_number=> "B111-20D02", :quantity=> "54"},
				{:part_id=> "B136", :batch_number=> "B136-20D01", :quantity=> "744"},
				{:part_id=> "B087", :batch_number=> "B087-20D04", :quantity=> "138"},
				{:part_id=> "B016", :batch_number=> "B016-19H01", :quantity=> "23"},
				{:part_id=> "B026", :batch_number=> "B026-19G01", :quantity=> "5294"},
				{:part_id=> "B018", :batch_number=> "B018-19G01", :quantity=> "416"},
				{:part_id=> "B003", :batch_number=> "B003-20B01", :quantity=> "2431"},
				{:part_id=> "B020", :batch_number=> "B020-19G01", :quantity=> "276"},
				{:part_id=> "B096", :batch_number=> "B096-20D01", :quantity=> "950"},
				{:part_id=> "B102", :batch_number=> "B102-20D01", :quantity=> "2000"},
				{:part_id=> "B101", :batch_number=> "B101-20D01", :quantity=> "2000"},
				{:part_id=> "AABU", :batch_number=> "AABU20002", :quantity=> "46"},
				{:part_id=> "B041", :batch_number=> "B041-20D01", :quantity=> "1000"},
				{:part_id=> "B083", :batch_number=> "B083-20D02", :quantity=> "500"},
				{:part_id=> "B090", :batch_number=> "B090-20D01", :quantity=> "2500"},
				{:part_id=> "B089", :batch_number=> "B089-20D01", :quantity=> "1000"},
				{:part_id=> "B084", :batch_number=> "B084-20D02", :quantity=> "500"},
				{:part_id=> "AABS", :batch_number=> "AABS20001", :quantity=> "943"},
				{:part_id=> "B007", :batch_number=> "B007-20001", :quantity=> "2335"},
				{:part_id=> "A062", :batch_number=> "A062-20E03", :quantity=> "400"},
				{:part_id=> "A083", :batch_number=> "A083-20E03", :quantity=> "484"},
				{:part_id=> "A003", :batch_number=> "A003-19L01", :quantity=> "8"},
				{:part_id=> "A049", :batch_number=> "A049-20B01", :quantity=> "300"},
				{:part_id=> "A008", :batch_number=> "A008-19H01", :quantity=> "310"},
				{:part_id=> "A014", :batch_number=> "A014-19G01", :quantity=> "4"},
				{:part_id=> "A015", :batch_number=> "A015-19G01", :quantity=> "21"},
				{:part_id=> "A017", :batch_number=> "A017-18J01", :quantity=> "3"},
				{:part_id=> "A016", :batch_number=> "A016-18J01", :quantity=> "4"},
				{:part_id=> "A019", :batch_number=> "A019-18J01", :quantity=> "1"},
				{:part_id=> "A015", :batch_number=> "A015-18H01", :quantity=> "4"},
				{:part_id=> "A005", :batch_number=> "A005-20E02", :quantity=> "3300"},
				{:part_id=> "A043", :batch_number=> "A043-19H01", :quantity=> "5"},
				{:part_id=> "A004", :batch_number=> "A004-19H01", :quantity=> "168"},
				{:part_id=> "A005", :batch_number=> "A005-20D01", :quantity=> "140"},
				{:part_id=> "A009", :batch_number=> "A009-19H01", :quantity=> "160"},
				{:part_id=> "A009", :batch_number=> "A009-19H02", :quantity=> "1000"},
				{:part_id=> "A027", :batch_number=> "A027-19C01", :quantity=> "900"},
				{:part_id=> "B032", :batch_number=> "B032-19H02", :quantity=> "500"},
		]

		periode_yyyy = '2020'
		periode_mm = '06'
		periode_yyyymm = "202006"
		myarray.each do |record|
			material = Material.find_by(:part_id=> record[:part_id])
			if material.present?
				material_receiving_item = MaterialReceivingItem.find_by(:material_receiving_id=>1, :material_id=> material.id, :quantity=> record[:quantity])
				if material_receiving_item.blank?
					mri = MaterialReceivingItem.new({
						:material_receiving_id=>1, :purchase_order_supplier_item_id=> 1,
						:material_id=> material.id, 
						:quantity=> record[:quantity].to_i,
						:remarks=> " ",
						:status=> 'active',
						:created_at=> DateTime.now(), :created_by=> 1
						})
					mri.save(validate: false)
					puts mri.inspect
				end

          material_batch_number = MaterialBatchNumber.find_by(:material_receiving_item_id=> material_receiving_item.id, :material_id=> material.id, :periode_yyyy=> periode_yyyy, :periode_mm=> periode_mm, :number=>  record[:batch_number])
          if material_batch_number.blank?
            material_batch_number = MaterialBatchNumber.create(
              :material_receiving_item_id=> material_receiving_item.id, 
              :material_id=> material.id, 
              :number=>  record[:batch_number],
              :periode_yyyy=> periode_yyyy,
              :periode_mm=> periode_mm
              )
          end 

          # stock = Inventory.find_by(:material_id=> material.id, :periode=> periode_yyyymm)
          # if stock.present?
          # 	stock.update_columns({
          # 		:begin_stock=> stock.begin_stock.to_f+record[:quantity].to_f
          # 	})
          # else
          # 	stock = Inventory.create({
          # 		:material_id=> material.id, :periode=> periode_yyyymm,
          # 		:begin_stock=> record[:quantity].to_f,
          # 		:created_at=> DateTime.now()

          # 	})
          # end

          stock_bn = InventoryBatchNumber.find_by(:material_id=> material.id, :material_batch_number_id=>material_batch_number.id, :periode=> periode_yyyymm)
          if stock_bn.present?
          	stock_bn.update_columns({
          		:begin_stock=> stock_bn.begin_stock.to_f+record[:quantity].to_f
          	})
          else
          	wew = InventoryBatchNumber.create({
          		:product_id=> nil, :product_batch_number_id=> nil,
          		:material_id=> material.id, :material_batch_number_id=>material_batch_number.id, :periode=> periode_yyyymm,
          		:begin_stock=> record[:quantity].to_f,
          		:created_at=> DateTime.now()

          	})
          	wew.inspect
          end
			end
		end
  end
end