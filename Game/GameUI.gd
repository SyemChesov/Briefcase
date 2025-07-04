extends Control
class_name GameUI

signal on_option_button(method, args)
signal on_rollback_button
signal onDevComButton
var buttons: Array = []
var buttonsCountPerPage: int = 15
var optionButtonScene: PackedScene = preload("res://Game/SceneOptionButton.tscn")
onready var optionButtonsContainer = $HBoxContainer/VBoxContainer2/HBoxContainer/GridContainer
var currentPage:int = 0
var options: Dictionary = {}
var extraOptions: Dictionary = {}
var optionsCurrentID = 0
var buttonsNeedUpdating:bool = false
var extraButtonsNeedUpdating:bool = false
onready var nextPageButton = $HBoxContainer/VBoxContainer2/HBoxContainer/NextPageButton
onready var prevPageButton = $HBoxContainer/VBoxContainer2/HBoxContainer/PrevPageButton
onready var optionTooltip = $CanvasLayer/TooltipDisplay
onready var textOutput = $HBoxContainer/VBoxContainer2/ScrollContainer/VBoxContainer/RichTextLabel
onready var mapAndTimePanel = $HBoxContainer/Panel2/MarginContainer/VBoxContainer/MapAndTimePanel
onready var playerPanel = $HBoxContainer/Panel/MarginContainer/PlayerPanel
onready var scrollPanel = $HBoxContainer/VBoxContainer2/ScrollContainer
onready var mainGameScreen = $HBoxContainer/VBoxContainer2
onready var ingameMenuScreen = $HBoxContainer/InGameMenu
onready var skillsScreen = $HBoxContainer/SkillsUI
onready var skillsButton = $HBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer3/SkillsButton
onready var debugScreen = $HBoxContainer/DebugPanel
onready var debugPanelButton = $HBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer3/DebugMenu
onready var rollbackButton = $HBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/RollbackButton
var uiTextboxScene = preload("res://UI/UITextbox.tscn")
var uiTextboxBigScene = preload("res://UI/UITextboxBig.tscn")
onready var textcontainer = $HBoxContainer/VBoxContainer2/ScrollContainer/VBoxContainer
onready var smartCharacterPanel = $HBoxContainer/Panel2/MarginContainer/VBoxContainer/SmartCharacterPanel
onready var devCommentaryPanel = $HBoxContainer/DevCommentary
onready var sceneArtWorkRect = $HBoxContainer/VBoxContainer2/ScrollContainer/VBoxContainer/SceneArtWorkRect
onready var fullArtWorkRect = $FullArtworkRect
onready var uniquePanelSpot = $HBoxContainer/VBoxContainer2/UniquePanelSpot
onready var extra_buttons_grid = $"%ExtraButtonsGrid"
var textboxes: Dictionary = {}
var gameParser: GameParser
var sayParser: SayParser
onready var hornyMessage = $MessageSystem
var isInBigAnswersMode = false

func _exit_tree():
	GM.ui = null

# Called when the node enters the scene tree for the first time.
func _ready():
	GM.ui = self
	
	if(!OPTIONS.isDebugPanelEnabled()):
		debugPanelButton.visible = false
		debugPanelButton.disabled = true
	
	if(!AutoTranslation.shouldTranslate()):
		$HBoxContainer/VBoxContainer2/Panel/TranslateBox.visible = false
	
	manualTranslateButton.visible = false
	
	var fontOverride = OPTIONS.getFontSize()
	if(fontOverride == "small"):
		setFontSize(18)
	if(fontOverride == "big"):
		setFontSize(30)
	#setFontSize(24)
	
	gameParser = GameParser.new()
	sayParser = SayParser.new()
	
	var shortCutKeys = [
		49, 50, 51, 52, 53,
		81, 87, 69, 82, 84,
		65, 83, 68, 70, 71,
		#90, 88, 67, 86, 66,
	]
	var _i = 0
	for n in buttonsCountPerPage:
		var newbutton = optionButtonScene.instance()
		buttons.append(newbutton)
		optionButtonsContainer.add_child(newbutton)
		
		if(_i < shortCutKeys.size()):
			newbutton.setShortcutPhysicalScancode(shortCutKeys[_i])
		_i += 1
		
	if(!OPTIONS.isRollbackEnabled()):
		rollbackButton.visible = false
		
	updateButtons()
	#setBigAnswersMode(true)
	
	if(OS.has_touchscreen_ui_hint()):
		textOutput.selection_enabled = false
	
	hornyMessage.visible = true
		
