extends SexInfoBase
class_name SexDomInfo

#var stance = SexStance.Standing

var goals:Array = []
var anger: float = 0.0
var isDown:bool = false
var angerFull: float = 0.0
var hasAnyCumGoals:bool = false
var dynamicJoiner:bool = false # Will auto-leave after completing their goals

func hasGoalToCum() -> bool:
	return hasAnyCumGoals

func afterGoalsAssigned():
	checkHasCumGoals()

func checkHasCumGoals():
	#hasAnyCumGoals = false
	for goalInfo in goals:
		var goalID = goalInfo[0]
		var sexGoal = GlobalRegistry.getSexGoal(goalID)
		if(sexGoal == null):
			continue
		if(sexGoal.domWantsToCum()):
			hasAnyCumGoals = true

func checkIsDown():
	if(!isDown && getChar().getPainLevel() >= 1.0):
		isDown = true
		return true
	return false

func getIsDown() -> bool:
	return isDown

func canDoActions() -> bool:
	return !isDown

func addAnger(howmuch = 0.2):
	var meanness = personalityScore({PersonalityStat.Mean:0.5, PersonalityStat.Impatient:0.2, PersonalityStat.Subby:-0.2})
	if(meanness >= 0.0):
		if(howmuch > 0.0):
			howmuch *= (1.0 + meanness)
		else:
			howmuch *= max(1.0 - meanness, 0.1)
	else:
		if(howmuch > 0.0):
			howmuch *= max(1.0 + meanness, 0.1)
		else:
			howmuch *= (1.0 - meanness)
	
	if(meanness < 0.5):
		addFrustration(max(howmuch * (0.5 - meanness), 0.0))
	
	anger += howmuch
	anger = clamp(anger, 0.0, 1.0)

func getAngerScore():
	return anger

func getIsAngryScore():
	if(isAngry()):
		return 1.0
	return 0.0

func getIsSlightlyAngryScore():
	if(isSlightlyAngry()):
		return 1.0
	return 0.0

func getTrustsSubScore():
	return clamp(1.0 - anger * 3.0, 0.0, 1.0)

func isSlightlyAngry():
	return anger > 0.2

func isAngry():
	return anger > (0.6 - personalityScore({PersonalityStat.Mean: 0.2}))

func getSadisticActionStore():
	var sadistScore = fetishScore({Fetish.Sadism: 1.0})
	var angerScore = getAngerScore()
	var meanScore = personalityScore({PersonalityStat.Mean: 1.0})
	
	return sadistScore / 8.0 + angerScore / 10.0 + meanScore / 10.0

func getInfoString(_isSelected:bool = false) -> String:
	var character = getChar()
	
	var text:String = ""
	if(character != null):
		if(_isSelected):
			text += "\\["+character.getName()+"\\]"+". "
		else:
			text += character.getName()+". "
	text += "Anger: "+str(Util.roundF(anger*100))+"% "
	text += "Arousal: "+str(Util.roundF(getArousal()*100))+"% "
	
	return text

func initFromPersonality():
	var character = getChar()
	var personality:Personality = character.getPersonality()

	var mean = personality.getStat(PersonalityStat.Mean)
	
	if(mean > 0.0):
		anger = RNG.randf_range(0.0, mean) / 5.0

func processTurn():
	arousalNaturalFade()
#	var character = getChar()
#	var personality:Personality = character.getPersonality()
#
#	var evilness = personality.getStat(PersonalityStat.Evilness)
#	anger = Util.moveNumberTowards(anger, evilness, 0.01)

	.processTurn()
	angerFull += anger

func hasGoals():
	return goals.size() > 0

func goalsScore(thegoals:Dictionary, theSubID):
	var result = 0.0
	for goalInfo in goals:
		if(thegoals.has(goalInfo[0]) && goalInfo[1] == theSubID):
			result += thegoals[goalInfo[0]]
	
	return result

func goalsScoreMax(thegoals:Dictionary, theSubID):
	var result = 0.0
	for goalInfo in goals:
		if(thegoals.has(goalInfo[0]) && goalInfo[1] == theSubID):
			result = max(result, thegoals[goalInfo[0]])
	
	return result

func getAverageAnger() -> float:
	return angerFull / float(Util.maxi(1, tick))

func getSexEndInfo():
	var texts:Array = .getSexEndInfo()
	
	texts.append("Average anger: "+str(Util.roundF(getAverageAnger()*100.0, 1))+"%")
	
	return texts

