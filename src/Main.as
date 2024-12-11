const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$f5d";
const string PluginIcon = Icons::Cogs;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;

// path:
/*
frame-global
    COTDQualifications_QualificationsProgress
        frame-content
            button-hide
*/

bool inQuali = false;
const wstring QualiGameMode = "TM_COTDQualifications_Online";
const string COTDQualifications_QualificationsProgress = "COTDQualifications_QualificationsProgress";

// yield a bunch because frequency doesn't matter
void _yield() {
    yield(73);
}


const wstring GetGameMode() {
    auto si = cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo);
    return si.CurGameModeStr;
}

bool IsGameMode(const string &in mode) {
    try {
        auto si = cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo);
        return si.CurGameModeStr == mode;
    } catch {
        warn("IsGameMode: " + getExceptionInfo());
        return false;
    }
}


void Main() {
    while (!IsGameMode(QualiGameMode)) _yield();
    inQuali = true;
    OnEnterQualiMode();
    while (IsGameMode(QualiGameMode)) _yield();
    inQuali = false;
}


void OnEnterQualiMode() {
#if DEV
    print(PluginName + ": Entered Quali mode");
#endif
    // yield a while for UI stuff to load; there's no rush
    _yield();
    if (!IsGameMode(QualiGameMode)) return;
    auto net = GetApp().Network;
    auto cmap = net.ClientManiaAppPlayground;
    if (cmap is null) return;
    while (net.ClientManiaAppPlayground !is null && cmap.UILayers.Length < 20) yield();
    if (net.ClientManiaAppPlayground is null) return;
    for (uint i = 0; i < cmap.UILayers.Length; i++) {
        auto l = cmap.UILayers[i];
        auto f = cast<CGameManialinkFrame>(l.LocalPage.GetFirstChild(COTDQualifications_QualificationsProgress));
        if (f is null) continue;
        auto c = f.GetFirstChild("button-hide");
        if (c is null) continue;
        c.Visible = true;
#if DEV
        print(PluginName + ": Found the UI element to toggle");
#endif
        return;
    }
    warn(PluginName + ": Couldn't find the UI element to toggle");
}




bool IsGameModeDev(const string &in mode) {
#if DEV
    auto net = GetApp().Network;
    auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
    if (si.CurGameModeStr == mode) {
        return true;
    }
    auto ps = GetApp().PlaygroundScript;
    return ps !is null && ps.ClientManiaAppUrl == "file://Media/ManiaApps/Nadeo/Trackmania/Modes/COTDQualifications.Script.txt";
#else
    auto si = cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo);
    return si.CurGameModeStr == mode;
#endif
}
