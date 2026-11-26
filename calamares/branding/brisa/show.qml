import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation
    function onActivate() { }
    function onLeave() { }
    Slide {
        Text {
            anchors.centerIn: parent
            text: "Instalando o @BRISA_NAME@…\nEm poucos minutos ele estará pronto."
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 20
            color: "#333333"
        }
    }
}