func affectPersonality(_personality:Personality, _fetishHolder:FetishHolder):
	var theChanges = []
	
	if(!canDoActions()):
		if(RNG.chance(50)):
			if(_personality.addStat(PersonalityStat.Subby, RNG.randf_range(0.05, 0.1))):
				theChanges.append("{npc.name} became less dominant because {npc.he} got beaten up by a sub.")
		if(RNG.chance(50)):
			if(_personality.addStat(PersonalityStat.Coward, RNG.randf_range(0.01, 0.1))):
				theChanges.append("{npc.name} became more cowardly because {npc.he} got beaten up by a sub.")
		if(RNG.chance(50)):
			if(_personality.addStat(PersonalityStat.Mean, RNG.randf_range(0.01, 0.1))):
				theChanges.append("{npc.name} became more mean because {npc.he} got beaten up by a sub.")
	else:
		if(RNG.chance(30)):
			if(_personality.addStat(PersonalityStat.Subby, RNG.randf_range(-0.05, -0.01))):
				theChanges.append("{npc.name} became slightly more dominant because {npc.he} achieved {npc.his} goals.")
		if(RNG.chance(30)):
			if(_personality.addStat(PersonalityStat.Impatient, RNG.randf_range(-0.05, -0.01))):
				theChanges.append("{npc.name} became less impatient because {npc.he} achieved {npc.his} goals.")
		if(RNG.chance(30)):
			if(_personality.addStat(PersonalityStat.Coward, RNG.randf_range(-0.05, -0.01))):
				theChanges.append("{npc.name} became more brave because {npc.he} achieved {npc.his} goals.")

		if(getTimesCame() >= 1 && getAverageAnger() < 0.3):
			if(RNG.chance(50)):
				if(_personality.addStat(PersonalityStat.Subby, RNG.randf_range(-0.1, -0.01))):
					theChanges.append("{npc.name} became more dominant after a good sex.")
			if(RNG.chance(30)):
				if(_personality.addStat(PersonalityStat.Brat, RNG.randf_range(0.01, 0.05))):
					theChanges.append("{npc.name} became slightly more bratty after a good sex.")
			if(RNG.chance(30)):
				if(_personality.addStat(PersonalityStat.Coward, RNG.randf_range(-0.05, -0.01))):
					theChanges.append("{npc.name} became less cowardly after a good sex.")

		if(getAverageAnger() > 0.5):
			if(RNG.chance(50)):
				if(_personality.addStat(PersonalityStat.Mean, RNG.randf_range(0.01, 0.1))):
					theChanges.append("{npc.name} became more mean after being so angry.")
			if(RNG.chance(40)):
				if(_personality.addStat(PersonalityStat.Subby, RNG.randf_range(-0.1, -0.01))):
					theChanges.append("{npc.name} became more dominant after being so angry.")
		else:
			if(RNG.chance(30)):
				if(_personality.addStat(PersonalityStat.Mean, RNG.randf_range(-0.05, -0.01))):
					theChanges.append("{npc.name} became slightly more kind after not being so angry.")
	
	return GM.ui.processString(Util.join(theChanges, "\n"), {npc=charID})

func getOpponentInfo():
	return getSexEngine().subs[getSexEngine().subs.keys()[0]]

func onGoalSatisfied(_thedominfo, _goalid, _thesubinfo, _mult:float = 1.0):
	addSatisfaction(0.5*_mult)

func onGoalFailed(_thedominfo, _goalid, _thesubinfo, _mult:float = 1.0):
	addFrustration(1.0*_mult)

func setDynamicJoiner(_isDyn:bool):
	dynamicJoiner = _isDyn

func isDynamicJoiner() -> bool:
	return dynamicJoiner

func saveData():
	var data = .saveData()
	
	data["goals"] = goals
	data["anger"] = anger
	data["isDown"] = isDown
	data["angerFull"] = angerFull
	data["hasAnyCumGoals"] = hasAnyCumGoals
	data["dynamicJoiner"] = dynamicJoiner

	return data
	
func loadData(data):
	.loadData(data)
	
	goals = SAVE.loadVar(data, "goals", [])
	anger = SAVE.loadVar(data, "anger", 0.0)
	isDown = SAVE.loadVar(data, "isDown", false)
	angerFull = SAVE.loadVar(data, "angerFull", 0.0)
	hasAnyCumGoals = SAVE.loadVar(data, "hasAnyCumGoals", false)
	dynamicJoiner = SAVE.loadVar(data, "dynamicJoiner", false)
