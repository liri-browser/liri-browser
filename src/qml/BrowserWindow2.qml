import QtQuick 2.4
import Material 0.2
import Material.ListItems 0.1 as ListItem
import Material.Extras 0.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.2 as Controls
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0

MaterialWindow {
    id: root

    property QtObject app

    title: activeTab ? (activeTab.view.title || qsTr("Loading")) + " - Liri Browser" : "Liri Browser"
    visible: true
    width: 1000
    height: 640

    theme {
        id: theme
        primaryColor: "#F44336"
        primaryDarkColor: "#D32F2F"
        accentColor: "#FF5722"
        backgroundColor: app.darkTheme ? app.darkThemeColor : "#f3f3f3"
    }

    /* Settings */
    property variant win;


    property alias tabPreview: page.tabPreview
    property string tabPreviewSource

    property bool snappedRight: false
    property bool snappedLeft: false

    property bool tabsListIsOpened: false
    property bool customSitesColorsIsOpened: false

    property bool reduceTabsSizes: ((tabWidth * tabsModel.count) > root.width - 200) && root.app.allowReducingTabsSizes

    property Settings settings: Settings {
        id: settings
        property alias x: root.x
        property alias y: root.y
        property alias width: root.width
        property alias height: root.height
        property alias primaryColor: theme.primaryColor
        property alias accentColor: theme.accentColor
    }

    property bool fullscreen: false
    property bool privateNav: false
    property bool mobile: Math.sqrt(Math.pow(width, 2) + Math.pow(height, 2)) < Units.dp(1000) || width < Units.dp(640)

    property alias toolbar: page.toolbar
    property alias titlebar: page.titlebar

    property alias txtSearch: page.txtSearch
    property alias websiteSearchOverlay: page.websiteSearchOverlay
    property var downloadsDrawer

    /* Style Settings */
    property int tabHeight: Units.dp(40)
    property int tabWidth: !reduceTabsSizes ? Units.dp(200) : Units.dp(50)
    property int tabWidthEdit: Units.dp(400)
    property int tabsSpacing: Units.dp(1)
    property int titlebarHeight: Units.dp(148)

    property color defaultBackgroundColor: app.lightThemeColor
    property color currentBackgroundColor: page.backgroundColor

    property color defaultForegroundColor: (privateNav || app.darkTheme) ? "white" : "#212121"
    property color currentForegroundColor: app.tabsEntirelyColorized && activeTab.view.customTextColor ? activeTab.view.customTextColor : defaultForegroundColor

    property color defaultInactiveForegroundColor: (privateNav || app.darkTheme) ? shadeColor("#FFFFF", 0.9) : "#757575"
    property color currentInactiveForegroundColor: app.tabsEntirelyColorized && activeTab.view.customTextColor ? shadeColor(activeTab.view.customTextColor, 0.9) : defaultInactiveForegroundColor

    property color currentIconColor: Theme.light.iconColor

    property string fontFamily: "Roboto"

    property alias shadow: page.shadow

    /* Tab Management */
    property var activeTab
    property var activeTabItem
    property var lastActiveTab
    property var activeTabHistory: []
    property int lastTabUID: 0
    property int lastBookmarkUID: 0
    property ListModel tabsModel: ListModel {}
    property var closedTabsUrls : []
    property bool activeTabInEditMode: false
    property var activeTabInEditModeItem
    property Component webviewComponent
    property Component browserViewComponent: Qt.createComponent(Qt.resolvedUrl("BrowserView.qml"))
    property Component newTabPageComponent: Qt.createComponent(Qt.resolvedUrl("NewTabPage.qml"))
    property Component settingsViewComponent: Qt.createComponent(Qt.resolvedUrl("SettingsView.qml"))
    property Component quickSearchesSettingsViewComponent: Qt.createComponent(Qt.resolvedUrl("QuickSearchesView.qml"))
    property Component sitesColorsSettingsViewComponent: Qt.createComponent(Qt.resolvedUrl("SitesColorsView.qml"))

    property int selectedQueryIndex: 0

    /* General */

    function startFullscreenMode(){
        fullscreen = true;
        showFullScreen();

    }

    function endFullscreenMode() {
        fullscreen = false;
        showNormal();
    }

    function showSearchOverlay() {
        websiteSearchOverlay.visible = true;
        txtSearch.forceActiveFocus();
        txtSearch.selectAll();
    }

    function hideSearchOverlay() {
        websiteSearchOverlay.visible = false;
    }

    function sortByKey(array, key) {
        // from http://stackoverflow.com/questions/8837454/sort-array-of-objects-by-single-key-with-date-value
        return array.sort(function(a, b) {
            var x = a[key]; var y = b[key];
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        });
    }

    /* URL Hangdling */




    /* Boomarks Management */



    function addToDash(url, title, color) {
        var uidMax = 0;
        for (var i=0; i<root.app.dashboardModel.count; i++) {
            if (root.app.dashboardModel.get(i).uid > uidMax){
                uidMax = root.app.dashboardModel.get(i).uid;
            }
        }

        getBetterIcon(url, title, color, function(url, title, color, iconUrl){
            var fgColor
            if (color)
                fgColor = getTextColorForBackground(color.toString())
            else
                fgColor = "black"
            root.app.dashboardModel.append({"title": title, "url": url.toString(), "iconUrl": iconUrl.toString(), "uid": uidMax+1, "bgColor": color || "white", "fgColor": fgColor});
            root.app.saveDashboard();
            //: %1 is a title
            snackbar.open(qsTr('Added website "%1" to dash').arg(title));
        });

    }

    function isBookmarked(url){
        for (var i=0; i<root.app.bookmarksModel.count; i++){
            if (root.app.bookmarksModel.get(i).url == url)
                return true
        }
        return false
    }

    function addBookmark(title, url, faviconUrl, color){
        lastBookmarkUID++;
        root.app.bookmarksModel.append({"title": title, "url": url, "faviconUrl": faviconUrl, "color": color, "uid": lastBookmarkUID})
        root.app.saveBookmarks();
    }

    function changeBookmark(url, title, newUrl, faviconUrl){
        for (var i=0; i<root.app.bookmarksModel.count; i++){
            if (root.app.bookmarksModel.get(i).url == url){
                root.app.bookmarksModel.get(i).url = newUrl;
                root.app.bookmarksModel.get(i).title = title;
                root.app.bookmarksModel.get(i).faviconUrl = faviconUrl;
                root.app.saveBookmarks();
                return true;
            }
        }
        return false;

    }

    function removeBookmark(url){
        for (var i=0; i<root.app.bookmarksModel.count; i++){
            if (root.app.bookmarksModel.get(i).url == url){
                root.app.bookmarksModel.remove(i);
                root.app.saveBookmarks();
                return true;
            }
        }
        return false;
    }

    /* Color Handling */

    function searchForCustomColor(url) {
        var domains = url.split(".")
        if(domains[0].indexOf("://") != 1)
            domains[0]=domains[0].substring(domains[0].indexOf("://")+3,domains[0].length)
        if(domains[0] == "www")
            domains.shift()
        var domains_l = domains.length;
        if(domains[domains_l-1].indexOf("/") != -1)
            domains[domains_l-1] = domains[domains_l-1].substring(0,domains[domains_l-1].indexOf("/"))
        var domain = domains.join(".")
        var nb = root.app.presetSitesColorsModel.count;
        var i;
        var result = "none";

        for(i=0;i<nb;i++) {
            if (root.app.presetSitesColorsModel.get(i).domain == domain)
                result=root.app.presetSitesColorsModel.get(i).color
        }
        nb=root.app.customSitesColorsModel.count;
        for(i=0;i<nb;i++) {
            if (root.app.customSitesColorsModel.get(i).domain == domain)
                result=root.app.customSitesColorsModel.get(i).color
        }
        return result
    }

    function shadeColor(color, percent) {
        // from http://stackoverflow.com/questions/5560248/programmatically-lighten-or-darken-a-hex-color-or-rgb-and-blend-colors
        color = color.toString()
        var f=parseInt(color.slice(1),16),t=percent<0?0:255,p=percent<0?percent*-1:percent,R=f>>16,G=f>>8&0x00FF,B=f&0x0000FF;
        return "#"+(0x1000000+(Math.round((t-R)*p)+R)*0x10000+(Math.round((t-G)*p)+G)*0x100+(Math.round((t-B)*p)+B)).toString(16).slice(1);
    }

    function getTextColorForBackground(bg) {
        // from http://stackoverflow.com/questions/12043187/how-to-check-if-hex-color-is-too-black
        var c = bg.substring(1);      // strip #
        var rgb = parseInt(c, 16);   // convert rrggbb to decimal
        var r = (rgb >> 16) & 0xff;  // extract red
        var g = (rgb >>  8) & 0xff;  // extract green
        var b = (rgb >>  0) & 0xff;  // extract blue

        var luma = 0.2126 * r + 0.7152 * g + 0.0722 * b; // per ITU-R BT.709

        if (luma < 200) {
            return "white";
        }
        else {
            return root.defaultForegroundColor
        }
    }


    /* Tabs Management */

    onActiveTabChanged: {
        // Handle last active tab
        if (lastActiveTab !== undefined && lastActiveTab !== null && lastActiveTab !== false) {
            lastActiveTab.state = "inactive";
            lastActiveTab.view.visible = false;
        }
        // Handle now active tab
        if (activeTab) {
            if (activeTabInEditModeItem)
                activeTabInEditModeItem.editModeActive = false;
            lastActiveTab = activeTab;
            activeTab.state = "active";
            activeTab.view.visible = true;
            activeTabHistory.push(activeTab.uid);
        }
    }

    function getTabModelDataByUID (uid) {
        for (var i=0; i<tabsModel.count; i++) {
            if (tabsModel.get(i).uid == uid) {
                return tabsModel.get(i);
            }
        }
        return false;
    }

    function getTabModelIndexByUID (uid) {
        for (var i=0; i<tabsModel.count; i++) {
            if (tabsModel.get(i).uid == uid) {
                return i;
            }
        }
        return false;
    }

    function getUIDByModelIndex(i) {
        return tabsModel.get(i).uid;
    }



    function saveThisTabUrl(url) {
        // Add this tab to the list of recently closed tabs
        closedTabsUrls.push(url)
    }

    function reopenLastClosedTab() {
        var url = closedTabsUrls[closedTabsUrls.length - 1]
        addTab(url)
        closedTabsUrls.pop()
    }

    function ensureTabIsVisible(t) {
        if (typeof(t) === "number") {
            var modelIndex = getTabModelIndexByUID(t);
            page.listView.positionViewAtIndex(modelIndex, ListView.Visible);
        }
    }

    function setActiveTab(t, ensureVisible, callback) {
        if (typeof(t) === "number") {
            activeTab = getTabModelDataByUID(t);
        }
        if (ensureVisible)
            ensureTabIsVisible(t);
        if (callback)
            callback();
    }

    function setLastActiveTabActive (callback) {
        if (tabsModel.count > 1) {
            if (activeTabHistory.length > 0) {
                setActiveTab(activeTabHistory[activeTabHistory.length-1], true, callback);
            } else {
                callback();
                setActiveTab(getUIDByModelIndex(0), true);
            }
        } else {
            callback();
        }
    }

    function setActiveTabURL(url, todownload) {
        activeTab.view.load(url);
    }

    function toggleActiveTabBookmark() {
        var url = activeTab.view.url;
        var icon = activeTab.view.icon;
        var title = activeTab.view.title;
        if (isBookmarked(url)) {
            snackbar.open(qsTr('Removed bookmark %1').arg(title));
            removeBookmark(url)
        } else {
            snackbar.open(qsTr('Added bookmark "%1"').arg(title));
            addBookmark(title, url, icon, activeTab.view.customColor);
        }
    }

    function activeTabFindText(text, backward) {
        var flags
        activeTab.view.findText(text, backward, function(success) {
            root.txtSearch.hasError = !success;
        });
    }

    function activeTabViewSourceCode () {
        activeTab.view.runJavaScript("function getSource() { return '' + document.documentElement.innerHTML + '';} getSource() ", function(content) {
            addTab("http://liri-project.github.io/browser/sourcecodeviewer/index.html");
            root.app.sourcetemp = content;
            root.app.sourcetemp = root.app.sourcetemp.replace(/\r?\n|\r/g,"");
            root.app.sourcetemp = root.app.sourcetemp.replace(/    /g,"");
            root.app.sourcetemp = encodeURI(root.app.sourcetemp);
        });
    }

    function tooglePrivateNav(){
        if(!root.privateNav) {
            root.initialPage.ink.color = app.privateNavColor
            root.initialPage.ink.createTapCircle(root.width - Units.dp(30),root.height-Units.dp(30))
            root.privateNav = true
        }
        else {
            root.initialPage.ink.lastCircle.removeCircle()
            root.privateNav = false
        }
    }

    Item {
        id: shortCutActionsContainer
    }

    initialPage: BrowserPage { id: page }

    SettingsPage { id: settingsPage }

    TabsListPage { id: tabsListPage }

    SitesColorsPage { id: sitesColorsPage }

    Snackbar {
        id: snackbar
    }

    Snackbar {
        id: snackbarTabClose
        property string url: ""
        buttonText: qsTr("Reopen")
        onClicked: {
            root.addTab(url);
        }
    }

    Dialog {
        id: dlgCertificateError

        property var page
        property var error
        property string url

        visible: false
        width: Units.dp(400)
        title: qsTr("This Connection Is Untrusted")
        //: %1 is an URL
        text: qsTr("You are about to securely connect to %1 but we can't confirm that your connection is secure because this site's identity can't be verified.").arg("'" + url + "'")
        positiveButtonText: qsTr("Continue anyway")
        negativeButtonText: qsTr("Leave page")

        onAccepted: {
           error.ignoreCertificateError();
        }

        onRejected: {
            error.rejectCertificate();
        }

        function showError(error) {
            error.defer();
            url = error.url;
            dlgCertificateError.error = error;
            dlgCertificateError.show();
        }
    }

    Component.onCompleted: {
        // WebView Component
        if (app.webEngine === "qtwebengine")
            webviewComponent = Qt.createComponent ("BrowserWebView.qml");
        else if (app.webEngine === "oxide")
            webviewComponent = Qt.createComponent ("BrowserOxideWebView.qml");

        // Create shortcut actions
        if (app.enableShortCuts) {
            var component = Qt.createComponent("ShortcutActions.qml");
            component.createObject(shortCutActionsContainer);
        }

       // Create download drawer
        if (app.webEngine === "qtwebengine") {
            var component = Qt.createComponent("DownloadsDrawer.qml");
            downloadsDrawer = component.createObject(page);
        }

        // Add tab
        addTab();
        var txtUrl = Utils.findChild(root,"txtUrl")
        txtUrl.forceActiveFocus();

        // Set last bookmarks UID
        lastBookmarkUID = app.bookmarksModel.count;
    }
}
