"use strict";

//-----------------------------------------------------------------------------------------
var g_sDiretideTips = [
	"DOTA_diretide_gameplay_tip_00",
	"DOTA_diretide_gameplay_tip_01",
	"DOTA_diretide_gameplay_tip_02",
	"DOTA_diretide_gameplay_tip_03",
	"DOTA_diretide_gameplay_tip_04",
	"DOTA_diretide_gameplay_tip_05",
	"DOTA_diretide_gameplay_tip_06",
	"DOTA_diretide_gameplay_tip_07",
	"DOTA_diretide_gameplay_tip_08",
	"DOTA_diretide_gameplay_tip_09",
	"DOTA_diretide_gameplay_tip_10",
	"DOTA_diretide_gameplay_tip_11",
	"DOTA_diretide_gameplay_tip_12",
	"DOTA_diretide_gameplay_tip_13",
	"DOTA_diretide_gameplay_tip_14",
	"DOTA_diretide_gameplay_tip_15",
];

var g_nNumDiretideTips = g_sDiretideTips.length
var g_nCurrentDiretideTip = 0

//-----------------------------------------------------------------------------------------
$.Schedule( 0.0, function() 
{
	$.Msg( "diretide_pregame_strategy.js - START!" )

	g_nCurrentDiretideTip = Game.Diretide2020GetGameplayTipNumber();

	OnShowPregameStrategy();
} );

//-----------------------------------------------------------------------------------------
function OnShowPregameStrategy()
{
	$.Msg( "diretide_pregame_strategy.js - OnShowPregameStrategy()!" )
	$.GetContextPanel().SetDialogVariableInt( "num_tips", g_nNumDiretideTips );
	SetDiretideTipDialogVars();
}

function IncrementTip( nIncrement )
{
	g_nCurrentDiretideTip = g_nCurrentDiretideTip + nIncrement;
	if ( g_nCurrentDiretideTip < 0 )
	{
		g_nCurrentDiretideTip += g_nNumDiretideTips;
	}
	g_nCurrentDiretideTip = g_nCurrentDiretideTip % g_nNumDiretideTips;

	Game.Diretide2020SetGameplayTipNumber( g_nCurrentDiretideTip );
	SetDiretideTipDialogVars(); 

	Game.EmitSound( "ui_select_arrow" );
}

//-----------------------------------------------------------------------------------------
function SetDiretideTipDialogVars()
{
	$.GetContextPanel().SetDialogVariable( "tip_text", $.Localize( g_sDiretideTips[ g_nCurrentDiretideTip ] ) );
	$.GetContextPanel().SetDialogVariableInt( "current_tip_num", g_nCurrentDiretideTip + 1 );

	$( '#TipBodyText' ).TriggerClass( 'AnimateNextTip' );
}