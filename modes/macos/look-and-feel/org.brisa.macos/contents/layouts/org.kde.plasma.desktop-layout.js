// Modo macOS: barra superior fina com menu global + dock inferior flutuante.

// Papel de parede da distro em todas as telas.
desktops().forEach(function (d) {
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/@BRISA_ID@");
});

// ---- Barra superior (~24 px) ----
var top = new Panel;
top.location = "top";
top.height = 26;
top.floating = false;

var logo = top.addWidget("org.kde.plasma.kickoff");
logo.currentConfigGroup = ["General"];
logo.writeConfig("icon", "start-here");          // logo da distro (substitui o da Apple)
logo.currentConfigGroup = ["Shortcuts"];
logo.writeConfig("global", "Alt+F1");

top.addWidget("org.kde.plasma.appmenu");          // menu global do app ativo
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
top.addWidget("org.kde.milou");                   // busca

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd");
clock.writeConfig("dateDisplayFormat", "BesideTime");

// ---- Dock inferior ----
var dock = new Panel;
dock.location = "bottom";
dock.height = 60;                                  // ícones ~48 px
dock.floating = true;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.hiding = "none";

var launchers = [
    "applications:org.kde.dolphin.desktop",
    "applications:chromium.desktop",
    "applications:mpv.desktop",
    "applications:org.kde.kate.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop"
];
if (applicationExists("calamares")) {              // só na sessão live
    launchers.push("applications:brisa-instalar.desktop");
}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", launchers.join(","));
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("groupingStrategy", "1");

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