func say(text: String):
	#textOutput.append_bbcode(gameParser.executeString(sayParser.processString(text)))
	textOutput.bbcode_text += gameParser.executeString(sayParser.processString(text))

func addImage(_image:Image):
	#var _ok = image.save_png("user://temp_image.png")
	#say("[img=300]"+"user://temp_image.png"+"[/img]\n\n")
	#textOutput.add_image(image, textOutput.rect_size.x-50.0, 0.0)
	pass

func clearText():
	#textOutput.scroll_to_line(1)
	scrollPanel.set_v_scroll(0)
	textOutput.bbcode_text = ""
		
		
func clearButtons():
	#for i in buttonsCountPerPage:
	#	buttons[i].queue_free()
	#buttons = []
	options = {}
	optionsCurrentID = 0
	currentPage = 0
	updateButtons()
	clearExtraButtons()
	_on_option_button_tooltip_end()
		
func addButtonAt(place, text: String, tooltip: String = "", method: String = "", args = []):
	options[place] = [true, text, tooltip, method, args]
	queueUpdate()
	
func addDisabledButtonAt(place, text: String, tooltip: String = ""):
	options[place] = [false, text, tooltip]
	queueUpdate()
		
func addButton(text: String, tooltip: String = "", method: String = "", args = []):
	while(options.has(optionsCurrentID)):
		optionsCurrentID += 1
	options[optionsCurrentID] = [true, text, tooltip, method, args]
	queueUpdate()
	
func addDisabledButton(text: String, tooltip: String = ""):
	while(options.has(optionsCurrentID)):
		optionsCurrentID += 1
	options[optionsCurrentID] = [false, text, tooltip]
	queueUpdate()


func queueUpdate():
	if(buttonsNeedUpdating):
		return
	buttonsNeedUpdating = true
	yield(get_tree(), "idle_frame")
	buttonsNeedUpdating = false
	updateButtons()

func clearExtraButtons():
	extraOptions.clear()
	updateExtraButtons()

func addExtraButton(text: String, tooltip: String = "", method: String = "", args = []):
	var _i:int = 0
	while(extraOptions.has(_i)):
		_i += 1
	addExtraButtonAt(_i, text, tooltip, method, args)

func addExtraButtonAt(_indx:int, text: String, tooltip: String = "", method: String = "", args = []):
	extraOptions[_indx] = [true, text, tooltip, method, args]
	queueExtraUpdate()

func queueExtraUpdate():
	if(extraButtonsNeedUpdating):
		return
	extraButtonsNeedUpdating = true
	yield(get_tree(), "idle_frame")
	extraButtonsNeedUpdating = false
	updateExtraButtons()

func updateExtraButtons():
	Util.delete_children(extra_buttons_grid)
	
	var theIndxes:Array = extraOptions.keys()
	theIndxes.sort()
	
	for _indx in theIndxes:
		var currButtonAm:int = extra_buttons_grid.get_child_count()
		if(_indx > currButtonAm):
			for _i in range(_indx-currButtonAm):
				var spaceHolder:Control = Control.new()
				spaceHolder.size_flags_horizontal = SIZE_EXPAND_FILL
				extra_buttons_grid.add_child(spaceHolder)
		
		var theOptionEntry:Array = extraOptions[_indx]
		var newButton = optionButtonScene.instance()
		newButton.text = theOptionEntry[1]
		extra_buttons_grid.add_child(newButton)
		newButton.setShortcutPhysicalScancode(KEY_1+_indx, true)
		var _some = newButton.connect("pressedActually", self, "_on_extra_option_button", [_indx])
		var _some2 = newButton.connect("mouse_entered", self, "_on_extra_option_button_tooltip", [_indx])
		var _some3 = newButton.connect("mouse_exited", self, "_on_option_button_tooltip_end")

