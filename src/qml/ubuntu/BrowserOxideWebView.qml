import QtQuick 2.4
import Material 0.2
import com.canonical.Oxide 1.0

BaseBrowserView {
    id: browserWebView
    anchors.fill: parent

    property var uid
    property alias webview: webview

    property alias page: webview.page
    property alias url: webview.url
    //property alias profile: webview.profile
    property alias icon: webview.icon
    property string title: webview.title
    property alias loading: webview.loading
    property alias canGoBack: webview.canGoBack
    property alias canGoForward: webview.canGoForward
    property bool secureConnection: false
    property real progress: webview.loadProgress/100

    property string usContext: "messaging://"

    property var preview

    property alias request: webview.request

    function goBack() {
        webview.goBack();
    }

    function goForward() {
        webview.goForward();
    }

    function runJavaScript(arg1, arg2) {
        webview.runJavaScript(arg1, arg2);
    }

    function reload() {
        webview.reload();
    }

    function stop() {
        webview.stop();
    }

    function findText (text, backward, callback){
        webview.findController.text = text;
        if (backward)
            webview.findController.previous();
        else
            webview.findController.next();
        callback(webview.findController.count > 0);
    }

    WebContext {
        id: webcontext
        property string defaultUserAgent: "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
        property string mobileUserAgent: "Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.133 Mobile Safari/535.19 "
        userScripts: [
            UserScript {
                context: usContext
                url: Qt.resolvedUrl("oxide-user.js")
            }
        ]
        userAgent: mobile ? mobileUserAgent : defaultUserAgent
    }

    WebView {
        id: webview
        property var page
        anchors.fill: parent

        context: webcontext

        onIconChanged: {
            // Set the favicon in history
            var historyModel = root.app.historyModel;
            for (var i=0; i<historyModel.count; i++) {
                var item = historyModel.get(i);
                if (item.url == webview.url){
                    item.faviconUrl = webview.icon
                    historyModel.set(i, item);
                    break;
                }
            }
        }

        onUrlChanged: {
            if (url.toString().lastIndexOf("https://", 0) === 0)
                browserWebView.secureConnection = true;
            else
                browserWebView.secureConnection = false;
        }

         onCertificateError: {
             dlgCertificateError.showError(error);
         }

         onNewViewRequested: {
             var webview = Qt.createComponent("BrowserOxideWebView.qml").createObject(browserWebView, {"request": request});
             if (request.disposition === NewViewRequest.DispositionNewForegroundTab) {
                 var tab = root.addTab("about:blank", false, webview);
             }
             else {
                 var tab = root.addTab("about:blank", true, webview);
             }
         }

         onFullscreenRequested: {
             webview.fullscreen = fullscreen;
             if (fullscreen) {
                 root.startFullscreenMode();
             }
             else {
                 root.endFullscreenMode();
             }
         }

         onDownloadRequested: {
             Qt.openUrlExternally(request.url)
         }

         onLoadingChanged: {
            if (loadEvent.type === 0) {

            }

            else if (loadEvent.type === 2) {
                // Looking for custom tab bar colors
                runJavaScript("function getThemeColor() { var metas = document.getElementsByTagName('meta'); for (i=0; i<metas.length; i++) { if (metas[i].getAttribute('name') === 'theme-color') { return metas[i].getAttribute('content');}} return '';} getThemeColor() ",
                    function(content){
                        if(content !== "") {
                            browserWebView.customColor = content;
                            browserWebView.customColorLight = root.shadeColor(content, 0.6);
                            browserWebView.customTextColor = root.getTextColorForBackground(content);

                            if(!root.privateNav && !root.app.darkTheme && root.app.tabsEntirelyColorized && view.visible) {
                                root.initialPage.ink.color = content
                                root.initialPage.ink.createTapCircle(root.width/2, root.height/1.5)
                                root.initialPage.inkTimer.restart()
                            }
                        }
                        else{
                            var customColor = root.app.customSitesColors ? searchForCustomColor(url.toString()) : "none";
                            if(customColor != "none") {
                                browserWebView.customColor = customColor;
                                browserWebView.customColorLight = root.shadeColor(customColor, 0.6);
                                browserWebView.customTextColor = root.getTextColorForBackground(customColor);
                                if(!root.privateNav && root.app.tabsEntirelyColorized && view.visible) {
                                    root.initialPage.ink.color = customColor
                                    root.initialPage.ink.createTapCircle(root.width/2, root.height/1.5)
                                    root.initialPage.inkTimer.restart()
                                }
                            }
                            else {
                                browserWebView.customColor = false;
                                browserWebView.customColorLight = false;
                                browserWebView.customTextColor = false;
                            }
                        }
                });

                // Add history entry
                if (title && url.toString() != root.app.homeUrl) {
                    var locale = Qt.locale()
                    var currentDate = new Date()
                    var dateString = currentDate.toLocaleDateString();

                    var item = {
                        "url": url.toString(),
                        "title": title,
                        "faviconUrl": icon.toString(),
                        "date": dateString,
                        "type": "entry"
                    }

                    root.app.historyModel.insert(0, item);
                }

                if(!loading && url.toString().indexOf("http://liriproject.me/browser/sourcecodeviewer/index.html") === 0) {

                    setSource(root.app.sourceHighlightTheme, root.app.sourcetemp)
                    /*runJavaScript("
                    function setSource(){
                        var head = document.head, link = document.createElement('link');
                        link.type = 'text/css';
                        link.rel = 'stylesheet';
                        link.href = 'http://softwaremaniacs.org/media/soft/highlight/styles/" + root.app.sourceHighlightTheme +".css';
                        head.appendChild(link);
                        var sc = '<!DOCTYPE html><html>' + decodeURI(\"" + root.app.sourcetemp + "\") + '</html>';
                        sc = style_html(sc, {
                          'indent_size': 2,
                          'indent_char': ' ',
                          'max_char': 48,
                          'brace_style': 'expand',
                          'unformatted': ['a', 'sub', 'sup', 'b', 'i', 'u']
                        });
                        sc = sc.replace(/</g, '&lt');
                        sc = sc.replace(/>/g, '&gt');
                        document.getElementById('source_container').innerHTML = sc;
                        hljs.highlightBlock(document.getElementById('source_container'));
                        document.getElementById('source_container').style.fontFamily = 'Hack';
                    }
                    setSource();");*/
                }

            }

            else if (loadEvent.isError) {
                root.setActiveTabURL('about:blank');
            }
         }

         function getHTML(callback) {
             var req = webview.rootFrame.sendMessage(usContext, "GET_HTML", {})
             req.onreply = function (msg) {
                 callback(msg.html);
             }
             req.onerror = function (code, explanation) {
                 console.log("Error " + code + ": " + explanation)
             }
         }

         function runJavaScript(js, callback) {
             var req = webview.rootFrame.sendMessage(usContext, "RUN_JAVASCRIPT", {script: js})
             req.onreply = function (msg) {
                 callback(msg.result);
             }
             req.onerror = function (code, explanation) {
                 console.log("Error " + code + ": " + explanation)
             }
         }

         function setSource(theme, temp) {
             var req = webview.rootFrame.sendMessage(usContext, "SET_SOURCE", {theme: theme, temp: temp})
             req.onreply = function (msg) {
                 callback(msg.result);
             }
             req.onerror = function (code, explanation) {
                 console.log("Error " + code + ": " + explanation)
             }

         }
    }

}
