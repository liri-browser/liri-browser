import QtQuick 2.0
import Material 0.2


Page {
    id: page
    title: qsTr("Tabs")
    visible: false
    TabsList {
        anchors.fill: parent
    }

}
