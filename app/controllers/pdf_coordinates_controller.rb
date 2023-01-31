class PdfCoordinatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pdf_coordinate, only: [:show, :edit, :update, :destroy, :approve, :print]
  # GET /pdf_coordinates
  # GET /pdf_coordinates.json
  def index
    session[:date_begin] = (params[:date_begin].present? ? params[:date_begin] : DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d"))
    session[:date_end]   = (params[:date_end].present? ? params[:date_end] : DateTime.now().at_end_of_month().strftime("%Y-%m-%d"))
    
    @pdf_coordinates = PdfCoordinate.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")

  end

  # GET /pdf_coordinates/1
  # GET /pdf_coordinates/1.json
  def show
  end

  # GET /pdf_coordinates/new
  def new
    @pdf_coordinate = PdfCoordinate.new
  end

  # GET /pdf_coordinates/1/edit
  def edit
  end

  # POST /pdf_coordinates
  # POST /pdf_coordinates.json
  def create
    @pdf_coordinate = PdfCoordinate.new(pdf_coordinate_params)

    respond_to do |format|
      if @pdf_coordinate.save

        # require 'fileutils'
        # digest = Digest::MD5.hexdigest("#{current_user.username}_#{DateTime.now()}")
        # filename = "#{digest}.pdf"
        # my_path = "public/uploads/pdf_coordinate/#{current_user.id}"

        # Dir.mkdir(my_path) unless File.exists?(my_path)

        # path = File.join(my_path, filename)
        # File.open(path, "wb") { |f| f.write(params[:data][:signature].read) }


        format.html { redirect_to @pdf_coordinate, notice: 'PDF Coordinate was successfully created.' }
        format.json { render :show, status: :created, location: @pdf_coordinate }
      else
        format.html { render :new }
        format.json { render json: @pdf_coordinate.errors, status: :unprocessable_entity }
      end
      logger.info @pdf_coordinate.errors
    end
  end

  # PATCH/PUT /pdf_coordinates/1
  # PATCH/PUT /pdf_coordinates/1.json
  def update
    respond_to do |format|
      if @pdf_coordinate.update(pdf_coordinate_params)
        params[:record_item].each do |item|
          coordinate_item = PdfCoordinateItem.find_by(:id=> item[:id])
          if coordinate_item.present?
            coordinate_item.update_columns({
              :pdf_description=> item["pdf_description"]
            })
          end
        end if params[:record_item].present?
        params[:new_record_item].each do |item|
          coordinate_item = PdfCoordinateItem.create({
            :pdf_coordinate_id=> @pdf_coordinate.id,
            :pdf_description=> item["pdf_description"],
            :html_position_x=> item["html_position_x"], :html_position_y=> item["html_position_y"],
            :pdf_position_x=> item["pdf_position_x"], :pdf_position_y=> item["pdf_position_y"],
            :pdf_value=> item["pdf_value"],
            :note=> item["note"],
            :created_at=> DateTime.now(), :created_by=> @pdf_coordinate.created_by
          })
        end if params[:new_record_item].present?

        format.html { redirect_to @pdf_coordinate, notice: 'Delivery order was successfully updated.' }
        format.json { render :show, status: :ok, location: @pdf_coordinate }
      else
        format.html { render :edit }
        format.json { render json: @pdf_coordinate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pdf_coordinates/1
  # DELETE /pdf_coordinates/1.json
  def destroy
    @pdf_coordinate.destroy
    respond_to do |format|
      format.html { redirect_to pdf_coordinates_url, notice: 'Delivery order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def print
    company         = "PT. PRIBADI INTERNATIONAL"
    company_address = "Kawasan Delta Silicon 3 
    Jl.Pinang Blok F 17 No.3 
    Lippo Cikarang Bekasi"
    respond_to do |format|
      format.html do
        width_pts  = (@pdf_coordinate.paper_size.present? ? @pdf_coordinate.paper_size.width : 0)
        height_pts  = (@pdf_coordinate.paper_size.present? ? @pdf_coordinate.paper_size.height : 0)
        
        pdf = Prawn::Document.new(:page_size=> [  height_pts.to_f, width_pts.to_f], :top_margin => 0,:bottom_margin => 0, :left_margin=> 0, :right_margin=> 0 ) 
        pdf.font "Times-Roman"
        pdf.font_size 11

        # pdf.text "#{pdf.y}"
        # pdf.text "A5 Landscape"

        # pdf.text "#{width_pts.to_f},  #{height_pts.to_f}"
        # pdf.draw_text "72, 10", :at => [72, 10], :size => 11
        # pdf.draw_text "10, 790", :at => [10, 790], :size => 11
        # pdf.draw_text "10, 780", :at => [10, 780], :size => 11
        # pdf.draw_text "10, 770", :at => [10, 770], :size => 11
        # pdf.draw_text "10, 760", :at => [10, 760], :size => 11
        # pdf.draw_text "10, 760", :at => [10, 760], :size => 11
        # pdf.draw_text "10, 750", :at => [10, 750], :size => 11
        # pdf.draw_text "10, 740", :at => [10, 740], :size => 11
        # pdf.draw_text "10, 730", :at => [10, 730], :size => 11
        # pdf.draw_text "10, 720", :at => [10, 720], :size => 11

        # @pdf_coordinate_items.each do |item|
        #   pdf.text "#{item.pdf_description} => #{item.pdf_position_x.to_i}, #{item.pdf_position_y.to_i}"
        # end
        @pdf_coordinate_items.each do |item|
          pdf.draw_text "#{item.pdf_description}", :at => [item.pdf_position_x.to_i, item.pdf_position_y.to_i], :size => 11
        end
        # tbl_width = [20, 160,90, 80, 80, 60, 80]
       
        # pdf.page_count.times do |i|
        #   den_row = 0
        #   tbl_top_position = 685
          
        #   tbl_width.each do |i|
        #     # puts den_row
        #     den_row += i
        #     pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 550) do
        #       pdf.stroke_color '000000'
        #       pdf.stroke_bounds
        #     end
        #   end

        #   pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 16) do
        #     pdf.stroke_color '000000'
        #     pdf.stroke_bounds
        #   end
        # end
        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pdf_coordinate
      @pdf_coordinate = PdfCoordinate.find(params[:id])
      @base_64        = @pdf_coordinate.base64
      @pdf_coordinate_items = PdfCoordinateItem.where(:pdf_coordinate_id=> @pdf_coordinate.id)
      @paper_sizes = PaperSize.all
      # 2020-06-09 GA akurat 
      # require 'pdf/reader'

      # reader = PDF::Reader.new("public/uploads/pdf_coordinate/#{@pdf_coordinate.filename}")
     
      # reader.pages.each do |page|
      #   bbox   = page.attributes[:MediaBox]
      #   width  = bbox[2] - bbox[0]
      #   height = bbox[3] - bbox[1]
      #   puts @pdf_coordinate.filename
      #   puts "width: #{width}pts #{pt2mm(width).to_s("F")}mm #{pt2in(width).to_s("F")}in"
      #   puts "height: #{height}pts #{pt2mm(height).to_s("F")}mm #{pt2in(height).to_s("F")}in"
      #   @pdf_coordinate.update_columns(
      #     :height_pts=> height, 
      #     :width_pts=> width
      #     )
      # end

      # puts reader.objects.inspect

      # file = open("public/uploads/pdf_coordinate/example.pdf")
      # @base_64 = Base64.encode64(file.read)
      # @pdf_coordinate.update_columns(:base64=> @base_64, :filename=> "example.pdf")

      # file = open("public/uploads/pdf_coordinate/exampleA4.pdf")
      # @base_64 = Base64.encode64(file.read)
      # @pdf_coordinate.update_columns(:base64=> @base_64, :filename=> "exampleA4.pdf")

      # file = open("public/uploads/pdf_coordinate/exampleA5_landscape.pdf")
      # @base_64 = Base64.encode64(file.read)
      # @pdf_coordinate.update_columns(:base64=> @base_64, :filename=> "exampleA5_landscape.pdf")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pdf_coordinate_params
      params[:pdf_coordinate]["created_by"] = current_user.id
      params[:pdf_coordinate]["created_at"] = DateTime.now()
      params.require(:pdf_coordinate).permit(:name, :filename, :paper_size_id, :page_layout, :created_by, :created_at)
    end

  require 'bigdecimal'

  def pt2mm(pt)
    (pt2in(pt) * BigDecimal("25.4")).round(2)
  end

  def pt2in(pt)
    (pt / BigDecimal("72")).round(2)
  end

end
