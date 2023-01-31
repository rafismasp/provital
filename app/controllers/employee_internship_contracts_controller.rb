class EmployeeInternshipContractsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee_internship_contract, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /employee_internship_contracts
  # GET /employee_internship_contracts.json
  def index
    @employee_internship_contracts = EmployeeInternshipContract.all
    case params[:partial]
    when 'change_internship'
      @employee_internship = EmployeeInternship.find_by(:id=> params[:employee_internship_id])
    when 'change_employee'
      @employee = Employee.find_by(:id=> params[:employee_id])
    end
  end

  # GET /employee_internship_contracts/1
  # GET /employee_internship_contracts/1.json
  def show
    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new(:page_size=> "A4",:top_margin => 40,:bottom_margin => 40, :left_margin=>70, :right_margin=>70) 
        pdf.font "Times-Roman"
        pdf.font_size 11
        record = @employee_internship_contract
        pdf.table([["Nomor Perjanjian : #{record.number}"]], :column_widths=>[450], :cell_style => {:size => 9, :padding=> [2,4,2,4], :border_width=> 0.5})
        pdf.move_down 20
        pdf.table([["PERJANJIAN PEMAGANGAN"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :size => 12, :padding=> [2,4,2,4], :border_width=> 0})
        pdf.table([["ANTARA"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :size => 12, :padding=> [2,4,2,4], :border_width=> 0})
        pdf.table([["PESERTA MAGANG DENGAN PENYELENGGARA"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :size => 12, :padding=> [2,4,2,4], :border_width=> 0})
        pdf.move_down 20
        pdf.table([["Pada hari ini #{record.begin_of_contract.strftime("%A")} tanggal #{record.begin_of_contract.strftime("%d")} Bulan #{record.begin_of_contract.strftime("%B")} tahun 2019 yang bertanda tangan dibawah ini :"]], :column_widths=>[450], :cell_style => {:padding=> [2,4,2,4], :border_width=> 0})
        pdf.move_down 15

        pdf.table([
          ["Nama", ":","#{record.employee.name}"],
          ["Jabatan", ":","#{record.employee.position.name}"],
          ["Perushaan", ":","-"],
          ["Alamat", ":","#{record.employee.domicile_address}"]
        ], :column_widths=>[100, 15, 335], :cell_style => {:font_style => :bold, :padding=> 1, :border_width=> 0})
        
        pdf.move_down 15
        pdf.table([[{:content=>""}, {:content=>"Selanjutnya disebut "}, {:content=> "PIHAK PERTAMA ( PENYELENGGARA )", :font_style=> :bold}]], :column_widths=>[40], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 15

        pdf.table([
          ["Nama", ":","#{record.employee_internship.name}"],
          ["Tempat tgl lahir", ":","#{record.employee_internship.born_place}, #{record.employee_internship.born_date}"],
          ["Pendidikan Terakhir", ":","#{record.employee_internship.last_education}"],
          ["Alamat", ":","#{record.employee_internship.address}"],
          ["Jenis Kelamin", ":","#{record.employee_internship.gender}"],
          ["No.Telp", ":","#{record.employee_internship.phone_number}"]
        ], :column_widths=>[100, 15, 335], :cell_style => {:font_style => :bold, :padding=> 1, :border_width=> 0})
        
        pdf.table([[{:content=>"Selanjutnya disebut "}, {:content=> "PIHAK KEDUA ( PESERTA MAGANG )", :font_style=> :bold}]], :cell_style => {:padding=> 0, :border_width=> 0})
        
        pdf.move_down 15
        pdf.table([[
          {:content=>""}, 
          {:content=>"Dengan ini "}, 
          {:content=> "PIHAK PERTAMA", :font_style=> :bold}, 
          {:content=>" dan "}, 
          {:content=> "PIHAK KEDUA", :font_style=> :bold}, 
          {:content=>" sepakat untuk memenuhi ketentuan -"}
        ]], :column_widths=>[40], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.table([[
          {:content=>"ketentuan dalam perjanjian sebagaimana tercantum dalam pasal - pasal dibawah :"}
        ]], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 20
        pdf.table([["Pasal 1"], ["Kesepakatan"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
        pdf.move_down 10
        pdf.table([[
          {:content=>"PIHAK PERTAMA bersedia menerima PIHAK KEDUA sebagai peserta program pemagangan dan
          PIHAK KEDUA menyatakan kesediaannya untuk mengikuti program pemagangan
          yang dilaksanakan oleh PIHAK PERTAMA di perusahaan PT.
          "}
        ]], :cell_style => {:padding=> 2, :border_width=> 0})

         pdf.move_down 20
        pdf.table([["Pasal 2"], ["Jangka Waktu Pemagangan"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
        pdf.move_down 5
        pdf.table([[
          {:content=>"1. "}, 
          {:content=>"Jangka waktu pelaksanaan pemagangan adalah selama 3 Bulan ( Tiga Bulan ) terhitung dari"}
        ]], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 5
        pdf.table([[
          {:content=>""}, 
          {:content=>"Tanggal :"},
          {:content=>"#{record.begin_of_contract.strftime("%d")}", :font_style=> :bold},
          {:content=>"Bulan :"},
          {:content=>"#{record.begin_of_contract.strftime("%B")}", :font_style=> :bold},
          {:content=>"Tahun :"},
          {:content=>"#{record.begin_of_contract.strftime("%Y")}", :font_style=> :bold},
          {:content=>"sampai dengan"}
        ]], :column_widths=>[20, 50, 50, 35, 65, 35, 65], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 5
        pdf.table([[
          {:content=>""}, 
          {:content=>"Tanggal :"},
          {:content=>"#{record.end_of_contract.strftime("%d")}", :font_style=> :bold},
          {:content=>"Bulan :"},
          {:content=>"#{record.end_of_contract.strftime("%B")}", :font_style=> :bold},
          {:content=>"Tahun :"},
          {:content=>"#{record.end_of_contract.strftime("%Y")}", :font_style=> :bold}
        ]], :column_widths=>[20, 50, 50, 35, 65, 35, 65], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 15
        pdf.table([
          [
            {:content=>"2. "}, 
            {:content=>"Pemagangan dilaksanakan pada jam kerja untuk setiap hari kerja, Total keseluruhan Jam Praktek"}
          ],
          [
            {:content=>""}, 
            {:content=>"dan Teori 40Jam dalam Satu Minggu. Dan untuk Pengaturan jam akan di sesuaikan dan mengacu"}
          ],
          [
            {:content=>""}, 
            {:content=>"Perundangan dan Aturan yang berlaku dan di tentukan oleh PIHAK PERTAMA"}
          ]
        ], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
         pdf.move_down 20
        pdf.table([["Pasal 3"], ["Jenis Kejuruan dan Program"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
         pdf.move_down 15
        pdf.table([
          [
            {:content=>"1. "}, 
            {:content=>"Pemagangan yang dilaksanakan Oleh PIHAK PERTAMA Adalah Program Pemagangan Industri"}
          ],
          [
            {:content=>""}, 
            {:content=>"Plastik yang mengacu pada Kurikulum atau Silabus"}
          ],
          [
            {:content=>"2. "}, 
            {:content=>"Program Pemagangan Untuk Mencapai Kualifikasi Mesin Proses,Quality Inspeksi, dan atau"}
          ],
          [
            {:content=>" "}, 
            {:content=>"penunjang lainya sesuai Kurikulum dan Silabus yang telah tersusun."}
          ]
        ], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
         pdf.move_down 40
        pdf.table([["Pasal 4"], ["Hak dan Kewajiban Pihak Pertama"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
        pdf.move_down 15
        pdf.table([[
          {:content=>"1. "}, 
          {:content=>"PIHAK PERTAMA mempunyai hak - hak sebagaiberikut :"}
        ]], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
          pdf.move_down 5
          pdf.table([
            [
              {:content=>""}, 
              {:content=>"1.1 "}, 
              {:content=>" Memberhentikan PIHAK KEDUA yang melanggar ketentuan yang dalam Perjanjian tanpa"}
            ], ["","","Konpensasi apapun juga, dalam hal antara lain :"]
          ], :column_widths=>[15, 20], :cell_style => {:padding=> 0, :border_width=> 0})
            pdf.move_down 5
            pdf.table([
              [
                {:content=>""}, 
                {:content=>"a. "}, 
                {:content=>" Melakukan kelalaian walaupun telah mendapat peringatan serta melakukan tindakan yang"}
              ], ["","","tidak bertanggung jawab."],
              [
                {:content=>""}, 
                {:content=>"b. "}, 
                {:content=>" Dengan segaja merusak, merugikan atau membiarkan dalam keadaan bahaya barang milik "}
              ], ["","","PIHAK PERTAMA"],
              [
                {:content=>""}, 
                {:content=>"c. "}, 
                {:content=>" Melakukan tindak kejahatan misalnya berkelahi, mencuri, menggelapkan, menipu dan"}
              ], ["","","membawa serta memperdagangkan barang – barang terlarang baik didalam maupun diluar"], ["","","perusahaan."],
              [
                {:content=>""}, 
                {:content=>"d. "}, 
                {:content=>"Absen atau mangkir tanpa alasan yang sah sesuai dengan peraturan yang berlaku di ", :font_style => :bold}
              ], ["","", {:content=>"perusahaan", :font_style => :bold}],
              [
                {:content=>""}, 
                {:content=>"e. "}, 
                {:content=>"Dapat memberhentikan peserta magang, bila Terjadi sesuatu hal yang dampaknya", :font_style => :bold}
              ], 
              ["","", {:content=>"terjadi Penurunan Order / Pekerjaan, tanpa Memberikan Kompensasi apapun ", :font_style => :bold}],
              ["","", {:content=>"terhadap PIHAK KEDUA", :font_style => :bold}]

            ], :column_widths=>[25, 20], :cell_style => {:padding=> 0, :border_width=> 0})

          pdf.move_down 5
          pdf.table([
            [
              {:content=>""}, 
              {:content=>"1.2 "}, 
              {:content=>" Memiliki hasil kerja PIHAK KEDUA selama pelaksanaan pemagangan di Perusahaan"}
            ]
          ], :column_widths=>[15, 20], :cell_style => {:padding=> 0, :border_width=> 0})
          pdf.move_down 5
          pdf.table([
            [
              {:content=>""}, 
              {:content=>"1.3 "}, 
              {:content=>" Merekrut aatau membantu PIHAK KEDUA , Bila setelah selesai program Pemagangan belum"}
            ], [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" mendapatkan pekerjaan, Dalam hal ini bila mana PIHAK PERTAMA memang membutuhkan."}
            ]
          ], :column_widths=>[15, 20], :cell_style => {:padding=> 0, :border_width=> 0})
          pdf.move_down 10
        pdf.table([[
          {:content=>"2. "}, 
          {:content=>"PIHAK PERTAMA mempunyai kewajiban - kewajiban sebagai berikut :"}
        ]], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
          pdf.move_down 5
          pdf.table([
            [
              {:content=>""}, 
              {:content=>"a. "}, 
              {:content=>" Memberikan hak - hak PIHAK KEDUA sesuai dengan pasal 5 ayat (1). "}
            ],
            [
              {:content=>""}, 
              {:content=>"b. "}, 
              {:content=>" Melaksanakan pelaksanaan pemagangan hingga selesai. "}
            ],
            [
              {:content=>""}, 
              {:content=>"c. "}, 
              {:content=>" Memberikan pembinaan dan pengarahan kepada PIHAK KEDUA. "}
            ],
            [
              {:content=>""}, 
              {:content=>"d. "}, 
              {:content=>" Melakukan evaluasi secara berkala tentang perkembangan PIHAK KEDUA dalam hal "}
            ],
            [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" pelaksanaan pemagangan. "}
            ],
            [
              {:content=>""}, 
              {:content=>"e. "}, 
              {:content=>" Bersama - sama LPK / BLK dan Perusahaan membuat laporan secara berkala tentang "}
            ],
            [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" pelaksanaan program pemagangan."}
            ]

          ], :column_widths=>[15, 20], :cell_style => {:padding=> 0, :border_width=> 0})

        # pdf.formatted_text [ { :text => 'Absen atau mangkir tanpa alasan yang sah sesuai dengan peraturan yang berlaku di', :size => 10,:styles => [:underline]}]
                
        pdf.move_down 20
        pdf.table([["Pasal 5"], ["Hak dan Kewajiban PIHAK KEDUA"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
        
          pdf.move_down 10
        pdf.table([[
          {:content=>"(1)."}, 
          {:content=>" Selama masa pemagangan PIHAK KEDUA mempunyai hak – hak sebagai berikut "}
        ]], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
          pdf.move_down 5
          pdf.table([
            [
              {:content=>""}, 
              {:content=>"a. "}, 
              {:content=>" Selama masa pemagangan PIHAK KEDUA menerima uang saku harian sebesar Rp. ,- atau"}
            ],
            [
              {:content=>""}, 
              {:content=>""}, 
              {:content=>" dikompersi perbulan Rp ( 25 Hari Kerja) dari PIHAK PERTAMA. Berdasarkan Harian"}
            ],
            [
              {:content=>""}, 
              {:content=>""}, 
              {:content=>" Kehadiran"}
            ],
            [
              {:content=>""}, 
              {:content=>"b. "}, 
              {:content=>" Fasilitas Transport Antar Jemput"}
            ],
            [
              {:content=>""}, 
              {:content=>"c. "}, 
              {:content=>" Fasilitas Makan Catering (Natura)"}
            ],
            [
              {:content=>""}, 
              {:content=>"d. "}, 
              {:content=>" Mendapatkan Uang saku tambahan Bila ada Penambahan Jam Praktek Pemagangan ("}
            ],
            [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" sesuai ketentuan PIHAK PERTAMA )"}
            ],
            [
              {:content=>""}, 
              {:content=>"e. "}, 
              {:content=>" Memperoleh serifikat pemagangan bila Lulus"}
            ],
            [
              {:content=>""}, 
              {:content=>"f. "}, 
              {:content=>" Mendapatkan alat Pelindung diri (APD) untuk K3 "}
            ],
            [
              {:content=>""}, 
              {:content=>"g. "}, 
              {:content=>" Seragam yang sudah di tentukan Oleh Pihak Pertama"}
            ],
            [
              {:content=>""}, 
              {:content=>"h. "}, 
              {:content=>" Mendapatkan Perlindungan atau jaminan kecelakaan dan Kematian dan mengikuti"}
            ],
            [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" perundangan atau ketentuan berlaku"}
            ],
            [
              {:content=>""}, 
              {:content=>"i. "}, 
              {:content=>" Mendapatkan Fasilitas Kesehatan"}
            ]

          ], :column_widths=>[15, 20], :cell_style => {:padding=> 0, :border_width=> 0})
          pdf.move_down 10

        pdf.table([[
          {:content=>"(2)."}, 
          {:content=>" Selama masa pemagangan PIHAK KEDUA mempunyai kewajiban – kewajiban sebagai berikut : "}
        ]], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})

        pdf.move_down 5
          pdf.table([
            [
              {:content=>""}, 
              {:content=>"a. "}, 
              {:content=>" Wajib mengikuti pemagangan hingga selesai."}
            ],
            [
              {:content=>""}, 
              {:content=>"b. "}, 
              {:content=>" Wajib mematuhi segala peraturan yang berlaku di perusahaan."}
            ],
            [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" (Hadir Tepat Waktu, Absen,Menggunakan Seragam, APD, dan ID Card,.)"}
            ],
            [
              {:content=>""}, 
              {:content=>"c. "}, 
              {:content=>" Wajib mentaati segala instruksi/Arahan dari instruktur/supervisor/Pemimbing"}
            ],
            [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" perusahaan, berdasarkan Aturan yang Berlaku"}
            ],
            [
              {:content=>""}, 
              {:content=>"d. "}, 
              {:content=>" Wajib tidak menuntut untuk dijadikan karyawan di perusahaan setelah selesai"}
            ],
            [
              {:content=>""}, 
              {:content=>" "}, 
              {:content=>" pemagangan sesuai dengan Perjanjian."}
            ],
            [
              {:content=>""}, 
              {:content=>"e. "}, 
              {:content=>" Tidak Menuntut mendapatkan Tunjangan Hari Raya (THR) atau Insentif lainya (Bonus)"}
            ]

          ], :column_widths=>[15, 20], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 20
        pdf.table([["Pasal 6"], ["Sanksi"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
        
        pdf.move_down 10
        pdf.table([
          [
            {:content=>"(1)."}, 
            {:content=>" Bagi PIHAK PERTAMA ."}
          ],
          [
            {:content=>""}, 
            {:content=>"Bila PIHAK PERTAMA tidak dapat melanjutkan kegiatan program pemagangan dikarena"}
          ],
          [
            {:content=>""}, 
            {:content=>"Kan keadaan/situasi perusahaan, maka PIHAK PERTAMA Berupaya Membantu menca-"}
          ],
          [
            {:content=>""}, 
            {:content=>"rikan tempat magang yang sesuai kepada PIHAK KEDUA, dan tidak Memperselisihkan/"}
          ],
          [
            {:content=>""}, 
            {:content=>"Menuntut hak Sisa Magang Pihak Kedua"}
          ]
        ], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 10
        pdf.table([
          [
            {:content=>"(2)."}, 
            {:content=>"Bila PIHAK KEDUA menggundurkan diri tanpa alasan yang jelas dan sah maka PIHAK "}
          ],
          [
            {:content=>""}, 
            {:content=>"KEDUA wajib mengembalikan biaya&Atribut Lainya, yang telah di keluarkan oleh PIHAK "}
          ],
          [
            {:content=>""}, 
            {:content=>"PERTAMA."}
          ]
        ], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})
        pdf.move_down 20
        pdf.table([["Pasal 7"], ["Perselisihan"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
         pdf.move_down 10
         pdf.table([[
          {:content=>"Jika terjadi perselisihan antara kedua belah pihak maka akan diselesaiakan secara musyawarah
            Untuk mufakat, dan jika tidak tercapai penyelesaiannya maka kedua belah pihak dapat meminta
            bantuan dari instasi terkait setempat, untuk menyelesaikannya sesuai hukum yang berlaku.

          "}
        ]], :cell_style => {:padding=> 2, :border_width=> 0})
        pdf.move_down 20
        pdf.table([["Pasal 8"], ["Lain-lain"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
        pdf.move_down 10
        pdf.table([
          [
            {:content=>"(1)."}, 
            {:content=>" Jika isi ketentuan dalam perjanjian ini ada yang bertentangan dengan hukum atau peraturan"}
          ],
          [
            {:content=>""}, 
            {:content=>"Yang berlaku maka akan diperbaiki sesuai dengan peraturan / hukum yang berlaku tersebut."}
          ],
          [
            {:content=>"(2)."}, 
            {:content=>" Hal - hal lain yang belum diatur dalam Perjanjian ini akan diatur sesuai dengan kesepakatan kedua"}
          ],
          [
            {:content=>""}, 
            {:content=>"belah pihak."}
          ]
        ], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})

        pdf.move_down 20
        pdf.table([["Pasal 9"], ["Penutup"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
        pdf.move_down 10
        pdf.table([
          [
            {:content=>"(1)."}, 
            {:content=>" Perjanjian ini dibuat dan ditanda tangani oleh kedua belah pihak dalam keadaan sadar"}
          ],
          [
            {:content=>""}, 
            {:content=>"Tanpa paksaan dari siapapun juga, serta berlaku Mengacu di Pasal 2 (Dua)"}
          ],
          [
            {:content=>"(2)."}, 
            {:content=>"Perjanjian pemagangangan ini di tandatangani diatas materai, dengan memiliki kekuatan hukum "}
          ],
          [
            {:content=>""}, 
            {:content=>"yang sama. yang dapat digunakan sebagai pemagangan bagi masing - masih pihak dalam"}
          ],
          [
            {:content=>""}, 
            {:content=>"melaksanakan perjanjian pemagangan dimaksud."}
          ]
        ], :column_widths=>[20], :cell_style => {:padding=> 0, :border_width=> 0})

        pdf.move_down 20
        pdf.table([["Bekasi, #{record.begin_of_contract.strftime("%d %B %Y")}"]], :column_widths=>[450], :cell_style => {:align=> :center, :padding=> 0, :border_width=> 0})
        
        pdf.move_down 20

        # pdf.table([
        #   ["Peserta Magang","","Direktur"]
        # ], :column_widths=>[100,250,100], :cell_style => {:font_style => :bold, :align=> :center, :padding=> 0, :border_width=> 0})
       
         pdf.bounding_box([0,750], :width => 450, :height => 750) do

            pdf.text_box "Mengetahui", 
                  :size => 12, :at=> [190,180], :width => 450, :height => 750 

            pdf.text_box "PIHAK KEDUA", 
                  :size => 12, :at=> [15,220], :width => 450, :height => 750 

            pdf.text_box "_________________", 
                  :size => 12, :at=> [0,145], :width => 450, :height => 750 
            pdf.text_box "Peserta Magang", 
                  :size => 12, :at=> [15,130], :width => 450, :height => 750 


            pdf.text_box "PIHAK PERTAMA", 
                  :size => 12, :at=> [350,220], :width => 450, :height => 750 
            pdf.text_box "_________________", 
                  :size => 12, :at=> [350,145], :width => 450, :height => 750 
            pdf.text_box "Direktur", 
                  :size => 12, :at=> [380,130], :width => 450, :height => 750 

            pdf.text_box "Dinas Tenaga Kerja Kabupaten Bekasi", 
                  :size => 12, :at=> [130,80], :width => 450, :height => 750 
          end
        pdf.start_new_page
        pdf.table([["SURAT PERNYATAAN"]], :column_widths=>[450], :cell_style => {:font_style => :bold, :align=> :center, :size => 12, :padding=> [2,4,2,4], :border_width=> 0})
        
        pdf.move_down 10
        pdf.table([["yang bertanda tangan dibawah ini"]], :column_widths=>[450], :cell_style => {:align=> :center, :padding=> [2,4,2,4], :border_width=> 0})
        pdf.table([["pada hari ini #{record.begin_of_contract.strftime("%A")}    Tgl #{record.begin_of_contract.strftime("%d")}   Bulan #{record.begin_of_contract.strftime("%B")}   Tahun #{record.begin_of_contract.strftime("%Y")}"   ]], :column_widths=>[450], :cell_style => {:align=> :center, :padding=> [2,4,2,4], :border_width=> 0})
        
        pdf.move_down 5

        pdf.table([
          ["Nama", ":","#{record.employee_internship.name}"],
          ["Tempat tgl lahir", ":","#{record.employee_internship.born_place}, #{record.employee_internship.born_date}"],
          
          ["NIK", ":","#{record.employee_internship.nik}"]
        ], :column_widths=>[100, 15, 335], :cell_style => {:padding=> 1, :border_width=> 0})
        pdf.move_down 5
        pdf.table([
          ["Dengan Kondisi Sadar dan Tidak ada paksaan, Tekanan dan Hasutan dari pihak Manapun, Saya"],
          ["sendiri membuat Pernyataan Yang ditandatangani di atas Materai, menyatakan sbb:"]
        ], :cell_style => {:padding=> [2,4,2,4], :border_width=> 0})
        pdf.move_down 5
        pdf.table([
          ["Checklist","No","Pernyataan","Parap"],
          ["","1","Telah membaca, memahami dan menerima perjanjian pemagangan yang saya tandatangani sendiri",""],
          ["","2","Memahami dan mengikuti segala peraturan dan program Pemagangan",""],
          ["","3","Mendapatkan dan mengerti pengisian buku kegiatan pemagangan (Logbook)",""],
          ["","4","Sebagai Siswa/Peserta Magang ( Bukan Karyawan ) dan tidak akan Menjadi Anggota/Pengururus dan terlibat Organisasi Pekerja yang ada di tempat Perusahaan ataupun di Luar Lingkungan Perusahaan",""],
          ["","5","Mengikuti Training (Pengenalan) Dasar-dasar Kerja (Kesehatan dan Keselamatan Kerja, 5R/5S, Disiplin Etos Kerja dan Pengenalan perusahaan yang ditempati) oleh Pihak LPK/Instruktur",""],
          ["","6","Menjunjung Tinggi dan Mengutamakan Keselamatan, Baik didalam kerja maupun berangkat dan pulang ketempat Perusahaan",""],
          ["","7","Menggunakan APD (Alat Pelindung Diri) Atribut/Seragam Kerja yang dibakukan dan diberlakukan di Perusahaan",""],
          ["","8","Mengikuti Jam Kerja yang telah ditentukan Perusahaan ( Bersedia di Shift ) dan bersedia Bila ada penambahan Jam Prektek Pemagangan",""],
          ["","9","Mengikuti Program Pemagangan ini Atas Kehendak Sendiri ( Tidak Melalui Calo) Dan Tidak dipungut Biaya",""],
          ["","10","Akan Memberitahukan dan Meminta izin jika ada hal Dimungkinkan tidak bisa masuk,Dan apa bila 2 (Dua) Hari bertutut-turut tidak masuk dan tidak memberitahukan/ informasi, Maka dianggap mundur dari Program Pemagangan",""],
          ["","11","Dalam Mengukuti Proses seleksi(Perekrutan) dan Program Pemagangan tidak dipungut biaya apapun ( Kecuali Penggantian Seragam/Atribut jika diperlukan",""]

        ], :column_widths=>[60, 40, 300, 50], :cell_style => {:padding=> 3, :border_width=> 0.5})
            
        pdf.move_down 2
        pdf.table([
          ["Demikian SURAT PERNYATAAN ini saya buat dengan sesadar sadarnya,"],
          ["Di buat"],
          [" "],
          ["Materai 6000"],
          [" "],
          ["Nama jelas dan tanda tangan di atas Materai 6000"]
        ], :cell_style => {:padding=> [2,4,2,4], :border_width=> 0})
        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
      end
    end
  end

  # GET /employee_internship_contracts/new
  def new
    @employee_internship_contract = EmployeeInternshipContract.new
    @employees = Employee.where(:status=> 'active', :department_id=> 3)
    @employee_internships = EmployeeInternship.where(:status=> 'active')
  end

  # GET /employee_internship_contracts/1/edit
  def edit
    @employee_internships = EmployeeInternship.where(:status=> 'active')
    @employees = Employee.where(:status=> 'active', :department_id=> 3)
  end

  # POST /employee_internship_contracts
  # POST /employee_internship_contracts.json
  def create
    @employee_internship_contract = EmployeeInternshipContract.new(employee_internship_contract_params)

    respond_to do |format|
      if @employee_internship_contract.save
        format.html { redirect_to @employee_internship_contract, notice: 'Employee internship contract was successfully created.' }
        format.json { render :show, status: :created, location: @employee_internship_contract }
      else
        format.html { render :new }
        format.json { render json: @employee_internship_contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_internship_contracts/1
  # PATCH/PUT /employee_internship_contracts/1.json
  def update
    respond_to do |format|
      if @employee_internship_contract.update(employee_internship_contract_params)
        format.html { redirect_to @employee_internship_contract, notice: 'Employee internship contract was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee_internship_contract }
      else
        format.html { render :edit }
        format.json { render json: @employee_internship_contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_internship_contracts/1
  # DELETE /employee_internship_contracts/1.json
  def destroy
    @employee_internship_contract.destroy
    respond_to do |format|
      format.html { redirect_to employee_internship_contracts_url, notice: 'Employee internship contract was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_internship_contract
      @employee_internship_contract = EmployeeInternshipContract.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_internship_contract_params
      params.require(:employee_internship_contract).permit(:number, :employee_internship_id, :employee_id, :begin_of_contract, :end_of_contract)
    end
end
