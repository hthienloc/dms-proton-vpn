import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

property string status: "Unknown"
    property string server: ""
    property string country: ""
    property string protocol: ""
    property bool connected: false
    property bool commandRunning: false
    property bool cliReady: true
    property bool isLoggedIn: true
    property string previousServer: ""
    property string previousCountry: ""
    property string previousProtocol: ""
    property bool previousConnected: false

    function copyToClipboard(text) {
        Proc.runCommand("copy-clipboard", ["sh", "-c", "echo -n " + JSON.stringify(text) + " | xclip -selection clipboard"], function() {}, 5000)
    }

    readonly property bool autoRefresh: (pluginData.autoRefresh ?? true)
    readonly property string storedUsername: pluginData.username || ""
    readonly property string storedPassword: pluginData.password || ""
    readonly property bool hasCredentials: storedUsername && storedPassword

    function login() {
        if (!root.storedUsername || !root.storedPassword) {
            status = "Enter credentials in Settings"
            return
        }
        if (root.commandRunning) return

        root.commandRunning = true
        status = "Logging in..."

        Proc.runCommand(
            "proton-login",
            ["expect", "-c", `spawn protonvpn signin ${root.storedUsername}; expect "Password:"; send "${root.storedPassword}\\r"; expect eof`],
            function(output, exitCode) {
                root.commandRunning = false
                root.fetchStatus()
            },
            30000
        )
    }

    Timer {
        id: statusTimer
        interval: 30000
        repeat: true
        running: root.autoRefresh && !root.commandRunning
        onTriggered: fetchStatus()
    }

    Component.onCompleted: {
        if (!root.storedUsername || !root.storedPassword) {
            status = "Configure credentials in Settings"
            cliReady = true
            isLoggedIn = false
        } else {
            fetchStatus()
        }
    }

    function fetchStatus() {
        if (root.commandRunning) return
        
        Proc.runCommand(
            "proton-status",
            ["protonvpn", "status"],
            function(output, exitCode) {
                if (exitCode !== 0 || !output) {
                    status = "Not ready"
                    cliReady = false
                    connected = false
                    return
                }
                cliReady = true
                parseStatus(output)
            },
            10000
        )
    }

    function parseStatus(output) {
        if (output.includes("Not logged in") || output.includes("Session expired")) {
            isLoggedIn = false
            connected = false
            status = "Not logged in"
            server = ""
            country = ""
            protocol = ""
            return
        }

        isLoggedIn = true

        if (output.includes("Disconnected")) {
            connected = false
            status = "Disconnected"
            server = ""
            country = ""
            protocol = ""
            return
        }

        connected = true
        status = "Connected"

        var lines = output.split('\n')
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.startsWith("Server:")) {
                var serverPart = line.split(':')[1]?.trim() || ""
                var serverMatch = serverPart.match(/^([A-Z]+-[A-Z]+#\d+)/)
                server = serverMatch ? serverMatch[1] : serverPart.split(' ')[0]
                if (serverPart.includes(' in ')) {
                    country = serverPart.split(' in ')[1]?.trim() || ""
                }
            } else if (line.startsWith("Protocol:")) {
                protocol = line.split(':')[1]?.trim() || ""
            }
        }
    }

    function getDisplayText() {
        if (!root.storedUsername || !root.storedPassword) return "Setup"
        if (root.commandRunning) return "..."
        var s = root.server
        return root.connected ? (s.split('#')[0] || "VPN") : "VPN"
    }

    function getServerFull() {
        return (root.commandRunning ? root.previousServer : root.server) || "-"
    }

    function getLocation() {
        return (root.commandRunning ? root.previousCountry : root.country) || "-"
    }

    function refreshStatus() {
        root.commandRunning = false
        fetchStatus()
    }

    function toggleConnection() {
        if (root.commandRunning) return
        
        root.previousConnected = root.connected
        root.previousServer = root.server
        root.previousCountry = root.country
        root.previousProtocol = root.protocol
        
        root.commandRunning = true
        var args = root.connected ? ["protonvpn", "disconnect"] : ["protonvpn", "connect"]
        
        Proc.runCommand(
            "proton-toggle",
            args,
            function(output, exitCode) {
                Proc.runCommand(
                    "proton-status",
                    ["protonvpn", "status"],
                    function(output, exitCode) {
                        root.commandRunning = false
                        if (exitCode !== 0 || !output) {
                            root.status = "Not ready"
                            root.cliReady = false
                            root.connected = false
                            return
                        }
                        root.cliReady = true
                        root.parseStatus(output)
                    },
                    10000
                )
            },
            root.connected ? 10000 : 30000
        )
    }

    readonly property color pillColor: {
        if (!root.hasCredentials) return Theme.error
        if (root.commandRunning) {
            return root.previousConnected ? Theme.warning : Theme.primary
        }
        if (!root.cliReady) return Theme.error
        if (!root.isLoggedIn) return Theme.warning
        if (root.connected) return Theme.primary
        return Theme.surfaceText
    }

    pillRightClickAction: () => { if (!root.commandRunning) refreshStatus() }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: root.commandRunning ? "sync" : (root.connected ? "vpn_lock" : "vpn_lock")
                size: Theme.iconSizeSmall
                color: root.pillColor
                anchors.verticalCenter: parent.verticalCenter

                RotationAnimator on rotation {
                    running: root.commandRunning
                    from: 0
                    to: 360
                    loops: Animation.Infinite
                    duration: 1000
                }
            }

            StyledText {
                text: root.commandRunning ? "..." : root.getDisplayText()
                color: root.pillColor
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.commandRunning ? "sync" : (root.connected ? "vpn_lock" : "vpn_lock")
                size: Theme.iconSizeSmall
                color: root.pillColor
                anchors.horizontalCenter: parent.horizontalCenter

                RotationAnimator on rotation {
                    running: root.commandRunning
                    from: 0
                    to: 360
                    loops: Animation.Infinite
                    duration: 1000
                }
            }

            StyledText {
                text: root.commandRunning ? "..." : root.getDisplayText()
                color: root.pillColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        FocusScope {
            width: parent ? parent.width : 0
            implicitHeight: mainContent.implicitHeight

            PopoutComponent {
                id: mainContent
                width: parent.width
                headerText: "Proton VPN"
                detailsText: root.status
                showCloseButton: false

                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    StyledRect {
                        width: parent.width
                        radius: Theme.cornerRadius
                        color: Theme.errorContainer
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.error, 0.3)
                        implicitHeight: warningColumn.implicitHeight + Theme.spacingM * 2
                        visible: !root.cliReady

                        Column {
                            id: warningColumn
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS
                            width: parent.width - Theme.spacingM * 2

                            Row {
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "warning"
                                    size: 20
                                    color: Theme.error
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "CLI not ready"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    color: Theme.error
                                }
                            }

                            StyledText {
                                text: "Run this in terminal to enable connect/disconnect:"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            Row {
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: "sudo visudo"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: "monospace"
                                    color: Theme.surfaceText
                                }

                                DankIcon {
                                    name: "content_copy"
                                    size: 16
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: copyToClipboard("sudo visudo")
                                    }
                                }
                            }

                            Row {
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: "%wheel ALL=(ALL) NOPASSWD: /usr/bin/protonvpn"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: "monospace"
                                    color: Theme.surfaceText
                                }

                                DankIcon {
                                    name: "content_copy"
                                    size: 16
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: copyToClipboard("%wheel ALL=(ALL) NOPASSWD: /usr/bin/protonvpn")
                                    }
                                }
                            }

                            DankButton {
                                text: "Retry"
                                iconName: "refresh"
                                backgroundColor: Theme.primary
                                textColor: Theme.onPrimary
                                onClicked: fetchStatus()
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        radius: Theme.cornerRadius
                        color: Theme.warningContainer
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.warning, 0.3)
                        implicitHeight: loginColumn.implicitHeight + Theme.spacingM * 2
                        visible: root.cliReady && !root.isLoggedIn

                        Column {
                            id: loginColumn
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            Row {
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "person_off"
                                    size: 20
                                    color: Theme.warning
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Login Required"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    color: Theme.warning
                                }
                            }

                            StyledText {
                                text: "Enter your Proton VPN credentials in Settings to sign in."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            DankButton {
                                text: "Sign In"
                                iconName: "login"
                                backgroundColor: Theme.primary
                                textColor: Theme.onPrimary
                                onClicked: login()
                                visible: root.hasCredentials
                            }
                        }
                    }

                    StatusDisplay {
                        id: statusDisplay
                        active: root.connected
                        iconName: root.commandRunning ? "sync" : (root.connected ? "vpn_lock" : "vpn_lock")
                        title: {
                            if (root.commandRunning) {
                                return root.previousConnected ? "Disconnecting..." : "Connecting..."
                            }
                            return root.connected ? "Connected" : "Disconnected"
                        }
                        subtitle: root.commandRunning ? (root.previousServer || "Please wait...") : (root.getServerFull())
                        infoText: root.commandRunning ? root.previousCountry : root.getLocation()
                        onClicked: refreshStatus()
                    }

                    Row {
                        spacing: Theme.spacingS
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.cliReady

                        DankButton {
                            text: "Refresh"
                            iconName: "refresh"
                            backgroundColor: Theme.surfaceContainer
                            textColor: Theme.surfaceText
                            enabled: !root.commandRunning
                            onClicked: refreshStatus()
                        }

                        DankButton {
                            text: root.connected ? "Disconnect" : "Connect"
                            iconName: root.connected ? "link_off" : "link"
                            backgroundColor: root.connected ? Theme.error : Theme.primary
                            textColor: root.connected ? Theme.onError : Theme.onPrimary
                            enabled: !root.commandRunning
                            onClicked: toggleConnection()
                        }
                    }

                    Grid {
                        columns: 2
                        columnSpacing: Theme.spacingS
                        rowSpacing: Theme.spacingS
                        visible: root.connected && root.cliReady
                        width: parent.width

                        InfoTile {
                            Layout.fillWidth: true
                            label: "Protocol"
                            value: (root.commandRunning ? root.previousProtocol : root.protocol) || "-"
                        }
                    }

                    StyledText {
                        text: "Right-click icon to refresh"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        horizontalAlignment: Text.AlignHCenter
                        visible: root.cliReady
                    }
                }
            }
        }
    }

    popoutWidth: 320
    popoutHeight: 480
}