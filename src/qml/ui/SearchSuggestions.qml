import QtQuick 2.4
import Material 0.2
import Material.ListItems 0.1 as ListItem
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.2 as Controls
import Material.Extras 0.1
import "../components"

View {
    width: root.app.integratedAddressbars ? parent.width / 4 : toolbar.omnibox.width
    height: if (toolbar.omnibox.txtUrl.activeFocus && toolbar.omnibox.txtUrl.text.length > 0) {
                root.app.searchSuggestionsModel.count * Units.dp(48) > Units.dp(400) ? Units.dp(400) : root.app.searchSuggestionsModel.count * Units.dp(48)
            }
            else {
                0
            }
    anchors {
        topMargin: searchSuggestionsView.count == 0 && bookmarksBar.visible ? -bookmarksBar.height - Units.dp(30) : searchSuggestionsView.count == 0 ? -Units.dp(30) : bookmarksBar.visible ? -bookmarksBar.height : 0
        top: titlebar.bottom
        left: parent.left
        leftMargin: root.app.integratedAddressbars ? parent.width/4 * 1.5 : Units.dp(24) * toolbar.leftIconsCount + (toolbar.leftIconsCount + 1) * Units.dp(27)
    }
    radius: toolbar.omnibox.radius
    elevation: searchSuggestionsView.count == 0 ? 0 : 2
    visible: height > 0
    z:20

    Behavior on height {
        NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
    }

    Behavior on anchors.topMargin {
        NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
    }

    Behavior on elevation {
        NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
    }

    Behavior on width {
        NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
    }

    ListView {
        id: searchSuggestionsView
        width: parent.width
        property int currentpos: searchSuggestionsModel.selectedIndex
        height: parent.height
        boundsBehavior: Flickable.StopAtBounds
        model: root.app.searchSuggestionsModel
        onCurrentposChanged: {
            positionViewAtIndex(currentpos,ListView.End)
        }

        delegate: ListItem.Standard {
            text: suggestion
            iconName: icon
            backgroundColor: searchSuggestionsModel.selectedIndex == index && (icon == "action/search" || icon == "action/bookmark" || icon == "action/history")? Qt.rgba(0,0,0,0.05) : "transparent"
            onClicked: {
                setActiveTabURL(suggestion)
                root.app.searchSuggestionsModel.clear()
            }
        }
    }
    ScrollbarThemed {
        flickableItem: searchSuggestionsView
        color: Qt.rgba(0,0,0,0.5)
        hideTime: 1000
    }

}
