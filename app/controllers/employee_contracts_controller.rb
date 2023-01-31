class EmployeeContractsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_employee_contract, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /employee_contracts
  # GET /employee_contracts.json
  def index
    @employee_contracts = EmployeeContract.all
    case params[:partial]
    when 'change_internship'
      @employee_internship = EmployeeInternship.find_by(:id=> params[:employee_internship_id])
    when 'change_employee'
      @employee  = @employees.find_by(:id=> params[:employee_id])
    end
  end

  # GET /employee_contracts/1
  # GET /employee_contracts/1.json
  def show
    respond_to do |format|
      format.html
      format.pdf do

        pdf = Prawn::Document.new(:page_size=> "LETTER",:left_margin=>60, :right_margin=>50)
        pdf.font "Times-Roman"
        pdf.font_size 10.9

        image_path      = "app/assets/images/logo.png"  
        company         = "PT. TRI-SAUDARA SENTOSA INDUSTRI"
        company_address = "Jl.Pinang Blok F.17 No. 3, Kawasan Delta Silicon 3, Lippo Cikarang, Cikarang Bekasi"
        city            = "Cikarang, " 
        title           = "PT. TRI-SAUDARA SENTOSA INDUSTRI 
            Jl.Pinang Blok F 17 No.3 Delta Silicon 3
            Lippo Cikarang, Bekasi"                 
        
        record = @employee_contract
        employee_born_date = (record.employee.born_date.present? ? record.employee.born_date.to_date.strftime("%d %B %Y") : "-")
        employee_position_name = (record.position_id.present? ? record.position.name : '-')
        employee_department_name = (record.department_id.present? ? record.department.name : '-')

        hrd_employee_name = record.hrd_name
        day = record.begin_of_contract.strftime("%A") 
        if day == "Sunday" 
          hari = "Minggu"
        elsif day == "Monday"
          hari = "Senin"
        elsif day == "Tuesday"
          hari = "Selasa"
        elsif day == "Wednesday"
          hari = "Rabu"
        elsif day == "Thursday"
          hari = "Kamis"
        elsif day == "Friday"
          hari = "Jumat"
        elsif day == "Saturday"
          hari = "Sabtu"
        end
        plus = 70
        pdf.move_down 30
        pdf.formatted_text [ { :text => "PERJANJIAN KERJA WAKTU TERTENTU", :size => 14,:styles => [:bold, :underline]}] , :align => :center
        pdf.formatted_text [ { :text => record.number, :size => 14}], :align=>:center
        
        pdf.move_down 10

        pdf.table([
          [
            :content=> "Pada hari ini #{hari}, #{month_indo(record.begin_of_contract)}, bertempat dikantor PT. Provital Perdana, kami yang bertandatangan dibawah ini :"
          ]
        ], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        
        pdf.move_down 10
        
        pdf.table([
          [
            {:content=> "1.", :align=> :right}, {:content=> "Nama"}, {:content=> ":"}, {:content=> "#{hrd_employee_name}"}
          ], [
            {:content=> "", :align=> :right}, {:content=> "Jabatan"}, {:content=> ":"}, {:content=> "HRD PT. Provital Perdana, Cikarang"}
          ], [
            {:content=> "Selanjutnya disebut PIHAK PERTAMA", :colspan=> 4}
          ],[
            {:content=> "", :height=> 10}
          ],[
            {:content=> "2.", :align=> :right}, {:content=> "Nama"}, {:content=> ":"}, {:content=> "#{record.employee.name}"}
          ], [
            {:content=> "", :align=> :right}, {:content=> "Alamat"}, {:content=> ":"}, {:content=> "#{record.employee.origin_address}"}
          ], [
            {:content=> "", :align=> :right}, {:content=> "Jenis Kelamin"}, {:content=> ":"}, {:content=> "#{record.employee.gender}"}
          ], [
            {:content=> "", :align=> :right}, {:content=> "Tempat & Tgl lahir"}, {:content=> ":"}, {:content=> "#{record.employee.born_place}, #{employee_born_date}"}
          ], [
            {:content=> "", :align=> :right}, {:content=> "Agama"}, {:content=> ":"}, {:content=> "#{record.employee.religion.humanize}"}
          ], [
            {:content=> "", :align=> :right}, {:content=> "No. Telepon"}, {:content=> ":"}, {:content=> "#{record.employee.phone_number}"}
          ], [
            {:content=> "", :align=> :right}, {:content=> "No. KTP"}, {:content=> ":"}, {:content=> "#{record.employee.ktp}"}
          ], [
            {:content=> "Selanjutnya disebut PIHAK KEDUA", :colspan=> 4}
          ]
        ], :column_widths => [30, 100, 20, 300], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        
        pdf.move_down 10

        pdf.table([
          [
            :content=> "Setelah KEDUA BELAH PIHAK menjelaskan diri masing - masing, maka keduanya sepakat membuat Perjanjian Kerja Waktu Tertentu (PKWT), yang diatur dengan pasal - pasal sebagai berikut :"
          ]
        ], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})

        pdf.move_down 15
        pdf.formatted_text [ { :text => "Pasal 1", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Pengertian Kerja Waktu Tertentu", :size => 12, :styles => [:bold]}], :align=>:center

        pdf.move_down 5
        pdf.text "PIHAK PERTAMA memberikan kesempatan kerja kepada PIHAK KEDUA untuk menjadi Karyawan (waktu tertentu) di perusahaan PIHAK PERTAMA, kemudian PIHAK KEDUA bersedia menerima kesempatan tersebut untuk menjadi Karyawan (waktu tertentu) diperusahaan PIHAK PERTAMA.", :size => 11, :align => :justify

        pdf.move_down 15
        pdf.formatted_text [ { :text => "Pasal 2", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Jangka Waktu", :size => 12, :styles => [:bold]}], :align=>:center

        pdf.move_down 5
        length_of_contract = (record.end_of_contract.year * 12 + record.end_of_contract.month) - (record.begin_of_contract.year * 12 + record.begin_of_contract.month)
        pdf.text "KEDUA BELAH PIHAK mengadakan kesepakatan bahwa jangka waktu Perjanjian Kerja Waktu Tertentu (PKWT) ini adalah selama #{length_of_contract} bulan, yang terhitung mulai tanggal : #{month_indo(record.begin_of_contract)} sampai dengan tanggal : #{month_indo(record.end_of_contract)}", :size => 11, :align => :justify

        pdf.move_down 15
        pdf.formatted_text [ { :text => "Pasal 3", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Penempatan", :size => 12, :styles => [:bold]}], :align=>:center

        pdf.move_down 5
        pdf.text "PIHAK KEDUA ditempatkan di PT. Provital Perdana Jl. Kranji Blok F15-1C Delta Silicon II, Lippo Cikarang Jawa Barat. Jabatan PIHAK KEDUA adalah sebagai #{employee_position_name} di departemen #{employee_department_name}.", :size => 11, :align => :justify

        pdf.start_new_page
        pdf.move_down 30
        pdf.formatted_text [ { :text => "Pasal 4", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Hari dan Jam Kerja", :size => 12, :styles => [:bold]}], :align=>:center

        pdf.move_down 10

        case params[:work_time]
        when 'non_shift'
          pdf.table([
            [
              {:content=> "a.", :align=> :right}, {:content=> "Hari Kerja"}, {:content=> ":"}, {:content=> "5 hari seminggu (Senin – Jumat)"}
            ], [
              {:content=> "b.", :align=> :right}, {:content=> "Jam Kerja"}, {:content=> ":"}, {:content=> "08:00 – 17:00 WIB dengan istirahat 1 (satu) jam"}
            ]

          ], :column_widths => [30, 100, 20, 300], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})

          pdf.table([
            [
              {:content=> "", :align=> :right}, {:content=> "Atau pembagian lain menurut ketentuan yang ada dan Hari libur karyawan tidak harus jatuh pada hari Minggu.",:colspan=>3}
            ]

          ], :column_widths => [30, 100, 20, 300], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        when 'shift'
          pdf.table([
            [
              {:content=> "a.", :align=> :right}, {:content=> "Waktu kerja adalah 6 (enam) hari dalam satu minggu, jam kerja diatur oleh PIHAK PERTAMA melalui Kepala bagian atau Kepala Seksi dari PIHAK PERTAMA dengan ketentuan sebagai berikut :",:colspan=>3}
            ]

          ], :column_widths => [30, 100, 20, 300], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
          pdf.table([["",{:content=>"Shift I",:align=>:left},{:content=>":"},{:content=> "08.00 - 16.00 WIB"} ],
                    ["",{:content=>"Shift II",:align=>:left},{:content=>":"},{:content=> "16.00 - 00.00 WIB"} ],
                    ["",{:content=>"Shift III",:align=>:left},{:content=>":"},{:content=> "00.00 - 08.00 WIB"} ]], :column_widths => [170,90, 10,210], :cell_style => {:padding => [0, 0, 3, 0], :border_color => "ffffff", :inline_format => true,:align=>:justify} )
          pdf.table([
              [
                {:content=> "", :align=> :right}, {:content=> "Atau pembagian lain menurut ketentuan yang ada dan Hari libur karyawan tidak harus jatuh pada hari Minggu.",:colspan=>3}
              ]
            ], :column_widths => [30, 100, 20, 300], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
          pdf.table([
              [
                {:content=> "b.", :align=> :right}, {:content=> "Apabila terdapat Hari Libur Resmi pada hari Senin sampai Sabtu tersebut diatas maka jadwal shift akan ditentukan oleh Kepala Bagian dari PIHAK PERTAMA.",:colspan=>3, :inline_format => true,:align=>:justify}
              ],[
                {:content=> "c.", :align=> :right}, {:content=> "Jumlah jam kerja normal adalah 40 jam dalam satu minggu, selebihnya dihitung lembur. Apabila dalam satu minggu ada hari libur nasional jika masuk kerja maka akan dibayar dengan upah lembur.",:colspan=>3, :inline_format => true,:align=>:justify}
              ]

          ], :column_widths => [30, 100, 20, 300], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        end

        pdf.move_down 15
        pdf.formatted_text [ { :text => "Pasal 5", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Upah", :size => 12, :styles => [:bold]}], :align=>:center

        pdf.move_down 10
        case params[:salary]
        when 'include'
            pdf.table([
              [
                {:content=> "a.", :align=> :right}, {:content=> "Upah"}, {:content=> ""}, {:content=> ""}
              ], [
                {:content=> "", :align=> :right}, {:content=> "PIHAK KEDUA akan mendapatkan Gaji"}, {:content=> ":"}, {:content=> ""}
              ], [
                {:content=> "", :align=> :right}, {:content=> "Yang terdiri dari :"}, {:content=> ""}, {:content=> ""}
              ], [
                {:content=> "", :align=> :right}, {:content=> "1. Gaji Pokok"}, {:content=> ":"}, {:content=> "#{number_with_precision(record.basic_salary.to_f, precision: 0, delimiter: ".", separator: ",")} / Bulan"}
              ], [
                {:content=> "", :align=> :right}, {:content=> "2. Makan / Transport"}, {:content=> ":"}, {:content=> "#{number_with_precision(record.meal_and_transport_cost.to_f, precision: 0, delimiter: ".", separator: ",")} / hari"}
              ],[
                {:content=> "", :height=> 15}
              ], [
                {:content=> "", :align=> :right}, {:content=> "Upah akan dibayarkan 1 kali dalam sebulan pada setiap hari kerja terakhir dibulan tersebut dengan cara ditransfer ke rekening PIHAK KEDUA pada bank yang ditunjuk oleh PIHAK PERTAMA", :colspan=>3}
              ],[
                {:content=> "", :height=> 15}
              ]
            ], :column_widths => [30, 200, 20, 250], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        when 'exclude'
            pdf.table([
              [
                {:content=> "a.", :align=> :right}, {:content=> "Sehubungan dengan tugas pekerjaan yang dibebankan kepada PIHAK KEDUA dalam perjanjian kerja ini, PIHAK PERTAMA memberikan upah kepada PIHAK KEDUA sebagai berikut. Akan disertakan dalam lampiran.", :colspan=>3},
              ]
            ], :column_widths => [30, 200, 20, 250], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        end
          pdf.move_down 10
          pdf.table([
          [
            {:content=> "b.", :align=> :right}, {:content=> "Potongan"}, {:content=> ""}, {:content=> ""}
          ], [
            {:content=> "", :align=> :right}, {:content=> "Semua upah/pendapatan PIHAK KEDUA akan dipotong"}, {:content=> ":"}, {:content=> ""}
          ], [
            {:content=> "", :align=> :right}, {:content=> "1. Pajak penghasilan (PPh 21)", :colspan=> 2}
          ], [
            {:content=> "", :align=> :right}, {:content=> "2. BPJS Kesehatan dan Ketenagakerjaan yang besarannya sesuai dengan aturan pemerintah yang berlaku", :colspan=> 3}
          ]

        ], :column_widths => [30, 200, 20, 250], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        if params[:work_time] == "shift" and params[:salary] == "include"
          pdf.start_new_page
          pdf.move_down 30
        else
          pdf.move_down 15
        end
        pdf.formatted_text [ { :text => "Pasal 6", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Tugas dan Tanggung Jawab", :size => 12, :styles => [:bold]}], :align=>:center
        pdf.move_down 5

        pdf.table([
          [
            {:content=> "1.", :align=> :right}, {:content=> "PIHAK KEDUA bersedia melaksanakan tugas dan tanggung jawab yang diberikan dengan sungguh-sungguh dan mematuhi Nilai-nilai, Kebijakan dan Peraturan Perusahan, baik yang sudah berlaku maupun yang dikeluarkan oleh Perusahaan dari waktu ke waktu sesuai dengan kepentingan Bisnis.", :size => 11, :align=>:justify}
          ],[
            {:content=> "2.", :align=> :right}, {:content=> "Pelanggaran atas Nilai-nilai, Kebijakan dan Peraturan Perusahaan dapat dikenakan sanksi Surat Peringatan 1 sampai Surat Peringatan 3, hingga kepada terminasi, tergantung pada beratnya Pelanggaran yang dilakukan.", :size => 11, :align=>:justify}
          ],[
            {:content=> "3.", :align=> :right}, {:content=> "Apabila PIHAK KEDUA tidak dapat melakukan pekerjaan berdasarkan perjanjian ini yang disebabkan gangguan kesehatan atau jiwa dengan lebih dari satu bulan secara berturut-turut, maka PIHAK PERTAMA berhak mengakhiri perjanjian kerja ini. Dalam hal ini PIHAK PERTAMA tidak berkewajban untuk membayar ganti rugi uang pesangon atau bentuk kompensasi lainnya.", :size => 11, :align=>:justify}
          ]
        ], :column_widths => [30, 470], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})

        pdf.move_down 15  
        pdf.formatted_text [ { :text => "Pasal 7", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Pengakhiran Masa Kerja", :size => 12, :styles => [:bold]}], :align=>:center
        pdf.move_down 5

        pdf.table([
          [
            {:content=> "1.", :align=> :right}, {:content=> "Apabila PIHAK KEDUA membatalkan Perjanjian Kerja Waktu Tertentu (PKWT) ini, maka PIHAK KEDUA wajib mengajukan ‘surat pengunduran diri’ selambat-lambatnya 30 hari dimuka.", :size => 11, :align=>:justify}
          ]
        ], :column_widths => [30, 470], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        if params[:work_time] == "shift" and params[:salary] == "include"
          pdf.move_down 15
        elsif params[:work_time] == "non_shift" and params[:salary] == "exclude"
          pdf.move_down 15
        else
          pdf.start_new_page
          pdf.move_down 30
        end
        pdf.table([
          [
            {:content=> "2.", :align=> :right}, {:content=> "PIHAK KEDUA wajib mengembalikan seluruh perlengkapan milik PIHAK PERTAMA yang telah dipinjamkan/digunakan bila hubungan kerja antara KEDUA BELAH PIHAK berakhir dengan alasan apapun.", :size => 11, :align=>:justify}
          ]
        ], :column_widths => [30, 470], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        
        if params[:work_time] == "non_shift" and params[:salary] == "exclude"
          pdf.start_new_page
          pdf.move_down 30
        else
          pdf.move_down 15
        end
        pdf.formatted_text [ { :text => "Pasal 8", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Penyelesaian Perselisihan Dan Jangkauan Hukum Yang Berlaku", :size => 12, :styles => [:bold]}], :align=>:center
        pdf.move_down 5
        pdf.table([
          [
            {:content=> "Jika terjadi perselisihan, dan atau salah pengertian sebagai akibat dari isi perjanjian kerja ini, maka KEDUA BELAH PIHAK sepakat dalam hal ini untuk sedapat mungkin akan diselesaikan dengan cara musyawarah, mufakat dan dengan cara baik terlebih dahulu. Apabila tidak dicapai kata sepakat, maka akan diselesaikan sesuai dengan mekanisme ketentuan Perundang-undangan.", :size => 11, :align=>:justify}
          ]
        ], :column_widths => [500], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        if params[:work_time] == "shift" and params[:salary] == "include"
          pdf.start_new_page
          pdf.move_down 30
        else
          pdf.move_down 15
        end
        pdf.formatted_text [ { :text => "Pasal 9", :size => 12, :styles => [:bold]}] , :align => :center
        pdf.formatted_text [ { :text => "Lain Lain", :size => 12, :styles => [:bold]}], :align=>:center
        pdf.move_down 5

        pdf.table([
          [
            {:content=> "1.", :align=> :right}, {:content=> "Jika PIHAK KEDUA tidak masuk kerja karena sakit, harus memberikan keterangan tidak masuk bekerja kepada atasan dan HRD di pagi harinya.", :size => 11, :align=>:justify}
          ],[
            {:content=> "2.", :align=> :right}, {:content=> "Apabila PIHAK KEDUA tidak masuk kerja karena sakit, maka wajib melampirkan surat keterangan sakit dari dokter. Bila tidak dapat melampirkan maka dikategorikan sebagai mangkir dan dalam hal ini akan dipotong sebesar 1/21 x Upah (per hari).", :size => 11, :align=>:justify}
          ],[
            {:content=> "3.", :align=> :right}, {:content=> "PIHAK KEDUA dilarang bekerja/mengikatkan diri dengan perusahaan/perorangan lain baik secara penuh maupun paruh waktu/part time kecuali mendapat izin dari PIHAK PERTAMA.", :size => 11, :align=>:justify}
          ],[
            {:content=> "4.", :align=> :right}, {:content=> "Bilamana diperlukan, sesuai dengan kebutuhan perusahaan dan perkembangan organisasi, maka PIHAK KEDUA harus bersedia untuk dimutasikan, dipromosikan dan dipindah tugaskan, sepanjang tidak melanggar peraturan yang berlaku.", :size => 11, :align=>:justify}
          ],[
            {:content=> "5.", :align=> :right}, {:content=> "Segala tugas dan tanggung jawab PIHAK KEDUA wajib dilaporkan ke Production Assistant Manager", :size => 11, :align=>:justify}
          ],[
            {:content=> "6.", :align=> :right}, {:content=> "Selama bekerja untuk Perusahaan dan 3 (tiga) tahun setelah meninggalkan Perusahaan, PIHAK KEDUA setuju untuk menjaga kerahasiaan, baik sebagian maupun seluruhnya, semua informasi dan tidak terbatas pada informasi teknis, bisnis, keuangan, komersial, pembuatan produk, metode, proses, penemuan baik yang dipatenkan ataupun tidak, yang berhubungan dengan Perusahaan dan Klien Perusahaan, dan tidak membocorkan kepada Pihak manapun diluar dari pada Perusahaan, baik secara langsung ataupun tidak langsung dan dengan cara apapun.", :size => 11, :align=>:justify}
          ],[
            {:content=> "7.", :align=> :right}, {:content=> "Apabila ada Peraturan Perusahaan yang belum tercantum dalam PKWT ini akan mengacu pada peraturan dan/atau kebijakan yang diatur terpisah.", :size => 11, :align=>:justify}
          ]
        ], :column_widths => [30, 470], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        
        pdf.move_down 5
        pdf.table([
          [
            {:content=> "PIHAK KEDUA telah membaca dan mengerti segala ketentuan isi Perjanjian Kerja Waktu Tertentu (PKWT) ini, serta akan tunduk dan patuh kepada Peraturan Perusahaan dan ketentuan-ketentuan yang ada. Demikian Perjanjian Kerja Waktu Tertentu (PKWT) ini dibuat dan ditanda tangani serta disepakati oleh kedua belah pihak dalam keadaan sehat dan sadar, tanpa adanya unsur paksaan atau ancaman dari pihak manapun.", :size => 11, :align=>:justify}
          ]
        ], :column_widths => [500], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})
        pdf.move_down 15
        pdf.table([
          [
            {:content=> "PIHAK PERTAMA", :size => 11}, "",
            {:content=> "PIHAK KEDUA", :size => 11}
          ], [    
            {:content=> "PT. Provital Perdana,", :size => 11}, "",
            {:content=> "", :size => 11}
          ], [
            {:content=> "", :height=> 40}
          ], [    
            {:content=> "#{record.hrd_name}", :size => 11 }, "",
            {:content=> "#{record.employee.name}", :size => 11 }
          ], [    
            {:content=> "HRD Departemen", :size => 11 }, "",
            {:content=> "Karyawan", :size => 11 }
          ]
        ], :column_widths => [200, 100, 200], :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff", :border_size=> 0})

        pdf.page_count.times do |i|             
          #header
          pdf.bounding_box([pdf.bounds.left, pdf.bounds.top+30], :width => pdf.bounds.width) {
            pdf.go_to_page i+1
            image_width = 100
            lebar = [110, 270, 100]

            pdf.table([['','',{:image => image_path, :image_height => 30,:image_width => image_width, :rowspan => 2}],[{:content=>(params[:tbl]=='product_price' ? "<br><font size='14'><color rgb='FF0000'><i>Rahasia<br>Perusahaan</i></color></font>": ""),:rotate => 10}]
              ], :column_widths => lebar, :cell_style => {:border_color => "ffffff", :inline_format => true}, :header => true)
            # pdf.text "_______________________________________________________________________________________"
            pdf.stroke_horizontal_rule
          }

          # footer
          pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom+plus], :width => pdf.bounds.width, :height => 60) {
            pdf.go_to_page i+1
              pdf.move_down 30
              pdf.text "________________________________________________________________________________________"
                pdf.draw_text "PT. Provital Perdana", :size => 10 , :at =>[280,10] , :style=> :bold
                pdf.draw_text "Jl. Kranji Blok F15-1C Delta Silicon II", :size => 8.5 , :at =>[280,0]
                pdf.draw_text "Lippo Cikarang, Bekasi 17530 Indonesia" , :size => 8.5 , :at =>[280,-10]
                pdf.draw_text "T : +62-21-245-200-51", :size => 8.5 , :at =>[280,-20]
                pdf.draw_text "F : +62-21-245-200-50", :size => 8.5 , :at =>[280,-30]

            
            
          }
        end

        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
      end
    end
  end

  # GET /employee_contracts/new
  def new
    @employee_contract = EmployeeContract.new
  end

  # GET /employee_contracts/1/edit
  def edit
  end

  # POST /employee_contracts
  # POST /employee_contracts.json
  def create
    params[:employee_contract]['number'] = generate_number
    params[:employee_contract]['created_by'] = current_user.id
    @employee_contract = EmployeeContract.new(employee_contract_params)

    respond_to do |format|
      if @employee_contract.save
        @employee_contract.employee.update_columns({
          :begin_of_contract=> @employee_contract.begin_of_contract,
          :end_of_contract=> @employee_contract.end_of_contract
        })
        format.html { redirect_to @employee_contract, notice: 'Employee contract was successfully created.' }
        format.json { render :show, status: :created, location: @employee_contract }
      else
        format.html { render :new }
        format.json { render json: @employee_contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_contracts/1
  # PATCH/PUT /employee_contracts/1.json
  def update
    respond_to do |format|
      if @employee_contract.update(employee_contract_params)
        format.html { redirect_to @employee_contract, notice: 'Employee contract was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee_contract }
      else
        format.html { render :edit }
        format.json { render json: @employee_contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_contracts/1
  # DELETE /employee_contracts/1.json
  def destroy
    @employee_contract.destroy
    respond_to do |format|
      format.html { redirect_to employee_contracts_url, notice: 'Employee contract was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_contract
      @employee_contract = EmployeeContract.find(params[:id])
    end

    def set_instance_variable
      @employees = Employee.where(:status=> 'active', :employee_legal_id=> current_user.company_profile_id)
      @work_statuses = WorkStatus.all
      @departments = Department.all
      @positions = Position.all
    end

    def generate_number
      record = EmployeeContract.where(:company_profile_id=> current_user.company_profile_id)
      last = (record.last.blank? ? 1 : record.last.number.to_s[0,3].to_i+1) # nomor dokumen, jika data kosong maka dimulai dari angka 1, jika ganti bulan nomor direset dari angka 1 jika tidak tambahkan +1
      num = last.to_s.length # nomor dokumen, menghitung jumlah karakter
      case num 
      when 1 
        numz = "00"
      when 2 
        numz = "0" 
      else
        numz = ""
      end # nomor dokumen, 
      puts last
      puts numz
      dept =  @departments.find(params[:employee_contract]['department_id']).hrd_contract_abbreviation
      workstatus = @work_statuses.find(params[:employee_contract]['work_status_id']).abbreviation
      result = "#{numz}#{last}/PP/#{dept}/#{workstatus}/#{RomanNumerals.to_roman(params[:employee_contract]['begin_of_contract'].to_date.strftime("%m").to_i)}/#{params[:employee_contract]['begin_of_contract'].to_date.strftime("%Y")}"
      
      return result
    end

    def month_indo(dt)
      month = dt.to_date.strftime("%m")
      if month == "01"
        bulan = "Januari"
      elsif month == "02"
        bulan = "Februari"
      elsif month == "03"
        bulan = "Maret"
      elsif month == "04"
        bulan = "April"
      elsif month == "05"
        bulan = "Mei"
      elsif month == "06"
        bulan = "Juni"
      elsif month == "07"
        bulan = "Juli"
      elsif month == "08"
        bulan = "Agustus"
      elsif month == "09"
        bulan = "September"
      elsif month == "10"
        bulan = "Oktober"
      elsif month == "11"
        bulan = "November"
      elsif month == "12"
        bulan = "Desember"
      end
      return "#{dt.to_date.strftime("%d")} #{bulan} #{dt.to_date.strftime("%Y")}"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_contract_params
      params.require(:employee_contract).permit(:meal_and_transport_cost, :number, :employee_id, :begin_of_contract, :end_of_contract, :department_id, :position_id, :work_status_id, :basic_salary, :hrd_name, :created_by)
    end
end
