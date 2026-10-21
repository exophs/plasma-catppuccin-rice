// Plasma 6 layout: floating top bar + centered dock on every screen.
// Applied by install.sh via:
//   qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat layout.js)"
// install.sh replaces __COLORIZER_PRESET__ with Panel Colorizer's "Rounded Widgets Floating" preset.
// WARNING: removes all existing panels first.

var colorizerPreset = __COLORIZER_PRESET__;
var dockLaunchers = [
    "preferred://browser",
    "applications:org.kde.konsole.desktop",
    "preferred://filemanager",
    "applications:systemsettings.desktop",
    "applications:org.kde.discover.desktop"
].join(",");

var known = {};
knownWidgetTypes.forEach(function (t) { known[t] = true; });

function add(panel, type, configure) {
    if (!known[type]) {
        print("skipping " + type + " (not installed)\n");
        return null;
    }
    var w = panel.addWidget(type);
    if (configure) configure(w);
    return w;
}

function cfg(w, group, values) {
    w.currentConfigGroup = group;
    for (var k in values) w.writeConfig(k, values[k]);
}

panels().forEach(function (p) { p.remove(); });

for (var screen = 0; screen < screenCount; screen++) {
    // ---- top bar ----
    var top = new Panel("org.kde.panel");
    top.screen = screen;
    top.location = "top";
    top.height = 34;
    top.floating = true;
    top.lengthMode = "fill";
    top.hiding = "none";

    add(top, "org.kde.plasma.kickoff");
    if (!add(top, "org.dhruv8sh.kara", function (w) { cfg(w, ["general"], { type: 0 }); })) {
        add(top, "org.kde.plasma.pager", function (w) {
            cfg(w, ["General"], { displayedText: "Number", showWindowIcons: false });
        });
    }
    add(top, "org.kde.plasma.appmenu");
    add(top, "plasmusic-toolbar");
    add(top, "luisbocanegra.audio.visualizer");
    add(top, "org.kde.plasma.panelspacer");
    add(top, "org.kde.plasma.digitalclock", function (w) {
        cfg(w, ["Appearance"], { showDate: true, dateDisplayFormat: "BesideTime" });
    });
    add(top, "org.kde.plasma.panelspacer");
    add(top, "org.kde.plasma.systemmonitor.cpu");
    add(top, "org.kde.plasma.systemmonitor.memory");
    add(top, "org.kde.plasma.systemtray");
    add(top, "org.kde.plasma.showdesktop");
    if (colorizerPreset) {
        add(top, "luisbocanegra.panel.colorizer", function (w) {
            cfg(w, ["General"], {
                globalSettings: JSON.stringify(colorizerPreset),
                hideWidget: true,
                isEnabled: true,
                enableDBusService: false
            });
        });
    }

    // ---- dock ----
    var dock = new Panel("org.kde.panel");
    dock.screen = screen;
    dock.location = "bottom";
    dock.height = 48;
    dock.floating = true;
    dock.lengthMode = "fit";
    dock.alignment = "center";
    dock.hiding = "none";

    add(dock, "org.kde.plasma.icontasks", function (w) {
        cfg(w, ["General"], {
            launchers: dockLaunchers,
            showOnlyCurrentDesktop: true,
            showOnlyCurrentScreen: true,
            iconSpacing: 0
        });
    });
    add(dock, "org.kde.plasma.marginsseparator");
    add(dock, "org.kde.plasma.trash");
}

print("layout applied to " + screenCount + " screen(s)\n");
