var pdfData = atob($('#pdfBase64').val());
 /*
 *  costanti per i placaholder 
 */
// kertas A4 pixel
// var maxPDFx = 595.28;
// var maxPDFy = 841.89;

// kertas A5
// var maxPDFy = 595.28;
// var maxPDFx = 841.89;

// var maxPDFx = $('#pdf_coordinate_paper_size_id').find(':selected').attr("width_pts");
// var maxPDFy = $('#pdf_coordinate_paper_size_id').find(':selected').attr("height_pts");

// var maxPDFx = $('#the-canvas').width();
// var maxPDFy = $('#the-canvas').height();
// var offsetY = 7;
var offsetY = 0;
 
'use strict';


// The workerSrc property shall be specified.
//
pdfjsLib.GlobalWorkerOptions.workerSrc =
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.0.943/pdf.worker.min.js';

  //
  // Asynchronous download PDF
  //
  var loadingTask = pdfjsLib.getDocument({data: pdfData});
  loadingTask.promise.then(function(pdf) {
    //
    // Fetch the first page
    //
    pdf.getPage(1).then(function(page) {
      var scale = 1.0;
      var viewport = page.getViewport(scale);
      //
      // Prepare canvas using PDF page dimensions
      //
      var canvas = document.getElementById('the-canvas');
      var context = canvas.getContext('2d');
      canvas.height = viewport.height;
      canvas.width = viewport.width;
      //
      // Render PDF page into canvas context
      //
      var renderContext = {
        canvasContext: context,
        viewport: viewport
      };
      //page.render(renderContext);
      
      page.render(renderContext).then(function() {
    	  $(document).trigger("pagerendered");
    	}, function() {
    	  console.log("ERROR");
    	});
      
    });
  });

  
  /* The dragging code for '.draggable' from the demo above
   * applies to this demo as well so it doesn't have to be repeated. */

  // enable draggables to be dropped into this
  interact('.dropzone').dropzone({
    // only accept elements matching this CSS selector
    accept: '.drag-drop',
    // Require a 100% element overlap for a drop to be possible
    overlap: 1,

    // listen for drop related events:

    ondropactivate: function (event) {
      // add active dropzone feedback
      event.target.classList.add('drop-active');
    },
    ondragenter: function (event) {
      var draggableElement = event.relatedTarget,
          dropzoneElement = event.target;

      // feedback the possibility of a drop
      dropzoneElement.classList.add('drop-target');
      draggableElement.classList.add('can-drop');
      draggableElement.classList.remove('dropped-out');
      //draggableElement.textContent = 'Dragged in';
    },
    ondragleave: function (event) {
      // remove the drop feedback style
      event.target.classList.remove('drop-target');
      event.relatedTarget.classList.remove('can-drop');
      event.relatedTarget.classList.add('dropped-out');
      //event.relatedTarget.textContent = 'Dragged out';
    },
    ondrop: function (event) {
      //event.relatedTarget.textContent = 'Dropped';
    },
    ondropdeactivate: function (event) {
      // remove active dropzone feedback
      event.target.classList.remove('drop-active');
      event.target.classList.remove('drop-target');
    }
  });

  interact('.drag-drop')
    .draggable({
      inertia: true,
      restrict: {
        restriction: "#selectorContainer",
        endOnly: true,
        elementRect: { top: 0, left: 0, bottom: 1, right: 1 }
      },
      autoScroll: true,
      // dragMoveListener from the dragging demo above
      onmove: dragMoveListener,
    });
  
  
  function dragMoveListener (event) {
	    var target = event.target,
	        // keep the dragged position in the data-x/data-y attributes
	        x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx,
	        y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;

	    // translate the element
	    target.style.webkitTransform =
	    target.style.transform ='translate(' + x + 'px, ' + y + 'px)';

	    // update the posiion attributes
	    target.setAttribute('data-x', x);
	    target.setAttribute('data-y', y);
	  }

	  // this is used later in the resizing demo
	  window.dragMoveListener = dragMoveListener;

  $(document).bind('pagerendered', function (e) {
	   $('#pdfManager').show();
	   var parametri = JSON.parse($('#parameters').val());
		 // $('#parametriContainer').empty();
	   renderizzaPlaceholder(0, parametri);	
	});
  
  function renderizzaPlaceholder(currentPage, parametri){
		  var maxHTMLx = $('#the-canvas').width();
			var maxHTMLy = $('#the-canvas').height();
		
			var paramContainerWidth = $('#parametriContainer').width();
			var yCounterOfGenerated = 0;
			var numOfMaxItem = 25;
			var notValidHeight = 30;
			var y = 0;
			var x = 6;
			var page=0;
			

			var totalPages=Math.ceil(parametri.length/numOfMaxItem);
			
			for (i = 0; i < parametri.length; i++) {
				var param = parametri[i];
				var page = Math.floor(i/numOfMaxItem);
				var display= currentPage == page ? "block" : "none";
				
				if(i > 0 && i%numOfMaxItem == 0){
					yCounterOfGenerated = 0;
				}

				var classStyle = "";
				var value = param.value;
				/*il placeholder non è valido: lo incolonna a sinistra*/
		
				if(i > 0 && i%numOfMaxItem == 0){
					yCounterOfGenerated = 0;
				}

				var classStyle = "";
				var value = param.value;
				/*il placeholder non è valido: lo incolonna a sinistra*/
				y = yCounterOfGenerated;
				yCounterOfGenerated += notValidHeight;
				classStyle = "drag-drop dropped-out";


				
				$("#parametriContainer").append('<div class="'+classStyle+'" data-id="-1" data-page="'+page+'" data-toggle="'+value+'" data-value="'+value+'" data-x="'+x+'" data-y="'+y+'" style="transform: translate('+x+'px, '+y+'px); display:'+display+'">  <span class="circle"></span><span class="description">'+param.description+' </span></div>');
			}
			
			y = notValidHeight * (numOfMaxItem+1);
			var prevStyle = "";
			var nextStyle = "";
			var prevDisabled = false;
			var nextDisabled = false;
			if(currentPage == 0){
				prevStyle = "disabled";
				prevDisabled = true;
			}
			
			if(currentPage >= totalPages-1 || totalPages == 1){
				nextDisabled=true;
				nextStyle="disabled";
			} 
			
			//Aggiunge la paginazione
			$("#parametriContainerPagination").append('<ul id="pager" class="pager uk-pagination" style="width:200px;">'+
        '<li onclick="changePage('+prevDisabled+','+currentPage+',-1)" class="page-item prev '+prevStyle+'"><span class="uk-page-link">« Prev</span></li>'+
        '<li onclick="changePage('+nextDisabled+','+currentPage+',1)" class="page-item next '+nextStyle+'" style="margin-left:10px;"><span class="uk-page-link">Next &raquo;</span></li>'+
        '</ul>');
			
	 }
  
  	function renderizzaInPagina(parametri){      
    var maxPDFx = $('#pdf_coordinate_paper_size_id').find(':selected').attr("width_pts");
    var maxPDFy = $('#pdf_coordinate_paper_size_id').find(':selected').attr("height_pts");

		var maxHTMLx = $('#the-canvas').width();
		var maxHTMLy = $('#the-canvas').height();
	
    var paramContainerWidth = $('#parametriContainer').width();
		var yCounterOfGenerated = 0;
		var numOfMaxItem = 26;
		var notValidHeight = 30;
		var y = 0;
		var x = 6;
  		for (i = 0; i < parametri.length; i++) {
			var param = parametri[i];
			
			var classStyle = "drag-drop can-drop";
			var value = param.value;
			/*il placeholder non è valido: lo incolonna a sinistra*/
			
			var pdfY = maxPDFy - param.positionY - offsetY;
			y = (pdfY * maxHTMLy) / maxPDFy;
			x = ((param.positionX * maxHTMLx) / maxPDFx) + paramContainerWidth;
	
			$("#parametriContainer").append('<div class="'+classStyle+'" data-id="'+param.idParameterModulo+'" data-toggle="'+value+'" data-value="'+value+'" data-x="'+x+'" data-y="'+y+'" style="transform: translate('+x+'px, '+y+'px);">  <span class="circle"></span><span class="description">'+param.description+' </span></div>');
		}
  	}
	 
	 
	 function changePage(disabled, currentPage, delta){
		 if(disabled){
			return;	 
		 }

		 /*recupera solo i parametri non posizionati in pagina*/
		 var parametri = [];
		 $(".drag-drop.dropped-out").each(function() {
			var value = $(this).data("value");
			var description = $(this).find(".description").text();
			parametri.push({value:value, description:description, positionX:-1000, positionY:-1000});
			$(this).remove();
		 });
		 
		 //svuota il contentitore
		 $('#pager').remove();
		 currentPage += delta;
		 renderizzaPlaceholder(currentPage, parametri);
		 //aggiorna lo stato dei pulsanti
		 //aggiorna gli elementi visualizzati
	 }

      // function writeMessage(canvas, message) {
      //   var context = canvas.getContext('2d');
      //   context.clearRect(0, 0, canvas.width, canvas.height);
      //   context.font = '18pt Calibri';
      //   context.fillStyle = 'black';
      //   context.fillText(message, 10, 25);
      // }
      // function getMousePos(canvas, evt) {
      //   var rect = canvas.getBoundingClientRect();
      //   return {
      //     x: evt.clientX - rect.left,
      //     y: evt.clientY - rect.top
      //   };
      // }
      // var canvas = document.getElementById('the-canvas');
      // var context = canvas.getContext('2d');

      // canvas.addEventListener('mousemove', function(evt) {
      //   var mousePos = getMousePos(canvas, evt);
      //   var message = 'Mouse position: ' + mousePos.x + ',' + mousePos.y;
      //   writeMessage(canvas, message);
      // }, false);

  
  function showCoordinates(){
    var validi = [];
  	  var nonValidi = [];
  	  
      var maxPDFx = $('#pdf_coordinate_paper_size_id').find(':selected').attr("width_pts");
      var maxPDFy = $('#pdf_coordinate_paper_size_id').find(':selected').attr("height_pts");

  	  var maxHTMLx = $('#the-canvas').width();
  	  var maxHTMLy = $('#the-canvas').height();
      var paramContainerWidth = $('#parametriContainer').width();

  	  $("#pageContainer").css("margin-left", paramContainerWidth);
  	  //recupera tutti i placholder validi
  	  $('.drag-drop.can-drop').each(function( index ) {
  		  var x = parseFloat($(this).data("x"));
  		  var y = parseFloat($(this).data("y"));
  		  var value = $(this).data("value");
  		  var description = $(this).find(".description").text();
  		    
  		  // var pdfY = y * maxPDFy / maxHTMLy;
      //   var positionY = maxPDFy - offsetY - pdfY;   
      //   var positionX =  (x * maxPDFx / maxHTMLx)  - paramContainerWidth;

        var positionY = maxPDFy - y;
        var positionX = x - paramContainerWidth ;
 		  
  		  var val = {"description": description, "positionX":positionX,   "positionY":positionY, "value":value};
  		  validi.push(val);
        $('#item_coordinate tr:last').after("<tr>"+
          "<input id='new_record_item__html_position_x' class='uk-input uk-form-width-medium uk-form-small' type='hidden' value='"+x+"' name='new_record_item[][html_position_x]'>"+
          "<input id='new_record_item__html_position_y' class='uk-input uk-form-width-medium uk-form-small' type='hidden' value='"+y+"' name='new_record_item[][html_position_y]'>"+
          "<td><input id='new_record_item__pdf_description' class='uk-input uk-form-width-medium uk-form-small' type='text' value='"+description+"' name='new_record_item[][pdf_description]'></td>"+
          "<td><input id='new_record_item__pdf_position_x' class='uk-input uk-form-width-medium uk-form-small' type='text' value='"+positionX+"' name='new_record_item[][pdf_position_x]'></td>"+
          "<td><input id='new_record_item__pdf_position_y' class='uk-input uk-form-width-medium uk-form-small' type='text' value='"+positionY+"' name='new_record_item[][pdf_position_y]'></td>"+
          "<td><input id='new_record_item__pdf_value' class='uk-input uk-form-width-medium uk-form-small' type='text' value='"+value+"' name='new_record_item[][pdf_value]'></td>"+
          "</tr>");
      
  	  });
    
      if(validi.length == 0){
         alert('No placeholder dragged into document');
      }
     else{

      // $("#pdf_coordinate_height_pts").val($('#the-canvas').height());
      // $("#pdf_coordinate_width_pts").val($('#the-canvas').width());
      // alert($('#the-canvas').width())
      // alert($('#the-canvas').height())
      // alert(JSON.stringify(validi));

     }
  }