func setBigAnswersMode(newmode):
	if(!isInBigAnswersMode && newmode):
		optionButtonsContainer.columns = 1
		buttonsCountPerPage = 15
		
		for i in buttonsCountPerPage:
			if(i <= 3):
				continue
			var button:Button = buttons[i]
			button.visible = false
		
		buttonsCountPerPage = 4
	elif(isInBigAnswersMode && !newmode):
		optionButtonsContainer.columns = 5
		buttonsCountPerPage = 15
		
		for i in buttonsCountPerPage:
			#if(i <= 3):
			#	continue
			var button:Button = buttons[i]
			button.visible = true
	isInBigAnswersMode = newmode

onready var save_button = $HBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer2/SaveButton
onready var skills_button = $HBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer3/SkillsButton


func updateButtons():
	checkPageButtons()
	
	if(GM.main != null):
		if(GM.main.rollbacker.canRollback()):
			rollbackButton.disabled = false
		else:
			rollbackButton.disabled = true
		if(GM.main.canSave()):
			save_button.disabled = false
		else:
			save_button.disabled = true
		
		if(GM.main.isInDungeon()):
			skills_button.disabled = true
		else:
			skills_button.disabled = false
		
	for i in buttonsCountPerPage:
		var button:Button = buttons[i]
		button.disabled = true
		button.text = ""
		if(button.is_connected("pressedActually", self, "_on_option_button")):
			button.disconnect("pressedActually", self, "_on_option_button")
		if(button.is_connected("mouse_entered", self, "_on_option_button_tooltip")):
			button.disconnect("mouse_entered", self, "_on_option_button_tooltip")
		if(button.is_connected("mouse_exited", self, "_on_option_button_tooltip_end")):
			button.disconnect("mouse_exited", self, "_on_option_button_tooltip_end")
	
	
	for i in buttonsCountPerPage:
		var index = currentPage * buttonsCountPerPage + i
		if(index < 0):
			break
		if(!options.has(index)):
			continue
			
		var option = options[index]
		var button:Button = buttons[i]
		button.text = option[1]
		button.disabled = !option[0]
		if(AutoTranslation.shouldTranslateButtons && !showOriginalCheckbox.pressed):
			if(!button.disabled && option.size() > 5):
				button.text = option[5]
			if(button.disabled && option.size() > 3):
				button.text = option[3]
		#button.set_meta("game_option", index)
		var _some = button.connect("pressedActually", self, "_on_option_button", [index])
		var _some2 = button.connect("mouse_entered", self, "_on_option_button_tooltip", [index])
		var _some3 = button.connect("mouse_exited", self, "_on_option_button_tooltip_end")


func _on_extra_option_button(index):
	var option = extraOptions[index]
	emit_signal("on_option_button", option[3], option[4])

func _on_option_button(index):
	var option = options[index]
	#print("hello ",index, option)
	
	emit_signal("on_option_button", option[3], option[4])
	
func _on_extra_option_button_tooltip(index):
	var option = extraOptions[index]
	if(option[2] == ""):
		return
	optionTooltip.set_is_active(true)
	optionTooltip.set_text(option[1], option[2])
	
func _on_option_button_tooltip(index):
	var option = options[index]
	if(option[2] == ""):
		return
	optionTooltip.set_is_active(true)
	if(!AutoTranslation.shouldTranslateButtons || showOriginalCheckbox.pressed):
		optionTooltip.set_text(option[1], option[2])
	else:
		if(option[0] && option.size() > 6):
			optionTooltip.set_text(option[5], option[6])
		elif(!option[0]&& option.size() > 4):
			optionTooltip.set_text(option[3], option[4])
		else:
			optionTooltip.set_text(option[1], option[2])

func _on_option_button_tooltip_end():
	optionTooltip.set_is_active(false)

func checkPageButtons():
	if(currentPage > 0):
		prevPageButton.disabled = false
	else:
		prevPageButton.disabled = true
	
	var maxpages = ceil(float(options.size())/float(buttonsCountPerPage))
	if(maxpages > (currentPage+1)):
		nextPageButton.disabled = false
	else:
		nextPageButton.disabled = true
		
	if(maxpages > 1):
		nextPageButton.visible = true
		prevPageButton.visible = true
	else:
		nextPageButton.visible = false
		prevPageButton.visible = false

