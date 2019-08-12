import QtQuick 2.0
import moneroComponents.TransactionInfo 1.0
import QtQuick.Controls 1.4
import QtQml 2.2
import moneroComponents.Wallet 1.0
import moneroComponents.WalletManager 1.0
import moneroComponents.PendingTransaction 1.0
import "../components"
import "../IntenseConfig.js" as Config

Rectangle {
    id: root
    property var model
    property variant arrChecked
    property var hexConfig
    property int numTimesRetriedSdp
    property bool autoLoadMode
    property bool backgroundColor: false
    property bool unlockedBalance: true
    property bool proxyRenew: true

    function buildTxDetailsString(data, rank) {
        //console.log(data.subsequentVerificationsNeeded + "-------------------- ttt")
        var trStart = '<tr><td width="185" style="padding-top:5px"><b>',
            trMiddle = '</b></td><td style="padding-left:10px;padding-top:5px;">',
            trEnd = "</td></tr>";

        return '<table border="0">'
            + (data.id ? trStart + qsTr("ID: ") + trMiddle + data.id + trEnd : "")
            + (data.provider ? trStart + qsTr("Provider: ") + trMiddle + data.provider  + trEnd : "")
            + (data.name ? trStart + qsTr("Plan: ") + trMiddle + data.name + trEnd : "")
            + (data.type ? trStart + qsTr("Type: ") + trMiddle + data.type  + trEnd : "")
            + (data.cost ? trStart + qsTr("Price:") + trMiddle + data.cost+" "+Config.coinName+"/min" + trEnd : "")
            + (data.firstPrePaidMinutes ? trStart + qsTr("First Pre Paid Minutes:") + trMiddle + data.firstPrePaidMinutes + trEnd : "")
            + (data.firstVerificationsNeeded ? trStart + qsTr("First Verifications Needed:") + trMiddle + data.firstVerificationsNeeded + trEnd : "")
            + (data.subsequentPrePaidMinutes ? trStart + qsTr("Subsequent Pre Paid Minutes:") + trMiddle + data.subsequentPrePaidMinutes + trEnd : "")
            + (data.subsequentVerificationsNeeded >= 0 ? trStart + qsTr("Subsequent Verifications Needed:") + trMiddle + data.subsequentVerificationsNeeded + trEnd : "")
            + (data.allowRefunds ? trStart + qsTr("Allow Refunds:") + trMiddle + data.allowRefunds + trEnd : "")
            + (data.downloadSpeed ? trStart + qsTr("Download Speed:") + trMiddle + formatBytes(data.downloadSpeed)+"/s" + trEnd : "")
            + (data.uploadSpeed ? trStart + qsTr("Upload Speed:") + trMiddle + formatBytes(data.uploadSpeed)+"/s" + trEnd : "")
            + (rank ? trStart + qsTr("Rating:") + trMiddle + rank + " of 5" + trEnd : "")
            + "</table>"
            + translationManager.emptyString;
    }

    function buildTxConnectionString(data) {
        var trStart = '<tr><td width="145" style="padding-top:5px"><b>',
            trMiddle = '</b></td><td style="padding-left:10px;padding-top:5px;">',
            trEnd = "</td></tr>";

        return '<table border="0">'
            //+ (data.id ? trStart + qsTr("ID: ") + trMiddle + data.id + trEnd : "")
            + (data.providerName ? trStart + qsTr("Provider: ") + trMiddle + data.providerName  + trEnd : "")
            + (data.name ? trStart + qsTr("Plan: ") + trMiddle + data.name + trEnd : "")
            + (data.type ? trStart + qsTr("Type: ") + trMiddle + data.type  + trEnd : "")
            + (data.cost ? trStart + qsTr("Price:") + trMiddle + data.cost+" "+Config.coinName+"/min" + trEnd : "")
            + (data.cost ? trStart + qsTr("Total Price:") + trMiddle + (parseFloat(data.cost)*data.firstPrePaidMinutes).toFixed(8)+" "+Config.coinName + trEnd : "")
            + (data.firstPrePaidMinutes ? trStart + qsTr("First Pre Paid Minutes:") + trMiddle + data.firstPrePaidMinutes + trEnd : "")
            + "</table>"
            + translationManager.emptyString;
    }

    function formatBytes(bytes,decimals) {
       if(bytes == 0) return '0 Bytes';
       var k = 1000,
           dm = decimals || 2,
           sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
           i = Math.floor(Math.log(bytes) / Math.log(k));
       return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    function getColor(id){
        if(id == 5){
            return "#008b00"
        }else if(id < 5 && id > 4.5){
            return "#66cd00"
        }else if(id <= 4.5 && id > 4){
            return "#c0ff3e"
        }else if(id <= 4 && id > 3.5){
            return "#caff70"
        }else if(id <= 3.5 && id > 3){
            return "#ffff00"
        }else if(id <= 3 && id > 2.5){
            return "#ffa500"
        }else if(id <= 2.5 && id > 2){
            return "#ffa54f"
        }else if(id <= 2 && id > 1.5){
            return "#ff7f24"
        }else if(id <= 1.5 && id > 1){
            return "#ee6363"
        }else{
            return "#ee2c2c"
        }

    }

    /*
    function decode64(input) {
        var keyStr = "ABCDEFGHIJKLMNOP" +
                       "QRSTUVWXYZabcdef" +
                       "ghijklmnopqrstuv" +
                       "wxyz0123456789+/" +
                       "=";
         var output = "";
         var chr1, chr2, chr3 = "";
         var enc1, enc2, enc3, enc4 = "";
         var i = 0;

         // remove all characters that are not A-Z, a-z, 0-9, +, /, or =
         var base64test = /[^A-Za-z0-9\+\/\=]/g;
         if (base64test.exec(input)) {
            alert("There were invalid base64 characters in the input text.\n" +
                  "Valid base64 characters are A-Z, a-z, 0-9, '+', '/',and '='\n" +
                  "Expect errors in decoding.");
         }
         input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

         do {
            enc1 = keyStr.indexOf(input.charAt(i++));
            enc2 = keyStr.indexOf(input.charAt(i++));
            enc3 = keyStr.indexOf(input.charAt(i++));
            enc4 = keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output = output + String.fromCharCode(chr1);

            if (enc3 != 64) {
               output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
               output = output + String.fromCharCode(chr3);
            }

            chr1 = chr2 = chr3 = "";
            enc1 = enc2 = enc3 = enc4 = "";

         } while (i < input.length);

         return unescape(output);
      }
      */


    function updateStatus() {
        if(typeof currentWallet === "undefined") {
            statusText.text = qsTr("Wallet is not connected to daemon.")
            return;
        }

        if (currentWallet.viewOnly) {
           // statusText.text = qsTr("Wallet is view only.")
           //return;
        }
        root.enabled = false;

        switch (currentWallet.connected()) {
        case Wallet.ConnectionStatus_Disconnected:
            statusText.text = qsTr("Wallet is not connected to daemon.")
            break
        case Wallet.ConnectionStatus_WrongVersion:
            statusText.text = qsTr("Connected daemon is not compatible with GUI. \n" +
                                   "Please upgrade or connect to another daemon")
            break
        default:
            if(!appWindow.daemonSynced){
                statusText.text = qsTr("Waiting on daemon synchronization to finish")
            } else {
                // everything OK, enable transfer page

                //listModel.

                getChecked()
                root.enabled = true;
                statusText.text = "";
            }

        }
    }

    function hexC(hex){
        var min = Math.ceil(10000000000000);
        var max = Math.floor(99999999999999);
        hex = hex + (Math.floor(Math.random() * (max - min + 1)) + min)
        hexConfig = hex
        appWindow.persistentSettings.hexId = hex.toString()
        return hexConfig
    }

    // create a Hex value from body message
    function asciiToHexa(str) {
        var arr1 = [];
        for (var n = 0, l = str.length; n < l; n ++) {
            var hex = "0x" + Number(str.charCodeAt(n)).toString(16);
            arr1.push(hex);
        }
        return arr1.join(',');
    }

    // add '0x' to a Hex value
    function createHexValue(value) {
        var hexValue = "";
        for (var i = 0; i < value.length; i+=2) {
            hexValue = hexValue + "0x" + value[i] + value[i+1] + ",";
        }
        return hexValue;
    }


    function createJsonFeedback(obj, rank){
      var url = Config.url + Config.version + Config.feedback + Config.setup
      var xmlhttpPost = new XMLHttpRequest();
      xmlhttpPost.onreadystatechange=function() {
          if (xmlhttpPost.readyState == 4 && xmlhttpPost.status == 200) {
              var feed = JSON.parse(xmlhttpPost.responseText)
              var host = applicationDirectory;
              //console.log(obj.certArray[0].certContent);

              hexC(obj.id);

              var endpoint = ''
              var port = ''
              if (obj.proxy.length > 0) {
                  endpoint = obj.proxy[0].endpoint
                  port = obj.proxy[0].port
              }
              else {
                  endpoint = obj.vpn[0].endpoint
                  port = obj.vpn[0].port

                  console.log("Starting lthnvpnc using authid " + appWindow.persistentSettings.hexId + " and provider " + obj.id + "/" + obj.idService);
                  // TODO obtain lthnvpnc path on Linux/Mac. Windows uses relative path to binary.
                  appWindow.persistentSettings.haproxyStart = new Date();
                  lthnvpnc.initializeLthnvpnc( "", appWindow.persistentSettings.hexId, obj.provider, obj.id );
              }

              if (callhaproxy.haproxyStatus !== "") {
                  callhaproxy.killHAproxy();
              }

              //var certArray = decode64(obj.certArray[0].certContent); // "4pyTIMOgIGxhIG1vZGU="
              //callhaproxy.haproxyCert(host, certArray);
              //callhaproxy.haproxy(host, Config.haproxyIp, Config.haproxyPort, endpoint, port.slice(0,-4), 'haproxy', hexC(obj.id).toString(), obj.provider)
              hexC(obj.id)
              intenseDashboardView.idService = obj.id
              intenseDashboardView.feedback = feed.id
              intenseDashboardView.providerName = obj.providerName
              intenseDashboardView.name = obj.name
              intenseDashboardView.type = obj.type
              intenseDashboardView.cost = parseFloat(obj.cost) * obj.firstPrePaidMinutes
              intenseDashboardView.rank = rank
              intenseDashboardView.speed = formatBytes(obj.downloadSpeed)
              intenseDashboardView.firstPrePaidMinutes = obj.firstPrePaidMinutes
              intenseDashboardView.subsequentPrePaidMinutes = obj.subsequentPrePaidMinutes
              intenseDashboardView.subsequentVerificationsNeeded = obj.subsequentVerificationsNeeded
              intenseDashboardView.bton = "qrc:///images/power_off.png"
              intenseDashboardView.flag = 1
              intenseDashboardView.obj = obj
              intenseDashboardView.secs = 0
              intenseDashboardView.itnsStart = parseFloat(obj.cost) * obj.firstPrePaidMinutes
              intenseDashboardView.macHostFlag = 0
              intenseDashboardView.hexConfig = hexConfig
              intenseDashboardView.firstPayment = 1
              intenseDashboardView.callProxy = 1
              intenseDashboardView.showTime = false
              appWindow.persistentSettings.haproxyAutoRenew = proxyRenew;

              // call important function to populate dashboard
              intenseDashboardView.changeStatus();
              intenseDashboardView.addTextAndButtonAtDashboard();

              middlePanel.state = "VPN Dashboard"
              leftPanel.selectItem("VPN Dashboard")
          }
      }

      var data = {"id":obj.providerWallet, "provider":obj.provider, "services":obj.id, "client":appWindow.currentWallet.address}
      data = JSON.stringify(data)
      xmlhttpPost.open("POST", url, true);
      xmlhttpPost.setRequestHeader("Content-type", "application/json");
      xmlhttpPost.send(data);

    }

    function getListView(arr,n, type, rank){
        listView.model.append( {listdata:"<div style='font-size: 14px; font-weight: bold;'> " + arr[n].providerName + "</div><br />" + arr[n].name +"<br /> "+ type + " - "+ arr[n].type.toUpperCase() +"<br /><div style='font-weight: bold;'>"+ formatBytes(arr[n].downloadSpeed) +"/s </div>- "+ arr[n].cost + " "+Config.coinName+"/min", obj: arr[n], rank: rank, type: type, index: n})
    }

    function getSignature(arr, data, i, speed, speedType, price, tp, favorite){
        var urlSign = Config.url+Config.version+Config.signature+Config.get
        var xmlhttpSign = new XMLHttpRequest();
        var signHash = data.hash
        delete data.hash
        var sign = {"sign":signHash, "json":data}

        xmlhttpSign.onreadystatechange = function() {
            if(xmlhttpSign.readyState == 4 && xmlhttpSign.status == 200) {
                if(xmlhttpSign.responseText == "true"){
                    if(data.mStability == null){

                        data.mStability = 0
                    }
                    if(data.mSpeed == null){
                        data.mSpeed = 0
                    }
                    if(data.type == "proxy"){
                        var type = data.proxy[0].endpoint +":"+data.proxy[0].port
                    }else{
                        var type = data.vpn[0].endpoint +":"+data.vpn[0].port
                    }

                    var rank = (data.mStability + data.mSpeed)/2
                    rank = parseFloat(rank).toFixed(1)
                    if(speed == undefined && tp == undefined && price == undefined){
                        getListView(arr,i,type,rank)
                    }else

                    // C1
                    if(speed == "" && isNaN(price) && tp == "all" && favorite == true){
                        for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                            if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                getListView(arr,i,type,rank)
                            }
                        }
                    }

                    // C1
                    if(speed == "" && isNaN(price) && tp == "all" && favorite == false){
                        getListView(arr,i,type,rank)
                    }
                    // AC1
                    else if(speed <= data.downloadSpeed && isNaN(price) && tp == "all" && favorite == false){
                        getListView(arr,i,type,rank)
                    }

                    else if(speed > 0 && speed <= data.downloadSpeed && isNaN(price) && tp == "all" && favorite == true){
                        for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                            if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                getListView(arr,i,type,rank)
                            }
                        }
                    }


                    // BC1
                    else if(speed == "" && price >= data.cost && tp == "all" && favorite == false){
                        getListView(arr,i,type,rank)
                    }

                    else if(speed == "" && price >= data.cost && tp == "all" && favorite == true){
                        for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                            if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                getListView(arr,i,type,rank)
                            }
                        }
                    }
                    // C2
                    else if(speed == "" && isNaN(price) && tp == "vpn" && favorite == false){
                        if(data.vpn.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }

                    else if(speed == "" && isNaN(price) && tp == "vpn" && favorite == true){
                        if(data.vpn.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                    // C3
                    else if(speed == "" && price >= data.cost && tp == "proxy" && favorite == false){
                        if(data.proxy.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }
                    else if(speed == "" && price >= data.cost && tp == "proxy" && favorite == true){
                        if(data.proxy.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                    // ABC1
                    else if(speed <= data.downloadSpeed && price >= data.cost && tp == "all" && favorite == false){
                        getListView(arr,i,type,rank)
                    }
                    else if(speed <= data.downloadSpeed && price >= data.cost && tp == "all" && favorite == true){
                        for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                            if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                getListView(arr,i,type,rank)
                            }
                        }
                    }
                    // ABC2
                    else if(speed <= data.downloadSpeed && price >= data.cost && tp == "vpn" && favorite == false){
                        if(data.vpn.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }
                    else if(speed <= data.downloadSpeed && price >= data.cost && tp == "vpn" && favorite == true){
                        if(data.vpn.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                    // ABC3
                    else if(speed <= data.downloadSpeed && price >= data.cost && tp == "proxy" && favorite == false){
                        if(data.proxy.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }
                    else if(speed <= data.downloadSpeed && price >= data.cost && tp == "proxy" && favorite == true){
                        if(data.proxy.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                    // BC2
                    else if(speed == "" && price >= data.cost && tp == "vpn" && favorite == false ){
                        if(data.vpn.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }
                    else if(speed == "" && price >= data.cost && tp == "vpn" && favorite == true ){
                        if(data.vpn.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                    // BC3
                    else if(speed == "" && price >= data.cost && tp == "proxy" && favorite == false){
                        if(data.proxy.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }
                    else if(speed == "" && price >= data.cost && tp == "proxy" && favorite == true){
                        if(data.proxy.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                    // AC2
                    else if(speed <= data.downloadSpeed && isNaN(price) && tp == "vpn" && favorite == false){
                        if(data.vpn.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }
                    else if(speed <= data.downloadSpeed && isNaN(price) && tp == "vpn" && favorite == true){
                        if(data.vpn.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                    // AC3
                    else if(speed <= data.downloadSpeed && isNaN(price) && tp == "proxy" && favorite == false){
                        if(data.proxy.length > 0 ){
                            getListView(arr,i,type,rank)
                        }
                    }
                    else if(speed <= data.downloadSpeed && isNaN(price) && tp == "proxy" && favorite == true){
                        if(data.proxy.length > 0 ){
                            for(var showFav = 0; showFav < arrChecked.length; showFav++) {
                                if(arrChecked[showFav].services == data.id && arrChecked[showFav].provider == data.provider) {
                                    getListView(arr,i,type,rank)
                                }
                            }
                        }
                    }
                }
            }
        }


        xmlhttpSign.open("POST", urlSign, true);
        xmlhttpSign.setRequestHeader("Content-type", "application/json");
        xmlhttpSign.send(JSON.stringify(sign));

    }

    function getJson(speed, speedType, price, tp, favorite) {
        //console.log("Getting SDP Services");

        // show loading information while we retrieve services
        loading.visible = true;
        // hide any previous error
        getJsonFail.visible = false;

        if (speed != undefined) {
            speed = speed * 1024
            if (speedType == "mb") {
                speed = speed * 1024
            }
        }
		
        var url = Config.url + Config.version + Config.services + Config.search
        var xmlhttp = new XMLHttpRequest();
        listView.model.clear()
        xmlhttp.onreadystatechange = function() {

            // hide loading once we have retrieved the services
            loading.visible = false;

            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                numTimesRetriedSdp = 0;
                var arr = JSON.parse(xmlhttp.responseText)

                // validate if SDP version matches wallet
                if (arr.protocolVersion == null || arr.protocolVersion != Config.SDPVersion) {
                    //console.log("Wallet is not updated to use latest SDP " + arr.protocolVersion);

                    getJsonFail.text = "<p><b>Wallet Update Required</b></p>";
                    getJsonFail.text += "Your wallet is outdated.<br>";
                    getJsonFail.text += "You need to update it to continue using the services.";

                    // disable the button to search the SDP
                    filterButton.enabled = false;

                    getJsonFail.visible = true;

                    return;
                }

                // Get the raw header string
                var headers = xmlhttp.getAllResponseHeaders();

                // Convert the header string into an array
                // of individual headers
                var arrHeaders = headers.trim().split(/[\r\n]+/);

                // Create a map of header names to values
                var headerMap = {};
                arrHeaders.forEach(function (line) {
                  var parts = line.split(': ');
                  var header = parts.shift();
                  var value = parts.join(': ');
                  headerMap[header] = value;
                });

                var signature = arrHeaders[5].split(".");

                // Receive a signed message from peer and verify it using their public key.
                var theirSignedMessage = JSON.stringify(arr);

                // get just signature from header
                var signatureString = signature[1];

                // format variable as Hex value
                var msghexkey = asciiToHexa(theirSignedMessage);
                var pkey = createHexValue(Config.publicKey);
                var sigkey = createHexValue(signatureString);


                if (!ed25519verify.verify(msghexkey, sigkey, pkey, Math.round(msghexkey.length/5))) {
                    getJsonFail.text = "<p><b>Provider information error</b></p>";
                    getJsonFail.text += "There was an error trying to retrieve available services.<br>";
                    getJsonFail.text += "Please try again, and contact support if the problem persists,<br>mentioning the code 'SDP001'.";

                    // disable the button to search the SDP
                    filterButton.enabled = false;

                    getJsonFail.visible = true;

                    return;
                }


                var providers = arr.providers
                for (var i = 0; i < providers.length; i++) {
                    getSignature(providers, providers[i], i, speed, speedType, price, tp, favorite)
                }

                // Show mesage when the user don't have Favorite
                if (arrChecked && arrChecked.length == 0 && favoriteFilter.checked) {
                    getJsonFail.text = "Sorry, you don't have any favorites.";
                    getJsonFail.visible = true;
                }
            }
            else if(xmlhttp.readyState == 4 && xmlhttp.status != 200) { // sdp services retrieval failed, notify user and try again later
                //console.log("SDP services retrieval failed");
                //console.log(xmlhttp);


                getJsonFail.visible = true;
                getJsonFail.text = "There was an error trying to retrieve available services.<br>";

                if (numTimesRetriedSdp >= 30) {
                  getJsonFail.text += "You may be offline (" + numTimesRetriedSdp + " failures). Retrying in 30 seconds.<br><br>";
                  timerGetSdpData.interval = 30000;
                } else {
                  getJsonFail.text += "Retrying in a moment...<br><br>";
                  timerGetSdpData.interval = 1000;
                }

                getJsonFail.text += "<b>Error details</b><br>";
                getJsonFail.text += "Code: " + xmlhttp.status + "<br>";
                getJsonFail.text += "Message: " + xmlhttp.responseText;

                timerGetSdpData.start();
            }
        }

        xmlhttp.open("GET", url, true);
        xmlhttp.setRequestHeader("Access-Control-Allow-Origin","*")
        xmlhttp.send();
    }

    function getChecked(){
        var url = Config.url+Config.version+Config.servicesCheked+Config.get+"/"+appWindow.currentWallet.address
        var xmlhttp = new XMLHttpRequest();
        arrChecked = [];
        xmlhttp.onreadystatechange=function() {
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                arrChecked = JSON.parse(xmlhttp.responseText)
            }

        }


        xmlhttp.open("GET", url, true);
        xmlhttp.setRequestHeader("Access-Control-Allow-Origin","*")
        xmlhttp.send();
    }

    function getCheckedFavorite(obj){
        if ( typeof (arrChecked) == 'undefined' ){
            return false
        } else {
            for(var iCheckedFavorite = 0; iCheckedFavorite < arrChecked.length; iCheckedFavorite++){
                if(arrChecked[iCheckedFavorite].services == obj.id && arrChecked[iCheckedFavorite].provider == obj.provider) {
                    return true
                }
            }
            return false
        }

    }

    function getFavorite(checked, obj){ 
        if(checked == true){
            var url = Config.url+Config.version+Config.servicesCheked+Config.add
            var data = {"services":obj.id, "provider":obj.provider, "client":appWindow.currentWallet.address}

        }else{
            var url = Config.url+Config.version+Config.servicesCheked+Config.remove
            for(var iCheckedFavorite = 0; iCheckedFavorite < arrChecked.length; iCheckedFavorite++){
                if(arrChecked[iCheckedFavorite].services == obj.id && arrChecked[iCheckedFavorite].provider == obj.provider) {

                    var data = {"uuid":arrChecked[iCheckedFavorite].uuid}
                }
            }

        }

        var xmlhttp = new XMLHttpRequest();

        data = JSON.stringify(data)
        xmlhttp.open("POST", url, true);
        xmlhttp.setRequestHeader("Content-type", "application/json");
        xmlhttp.send(data);


    }


    QtObject {
        id: d
        property bool initialized: false
    }

    color: "#F0EEEE"

    Rectangle {
        color: "#F0EEEE"
        height: 95
        width: root.width
        z: 20

        Label {
              visible: !isMobile
              id: typeText
              anchors.left: parent.left
              anchors.top:  parent.top
              anchors.leftMargin: 17
              anchors.topMargin: 17
              width: 100
              text: qsTr("Type") + translationManager.emptyString
              fontSize: 14
          }

          ListModel {
              id: typeTransaction
              ListElement { column1: "ALL"; column2: ""; value: "all" }
              ListElement { column1: "VPN"; column2: ""; value: "vpn" }
              ListElement { column1: "PROXY"; column2: ""; value: "proxy" }

          }

          StandardDropdown {
              visible: !isMobile
              id: typeDrop
              anchors.left: parent.left
              anchors.top: typeText.bottom
              anchors.leftMargin: 17
              anchors.topMargin: 5
              width: 100
              shadowReleasedColor: "#A7B8C0"
              shadowPressedColor: "#666e71"
              releasedColor: "#6C8896"
              pressedColor: "#A7B8C0"
              dataModel: typeTransaction
              z: 100
              onCurrentIndexChanged: {
                  querySdpForProviderInfo()
              }
          }

          Label {
              visible: !isMobile
              id: maxPriceText
              anchors.left: typeText.right
              anchors.top:  parent.top
              anchors.leftMargin: 17
              anchors.topMargin: 17
              width: 136
              text: qsTr("Max Price") + translationManager.emptyString
              fontSize: 14
          }

          LineEdit {
              visible: !isMobile
              id: maxPriceLine
              anchors.left: typeDrop.right
              anchors.top: maxPriceText.bottom
              anchors.leftMargin: 17
              anchors.topMargin: 5
              width: 136
              onTextChanged: {
                  querySdpForProviderInfo()
              }
          }

          Label {
              visible: !isMobile
              id: minSpeedText
              anchors.left: maxPriceText.right
              anchors.top: parent.top
              anchors.leftMargin: 17
              anchors.topMargin: 17
              width: 136
              text: qsTr("Min Speed") + translationManager.emptyString
              fontSize: 14
          }

          LineEdit {
              visible: !isMobile
              id: minSpeedLine
              anchors.left: maxPriceLine.right
              anchors.top: minSpeedText.bottom
              anchors.leftMargin: 17
              anchors.topMargin: 5
              width: 136
              onTextChanged: {
                  querySdpForProviderInfo()
              }

          }

          ListModel {
              id: typeSpeed
              ListElement { column1: "KB/s"; column2: ""; value: "kb" }
              ListElement { column1: "MB/s"; column2: ""; value: "mb" }
          }

          StandardDropdown {
              visible: !isMobile
              id: speedDrop
              anchors.left: minSpeedLine.right
              anchors.top: minSpeedText.bottom
              anchors.leftMargin: 0
              anchors.topMargin: 5
              width: 80
              shadowReleasedColor: "#A7B8C0"
              shadowPressedColor: "#666e71"
              releasedColor: "#6C8896"
              pressedColor: "#A7B8C0"
              dataModel: typeSpeed
              z: 100
              onCurrentIndexChanged: {
                  querySdpForProviderInfo()
              }
          }

          StandardButton {
              visible: !isMobile
              id: mapButton
              anchors.top: parent.top
              anchors.left: speedDrop.right
              anchors.leftMargin: 17
              anchors.topMargin: 40
              width: 60
              text: qsTr("Map") + translationManager.emptyString
              shadowReleasedColor: "#A7B8C0"
              shadowPressedColor: "#666e71"
              releasedColor: "#6C8896"
              pressedColor: "#A7B8C0"
              onClicked:  {
                  appWindow.hide()
                  worldMapVPNSelectionDialog.show()
              }
          }

          CheckBox {
              visible: !isMobile
              id: favoriteFilter
              text: qsTr("Favorite") + translationManager.emptyString
              anchors.left: mapButton.right
              anchors.top: parent.top
              anchors.leftMargin: 17
              anchors.topMargin: 46
              checkedIcon: "../images/star.png"
              uncheckedIcon: "../images/unstar.png"
              onClicked: {
                  querySdpForProviderInfo()
              }
          }

          /*
          StandardButton {
              visible: !isMobile
              id: filterButton
              anchors.top: parent.top
              anchors.left: favoriteFilter.right
              anchors.leftMargin: 17
              anchors.topMargin: 40
              width: 60
              text: qsTr("Filter") + translationManager.emptyString
              shadowReleasedColor: "#A7B8C0"
              shadowPressedColor: "#666e71"
              releasedColor: "#6C8896"
              pressedColor: "#A7B8C0"
              onClicked:  {
                  //console.log("Getting SDP Services after clicking on button");
                  querySdpForProviderInfo()
              }
          }
          */
    }

    Rectangle {
        //property int expandedHeight: parent.height - parent.y - parent.height - 5
        property int middleHeight: parent.height - maxPriceLine.y - maxPriceLine.height - 17
        //property int collapsedHeight: parent.height - typeDrop.y - typeDrop.height - 17

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#FFFFFF"

        height: (isMobile)? parent.height : middleHeight

        /*
        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.InQuad }
        }
        */

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: "#DBDBDB"
        }


        Text {
          visible: false
          id: getJsonFail
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top:  parent.top
          anchors.topMargin: 75
          font.pixelSize: 16
          width: 400
          height: 800
          color: "#535353"
          font.family: "Arial"
        }

        Text {
          id: loading
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top:  parent.top
          anchors.topMargin: 75
          text: qsTr("Loading services ...") + translationManager.emptyString
          font.pixelSize: 20
          color: "#535353"
          font.family: "Arial"
        }



        ListView {
                id: listView
                anchors.fill: parent
                model: listModel


                delegate: Rectangle {
                    width: listView.width
                    height: listView.height / 6.8
                    Component.onCompleted:{
                        if(backgroundColor == true){
                            backgroundColor = false;
                            this.color = "#f0f0f0";
                        }else{
                            backgroundColor = true;
                            this.color = "#fafafa";
                        }
                    }

                    Text {
                        text: listdata
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 70
                        anchors.topMargin: 15
                        textFormat: Text.RichText


                        CheckBox {
                            visible: !isMobile
                            id: favoriteCheck
                            //text: qsTr("Favorite") + translationManager.emptyString
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: -50
                            anchors.topMargin: 5
                            checkedIcon: "../images/star.png"
                            uncheckedIcon: "../images/unstar.png"
                            checked: getCheckedFavorite(obj)
                            onClicked: {
                                getFavorite(this.checked, obj)
                            }
                        }

                        StandardDialog {
                            id: connectPopup
                            cancelVisible: true
                            okVisible: true
                            width:400
                            height: 380
                            onAccepted:{
                                createJsonFeedback(obj, rank)

                            }

                            GroupBox {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: 215
                                height: 70
                                ExclusiveGroup { id: tabPositionGroup }
                                flat: true
                                Column {
                                    anchors.top: parent.top
                                    anchors.topMargin: 20
                                    RadioButton {
                                        id: radioRenew
                                        text: "Auto Renew Connection"
                                        checked: true
                                        exclusiveGroup: tabPositionGroup
                                        onClicked: {
                                            proxyRenew = true;
                                        }
                                    }
                                    RadioButton {
                                        id: radioClose
                                        text: "Close after time expired"
                                        exclusiveGroup: tabPositionGroup
                                        onClicked: {
                                            proxyRenew = false;
                                        }
                                    }
                                }

                            }
                        }



                        StandardDialog {
                            id: detailsPopup
                            cancelVisible: false
                            okVisible: true
                            width:720
                            height: 500

                        }

                        StandardButton {
                            visible: !isMobile
                            id: rankButton
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.leftMargin: -50
                            anchors.topMargin: 40
                            width: 25
                            height: 25
                            text: rank
                            shadowReleasedColor: getColor(rank)
                            shadowPressedColor: getColor(rank)
                            releasedColor: getColor(rank)
                            pressedColor: getColor(rank)
                            textColor: "#000000"

                        }

                        StandardButton {
                            visible: true
                            id: subButton
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.rightMargin: 17
                            anchors.topMargin: 0
                            width: 80
                            text: qsTr("Connect") + translationManager.emptyString
                            shadowReleasedColor: "#A7B8C0"
                            shadowPressedColor: "#666e71"
                            releasedColor: "#6C8896"
                            pressedColor: "#A7B8C0"
                            Component.onCompleted:{
                                // check the unlocked balance to lock the connect button.
                                // unlockedbalance == true because its have to run only once
                                if(walletManager.displayAmount(currentWallet.unlockedBalance) < 1) {
                                    statusText.text = qsTr("Waiting for wallet balance");
                                    timerUnlockedBalance.start();
                                    unlockedBalance = false
                                    this.enabled = false
                                }
                                else{
                                    if (statusText.text === qsTr("Waiting for wallet balance")) {
                                      statusText.text = "";
                                    }
                                    timerUnlockedBalance.stop();
                                    unlockedBalance = true
                                    this.enabled = true
                                }
                            }

                            onClicked:{
                                connectPopup.title = "Connection Confirmation";
                                connectPopup.content = buildTxConnectionString(obj);
                                connectPopup.open();

                            }
                        }



                        StandardButton {
                            visible: !isMobile
                            id: infoButton
                            anchors.top: subButton.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: 17
                            anchors.topMargin: 2
                            width: 80
                            text: qsTr("Details") + translationManager.emptyString
                            shadowReleasedColor: "#A7B8C0"
                            shadowPressedColor: "#666e71"
                            releasedColor: "#6C8896"
                            pressedColor: "#A7B8C0"

                            onClicked:  {
                                detailsPopup.title = "Services details";
                                detailsPopup.content = buildTxDetailsString(obj,rank);
                                detailsPopup.open();
                            }
                        }
                    }
                }
            }

            ListModel {
                id: listModel

                Component.onCompleted: {
                    //console.log("Getting SDP Services after List initialized");
                    autoLoadMode = true;
                    querySdpForProviderInfo()

                }


            }
    }

    Rectangle {
        x: root.width/2 - width/2
        y: root.height/2 - height/2
        height:statusText.paintedHeight + 50
        width:statusText.paintedWidth + 40
        visible: statusText.text != ""
        opacity: 0.9

        Text {
            id: statusText
            anchors.fill:parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.RichText
            onLinkActivated: { appWindow.startDaemon(appWindow.persistentSettings.daemonFlags); }
        }
    }

    Component.onCompleted: {
        //Disable password page until enabled by updateStatus
        root.enabled = false
    }

    Timer {
      id: timerGetSdpData
      interval: 1000
      repeat: false
      onTriggered: {
        numTimesRetriedSdp++;
        querySdpForProviderInfo();
      }
    }


    // create timer to validate whether or not we have unlocked balance
    Timer {
        id: timerUnlockedBalance
        interval: 10000
        repeat: true

        onTriggered:
        {
            if(unlockedBalance == true && appWindow.currentWallet.unlockedBalance < 1){
                querySdpForProviderInfo()
            }else if(appWindow.currentWallet.unlockedBalance > 1){
                querySdpForProviderInfo()
            }
        }
    }

    function querySdpForProviderInfo() {
      getJson(minSpeedLine.text, typeSpeed.get(speedDrop.currentIndex).value, parseFloat(maxPriceLine.text), typeTransaction.get(typeDrop.currentIndex).value, favoriteFilter.checked);
    }

    function onPageCompleted() {
        proxyRenew = true;
        updateStatus();
        querySdpForProviderInfo()

    }
}
