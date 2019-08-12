var spawn = require('child_process').spawn;

function backgroundProcess(item) {
  let cmd = is.windows() ? 'resources\\lthnvpnc.exe' : './resources/program.sh';
  var child = spawn(cmd, ['--sdp-server', 'https://sdp.staging.cloud.lethean.io/v1', 'connect', item + "/1A"]);

  child.stdout.on('data', function (data) {   console.log(data.toString());  });
  child.stderr.on('data', function (data) {   console.log(data.toString());  });

  child.on('close', function (code) { 
    console.log("Finished with code " + code);
  });
}

function showMessage(msj) {
  $('#toast-info').toast('show');
  $('#toast-info .toast-body').html(msj);
  setTimeout(function () {
    $('#toast-info').toast('hide');
  }, 3000)
}