func _on_NextPageButton_pressed():
	currentPage += 1
	updateButtons()

func _on_PrevPageButton_pressed():
	currentPage -= 1
	if(currentPage < 0):
		currentPage = 0
		return
	updateButtons()

func setLocationName(locname: String):
	mapAndTimePanel.setLocationName(locname)

func setSceneCreator(sceneCreator, shouldShowDevCommentaryIcon = false):
	mapAndTimePanel.setSceneCreator(sceneCreator, shouldShowDevCommentaryIcon)

func clearCharactersPanel():
	smartCharacterPanel.clear()

func getPlayerStatusEffectsPanel():
	return playerPanel.getStatusEffectsPanel()

func getCharactersPanel():
	return smartCharacterPanel

func addFullScreenCustomControl(id, control):
	assert(!textboxes.has(id), "Trying to add a control with the same id. Id is "+id)

	#var uitextbox = uiTextboxScene.instance()
	#uitextbox.id = id
	uniquePanelSpot.visible = true
	scrollPanel.visible = false
	uniquePanelSpot.add_child(control)
	textboxes[id] = control

func addUITextbox(id):
	assert(!textboxes.has(id), "Trying to add a textbox with the same id. Id is "+id)
	
	var uitextbox = uiTextboxScene.instance()
	uitextbox.id = id
	textcontainer.add_child(uitextbox)
	if(!OPTIONS.shouldUseFallbackTextInputs()):
		uitextbox.grab_focus()
	textboxes[id] = uitextbox
	return uitextbox

func addBigUITextbox(id):
	assert(!textboxes.has(id), "Trying to add a textbox with the same id. Id is "+id)
	
	var uitextbox = uiTextboxBigScene.instance()
	uitextbox.id = id
	textcontainer.add_child(uitextbox)
	if(!OPTIONS.shouldUseFallbackTextInputs()):
		uitextbox.grab_focus()
	textboxes[id] = uitextbox
	return uitextbox
	
func addCustomControl(id, control):
	assert(!textboxes.has(id), "Trying to add a control with the same id. Id is "+id)

	#var uitextbox = uiTextboxScene.instance()
	#uitextbox.id = id
	textcontainer.add_child(control)
	textboxes[id] = control

func getCustomControl(id):
	if(!textboxes.has(id)):
		return null
	
	return textboxes[id]

func getUIdata(id):
	assert(textboxes.has(id), "Trying to get info from bad id. Id is "+id)
	return textboxes[id].getData()

func clearUItextboxes():
	for id in textboxes.keys():
		var textbox = textboxes[id]
		#textcontainer.remove_child(textbox)
		textbox.queue_free()
	textboxes = {}
	scrollPanel.visible = true
	uniquePanelSpot.visible = false

func loadingSavefileFinished():
	playerPanel.loadingSavefileFinished()

func _on_SaveButton_pressed():
	SAVE.makeQuickSave()

func _on_LoadButton_pressed():
	SAVE.loadQuickSave()
	
func trimLineEndings():
	textOutput.bbcode_text = textOutput.bbcode_text.trim_suffix("\n")

func onTimePassed(_secondsPassed):
	mapAndTimePanel.onTimePassed(_secondsPassed)

func processString(strText: String, overrides: Dictionary = {}):
	return gameParser.executeString(sayParser.processString(strText, overrides), overrides)

func hideAllScreens():
	GlobalTooltip.resetTooltips()
	mainGameScreen.visible = false
	ingameMenuScreen.visible = false
	skillsScreen.visible = false
	debugScreen.visible = false
	devCommentaryPanel.visible = false

func _on_MenuButton_pressed():
	if(!ingameMenuScreen.visible):
		hideAllScreens()
		ingameMenuScreen.visible = true
	else:
		hideAllScreens()
		mainGameScreen.visible = true

func showGameScreen():
	hideAllScreens()
	mainGameScreen.visible = true

func getCurrentLocationName():
	return mapAndTimePanel.getLocationName()


func _on_SkillsButton_pressed():
	skillsButton.text = "Skills"
	if(!skillsScreen.visible):
		hideAllScreens()
		skillsScreen.visible = true
	else:
		hideAllScreens()
		mainGameScreen.visible = true

