GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, true )
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false )
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false )

//Game HUDElements
let hud = $.GetContextPanel().GetParent().GetParent().GetParent()
let radiants = hud.FindChildTraverse( "HUDElements" ).FindChildTraverse( "topbar" ).FindChildTraverse( "TopBarRadiantTeamContainer" ).FindChildTraverse( "TopBarRadiantPlayersContainer" )


newUI = hud.FindChildTraverse( "HUDElements" ).FindChildTraverse( "shop" ).FindChildTraverse( "Main" )
newUI.FindChildTraverse( "GridMainShop" ).FindChildTraverse( "GridNeutralsTab" ).style.visibility = "collapse"

//Bg image
let pick_screen = hud.FindChildTraverse( "PreGame" )
let bg = pick_screen.FindChildTraverse( "PregameBG" )
let new_back = $.CreatePanel( "Image", pick_screen, "" )
pick_screen.MoveChildAfter( new_back, bg )
new_back.SetImage( "file://{images}/custom_game/loading_screen/heropick_screen.jpg" )

function HidePickScreen() {
	if ( Game.GetState() != DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION ) {
		pick_screen.style.opacity = "0";
		$.Schedule( 0.01, HidePickScreen)
	}
	else {
		pick_screen.style.opacity = "1";
	}
}

HidePickScreen()

let bottom_panels = pick_screen.FindChildTraverse( "BottomPanelsContainer" )
bottom_panels.FindChildTraverse( "PreMinimapContainer" ).style.visibility = "collapse"
bottom_panels.FindChildTraverse( "AvailableItemsContainer" ).style.visibility = "collapse"
