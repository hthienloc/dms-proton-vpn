import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "protonVpn"

    StyledText {
        width: parent.width
        text: "Proton VPN Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledRect {
        width: parent.width
        height: authColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: authColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Credentials"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StringSetting {
                settingKey: "username"
                label: "Username"
                placeholder: "your@email.com"
                defaultValue: ""
            }

            StringSetting {
                settingKey: "password"
                label: "Password"
                placeholder: "••••••••"
                defaultValue: ""
            }

            StyledText {
                text: "Note: Enter your Proton VPN credentials to enable login functionality. Your credentials are stored locally."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                width: parent.width
                wrapMode: Text.Wrap
            }
        }
    }

    StyledRect {
        width: parent.width
        height: behaviorColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: behaviorColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Behavior"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            ToggleSetting {
                settingKey: "autoRefresh"
                label: "Auto Refresh Status"
                description: "Automatically check VPN status periodically."
                defaultValue: true
            }
        }
    }

    StyledRect {
        width: parent.width
        height: noteColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: noteColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingS

            StyledText {
                text: "Note"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: "1. Open sudoers: sudo visudo"
                font.pixelSize: Theme.fontSizeSmall
                font.family: "monospace"
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: "2. Add: %wheel ALL=(ALL) NOPASSWD: /usr/bin/protonvpn"
                font.pixelSize: Theme.fontSizeSmall
                font.family: "monospace"
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }
}