func makeSkillsButtonFlash():
	skillsButton.text = "[!]Skills"


func _on_Player_animation_changed(newanim):
	playerPanel.on_player_animationchange(newanim)

func _on_Player_bodypart_changed():
	playerPanel.on_player_bodypartchange()

func _on_Player_stat_changed():
	playerPanel.on_player_statchange()

func getStage3d() -> Stage3D:
	return playerPanel.getStage3d()

func setFontSize(_newsize):
	var fontsToChange = ["normal_font", "bold_font", "bold_italics_font", "italics_font"]
	
	for fontToChange in fontsToChange:
		var theFont = textOutput.get_font(fontToChange)
		theFont.size = _newsize
#	if(newsize == "big"):
#		textOutput.add_font_override("normal_font", load("res://UI/FontResources/Big/NormalFont.tres"))
#		textOutput.add_font_override("italics_font", load("res://UI/FontResources/Big/ItalicsFont.tres"))
#		textOutput.add_font_override("bold_italics_font", load("res://UI/FontResources/Big/BoldItalicsFont.tres"))
#		textOutput.add_font_override("bold_font", load("res://UI/FontResources/Big/BoldFont.tres"))
#	if(newsize == "normal"):
#		textOutput.add_font_override("normal_font", load("res://UI/FontResources/Normal/NormalFont.tres"))
#		textOutput.add_font_override("italics_font", load("res://UI/FontResources/Normal/ItalicsFont.tres"))
#		textOutput.add_font_override("bold_italics_font", load("res://UI/FontResources/Normal/BoldItalicsFont.tres"))
#		textOutput.add_font_override("bold_font", load("res://UI/FontResources/Normal/BoldFont.tres"))
#	if(newsize == "small"):
#		textOutput.add_font_override("normal_font", load("res://UI/FontResources/Small/NormalFont.tres"))
#		textOutput.add_font_override("italics_font", load("res://UI/FontResources/Small/ItalicsFont.tres"))
#		textOutput.add_font_override("bold_italics_font", load("res://UI/FontResources/Small/BoldItalicsFont.tres"))
#		textOutput.add_font_override("bold_font", load("res://UI/FontResources/Small/BoldFont.tres"))
		
func _on_DebugMenu_pressed():
	if(!debugScreen.visible):
		hideAllScreens()
		debugScreen.visible = true
	else:
		hideAllScreens()
		mainGameScreen.visible = true

func addCharacterToPanel(id, variant):
	smartCharacterPanel.addCharacter(id, variant)
	
func removeCharacterFromPanel(id):
	smartCharacterPanel.removeCharacter(id)

func updateCharactersInPanel():
	smartCharacterPanel.updateData()

func recreateWorld():
	mapAndTimePanel.recreateWorld()

func _on_RollbackButton_pressed():
	emit_signal("on_rollback_button")

