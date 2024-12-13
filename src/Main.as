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
    Swaps to COTDQualifications_Ranking after first fin
*/

bool inQuali = false;
const wstring QualiGameMode = "TM_COTDQualifications_Online";
const string COTDQualifications_QualificationsProgress = "COTDQualifications_QualificationsProgress";
const string COTDQualifications_Ranking = "COTDQualifications_Ranking";

// yield a bunch because frequency doesn't matter
void _yield() {
    yield(73);
}


const wstring GetGameMode() {
    auto si = cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo);
    return si.CurGameModeStr;
}

bool IsGameMode(const string &in mode) {
#if DEV
    return IsGameModeDev(mode);
#else
    try {
        auto si = cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo);
        return si.CurGameModeStr == mode;
    } catch {
        warn("IsGameMode: " + getExceptionInfo());
        return false;
    }
#endif
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
    FindAndUnhideToggleButton();
}

int _lastQualiProgLayerIx = -1;

void FindAndUnhideToggleButton() {
    if (!IsGameMode(QualiGameMode)) return;
    auto net = GetApp().Network;
    auto cmap = net.ClientManiaAppPlayground;
    if (cmap is null) return;
    while (net.ClientManiaAppPlayground !is null && cmap.UILayers.Length < 20) yield();
    if (net.ClientManiaAppPlayground is null) return;
    CGameManialinkFrame@ cq_QualProgressFrame;
    @cq_QualProgressFrame = GetCmapUiLayerFirstChild_Frame(cmap, _lastQualiProgLayerIx, COTDQualifications_QualificationsProgress);
    if (cq_QualProgressFrame is null) {
        _lastQualiProgLayerIx = FindQualiProgLayerIx(cmap);
        @cq_QualProgressFrame = GetCmapUiLayerFirstChild_Frame(cmap, _lastQualiProgLayerIx, COTDQualifications_QualificationsProgress);
        if (cq_QualProgressFrame is null) {
            warn(PluginName + ": Couldn't find the QualificationsProgress frame");
            return;
        }
    }

    auto cq_QP_ButtonHide = cq_QualProgressFrame.GetFirstChild("button-hide");
    if (cq_QP_ButtonHide !is null) cq_QP_ButtonHide.Show();
    else warn(PluginName + ": Couldn't find the button-hide on QualificationsProgress frame");

    auto cq_QualResultsFrame = GetCmapUiLayerFirstChild_Frame(cmap, _lastQualiProgLayerIx+1, COTDQualifications_Ranking);
    if (cq_QualResultsFrame is null) {
        warn(PluginName + ": Couldn't find the QualificationsRanking frame");
        return;
    }

    auto cq_QR_ButtonHide = cq_QualResultsFrame.GetFirstChild("button-hide");
    if (cq_QR_ButtonHide !is null) cq_QR_ButtonHide.Show();
    else warn(PluginName + ": Couldn't find the button-hide on QualificationsRanking frame");

//     for (uint i = 0; i < cmap.UILayers.Length; i++) {
//         auto l = cmap.UILayers[i];
//         auto f = cast<CGameManialinkFrame>(l.LocalPage.GetFirstChild(COTDQualifications_QualificationsProgress));
//         if (f is null) continue;
//         auto c = f.GetFirstChild("button-hide");
//         // might need to toggle on frame-content and/or frame-hideable-content (child) too?
//         if (c is null) continue;
//         c.Show();
//         FindAndUnhideToggleButtonOnLayer(cmap.UILayers[i+1]);
// #if DEV
//         print(PluginName + ": Found the UI element to toggle");
// #endif
//         return;
//     }
//     warn(PluginName + ": Couldn't find the UI element to toggle");
}

CGameManialinkFrame@ GetCmapUiLayerFirstChild_Frame(CGameManiaAppPlayground@ cmap, uint layerIx, const string &in id) {
    return cast<CGameManialinkFrame>(GetCmapUiLayerFirstChild(cmap, layerIx, id));
}

CGameManialinkControl@ GetCmapUiLayerFirstChild(CGameManiaAppPlayground@ cmap, uint layerIx, const string &in id) {
    if (cmap is null || layerIx >= cmap.UILayers.Length) return null;
    auto l = cmap.UILayers[layerIx];
    return l.LocalPage.GetFirstChild(id);
}

int FindQualiProgLayerIx(CGameManiaAppPlayground@ cmap) {
    for (uint i = 0; i < cmap.UILayers.Length; i++) {
        auto l = cmap.UILayers[i];
        auto f = l.LocalPage.GetFirstChild(COTDQualifications_QualificationsProgress);
        if (f !is null) return i;
    }
    return -1;
}

void FindAndUnhideToggleButtonOnLayer(CGameUILayer@ layer) {
    if (layer is null) return;
    auto f = cast<CGameManialinkFrame>(layer.LocalPage.GetFirstChild(COTDQualifications_Ranking));
    if (f is null) return;
    auto c = f.GetFirstChild("button-hide");
    if (c is null) return;
    c.Show();
}

void WatchQualiRespawn() {
    auto app = GetApp();
    while (true) {
        sleep(1000);
        if (!inQuali) return;
        FindAndUnhideToggleButton();
    }
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
