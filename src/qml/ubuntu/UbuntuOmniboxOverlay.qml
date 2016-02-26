import QtQuick 2.0
import Material 0.2 as Material
import Ubuntu.Components 1.3


Rectangle {
    id: view
    anchors.fill: parent
    visible: false
    opacity: visible ? 1.0 : 0
    color: root.currentBackgroundColor

    function show() {
        textField.text = root.activeTab.view.url;
        visible = true;
        textField.forceActiveFocus();
        textField.selectAll();
    }

    function hide() {
        visible = false;
    }

    Material.Icon {
        id: connectionIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Material.Units.dp(15)
        color: root.currentIconColor
        name: "action/search"
    }

    TextField {
        id: textField

        text: root.activeTab.view.url
        placeholderText: qsTr("Search or enter website name")

        anchors.left: connectionIcon.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: hideButton.left
        anchors.leftMargin: Material.Units.dp(15)
        anchors.rightMargin: Material.Units.dp(15)

        inputMethodHints: Qt.ImhUrlCharactersOnly

        onTextChanged: {
            isASearchQuery(text) ? connectionIcon.name = "action/search" :  connectionIcon.name = "social/public";
        }
        onAccepted: {
            setActiveTabURL(text);
            hide();
        }
        onActiveFocusChanged: {
            if(!activeFocus)
                hide();
        }
    }

    Material.IconButton {
        id: hideButton
        iconName: "hardware/keyboard_return"
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Material.Units.dp(15)
        onClicked: {
            hide();
        }
        color: root.currentIconColor
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
}