var savedOriginalText = ""
var savedTranslatedText = ""
var currentTranslationTask = 0
onready var translateStatusLabel = $HBoxContainer/VBoxContainer2/Panel/TranslateBox/TranslateStatusLabel
onready var showOriginalCheckbox = $HBoxContainer/VBoxContainer2/Panel/TranslateBox/ShowOriginalCheckbox
onready var manualTranslateButton = $HBoxContainer/VBoxContainer2/Panel/TranslateBox/ManualTranslateButton
func translateText(manualButton = false):
	if(AutoTranslation.shouldTranslate()):
		showOriginalCheckbox.disabled = true
		if(!manualButton && AutoTranslation.shouldHaveManualTranslateButton()):
			manualTranslateButton.visible = true
			return
		
		var buttonsTexts = []
		if(AutoTranslation.shouldTranslateButtons):
			for optionID in options:
				buttonsTexts.append(options[optionID][1])
				buttonsTexts.append(options[optionID][2].replace("\n", "^"))
		
		translateStatusLabel.text = "Translating.."
		currentTranslationTask += 1
		var rememberedTask = currentTranslationTask
		savedOriginalText = textOutput.bbcode_text
		
		var toTranslate = textOutput.text
		if(buttonsTexts.size() > 0):
			toTranslate += "\n"+Util.join(buttonsTexts, "\n")
		var result = AutoTranslation.translate(toTranslate)
	
		if(result is GDScriptFunctionState):
			result = yield(result, "completed")
		
		if(rememberedTask != currentTranslationTask):
			return
		
		if(result == null || result == ""):
			translateStatusLabel.text = "Failed to translate"
		if(result != null && result != ""):
			if(buttonsTexts.size() > 0):
				var resultSplitted = result.split("\n")
				if(resultSplitted.size() >= buttonsTexts.size()):
					var _i = 0
					for optionID in options:
						var realI = resultSplitted.size() - buttonsTexts.size() + _i*2
						options[optionID].append(resultSplitted[realI])
						options[optionID].append(resultSplitted[realI+1].replace("^", "\n"))
						
						_i += 1
					resultSplitted.resize(resultSplitted.size() - buttonsTexts.size())
					result = Util.join(resultSplitted, "\n")
					queueUpdate()
			
			savedTranslatedText = result
			if(!showOriginalCheckbox.pressed):
				textOutput.bbcode_text = result
			if(AutoTranslation.hadToUseFallback):
				translateStatusLabel.text = "Used fallback translator"
				yield(get_tree().create_timer(2.0), "timeout")
				if(translateStatusLabel != null && translateStatusLabel.text == "Used fallback translator"):
					translateStatusLabel.text = ""
			else:
				translateStatusLabel.text = ""
				
			showOriginalCheckbox.disabled = false

func _on_ShowOriginalCheckbox_pressed():
	if(showOriginalCheckbox.pressed):
		textOutput.bbcode_text = savedOriginalText
	else:
		textOutput.bbcode_text = savedTranslatedText
	queueUpdate()


func _on_ManualTranslateButton_pressed():
	manualTranslateButton.visible = false
	translateText(true)


func _on_MapAndTimePanel_onDevComButton():
	emit_signal("onDevComButton")
	
	

onready var devComLabel = $HBoxContainer/DevCommentary/ScrollContainer/DevComLabel
func showDevCommentary(thetext):
	hideAllScreens()
	devCommentaryPanel.visible = true
	devComLabel.bbcode_text = thetext

func _on_DevComLabel_meta_clicked(meta):
	var _ok = OS.shell_open(meta)

func isShowingDevCommentary():
	return devCommentaryPanel.visible

func clearSceneArtwork():
	sceneArtWorkRect.textures = null
	sceneArtWorkRect.visible = false
	fullArtWorkRect.textures = null
	$FullArtworkRect/Label.text = ""

func setSceneArtWork(imageData):
	if(imageData == null || !(imageData is Dictionary) || !OPTIONS.shouldShowSceneArt()):
		pass
	else:
		if(imageData.has("artist") && imageData["artist"] != ""):
			$FullArtworkRect/Label.text = "Art by "+str(imageData["artist"])
		else:
			$FullArtworkRect/Label.text = ""
		fullArtWorkRect.textures = imageData["imagePath"]
		sceneArtWorkRect.textures = imageData["imagePath"]
		if(imageData.has("imageHeight")):
			sceneArtWorkRect.rect_min_size.y = imageData["imageHeight"]
		else:
			sceneArtWorkRect.rect_min_size.y = 0
			sceneArtWorkRect.hydrateSize(imageData["imageScale"] if imageData.has("imageScale") else 1.0)
		sceneArtWorkRect.visible = true

func _on_OpenFullArtWorkButton_pressed():
	fullArtWorkRect.visible = true

func _on_CloseFullArtWork_pressed():
	fullArtWorkRect.visible = false

func showHornyMessage(theMessage: String):
	hornyMessage.showMessageOnScreen(theMessage)

func getCurrentPage() -> int:
	return currentPage

func setCurrentPage(newCurrentPage:int):
	var maxpages:int = int(ceil(float(options.size())/float(buttonsCountPerPage)))
	if(newCurrentPage > maxpages):
		newCurrentPage = maxpages
	if(newCurrentPage < 0):
		newCurrentPage = 0
	
	currentPage = newCurrentPage
	
	updateButtons()
