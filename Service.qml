import QtQuick
import Quickshell
import Quickshell.Io

// Headless: watches the dkms-built snd_hda_macbookpro speaker driver and
// sends one notification per boot if an installed kernel is missing its
// build -- including a freshly updated kernel you haven't rebooted into
// yet, so the warning arrives before the speakers go silent -- or if the
// stock codec driver is loaded instead. Never applies the fix itself:
// that needs root, downloads kernel sources, and the running kernel's
// module only swaps in after a reboot.
Item {
  id: root

  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string pluginDir: home + "/.config/omarchy/plugins/dkms-audio-guard"
  readonly property string fixScript: pluginDir + "/bin/omarchy-dkms-audio-guard"
  // Boot-scoped (tmpfs) markers: they only dedupe repeat notifications
  // within one boot. One marker per exit code, so "needs fix" (1) and,
  // after running the fix, "reboot to finish" (2) each notify once.
  readonly property string stateDir: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy/indicators"
  readonly property string neededMarker: stateDir + "/dkms-audio-guard-notified-needed"
  readonly property string stagedMarker: stateDir + "/dkms-audio-guard-notified-staged"

  function runCheck() {
    if (checkProcess.running) return
    checkProcess.running = true
  }

  function notifyOnce(marker, title, body) {
    notifyProcess.command = ["bash", "-c",
      "mkdir -p " + JSON.stringify(root.stateDir) + "; " +
      "[[ -f " + JSON.stringify(marker) + " ]] && exit 0; " +
      "touch " + JSON.stringify(marker) + "; " +
      "omarchy-notification-send -u normal " + JSON.stringify(title) + " " + JSON.stringify(body)
    ]
    notifyProcess.running = true
  }

  Process {
    id: checkProcess
    command: ["bash", root.fixScript, "--check", "--quiet"]
    onExited: function(exitCode) {
      if (exitCode === 1) {
        root.notifyOnce(root.neededMarker,
          "Speaker driver needs a rebuild",
          "The snd_hda_macbookpro dkms build is missing for an installed kernel, or the stock driver is loaded. Don't reboot yet -- run: sudo " + root.fixScript)
      } else if (exitCode === 2) {
        root.notifyOnce(root.stagedMarker,
          "Speaker driver rebuilt",
          "The rebuilt snd_hda_macbookpro module takes effect after a reboot: systemctl reboot")
      }
    }
  }

  Process {
    id: notifyProcess
  }

  Timer {
    // Shortly after shell start catches a boot into a kernel without the
    // build; the periodic check below catches a kernel update landing
    // mid-session, before you reboot into it. A check is one `dkms
    // status` (~0.2 s), so polling this often is cheap.
    interval: 15000
    running: true
    repeat: false
    onTriggered: root.runCheck()
  }

  Timer {
    interval: 600000
    running: true
    repeat: true
    onTriggered: root.runCheck()
  }
}
