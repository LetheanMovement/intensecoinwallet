import QtQuick 2.0
import moneroComponents.TransactionInfo 1.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQml 2.2
import moneroComponents.Wallet 1.0
import moneroComponents.WalletManager 1.0
import moneroComponents.PendingTransaction 1.0
import QtQuick.Dialogs 1.1

import "../components"
import "../pages"
import "../IntenseConfig.js" as Config


Rectangle {
    id: root

    property var model
    property string idService
    property string providerName
    property string name
    property string type
    property string cost
    property int firstPrePaidMinutes
    property string subsequentPrePaidMinutes
    property int subsequentVerificationsNeeded
    property string speed
    property var feedback
    property string bton
    property string rank
    property bool proxyRenew: true
    property bool reportedWalletLoad: false
    property var reportedConnectedIds: []

    // set if the connection come from Dashboard or provider List
    property int dashboardPayment: 0

    // keeps track of connection status. 0 for disconnected, 1 for connected
    property int flag
    property int secs
    property var obj
    property double itnsStart
    property int macHostFlag
    property var timerPayment
    property var hexConfig
    property int firstPayment

    // if set to 1, waiting for payment popup will be shown
    property int waitHaproxy: 0
    property int callProxy
    property int proxyStats: 0
    property bool showTime

    // keep track haproxy verify 10 before payment and 300 after payment
    property int verification: 10

    property string pathToSaveHaproxyConfig: (typeof currentWallet == "undefined") ? persistentSettings.wallet_path : (Qt.platform.os === "osx" ? currentWallet.daemonLogPath : currentWallet.walletLogPath)

    function getITNS() {
        itnsStart = itnsStart + ( parseFloat(cost) / firstPrePaidMinutes * subsequentPrePaidMinutes );
        appWindow.persistentSettings.paidTextLineTimeLeft = itnsStart.toFixed(8) + " " + Config.coinName;
        paidTextLine.text = itnsStart.toFixed(8) + " " + Config.coinName;
    }

    function hex2bin( hex ) {
        var hexbin = ""
        for ( var i = 0; i < hex.length; i++ ) {
            var bin = ( "0000" + parseInt( hex[i], 16 ).toString( 2 ) ).substr( -4 )
            hexbin = hexbin + bin
            if ( i == hex.length-1 ) {
                return hexbin
            }
        }
    }

    function hexC( hex ) {
        var min = Math.ceil( 10000000000000 );
        var max = Math.floor( 99999999999999 );
        hex = hex + ( Math.floor( Math.random() * ( max - min + 1 ) ) + min )
        hexConfig = hex
        appWindow.persistentSettings.hexId = hex.toString()
        return hexConfig
    }

    function getPathToSaveHaproxyConfig(dir) {
        var path = dir;
        path = dir.split(dir.substring(dir.lastIndexOf('/')));
        console.log(path[0]+"/");
        return path[0]+"/";
    }

    function setPayment(){
        var walletHaproxyPath = getPathToSaveHaproxyConfig(pathToSaveHaproxyConfig);
        var data = new Date();

        if (firstPayment == 1) {
            var value = parseFloat(cost)
            // set first payment or subsequentPrePaidMinutes
            appWindow.persistentSettings.haproxyTimeLeft = new Date(data.getTime() + firstPrePaidMinutes*60000);
            appWindow.persistentSettings.haproxyStart = new Date();
        } else {
            var value = parseFloat(cost)/firstPrePaidMinutes*subsequentPrePaidMinutes
            appWindow.persistentSettings.haproxyTimeLeft = new Date(appWindow.persistentSettings.haproxyTimeLeft.getTime() + subsequentPrePaidMinutes*60000);
        }

        appWindow.persistentSettings.objTimeLeft = obj;
        appWindow.persistentSettings.idServiceTimeLeft = idService
        appWindow.persistentSettings.providerNameTimeLeft = providerName
        appWindow.persistentSettings.nameTimeLeft = name
        appWindow.persistentSettings.typeTimeLeft = type
        appWindow.persistentSettings.costTimeLeft = cost
        appWindow.persistentSettings.firstPrePaidMinutesTimeLeft = firstPrePaidMinutes
        appWindow.persistentSettings.subsequentPrePaidMinutesTimeLeft = subsequentPrePaidMinutes
        appWindow.persistentSettings.subsequentVerificationsNeededLeft = obj.subsequentVerificationsNeeded
        appWindow.persistentSettings.speedTimeLeft = speed
        appWindow.persistentSettings.feedbackTimeLeft = feedback
        appWindow.persistentSettings.btonTimeLeft = bton
        appWindow.persistentSettings.rankTimeLeft = rank
        appWindow.persistentSettings.flagTimeLeft = flag
        appWindow.persistentSettings.secsTimeLeft = secs
        appWindow.persistentSettings.itnsStartTimeLeft = itnsStart
        appWindow.persistentSettings.macHostFlagTimeLeft = macHostFlag
        appWindow.persistentSettings.timerPaymentTimeLeft = timerPayment
        appWindow.persistentSettings.hexConfigTimeLeft = hexConfig
        appWindow.persistentSettings.firstPaymentTimeLeft = firstPayment;

        // make more than one payment if necessary
        if ( ( ( appWindow.persistentSettings.haproxyTimeLeft.getTime() - appWindow.persistentSettings.haproxyStart.getTime() ) / 1000 ).toFixed( 0 ) <= Config.payTimer + ( Config.subsequentVerificationsNeeded * subsequentVerificationsNeeded ) ) {
            if ( firstPayment == 1 ) {
                var value = parseFloat( cost ) + ( parseFloat( cost ) / firstPrePaidMinutes*subsequentPrePaidMinutes )
            } else {
                var value = ( parseFloat( cost ) / firstPrePaidMinutes * subsequentPrePaidMinutes ) + ( parseFloat( cost ) / firstPrePaidMinutes * subsequentPrePaidMinutes )
            }
            appWindow.persistentSettings.haproxyTimeLeft = new Date( appWindow.persistentSettings.haproxyTimeLeft.getTime() + subsequentPrePaidMinutes * 60000 )

        }

        var priority = 2
        var privacy = 4
        var amountxmr = walletManager.amountFromString( value.toFixed( 8 ) );

        // validate amount;
        if ( amountxmr <= 0 ) {
            hideProcessingSplash()
            flag = 0
            changeStatus()
            closeProxyClient();
            informationPopup.title = qsTr( "Error" ) + translationManager.emptyString;
            informationPopup.text  = qsTr( "Amount is wrong: expected number from %1 to %2" )
                    .arg( walletManager.displayAmount( 0 ) )
                    .arg( walletManager.maximumAllowedAmountAsSting() )
                    + translationManager.emptyString

            informationPopup.onCloseCallback = null
            informationPopup.open()
            return;
        } else if ( amountxmr > currentWallet.unlockedBalance ) {
            hideProcessingSplash()
            flag = 0
            changeStatus()
            closeProxyClient();
            informationPopup.title = qsTr( "Error" ) + translationManager.emptyString;
            informationPopup.text  = qsTr( "Insufficient funds. Unlocked balance: %1" )
                    .arg( walletManager.displayAmount( currentWallet.unlockedBalance ) )
                    + translationManager.emptyString

            informationPopup.onCloseCallback = null
            informationPopup.open()
            return;
        } else {
            if ( callProxy == 1 ) {
                callProxy = 0
                var host = applicationDirectory;

                var endpoint = ''
                var port = ''
                var proxyStarted = false;
                if ( obj.proxy.length > 0 ) {
                    endpoint = obj.proxy[0].endpoint
                    port = obj.proxy[0].port

                    var certArray = decode64( obj.certArray[0].certContent ); // "4pyTIMOgIGxhIG1vZGU="
                    callhaproxy.haproxyCert( walletHaproxyPath, certArray );

                    // try to start proxy and show error if it does not start
                    proxyStarted = callhaproxy.haproxy( walletHaproxyPath, Config.haproxyIp, Config.haproxyPort, endpoint, port.slice( 0,-4 ), 'haproxy', hexC( obj.id ).toString(), obj.provider, obj.providerName, obj.name )

                } else {
                    endpoint = obj.vpn[0].endpoint
                    port = obj.vpn[0].port
                    proxyStarted = true;
                }

                if ( !proxyStarted ) {
                    showProxyStartupError();
                }

                changeStatus();
            }

            if (!isUsingLthnVpnc()) {
                //callhaproxy.haproxyStatus NO_PAYMENT: used in initial connection
                //callhaproxy.haproxyStatus OK: used to renew ongoing connection
                if (callhaproxy.haproxyStatus === "NO_PAYMENT" || callhaproxy.haproxyStatus === "OK") {
                      // make payment only when comes from timer() function, some times we call setPayment() function from dashboard
                      if (dashboardPayment != 0) {
                          firstPayment = 0;
                          dashboardPayment = 0;
                          appWindow.persistentSettings.firstPaymentTimeLeft = firstPayment;
                          paymentAutoClicked(obj.providerWallet, appWindow.persistentSettings.hexId, value.toString(), privacy, priority, "Lethean payment");

                      }
                }
                else if (callhaproxy.haproxyStatus === "READY") {
                    //waiting for an actionable haproxy status (OK or NO_PAYMENT), nothing to do
                }
                else {
                      callhaproxy.killHAproxy()
                      loadingTimer.stop()
                      backgroundLoader.visible = false
                      if (dialogConfirmCancel.visible)
                        dialogConfirmCancel.visible = false
                      waitHaproxyPopup.title = "Unavailable Service";
                      waitHaproxyPopup.content = "The proxy may not work or the service is Unavailable.";
                      waitHaproxyPopup.open();
                      timeonlineTextLine.text = "Unavailable Service"
                      flag = 0;
                      changeStatus()
                }
            } else {
                //if setPayment() was called and we're in VPN mode, it's time to send a payment
                console.log("Initiating VPN payment...");
                if (dashboardPayment != 0) {
                  firstPayment = 0;
                  dashboardPayment = 0;
                  appWindow.persistentSettings.firstPaymentTimeLeft = firstPayment;
                  paymentAutoClicked(obj.providerWallet, appWindow.persistentSettings.hexId, value.toString(), privacy, priority, "Lethean payment");
              }
            }

        }


    }

    function showVpnError(error) {
        errorPopup.title = "VPN Error";
        errorPopup.content = "There was an error trying to start the VPN service.\n" + error + "\nIf you have already paid, restart the wallet to attempt reconnection.";
        errorPopup.open();

        // set this to 1 so the popup waiting for payment is not shown
        waitHaproxy = 1;

        // set this to one and for update of status so we dont see the service as connected
        flag = 0

        // update dashboard status
        changeStatus();
    }

    function showProxyStartupError() {
        errorPopup.title = "Proxy Startup Error";
        errorPopup.content = "There was an error trying to start the proxy service.\n" + callhaproxy.haproxyStatus + ".\n Wallet path: "  + getPathToSaveHaproxyConfig(persistentSettings.wallet_path) + "\nPlease confirm that you have HAProxy installed in your machine.";
        errorPopup.open();

        // set this to 1 so the popup waiting for payment is not shown
        waitHaproxy = 1;

        // set this to one and for update of status so we dont see the service as connected
        flag = 0

        // update dashboard status
        changeStatus();
    }

    function postJsonFeedback( fbId ) {
        var url = Config.url + Config.version + Config.feedback + Config.add
        var xmlhttpPost = new XMLHttpRequest();
        xmlhttpPost.onreadystatechange=function() {
            if ( xmlhttpPost.readyState == 4 && xmlhttpPost.status == 200 ) {
                var feed = JSON.parse( xmlhttpPost.responseText )
            }
        }

        var sp = 0
        var st = 0
        var i = 0
        var arrRank = [rank1, rank2, rank3, rank4, rank5]
        var arrRankText = [rText1, rText2, rText3, rText4, rText5]
        var arrQRank = [rankQ1, rankQ2, rankQ3, rankQ4, rankQ5]
        var arrQRankText = [rqText1, rqText2, rqText3, rqText4, rqText5]
        for( i = 0; i < 5; i++ ) {
            if ( arrRank[i].color == "#a7b8c0" ) {
                sp = parseInt( arrRankText[i].text )
            }
            if ( arrQRank[i].color == "#a7b8c0" ) {
                st = parseInt( arrQRankText[i].text )
            }
        }

        var data = {"id":fbId, "speed":sp, "stability":st}
        data = JSON.stringify( data )
        xmlhttpPost.open( "POST", url, true );
        xmlhttpPost.setRequestHeader( "Content-type", "application/json" );
        xmlhttpPost.send( data );

    }

    function csvToArray( strData, strDelimiter  ) {
            strDelimiter = ( strDelimiter || "," );
            var objPattern = new RegExp(
                (
                    // Delimiters.
                    "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +

                    // Quoted fields.
                    "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +

                    // Standard fields.
                    "([^\"\\" + strDelimiter + "\\r\\n]*))"
                ),
                "gi"
                );

            var arrData = [[]];

            var arrMatches = null;
            while ( arrMatches = objPattern.exec( strData ) ) {

                var strMatchedDelimiter = arrMatches[ 1 ];
                if (
                    strMatchedDelimiter.length &&
                    strMatchedDelimiter !== strDelimiter
                     ) {
                    arrData.push( [] );

                }

                var strMatchedValue;
                if ( arrMatches[ 2 ] ) {
                    strMatchedValue = arrMatches[ 2 ].replace(
                        new RegExp( "\"\"", "g" ),
                        "\""
                        );

                } else {
                    strMatchedValue = arrMatches[ 3 ];
                }

                arrData[ arrData.length - 1 ].push( strMatchedValue );
            }
            return( arrData );
        }

    // get my location by provider IP
    function getGeoLocation() {
        var url = "http://ip-api.com/json/" + getProviderEndpoint();
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.onreadystatechange=function() {
            if ( xmlhttp.readyState == 4 && xmlhttp.status == 200 ) {
                var location = JSON.parse( xmlhttp.responseText );
                serverCountryTextLine.text = location.city + " - " + location.country
            }
        }

        xmlhttp.open( "GET", url, true );
        xmlhttp.setRequestHeader( "Access-Control-Allow-Origin","*" )
        xmlhttp.send();
    }

    function getHaproxyStats( obj ) {

        // Get download and upload each 10 seconds
        var data = new Date();
        var secsToCheckHaproxy = ( ( data.getTime() - appWindow.persistentSettings.haproxyStart.getTime() ) / 1000 ).toFixed( 0 );
        if ( secsToCheckHaproxy % 10 != 0 ) return;

        var url = "http://" +Config.haproxyIp+":8181/stats;csv"
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.onreadystatechange=function() {
            if ( xmlhttp.readyState == 4 && xmlhttp.status == 200 ) {
                var haproxyStats = csvToArray( xmlhttp.responseText )
                haproxyStats = JSON.stringify( haproxyStats[1] );
                haproxyStats = haproxyStats.split( ',' )
                haproxyStats[8] = haproxyStats[8].replace( '"', '' )
                haproxyStats[9] = haproxyStats[9].replace( '"', '' )
                transferredTextLine.color = "#000000"
                transferredTextLine.font.bold = false
                appWindow.persistentSettings.transferredTextLineTimeLeft = "Download: " + formatBytes( parseInt( haproxyStats[9] ) ) + " / Upload: " + formatBytes( parseInt( haproxyStats[8] ) );
                transferredTextLine.text = "Download: " + formatBytes( parseInt( haproxyStats[9] ) ) + " / Upload: " + formatBytes( parseInt( haproxyStats[8] ) )
            }
            else if ( xmlhttp.readyState == 4 ) {
                var host = applicationDirectory;
                var endpoint = ''
                var port = ''
                var proxyStarted = false;

                flag = 0
                transferredTextLine.text = "Proxy not running!"
                transferredTextLine.color = "#FF4500"
                transferredTextLine.font.bold = true

                if ( obj.proxy.length > 0 ) {
                    endpoint = obj.proxy[0].endpoint
                    port = obj.proxy[0].port
                    var certArray = decode64( obj.certArray[0].certContent ); // "4pyTIMOgIGxhIG1vZGU="
                    var walletHaproxyPath = getPathToSaveHaproxyConfig(pathToSaveHaproxyConfig);
                    callhaproxy.haproxyCert( walletHaproxyPath, certArray );

                    proxyStarted = callhaproxy.haproxy( walletHaproxyPath, Config.haproxyIp, Config.haproxyPort, endpoint, port.slice( 0,-4 ), 'haproxy', hexC( obj.id ).toString(), obj.provider, obj.providerName, obj.name );
                } else {
                    endpoint = obj.vpn[0].endpoint
                    port = obj.vpn[0].port
                    proxyStarted = true;
                }

                if ( !proxyStarted ) {
                    showProxyStartupError();
                }

                changeStatus();

            }
        }

        xmlhttp.open( "GET", url, true );
        xmlhttp.setRequestHeader( "Access-Control-Allow-Origin","*" )
        xmlhttp.send();
    }

    function getMyFeedJson() {
        var myRank = 0
        var url = Config.url + Config.version + Config.feedback + Config.get + "/" + appWindow.currentWallet.address + "/" + idService
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.onreadystatechange=function() {
            if ( xmlhttp.readyState == 4 && xmlhttp.status == 200 ) {
                var mFeed = JSON.parse( xmlhttp.responseText )
                for( var i = 0; i < mFeed.length; i++ ) {
                    if ( mFeed[i].mStability == null ) {
                        mFeed[i].mStability = 0
                    }
                    if ( mFeed[i].mSpeed == null ) {
                        mFeed[i].mSpeed = 0
                    }
                    myRank = ( mFeed[i].mStability + mFeed[i].mSpeed ) / 2
                }
                myRank = parseFloat( myRank ).toFixed( 1 )
                appWindow.persistentSettings.myRankTextTimeLeft = myRank
                myRankText.text =  myRank
                getColor( myRank, myRankRectangle )

            }
        }

        xmlhttp.open( "GET", url, true );
        xmlhttp.setRequestHeader( "Access-Control-Allow-Origin","*" )
        xmlhttp.send();

    }

    // update dashboard status depending on proxy connection status
    function changeStatus() {
        if ( flag == 1 ) {
            // add loading page until waiting the payment
            backgroundLoader.visible = true;
            loadingTimer.start();
            timerHaproxy.restart()
            timerHaproxy.running = true

            subButton.visible = true
            powerOn.source = "../images/power_on.png"
            console.log("node type: " + type);
            if ( type == "vpn" ) {
                shield.source = "../images/shield_vpn_on.png"
                transferredText.visible = false;
                transferredTextLine.visible = false;
                paiduntilnowText.anchors.top =
                    paidTextLine.anchors.top =
                    transferredText.visible ? transferredText.top : timeonlineText.top;
            }
            else {
                shield.source = "../images/shield_proxy_on.png"
                transferredText.visible = true;
                transferredTextLine.visible = true;
                paiduntilnowText.anchors.top =
                    paidTextLine.anchors.top =
                    transferredText.visible ? transferredText.top : timeonlineText.top;
            }
            runningText.text = "Connected"
            subButtonText.text = "Disconnect"
            subConnectButton.visible = false

            startText.text = "Connected"
            appWindow.persistentSettings.paidTextLineTimeLeft = itnsStart.toFixed(8) + " "+Config.coinName;
            paidTextLine.text = itnsStart.toFixed(8) + " "+Config.coinName
            switchAutoRenew.checked = appWindow.persistentSettings.haproxyAutoRenew

        }
        else {
            loadingTimer.stop()
            backgroundLoader.visible = false
            if (dialogConfirmCancel.visible)
                dialogConfirmCancel.visible = false
            subButton.visible = false
            shield.source = "../images/shield.png"
            runningText.text = "Not running"
            subConnectButton.visible = true
            timerHaproxy.stop()
            timerHaproxy.running = false
            bton = ""
            if ( startText.text != "Disconnected" ) {
                startText.text = "Reconnect"
            }

        }

    }

    function buildTxConnectionString( data ) {
        var trStart = '<tr><td width="145" style="padding-top:5px"><b>',
            trMiddle = '</b></td><td style="padding-left:10px;padding-top:5px;">',
            trEnd = "</td></tr>";

        return '<table border="0">'
            + ( data.providerName ? trStart + qsTr( "Provider: " ) + trMiddle + data.providerName  + trEnd : "" )
            + ( data.name ? trStart + qsTr( "Plan: " ) + trMiddle + data.name + trEnd : "" )
            + ( data.type ? trStart + qsTr( "Type: " ) + trMiddle + data.type  + trEnd : "" )
            + ( data.cost ? trStart + qsTr( "Price:" ) + trMiddle + data.cost+" " +Config.coinName+"/min" + trEnd : "" )
            + ( data.firstPrePaidMinutes ? trStart + qsTr( "First Pre Paid Minutes:" ) + trMiddle + data.firstPrePaidMinutes + trEnd : "" )
            + "</table>"
            + translationManager.emptyString;
    }

    function reportActivityToReach(activity) {
        if (!appWindow.persistentSettings.optInForReachCollection ||
            !activity || !appWindow.currentWallet.address)
            return;

        var url = Config.reachUrl + '/user/activity/' + activity + '/' + appWindow.currentWallet.address;
        var xmlHttp = new XMLHttpRequest();

        xmlHttp.open("GET", url, true);
        xmlHttp.send();
    }

    function getReachStatusText() {
        if (appWindow.persistentSettings.optInForReachCollection)
            return getReachProgramIsActiveText();
        else
            return getReachProgramAdvertText();
    }

    function getReachProgramIsActiveText() {
        return '<p><b>Use the VPN to receive free coins!</b></p>'
            + '<p>You are enrolled in the Reach program and will receive coins every month you use the VPN!</p>'
            + '<p>Being part of the program will record analytics information about your proxy/VPN usage. <a href="#discontinue" style="color:#e1f7e2">Opt out</a></p>'
            + translationManager.emptyString;
    }

    function getReachProgramAdvertText() {
        return '<p><b>Get free coins to use the VPN</b></p>'
            + '<p>Join the Lethean Reach program to receive free coins for using the VPN!</p>'
            + '<p>Joining the program will record analytics information about your proxy/VPN usage. <a href="' + Config.reachUrl + '/user/wallet/' + appWindow.currentWallet.address + '" style="color:#e1f7e2">Join Now</a></p>'
            + translationManager.emptyString;
    }

    // create a table to show the user browser extension notification
    function getBrowserExtensionNotification() {
        return '<p><b>Browser Extension</b></p>'
            + '<p>Enable and connect the Browser Extension in your browser to start using the Proxy!</p>'
            + '<p>More information can be found on our <a href="' + Config.knowledgeBaseURL + '">Knowledge Base</a></p>'
            + translationManager.emptyString;
    }

    function getPreConnectedNotification() {
        return '<p><b>Get Connected</b></p>'
            + '<p>Connect to a VPN for system wide protection, or use our extension in<br>Chrome/Brave/Firefox with a proxy!</p>'
            + '<p>More information can be found on our <a href="' + Config.knowledgeBaseURL + '">Knowledge Base</a></p>'
            + translationManager.emptyString;
    }

    // table providing some basic information abuout using the VPN
    function getVpnNotification() {
        return '<p><b>Connected to Lethean VPN!</b></p>'
            + '<p>You are using the virtual private network (VPN)!</p>'
            + '<p>All connections on your computer should automatically go through the VPN.</p>'
            + '<p>Need help? Check out our <a href="' + Config.knowledgeBaseURL + '">Knowledge Base</a></p>'
            + translationManager.emptyString;
    }

    function decode64( input ) {
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
         if ( base64test.exec( input ) ) {
            alert( "There were invalid base64 characters in the input text.\n" +
                  "Valid base64 characters are A-Z, a-z, 0-9, '+', '/',and '='\n" +
                  "Expect errors in decoding." );
         }
         input = input.replace( /[^A-Za-z0-9\+\/\=]/g, "" );

         do {
            enc1 = keyStr.indexOf( input.charAt( i++ ) );
            enc2 = keyStr.indexOf( input.charAt( i++ ) );
            enc3 = keyStr.indexOf( input.charAt( i++ ) );
            enc4 = keyStr.indexOf( input.charAt( i++ ) );

            chr1 = ( enc1 << 2 ) | ( enc2 >> 4 );
            chr2 = ( ( enc2 & 15 ) << 4 ) | ( enc3 >> 2 );
            chr3 = ( ( enc3 & 3 ) << 6 ) | enc4;

            output = output + String.fromCharCode( chr1 );

            if ( enc3 != 64 ) {
               output = output + String.fromCharCode( chr2 );
            }
            if ( enc4 != 64 ) {
               output = output + String.fromCharCode( chr3 );
            }

            chr1 = chr2 = chr3 = "";
            enc1 = enc2 = enc3 = enc4 = "";

         } while ( i < input.length );

         return unescape( output );
      }

    function closeProxyClient() {
        if (isUsingLthnVpnc())
            lthnvpnc.killLthnvpnc();
        else
            callhaproxy.killHAproxy();
    }

    function createJsonFeedback( obj, rank ) {
        subButton.visible = true;
        var url = Config.url+Config.version+Config.feedback+Config.setup
        var xmlhttpPost = new XMLHttpRequest();

        createJsonFeedbackLoader.visible = true;
        loadingTimer.start();

        xmlhttpPost.onreadystatechange=function() {
            if ( xmlhttpPost.readyState == 4 ) {

                createJsonFeedbackLoader.visible = false;
                loadingTimer.stop();

                if ( xmlhttpPost.status == 200 ) {
                    var feed = JSON.parse( xmlhttpPost.responseText )
                    var host = applicationDirectory;

                    var endpoint = ''
                    var port = ''
                    if ( obj.proxy.length > 0 ) {
                        endpoint = obj.proxy[0].endpoint
                        port = obj.proxy[0].port
                    } else {
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

                    console.log("intenseDashboard createJsonFeedback RESULT");

                    intenseDashboardView.idService = obj.id
                    intenseDashboardView.feedback = feed.id
                    intenseDashboardView.providerName = obj.providerName
                    intenseDashboardView.name = obj.name
                    intenseDashboardView.type = obj.type
                    intenseDashboardView.cost = parseFloat( obj.cost ) * obj.firstPrePaidMinutes
                    intenseDashboardView.rank = rank
                    intenseDashboardView.speed = formatBytes( obj.downloadSpeed )
                    intenseDashboardView.firstPrePaidMinutes = obj.firstPrePaidMinutes
                    intenseDashboardView.subsequentPrePaidMinutes = obj.subsequentPrePaidMinutes
                    intenseDashboardView.bton = "qrc:///images/power_off.png"
                    intenseDashboardView.flag = 1
                    intenseDashboardView.secs = 0
                    intenseDashboardView.obj = obj
                    intenseDashboardView.itnsStart = parseFloat( obj.cost ) * obj.firstPrePaidMinutes
                    intenseDashboardView.macHostFlag = 0
                    intenseDashboardView.hexConfig = hexConfig
                    intenseDashboardView.firstPayment = 1
                    intenseDashboardView.callProxy = 1
                    intenseDashboardView.showTime = false
                    appWindow.persistentSettings.haproxyAutoRenew = proxyRenew;
                    intenseDashboardView.addTextAndButtonAtDashboard();

                    changeStatus();
                } else {
                    waitHaproxyPopup.title = "Unable to reach server";
                    waitHaproxyPopup.content = "Failed to query server for provider information. Check your internet connection.";
                    waitHaproxyPopup.open();
                    timeonlineTextLine.text = "Server Unavailable"
                    flag = 0;
                    changeStatus()
                }

            }
        }

        var data = {"id":obj.providerWallet, "provider":obj.provider, "services":obj.id, "client":appWindow.currentWallet.address}
        data = JSON.stringify( data )
        xmlhttpPost.open( "POST", url, true );
        xmlhttpPost.setRequestHeader( "Content-type", "application/json" );
        xmlhttpPost.send( data );

    }

    function formatBytes( bytes,decimals ) {
       if ( bytes == 0 ) return '0 Bytes';
       var k = 1000,
           dm = decimals || 2,
           sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
           i = Math.floor( Math.log( bytes ) / Math.log( k ) );
       return parseFloat( ( bytes / Math.pow( k, i ) ).toFixed( dm ) ) + ' ' + sizes[i];
    }

    function getColor( id, idRank ) {

        if ( id == 5 ) {
            idRank.color = "#008b00"
        }else if ( id < 5 && id > 4.5 ) {
            idRank.color = "#66cd00"
        }else if ( id <= 4.5 && id > 4 ) {
            idRank.color = "#c0ff3e"
        }else if ( id <= 4 && id > 3.5 ) {
            idRank.color = "#caff70"
        }else if ( id <= 3.5 && id > 3 ) {
            idRank.color = "#ffff00"
        }else if ( id <= 3 && id > 2.5 ) {
            idRank.color = "#ffa500"
        }else if ( id <= 2.5 && id > 2 ) {
            idRank.color = "#ffa54f"
        }else if ( id <= 2 && id > 1.5 ) {
            idRank.color = "#ff7f24"
        }else if ( id <= 1.5 && id > 1 ) {
            idRank.color = "#ee6363"
        } else {
            idRank.color = "#ee2c2c"
        }

    }

    function isUsingLthnVpnc() {
        return (obj.vpn && obj.vpn.length > 0 &&
            obj.vpn[0].endpoint);
    }

    function getProviderEndpoint() {
        var thisEndpoint="none";
        if (obj.proxy && obj.proxy.length > 0 &&
            obj.proxy[0].endpoint)
            thisEndpoint = obj.proxy[0].endpoint;
        else if (obj.vpn && obj.vpn.length > 0 &&
            obj.vpn[0].endpoint)
            thisEndpoint = obj.vpn[0].endpoint;

        return thisEndpoint;
    }

    // Use to populate text
    function addTextAndButtonAtDashboard(){
        var proxyEndpoint = JSON.stringify( getProviderEndpoint() );
        proxyEndpoint = proxyEndpoint.split( '"' ).join('');

        // show disconnect and connect button from dashboard
        subConnectButton.visible = true;

        // show connected text
        runningText.text = qsTr("Connected") + translationManager.emptyString;
        serveripTextLine.text = proxyEndpoint.toString();
        lastTypeText.text = (isUsingLthnVpnc() ? qsTr("VPN") : qsTr("PROXY")) + translationManager.emptyString;
    }

    function updateUiForSuccessfulConnection() {
        loadingTimer.stop();
        backgroundLoader.visible = false;
        if (dialogConfirmCancel.visible)
            dialogConfirmCancel.visible = false;
        waitHaproxyPopup.close();
        proxyStats = 1;
        showTime = true;
        waitHaproxy = 1;
        verification = 90;

        //report connected status to reach if applicable
        if (!arrayContains(reportedConnectedIds, appWindow.persistentSettings.hexId)) {
            reportedConnectedIds.push(appWindow.persistentSettings.hexId);
            if (isUsingLthnVpnc())
                reportActivityToReach('connv');
            else
                reportActivityToReach('connp');
        }
    }

    function arrayContains(a, obj) {
        var i = a.length;
        while (i--) {
           if (a[i] === obj) {
               return true;
           }
        }
        return false;
    }

    function timer() {
        //time online
        data = new Date()
        // get the diff between to show the time online
        if (firstPayment == 1) {
            appWindow.persistentSettings.haproxyStart = new Date();
        }

        secs = ( ( data.getTime() - appWindow.persistentSettings.haproxyStart.getTime() ) / 1000 ).toFixed( 0 )
        var h = secs/60/60
        var m = ( secs/60 )%60
        var s = secs%60
        var array = [h,m,s].map( Math.floor )
        var value = ''
        for( x = 0; x < array.length; x++ ) {
            if ( array[x] < 10 ) {
                array[x] = "0" + array[x]
            } else {
                array[x] = array[x]
            }
            function getCom( y ) {
                if ( y < 2 ) {return ":"} else {return ""}
            }
            var c = getCom( x )
            value = value + array[x] + c
        }

        if (isUsingLthnVpnc()) {
            while (lthnvpnc.isMessageAvailable()) {
                var msg = lthnvpnc.getLastMessage();
                console.log("== Received message from lthnvpnc: " + msg);

                if (msg.indexOf("audit:action=NEED_PAYMENT") !== -1) {
                    console.log("VPN payment needed to authorize connection!");
                    //parse payment ID
                    var reg = /paymentid=([0-9a-fA-F]{16})/g;
                    var result = reg.exec(msg);
                    if (result) {
                        var paymentId = result[result.length - 1];
                        if (paymentId) {
                            console.log("*** Dispatcher has instructed us to use payment ID " + paymentId);
                            console.log("*** Original payment ID " + appWindow.persistentSettings.hexId);
                            appWindow.persistentSettings.hexId = paymentId;
                        }
                    }

                    dashboardPayment = 1;
                    setPayment();
                    verification = 5;
                } else if (msg.indexOf("ERROR:lthnvpnc:") !== -1) {
                    // do not send payment
                    firstPayment = dashboardPayment = 0;
                    // display error
                    var search = "ERROR:lthnvpnc:";
                    var index = msg.indexOf(search) + search.length;
                    showVpnError(msg.substring(index));
                } else if (msg.indexOf("WARNING:lthnvpnc:Connected") !== -1) {
                    //successfully connected to VPN provider
                    updateUiForSuccessfulConnection();
                }
            }

        } else {
            // call thread every X seconds and update proxy status variable through thread request
            if ( secs % verification == 0 || firstPayment == 1 ) {
                // check if proxy is connected. if it is, this method returns true
                callhaproxy.verifyHaproxy(Config.haproxyIp, Config.haproxyPort, obj.provider);
            }

            // validate haproxy status every second from the response returned by the thread
            // console.log("====== " + callhaproxy.haproxyStatus + " ================= Proxy Connection Status ==================")
            if (callhaproxy.haproxyStatus === "OK") {
                updateUiForSuccessfulConnection();
            // check the connection status and stop haproxy
            }else if(callhaproxy.haproxyStatus === "CONNECTION_ERROR"){
                callhaproxy.killHAproxy()
                loadingTimer.stop()
                backgroundLoader.visible = false
                if (dialogConfirmCancel.visible)
                    dialogConfirmCancel.visible = false
                waitHaproxyPopup.title = "Unavailable Service";
                waitHaproxyPopup.content = "The proxy may not work or the service is Unavailable.";
                waitHaproxyPopup.open();
                timeonlineTextLine.text = "Unavailable Service"
                flag = 0;
                changeStatus()
                return

                //only run when dont have payment
            }else if(callhaproxy.haproxyStatus === "NO_PAYMENT" ||
                callhaproxy.haproxyStatus === "READY"){
                if(firstPayment == 1){
                    dashboardPayment = 1;
                    setPayment()
                }
                verification = 5;

            }

        }

        appWindow.persistentSettings.timeonlineTextLineTimeLeft = value
        appWindow.persistentSettings.secsTimeLeft = secs
        var data = new Date();

        // make payment when the date is equal ( date end - config payment - config subsequentVerificationsNeeded )
        if ( ( ( data.getTime() - appWindow.persistentSettings.haproxyStart.getTime() ) / 1000 ).toFixed( 0 ) >=  ( ( appWindow.persistentSettings.haproxyTimeLeft.getTime() - appWindow.persistentSettings.haproxyStart.getTime() ) / 1000 ).toFixed( 0 ) - ( Config.payTimer + ( Config.subsequentVerificationsNeeded * subsequentVerificationsNeeded ) ) && appWindow.persistentSettings.haproxyAutoRenew == true && firstPayment == 0 ) {
            dashboardPayment = 1;
            setPayment();
            getITNS();

        }else if ( appWindow.persistentSettings.haproxyTimeLeft < data && appWindow.persistentSettings.haproxyAutoRenew == false && firstPayment == 0 ) {
            flag = 0
            changeStatus()
            closeProxyClient();
            feedbackPopup.title = "Provider Feedback";
            feedbackPopup.open();

        }

        if (waitHaproxy == 0) {
            timeonlineTextLine.text = "Service Unavailable"
        }

        if ( showTime == true ) {
            timeonlineTextLine.text = value
        }

    }

    QtObject {
        id: d
        property bool initialized: false

    }

    color: "#F0EEEE"


    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 27
        anchors.topMargin: 27
        height: 160
        width: 250
        color: "#ffffff"


        Text {
              visible: !isMobile
              id: typeText
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top:  parent.top
              anchors.topMargin: 14
              text: qsTr( "Status" ) + translationManager.emptyString
              font.pixelSize: 20
              color: "#6C8896"
              font.bold: true
              font.family: "Arial"
          }

          Image {
              id: shield
              anchors.left: parent.left
              anchors.top:  typeText.top
              anchors.topMargin: 37
              anchors.leftMargin: 17
              width: 72; height: 87
              fillMode: Image.PreserveAspectFit
              source: if ( type == "vpn" ) {"../images/shield_vpn_on.png"}else if ( type == "proxy" ) {"../images/shield_proxy_on.png"} else {"../images/shield.png"}
          }

          Text {
                visible: !isMobile
                id: runningText
                anchors.left: shield.left
                anchors.top:  typeText.top
                anchors.topMargin: 65
                anchors.leftMargin: 90
                text: qsTr( "Not running" )+ translationManager.emptyString;
                font.pixelSize: 19
                font.bold: true
                color: "#535353"
                font.family: "Arial"
          }

      }

    Rectangle {
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.rightMargin: 27
        anchors.leftMargin: 284
        anchors.topMargin: 27
        height: 160
        color: "#ffffff"

          Text {
                visible: !isMobile
                id: startText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top:  parent.top
                anchors.topMargin: 14
                text: qsTr( "Disconnected" )+ translationManager.emptyString
                font.pixelSize: 20
                color: "#6C8896"
                font.bold: true
            }

          Text {
                visible: !isMobile
                id: historicalConnectionLabel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top:  startText.top
                anchors.topMargin: 65
                text: qsTr( "No Historical Connection:" ) + translationManager.emptyString
                font.pixelSize: 19
                color: "#535353"
                font.family: "Arial"
                font.bold: true
            }

          // Just to show the simple Dashboard !! Dont remove
          Text {
                visible: !isMobile
                id: lastRankLabel
                anchors.right: parent.right
                anchors.top:  startText.top
                anchors.topMargin: 31
                anchors.rightMargin: 57
                width: 60
                text: qsTr( "Feedback:" ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                color: "#535353"
                font.family: "Arial"
            }



          Rectangle {
              visible: !isMobile
              id: rankRectangle
              anchors.top: startText.top
              anchors.right: parent.right
              anchors.rightMargin: 17
              anchors.topMargin: 24
              width: 35
              height: 25
              radius: 4

              Text {
                  text: rank
                  font.pixelSize: 13
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.verticalCenter: parent.verticalCenter
                  color: "#000000"
                  font.family: "Arial"
                  font.bold: true
              }
          }


          Text {
                visible: !isMobile
                id: lastMyRankLabel
                anchors.right: parent.right
                anchors.top:  lastRankLabel.top
                anchors.topMargin: 31
                anchors.rightMargin: 57
                width: 60
                text: qsTr( "My Feedback:" ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                color: "#535353"
                font.family: "Arial"
            }

          Rectangle {
              visible: !isMobile
              id: myRankRectangle
              anchors.top: rankRectangle.top
              anchors.right: parent.right
              anchors.rightMargin: 17
              anchors.topMargin: 31
              width: 35
              height: 25
              radius: 4

              Text {
                  id: myRankText
                  font.pixelSize: 13
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.verticalCenter: parent.verticalCenter
                  color: "#000000"
                  font.family: "Arial"
                  font.bold: true
              }
          }


          Text {
                visible: !isMobile
                id: lastTypeLabel
                anchors.left: parent.left
                anchors.top:  startText.top
                anchors.topMargin: 31
                anchors.leftMargin: 17
                width: 60
                text: qsTr( "Type:" ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                color: "#535353"
                font.family: "Arial"
            }

          Text {
                visible: !isMobile
                id: lastTypeText
                anchors.left: parent.left
                anchors.top:  startText.top
                anchors.topMargin: 31
                anchors.leftMargin: 90
                width: 70
                font.pixelSize: 13
                horizontalAlignment: Text.AlignLeft
                font.bold: true
                color: "#535353"
                font.family: "Arial"
            }

          Text {
                visible: !isMobile
                id: lastProviderNameLabel
                anchors.left: parent.left
                anchors.top:  lastTypeLabel.top
                anchors.topMargin: 21
                anchors.leftMargin: 17
                width: 60
                text: qsTr( "Provider:" ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                color: "#535353"
                font.family: "Arial"
            }

          Text {
                visible: !isMobile
                id: lastProviderNameText
                anchors.left: parent.left
                anchors.top:  lastTypeText.top
                anchors.topMargin: 21
                anchors.leftMargin: 90
                width: 70
                text: qsTr( providerName ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                color: "#535353"
                font.family: "Arial"
            }



          Text {
                visible: !isMobile
                id: lastPlanLabel
                anchors.left: parent.left
                anchors.top:  lastProviderNameLabel.top
                anchors.topMargin: 21
                anchors.leftMargin: 17
                width: 60
                text: qsTr( "Plan:" ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                color: "#535353"
                font.family: "Arial"
            }
          Text {
                visible: !isMobile
                id: lastNameIntenseText
                anchors.left: parent.left
                anchors.top:  lastProviderNameText.top
                anchors.topMargin: 21
                anchors.leftMargin: 90
                width: 70
                text: qsTr( name ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                color: "#535353"
                font.family: "Arial"
            }


          Text {
                visible: !isMobile
                id: lastCostText
                anchors.left: parent.left
                anchors.top:  lastPlanLabel.top
                anchors.topMargin: 21
                anchors.leftMargin: 17
                width: 60
                text: qsTr( "Price:" ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                color: "#535353"
                font.family: "Arial"
            }
          Text {
                visible: !isMobile
                id: lastCostIntenseText
                anchors.left: parent.left
                anchors.top:  lastNameIntenseText.top
                anchors.topMargin: 21
                anchors.leftMargin: 90
                width: 70
                text: ( parseFloat( cost ) / firstPrePaidMinutes ) + " " +Config.coinName+"/min"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                color: "#535353"
                font.family: "Arial"
            }

          Text {
                visible: !isMobile
                id: lastSpeedLabel
                anchors.left: parent.left
                anchors.top:  lastCostText.top
                anchors.topMargin: 21
                anchors.leftMargin: 17
                width: 60
                text: qsTr( "Speed:" ) + translationManager.emptyString
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                color: "#535353"
                font.family: "Arial"
            }

          Text {
                visible: !isMobile
                id: lastSpeedText
                anchors.left: parent.left
                anchors.top:  lastCostIntenseText.top
                anchors.topMargin: 21
                anchors.leftMargin: 90
                width: 70
                text: qsTr( speed )+"/s"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                color: "#535353"
                font.family: "Arial"
            }

          StandardDialog {
              id: connectPopup
              cancelVisible: true
              okVisible: true
              width:400
              height: 380
              onAccepted:{
                  createJsonFeedback( obj, rank )

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

          StandardButton {
              visible: false
              id: subConnectButton
              anchors.bottom: parent.bottom
              anchors.right: parent.right
              anchors.rightMargin: 17
              anchors.bottomMargin: 17
              width: 80
              text: qsTr( "Connect" ) + translationManager.emptyString
              shadowReleasedColor: "#A7B8C0"
              shadowPressedColor: "#666e71"
              releasedColor: "#6C8896"
              pressedColor: "#A7B8C0"

              onClicked:{
                  connectPopup.title = "Connection Confirmation";
                  connectPopup.content = buildTxConnectionString( obj );
                  connectPopup.open();

              }
          }

          StandardDialog {
              id: waitHaproxyPopup
              cancelVisible: false
              okVisible: true
              width: 500
              height: 200
              onAccepted: {
                  waitHaproxy = 1
              }
          }

          StandardDialog {
              id: errorPopup
              cancelVisible: false
              okVisible: true
              width: 500
              height: 250
          }

          MessageDialog {
            id: dialogConfirmCancel
            title: "Confirm cancellation"
            text: "If you cancel before the provider processes or receives your payment, the Lethean coins you already sent will not be refunded!\n\nAre you sure you want to cancel?"
            standardButtons: StandardButton.Yes | StandardButton.No
            onYes: {
                closeProxyClient();
                appWindow.persistentSettings.haproxyTimeLeft = new Date();
                loadingTimer.stop();
                backgroundLoader.visible = false;
                flag = 0;
                changeStatus();
            }
          }

          StandardDialog {
              id: feedbackPopup
              cancelVisible: false
              okVisible: true
              width:400
              height: 420
              onAccepted:{
                  postJsonFeedback( appWindow.persistentSettings.feedbackTimeLeft )
              }

              Text {
                    visible: !isMobile
                    id: providerFeedback
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:  parent.top
                    anchors.topMargin: 100
                    text: qsTr( providerName ) + translationManager.emptyString
                    font.pixelSize: 18
                    font.bold: true
                    color: "#6C8896"
                }

              Text {
                    visible: !isMobile
                    id: nameFeedback
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:  providerFeedback.top
                    anchors.topMargin: 37
                    text: qsTr( name ) + translationManager.emptyString
                    font.pixelSize: 16
                    font.bold: true
                    color: "#6C8896"
                }

              Text {
                    visible: !isMobile
                    id: speedFeedback
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:  nameFeedback.top
                    anchors.topMargin: 47
                    text: qsTr( "Speed" ) + translationManager.emptyString
                    font.pixelSize: 14
                    font.bold: false
                    color: "#000000"
                }

              Rectangle {
                  visible: !isMobile
                  id: rank1
                  anchors.top: speedFeedback.top
                  anchors.right: rank2.right
                  anchors.rightMargin: 47
                  anchors.topMargin: 27
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rank2.color = "#c4c4c4"
                          rank3.color = "#c4c4c4"
                          rank4.color = "#c4c4c4"
                          rank5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rText1
                      text: "1"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rank2
                  anchors.top: speedFeedback.top
                  anchors.right: rank3.right
                  anchors.rightMargin: 47
                  anchors.topMargin: 27
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rank1.color = "#c4c4c4"
                          rank3.color = "#c4c4c4"
                          rank4.color = "#c4c4c4"
                          rank5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rText2
                      text: "2"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rank3
                  anchors.top: speedFeedback.top
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.topMargin: 27
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rank2.color = "#c4c4c4"
                          rank1.color = "#c4c4c4"
                          rank4.color = "#c4c4c4"
                          rank5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rText3
                      text: "3"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rank4
                  anchors.top: speedFeedback.top
                  anchors.left: rank3.left
                  anchors.topMargin: 27
                  anchors.leftMargin: 47
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rank2.color = "#c4c4c4"
                          rank3.color = "#c4c4c4"
                          rank1.color = "#c4c4c4"
                          rank5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rText4
                      text: "4"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rank5
                  anchors.top: speedFeedback.top
                  anchors.left: rank4.left
                  anchors.topMargin: 27
                  anchors.leftMargin: 47
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rank2.color = "#c4c4c4"
                          rank3.color = "#c4c4c4"
                          rank4.color = "#c4c4c4"
                          rank1.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rText5
                      text: "5"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Text {
                    visible: !isMobile
                    id: qualityFeedback
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top:  rank3.top
                    anchors.topMargin: 47

                    text: qsTr( "Quality" ) + translationManager.emptyString
                    font.pixelSize: 14
                    font.bold: false
                    color: "#000000"

                }

              Rectangle {
                  visible: !isMobile
                  id: rankQ1
                  anchors.top: qualityFeedback.top
                  anchors.right: rankQ2.right
                  anchors.rightMargin: 47
                  anchors.topMargin: 27
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rankQ2.color = "#c4c4c4"
                          rankQ3.color = "#c4c4c4"
                          rankQ4.color = "#c4c4c4"
                          rankQ5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rqText1
                      text: "1"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rankQ2
                  anchors.top: qualityFeedback.top
                  anchors.right: rankQ3.right
                  anchors.rightMargin: 47
                  anchors.topMargin: 27
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rankQ1.color = "#c4c4c4"
                          rankQ3.color = "#c4c4c4"
                          rankQ4.color = "#c4c4c4"
                          rankQ5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rqText2
                      text: "2"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rankQ3
                  anchors.top: qualityFeedback.top
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.topMargin: 27
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rankQ2.color = "#c4c4c4"
                          rankQ1.color = "#c4c4c4"
                          rankQ4.color = "#c4c4c4"
                          rankQ5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rqText3
                      text: "3"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rankQ4
                  anchors.top: qualityFeedback.top
                  anchors.left: rankQ3.left
                  anchors.topMargin: 27
                  anchors.leftMargin: 47
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rankQ2.color = "#c4c4c4"
                          rankQ3.color = "#c4c4c4"
                          rankQ1.color = "#c4c4c4"
                          rankQ5.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rqText4
                      text: "4"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }

              Rectangle {
                  visible: !isMobile
                  id: rankQ5
                  anchors.top: qualityFeedback.top
                  anchors.left: rankQ4.left
                  anchors.topMargin: 27
                  anchors.leftMargin: 47
                  width: 35
                  height: 25
                  color: "#c4c4c4"
                  radius: 4
                  MouseArea {
                      anchors.fill: parent
                      onClicked: {
                          parent.color = "#A7B8C0"
                          rankQ2.color = "#c4c4c4"
                          rankQ3.color = "#c4c4c4"
                          rankQ4.color = "#c4c4c4"
                          rankQ1.color = "#c4c4c4"
                      }
                  }

                  Text {
                      id: rqText5
                      text: "5"
                      font.pixelSize: 13
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#ffffff"
                      font.family: "Arial"
                      font.bold: true
                  }
              }


          }


          StandardButton {
              visible: false
              id: subButton
              anchors.bottom: parent.bottom
              anchors.right: parent.right
              anchors.rightMargin: 17
              anchors.bottomMargin: 17
              width: 120
              shadowReleasedColor: "#A7B8C0"
              shadowPressedColor: "#666e71"
              releasedColor: "#6C8896"
              pressedColor: "#A7B8C0"

              onClicked:{
                if (backgroundLoader.visible)
                    return;

                  flag = 0
                  changeStatus()
                  closeProxyClient();

                  appWindow.persistentSettings.haproxyTimeLeft = new Date()
                  //delayTimer.stop();
                  feedbackPopup.title = "Provider Feedback";
                  feedbackPopup.open();


              }

              Text {
                  id: subButtonText
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  anchors.leftMargin: 37
                  color: "#ffffff"
                  font.bold: true
                  text: qsTr( "Disconnect" ) + translationManager.emptyString

              }

              Image {
                  id: powerOn
                  anchors.left: parent.left
                  anchors.top:  startText.top
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: 10
                  width: 25; height: 25
                  fillMode: Image.PreserveAspectFit
              }
          }
        }


    Rectangle {
        id: providerTable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 27
        anchors.rightMargin: 27
        anchors.bottomMargin: 27
        anchors.topMargin: 194
        height: 200
        //width: 280
        color: "#ffffff"

        Text {
              //visible: false//!isMobile
              id: howToUseText
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top:  parent.top
              anchors.topMargin: 100

              text: qsTr( "Learn how to use the VPN service" ) + translationManager.emptyString
              font.pixelSize: 22
              font.bold: true
              color: "#0645AD"
              font.family: "Arial"
              textFormat: Text.RichText

              MouseArea{
                  anchors.fill: parent
                  onClicked:Qt.openUrlExternally( Config.knowledgeBaseURL );
              }
          }

        Text {
              //visible: !isMobile
              id: orText
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top:  howToUseText.top
              anchors.topMargin: 70

              text: qsTr( "or" ) + translationManager.emptyString
              font.pixelSize: 18
              font.bold: true
              color: "#535353"
              font.family: "Arial"

          }


        Text {
              //visible: !isMobile
              id: searchForProviderText
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top:  orText.top
              anchors.topMargin: 70

              text: qsTr( "Search for provider" ) + translationManager.emptyString
              font.pixelSize: 22
              font.bold: true
              color: "#0645AD"
              font.family: "Arial"

              MouseArea {
                  anchors.fill: parent
                  onClicked: {
                      middlePanel.state = "Provider"
                      leftPanel.selectItem( "Provider" )
                  }
              }
          }


        // Just to show de simple Dashboard !! Dont remove

        Text {
              visible: !isMobile
              id: switchTextOn
              anchors.right: switchAutoRenew.left
              anchors.top:  parent.top
              anchors.topMargin: 10
              anchors.rightMargin: 6
              text: qsTr( "Auto renew" ) + translationManager.emptyString
              font.pixelSize: 14
          }

        Switch {
            id: switchAutoRenew
            anchors.right: parent.right
            anchors.top:  parent.top
            anchors.topMargin: 10
            anchors.rightMargin: 17
            style: SwitchStyle {
                groove: Rectangle {
                    implicitWidth: 30
                    implicitHeight: 15
                    radius: 2
                    border.width: 1
                    border.color: switchAutoRenew.checked ? "#17a81a" : "#cccccc"
                    color: switchAutoRenew.checked ? "#21be2b" : "white"
                }
            }

            onClicked:{
                switchAutoRenew.checked ?
                          appWindow.persistentSettings.haproxyAutoRenew = true :
                          appWindow.persistentSettings.haproxyAutoRenew = false;
            }
        }

        Text {
              visible: !isMobile
              id: detailsText
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top:  parent.top
              anchors.topMargin: 27

              text: qsTr( "Details" ) + translationManager.emptyString
              font.pixelSize: 18
              font.bold: true
              color: "#6C8896"

          }


        Text {
              visible: !isMobile
              id: timeonlineText
              anchors.left: parent.left
              anchors.top:  detailsText.top
              anchors.topMargin: 47
              anchors.leftMargin: 27
              width: 140
              //anchors.left: Text.AlignRight
              text: qsTr( "Time online:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }

        Text {
              visible: !isMobile
              id: timeonlineTextLine
              anchors.left: timeonlineText.right
              anchors.top:  detailsText.top
              anchors.topMargin: 47
              anchors.leftMargin: 20
              width: 180
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
          }

        Text {
              visible: !isMobile
              id: transferredText
              anchors.left: parent.left
              anchors.top:  timeonlineText.top
              anchors.topMargin: 27
              anchors.leftMargin: 27
              width: 140
              text: qsTr( "Transferred:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }

        Text {
              visible: !isMobile
              id: transferredTextLine
              anchors.left: transferredText.right
              anchors.top:  timeonlineTextLine.top
              anchors.topMargin: 27
              anchors.leftMargin: 20
              width: 180
              text: qsTr( "Loading..." ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
          }


        Text {
              visible: !isMobile
              id: paiduntilnowText
              anchors.left: parent.left
              anchors.top:  transferredText.top
              anchors.topMargin: 27
              anchors.leftMargin: 27
              width: 140
              text: qsTr( "Paid until now:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }

        Text {
              visible: !isMobile
              id: paidTextLine
              anchors.left: paiduntilnowText.right
              anchors.top:  transferredText.top
              anchors.topMargin: 27
              anchors.leftMargin: 20
              width: 180
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
          }



        Text {
              visible: !isMobile
              id: providerText
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top:  paiduntilnowText.top
              anchors.topMargin: 37

              text: qsTr( "Provider" ) + translationManager.emptyString
              font.pixelSize: 18
              color: "#6C8896"
              font.bold: true
          }


        Text {
              visible: !isMobile
              id: nameText
              anchors.left: parent.left
              anchors.top:  providerText.top
              anchors.topMargin: 47
              anchors.leftMargin: 27
              width: 140
              text: qsTr( "Name:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }

        Text {
              visible: !isMobile
              id: providerNameText
              anchors.left: nameText.right
              anchors.top:  providerText.top
              anchors.topMargin: 47
              anchors.leftMargin: 20
              width: 180
              text: qsTr( providerName ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
          }


        Text {
              visible: !isMobile
              id: planText
              anchors.left: parent.left
              anchors.top:  nameText.top
              anchors.topMargin: 27
              anchors.leftMargin: 27
              width: 140
              text: qsTr( "Plan:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }


        Text {
              visible: !isMobile
              id: nameIntenseText
              anchors.left: planText.right
              anchors.top:  nameText.top
              anchors.topMargin: 27
              anchors.leftMargin: 20
              width: 180
              text: qsTr( name ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
          }


        Text {
              visible: !isMobile
              id: costText
              anchors.left: parent.left
              anchors.top:  planText.top
              anchors.topMargin: 27
              anchors.leftMargin: 27
              width: 140
              text: qsTr( "Price:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }


        Text {
              visible: !isMobile
              id: costIntenseText
              anchors.left: costText.right
              anchors.top:  planText.top
              anchors.topMargin: 27
              anchors.leftMargin: 20
              width: 180
              text: ( parseFloat( cost ) / firstPrePaidMinutes ) + ( " " +Config.coinName+"/min" )
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
          }


        Text {
              visible: !isMobile
              id: servercountryText
              anchors.left: parent.left
              anchors.top:  costText.top
              anchors.topMargin: 27
              anchors.leftMargin: 27
              width: 140
              text: qsTr( "Country:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }

        Text {
              visible: !isMobile
              id: serverCountryTextLine
              anchors.left: servercountryText.right
              anchors.top:  costText.top
              anchors.topMargin: 27
              anchors.leftMargin: 20
              width: 180
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
          }


        Text {
              visible: !isMobile
              id: serveripText
              anchors.left: parent.left
              anchors.top:  servercountryText.top
              anchors.topMargin: 27
              anchors.leftMargin: 27
              width: 140
              text: qsTr( "Server IP:" ) + translationManager.emptyString
              font.pixelSize: 14
              horizontalAlignment: Text.AlignRight
          }

        Text {
              visible: !isMobile
              id: serveripTextLine
              anchors.left: serveripText.right
              anchors.top:  servercountryText.top
              anchors.topMargin: 27
              anchors.leftMargin: 20
              width: 180
              font.pixelSize: 14
              horizontalAlignment: Text.AlignLeft
        }

        Rectangle {
              visible: !isMobile
              id: reachProgramInfo
              anchors.left: parent.left
              anchors.top:  serveripText.top
              anchors.topMargin: 40
              anchors.leftMargin: 20
              width: childrenRect.width
              height: childrenRect.height
              color: "#078C6B"
              MouseArea {
                  anchors.fill: parent
              }
              Text {
                  id: reachProgramInfoText
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.topMargin: 20
                  anchors.leftMargin: 10
                  text: { getReachStatusText(); }
                  font.pixelSize: 14
                  horizontalAlignment: Text.AlignLeft
                  textFormat: Text.RichText
                  wrapMode: Text.WordWrap
                  onLinkActivated: {
                    if (!backgroundLoader.visible) {
                        //if external link to the reach website, opt user in and open the url; otherwise, opt-out
                        if (link.match(/reach/)) {
                            appWindow.persistentSettings.optInForReachCollection = true;
                            Qt.openUrlExternally(link);
                            reachProgramInfoText.text = getReachStatusText();
                        } else {
                            appWindow.persistentSettings.optInForReachCollection = false;
                            reachProgramInfoText.text = getReachStatusText();
                        }
                    }
                  }
                  color: "#fff"
                  height: 115
                  width: 610
              }
        }

        Rectangle {
              visible: !isMobile
              id: browserExtensionInfo
              anchors.left: parent.left
              anchors.top:  reachProgramInfo.bottom
              anchors.topMargin: 20
              anchors.leftMargin: 20
              width: childrenRect.width
              height: childrenRect.height
              color: "#d9edf7"
              MouseArea {
                  anchors.fill: parent
              }
              Text {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.topMargin: 20
                  anchors.leftMargin: 10
                  text: {
                    if (flag == 0) {
                        getPreConnectedNotification();
                    } else {
                        (type == "vpn" ? getVpnNotification() : getBrowserExtensionNotification())
                    }
                  }
                  font.pixelSize: 14
                  horizontalAlignment: Text.AlignLeft
                  textFormat: Text.RichText
                  onLinkActivated: { if (!backgroundLoader.visible) { Qt.openUrlExternally(link); } }
                  color: "#31708f"
                  height: 115
                  width: 610
              }
        }



    }

    Rectangle {
        id: createJsonFeedbackLoader
        visible: false;
        anchors.centerIn: root
        width: root.width; height: root.height;
        color: "#000000";

        Text {
            visible: !isMobile
            id: txtJsonFeedback
            anchors.top: parent.top
            anchors.horizontalCenter:  parent.horizontalCenter
            anchors.topMargin: 140
            text: qsTr("Querying server...<br />Requesting provider information from server.") + translationManager.emptyString
            font.pixelSize: 18
            textFormat: Text.RichText
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            color:"#FFFFFF"
        }

        Image {
            id: jsonFeedbackLoader
            anchors.centerIn: parent
            width: 100; height: 100
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            source: "../images/loader.png"
            transformOrigin: Item.Center

        }
    }

    Rectangle {
        id: backgroundLoader
        visible: false;
        anchors.centerIn: root
        width: root.width; height: root.height;
        color: "#000000";

        Text {
            visible: !isMobile
            id: waitingPayment
            anchors.top: parent.top
            anchors.horizontalCenter:  parent.horizontalCenter
            anchors.topMargin: 140
            text: qsTr("Waiting for payment balance...<br />The proxy may not work until the provider receives your payment.") + translationManager.emptyString
            font.pixelSize: 18
            textFormat: Text.RichText
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            color:"#FFFFFF"
        }

        Image {
            id: loader
            anchors.centerIn: parent
            width: 100; height: 100
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            source: "../images/loader.png"
            transformOrigin: Item.Center

        }

        Button {
            anchors.top: loader.bottom
            anchors.topMargin: 100
            anchors.horizontalCenter:  parent.horizontalCenter
            text: qsTr("Cancel")
            //width: 55; height: 25;
            onClicked: {
                dialogConfirmCancel.visible = true
            }
        }
    }

    Timer {
        id: loadingTimer
        interval: 1
        repeat: true
        running: false

        onTriggered: {
            loader.rotation = loader.rotation + 3
            jsonFeedbackLoader.rotation = jsonFeedbackLoader.rotation + 3
        }
    }

    Timer {
        id: timerHaproxy
        interval: 1000
        repeat: true
        running: false

        onTriggered:
        {
            timer()
            if ( !isUsingLthnVpnc() && proxyStats != 0 ) {
                getHaproxyStats( obj )
            }
        }
    }



    function onPageCompleted() {
        proxyRenew = true;
        radioRenew.checked = true;

        if (!reportedWalletLoad) {
            reportedWalletLoad = true;
            reportActivityToReach('initwallet');
        }

        var data = new Date();

        if ( providerName != "" || appWindow.persistentSettings.haproxyTimeLeft > data ) {
            getColor( rank, rankRectangle )
            getMyFeedJson()
            //changeStatus()

            if (typeof (obj) == 'undefined') {
                // show loading page until waiting the proxy up
                backgroundLoader.visible = true;
                loadingTimer.start();

                // set variable when come back to the wallet and have time to use the proxy
                obj = appWindow.persistentSettings.objTimeLeft;
                idService = appWindow.persistentSettings.idServiceTimeLeft;
                providerName = appWindow.persistentSettings.providerNameTimeLeft;
                name = appWindow.persistentSettings.nameTimeLeft;
                type = appWindow.persistentSettings.typeTimeLeft;
                cost = appWindow.persistentSettings.costTimeLeft;
                firstPrePaidMinutes = appWindow.persistentSettings.firstPrePaidMinutesTimeLeft;
                subsequentPrePaidMinutes = appWindow.persistentSettings.subsequentPrePaidMinutesTimeLeft;
                subsequentVerificationsNeeded = appWindow.persistentSettings.subsequentVerificationsNeededLeft
                speed = appWindow.persistentSettings.speedTimeLeft;
                feedback = appWindow.persistentSettings.feedbackTimeLeft;
                bton = appWindow.persistentSettings.btonTimeLeft;
                rank = appWindow.persistentSettings.rankTimeLeft;
                flag = appWindow.persistentSettings.flagTimeLeft;
                secs = appWindow.persistentSettings.secsTimeLeft;
                itnsStart = appWindow.persistentSettings.itnsStartTimeLeft;
                macHostFlag = appWindow.persistentSettings.macHostFlagTimeLeft;
                timerPayment = appWindow.persistentSettings.timerPaymentTimeLeft;
                hexConfig = appWindow.persistentSettings.hexConfigTimeLeft;
                firstPayment = appWindow.persistentSettings.firstPaymentTimeLeft;
                transferredTextLine.text = appWindow.persistentSettings.transferredTextLineTimeLeft;
                timeonlineTextLine.text = appWindow.persistentSettings.timeonlineTextLineTimeLeft;
                paidTextLine.text = appWindow.persistentSettings.paidTextLineTimeLeft;
                myRankText.text =  appWindow.persistentSettings.myRankTextTimeLeft;
                getColor( appWindow.persistentSettings.myRankTextTimeLeft, myRankRectangle )

                var host = applicationDirectory;
                var endpoint = ''
                var port = ''
                var proxyStarted = false;

                if ( obj.proxy.length > 0 ) {
                    endpoint = obj.proxy[0].endpoint
                    port = obj.proxy[0].port

                    var certArray = decode64( obj.certArray[0].certContent ); // "4pyTIMOgIGxhIG1vZGU="

                    console.log( "Generating certificate" );

                    var walletHaproxyPath = getPathToSaveHaproxyConfig(pathToSaveHaproxyConfig);

                    callhaproxy.haproxyCert( walletHaproxyPath, certArray );
                    console.log( "Starting haproxy" );

                    // try to start proxy and show error if it does not start
                    proxyStarted = callhaproxy.haproxy( walletHaproxyPath, Config.haproxyIp, Config.haproxyPort, endpoint, port.slice( 0,-4 ), 'haproxy', appWindow.persistentSettings.hexId, obj.provider, obj.providerName, obj.name )
                } else {
                    endpoint = obj.vpn[0].endpoint
                    port = obj.vpn[0].port
                    var serviceId = appWindow.persistentSettings.hexId.substring(0, 2);
                    console.log("Starting lthnvpnc using authid " + appWindow.persistentSettings.hexId + " and provider " + obj.provider + "/" + serviceId);
                    // TODO obtain lthnvpnc path on Linux/Mac. Windows uses relative path to binary.
                    proxyStarted = lthnvpnc.initializeLthnvpnc( "", appWindow.persistentSettings.hexId, obj.provider, serviceId );
                }

                if ( !proxyStarted ) {
                    showProxyStartupError();
                }

                // change to online
                changeStatus();
                intenseDashboardView.addTextAndButtonAtDashboard();
            }

            getGeoLocation()
            howToUseText.visible = false
            orText.visible = false
            searchForProviderText.visible = false
            historicalConnectionLabel.visible = false

            detailsText.visible = true
            timeonlineText.visible = true
            transferredText.visible =
                transferredTextLine.visible =
                type === "proxy" ? true : false
            paiduntilnowText.visible = true
            paidTextLine.visible = true
            providerText.visible = true
            nameText.visible = true
            providerNameText.visible = true
            planText.visible = true
            nameIntenseText.visible = true
            costText.visible = true
            costIntenseText.visible = true
            servercountryText.visible = true
            serveripText.visible = true
            lastRankLabel.visible = true
            rankRectangle.visible = true
            lastMyRankLabel.visible = true
            myRankRectangle.visible = true
            lastTypeLabel.visible = true
            lastTypeText.visible = true
            lastProviderNameLabel.visible = true
            lastProviderNameText.visible = true
            lastPlanLabel.visible = true
            lastNameIntenseText.visible = true
            lastCostText.visible = true
            lastCostIntenseText.visible = true
            lastSpeedLabel.visible = true
            lastSpeedText.visible = true
            switchTextOn.visible = true
            switchAutoRenew.visible = true

        }
        else {
            howToUseText.visible = true
            orText.visible = true
            searchForProviderText.visible = true
            historicalConnectionLabel.visible = true

            detailsText.visible = false
            timeonlineText.visible = false
            transferredText.visible =
                transferredTextLine.visible =
                false
            paiduntilnowText.visible = false
            paidTextLine.visible = false
            providerText.visible = false
            nameText.visible = false
            providerNameText.visible = false
            planText.visible = false
            nameIntenseText.visible = false
            costText.visible = false
            costIntenseText.visible = false
            servercountryText.visible = false
            serveripText.visible = false
            lastRankLabel.visible = false
            rankRectangle.visible = false
            lastMyRankLabel.visible = false
            myRankRectangle.visible = false
            lastTypeLabel.visible = false
            lastTypeText.visible = false
            lastProviderNameLabel.visible = false
            lastProviderNameText.visible = false
            lastPlanLabel.visible = false
            lastNameIntenseText.visible = false
            lastCostText.visible = false
            lastCostIntenseText.visible = false
            lastSpeedLabel.visible = false
            lastSpeedText.visible = false
            subConnectButton.visible = false
            switchTextOn.visible = false
            switchAutoRenew.visible = false
        }
    }
}
