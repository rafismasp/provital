var signaturePad = new SignaturePad(document.getElementById('signature-pad'), {
  backgroundColor: 'rgba(255, 255, 255, 0)',
  penColor: 'rgb(0, 0, 0)'
});
var saveButton = document.getElementById('save');
var cancelButton = document.getElementById('clear');

saveButton.addEventListener('click', function (event) {
 if (signaturePad.isEmpty()) {
    alert("Please provide a signature first.");
  } else {
    var dataURL = signaturePad.toDataURL();
    // download(dataURL, "signature.png");

    uploadSignature('image/png');
  }
  // var data = signaturePad.toDataURL('image/png');

// Send data to server instead...
  // window.open(data);
});

cancelButton.addEventListener('click', function (event) {
  signaturePad.clear();
});


function download(dataURL, filename) {
  if (navigator.userAgent.indexOf("Safari") > -1 && navigator.userAgent.indexOf("Chrome") === -1) {
    window.open(dataURL);
  } else {
    var blob = dataURLToBlob(dataURL);
    var url = window.URL.createObjectURL(blob);

    var a = document.createElement("a");
    a.style = "display: none";
    a.href = url;
    a.download = filename;

    document.body.appendChild(a);
    a.click();

    window.URL.revokeObjectURL(url);
  }
}
// One could simply use Canvas#toBlob method instead, but it's just to show
// that it can be done using result of SignaturePad#toDataURL.
function dataURLToBlob(dataURL) {
  // Code taken from https://github.com/ebidel/filer.js
  var parts = dataURL.split(';base64,');
  var contentType = parts[0].split(":")[1];
  var raw = window.atob(parts[1]);
  var rawLength = raw.length;
  var uInt8Array = new Uint8Array(rawLength);

  for (var i = 0; i < rawLength; ++i) {
    uInt8Array[i] = raw.charCodeAt(i);
  }

  return new Blob([uInt8Array], { type: contentType });
}


function uploadSignature(mimetype) {
  var dataurl = signaturePad.toDataURL(mimetype);
  var blobdata = dataURLToBlob(dataurl);

  var fd = new FormData(document.getElementById("UploadForm"));
  fd.append("data[signature]", blobdata, "filename");

  /** will result in normal file upload with post name "signature" on target url **/
  $.ajax({
    url: "/upload_signature",
    type: 'POST',
    data: fd,
    processData: false,
    contentType: false,
    dataType: 'html',
    success: function (response) {
      // alert("AJAX OK: uploadSignature() ok");
      console.log(response);
      window.location = '/'; 
    },
    error: function (e) {
      // alert("AJAX ERROR: uploadSignature() fehlgeschlagen");
      console.log(e);
    }
  });
}