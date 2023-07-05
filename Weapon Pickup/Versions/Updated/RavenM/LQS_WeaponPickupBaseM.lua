-- low_quality_soarin, RadioactiveJellyfish © 2023-2024
-- Weapon Pickup Rewrite, RavenM version.
behaviour("LQS_WeaponPickupBaseM")

function LQS_WeaponPickupBaseM:Awake()
    -- Drop Index
    -- For RavenM aswell lmao
    self.curIDIndex = 0

	-- From RadioactiveJellyfish: Table of functions for event listeners
	self.onWeaponPickUpListeners = {}
end

function LQS_WeaponPickupBaseM:Start()
	-- Base
    self.pickupObject = self.targets.pickupObject
    self.emptyCopy = self.targets.emptyCopy

    -- HUD
    self.canvas = self.targets.canvas

	self.defaultHUD = self.targets.hud
	self.anarchyHUD = self.targets.anarchyHud

	self.anarchy = self.targets.anarchyInv.GetComponent(ScriptedBehaviour).self
	self.standard = self.targets.defaultInv.GetComponent(ScriptedBehaviour).self

    -- Rigid force
    self.throwForce = 18.7
    self.upwardForce = 8.5

    -- Keybinds
	self.pickupKey = self:CheckKeyCode(string.lower(self.script.mutator.GetConfigurationString("pickupKey")))
	self.dropKey = self:CheckKeyCode(string.lower(self.script.mutator.GetConfigurationString("dropKey")))

    -- Config
	self.pickupRange = self.script.mutator.GetConfigurationFloat("pickupRange")

	self.canDespawn = self.script.mutator.GetConfigurationBool("canDespawn")
	self.despawnTime = self.script.mutator.GetConfigurationFloat("despawnTime")

	self.pickupCooldown = self.script.mutator.GetConfigurationFloat("pickupDelay")
	self.canPickup = true

	self.dropChanceEnabled = self.script.mutator.GetConfigurationBool("dropChanceEnabled")
	self.dropChanceDontAffectPlayer = self.script.mutator.GetConfigurationBool("dropChanceDontAffectPlayer")
	self.dropChance = self.script.mutator.GetConfigurationRange("dropChance")

	self.canBlacklist = self.script.mutator.GetConfigurationBool("canBlacklist")
	self.blacklistedWeapons = {}

	for word in string.gmatch(string.upper(self.script.mutator.GetConfigurationString("weaponBlacklist")), '([^,]+)') do
		self.blacklistedWeapons[word] = true
	end

	self.dropDistanceEnabled = self.script.mutator.GetConfigurationBool("dropByDistance")
	self.dropDistance = self.script.mutator.GetConfigurationFloat("dropDistance")

	self.freezePhysicsWhenStopped = self.script.mutator.GetConfigurationBool("freezePhysicsWhenStopped")
	self.freezePhysicsDistance = self.script.mutator.GetConfigurationFloat("freezePhysicsDistance")

	self.anarchyMode = self.script.mutator.GetConfigurationBool("anarchyMode")

	-- Listeners
	GameEvents.onActorDied.AddListener(self, "OnActorDied")
    GameEventsOnline.onSendPacket.AddListener(self, "SendPacket")
    GameEventsOnline.onReceivePacket.AddListener(self,"ReceivePacket")

    -- RavenM shit
    -- RandomID, this is always random per clients in a match since it doesn't matter ig
    -- Its always a string. But it will be converted into a int later when sending packets
    self.weaponPickupBaseID = math.random(0, 100) .. math.random(0, 100) .. math.random(0, 100) .. math.random(0, 100)

    -- Vars
    self.queuePickupData = nil
    self.isMenuOpen = false
    self.alreadyDisabledHUD = true

	-- Finishing touches
    -- Compatability
    self.script.StartCoroutine(self:Compatibility())

    -- Disable selection HUDs
    self.canvas.SetActive(false)
	self.anarchyHUD.SetActive(false)
	self.defaultHUD.SetActive(false)

    -- Share Instance
    _G.LQSWeaponPickupBaseM = self.gameObject.GetComponent(ScriptedBehaviour).self
end

function LQS_WeaponPickupBaseM:SendPacket(id, data)
    -- I don't know anything about networking, soo here goes trying..
    self:DropWeaponStart(data)
end

function LQS_WeaponPickupBaseM:ReceivePacket(id, data)
    -- Same thing as send packet..
    self:DropWeaponStart(data)
    self:UpdateDropID(data)
end

function LQS_WeaponPickupBaseM:UpdateDropID(data)
    -- Basically just updates the drop ID
    local unwrappedData = self:UnwrapPacket(data)

    if (#unwrappedData == 0) then return end
    if (unwrappedData[1] ~= "lqswpbase") then return end
    if (unwrappedData[3] ~= "updateidindex") then return end

    local idNumber = tonumber(unwrappedData[2])
    if (idNumber) then
        self.curIDIndex = idNumber
    end
end

function LQS_WeaponPickupBaseM:UnwrapPacket(data)
    -- My own unwrapping method
    -- It always uses ";;" as a seperator
    local dataFinal = {}
    for word in string.gmatch(data, "([^;;]+)") do
        dataFinal[#dataFinal+1] = word
    end
    return dataFinal
end

function LQS_WeaponPickupBaseM:CheckKeyCode(key)
	-- From my badycam mutator
	-- Basically converts it to a keycode when its a unique one
    
    -- If the given key is a nil then retun the "None" keycode
    if (not key) then return KeyCode.None end

    -- The binds
	local uniqueBinds = {
		{"leftalt", KeyCode.LeftAlt},
		{"rightalt", KeyCode.RightAlt},
		{"capslock", KeyCode.CapsLock},
		{"tab", KeyCode.Tab},
		{"rightshift", KeyCode.RightShift},
		{"leftshift", KeyCode.LeftShift},
		{"pageup", KeyCode.PageUp},
		{"pagedown", KeyCode.PageDown},
		{"delete", KeyCode.Delete},
		{"backspace", KeyCode.Backspace},
		{"space", KeyCode.Space},
		{"clear", KeyCode.Clear},
		{"uparrow", KeyCode.UpArrow},
		{"downarrow", KeyCode.DownArrow},
		{"rightarrow", KeyCode.RightArrow},
		{"leftarrow", KeyCode.LeftArrow},
		{"insert", KeyCode.Insert},
		{"home", KeyCode.Home},
		{"end", KeyCode.End},
		{"f1", KeyCode.F1},
		{"f2", KeyCode.F2},
		{"f3", KeyCode.F3},
		{"f4", KeyCode.F4},
		{"f5", KeyCode.F5},
		{"f6", KeyCode.F6},
		{"f7", KeyCode.F7},
		{"f8", KeyCode.F8},
		{"f9", KeyCode.F9},
		{"f10", KeyCode.F10},
		{"f11", KeyCode.F11},
		{"f12", KeyCode.F12},
		{"f13", KeyCode.F13},
		{"f14", KeyCode.F14},
		{"f15", KeyCode.F15},
		{"mouse0", KeyCode.Mouse0},
		{"mouse1", KeyCode.Mouse1},
		{"mouse2", KeyCode.Mouse2},
		{"mouse3", KeyCode.Mouse3},
		{"mouse4", KeyCode.Mouse4},
		{"mouse5", KeyCode.Mouse5},
		{"mouse6", KeyCode.Mouse6},
		{"none", KeyCode.None}
	}

	for index,bind in pairs(uniqueBinds) do
		-- If the binds are the same then bind it to it
		if (key == bind[1]) then
			return bind[2]
		end
	end
    return key
end

function LQS_WeaponPickupBaseM:Compatibility()
    -- Redoing some of the compat checks by RadioactiveJelly
    return function()
        coroutine.yield(WaitForSeconds(1.0))

        local quickThrowObj = GameObject.Find("QuickThrow")
        if quickThrowObj then
            self.quickThrow = quickThrowObj.GetComponent(ScriptedBehaviour)
            print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base: Quick Throw found!")
        end
    
        local armorObj = GameObject.Find("PlayerArmor")
        if armorObj then
            self.playerArmor = armorObj.GetComponent(ScriptedBehaviour)
            print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base: Player Armor found!")
        end
    
        local urmObj = GameObject.find("RecoilPrefab(Clone)")
        if (urmObj) then
            self.URM = self.URM.gameObject.GetComponent(ScriptedBehaviour)
            print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base: Universal Recoil Mutator found!")
        end
    
        local bodycamObj = GameObject.Find("[LQS]Bodycam(Clone)")
        if (bodycamObj) then
            self.bodycamBase = bodycamObj.GetComponent(ScriptedBehaviour)
            print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base</color>: Soarin's Bodycam found!")
        end
    end
end

-- From RadioactiveJellyfish: Will always return true if neither mod is present
function LQS_WeaponPickupBaseM:CompatChecks()
	if self.quickThrow and self.quickThrow.self.isThrowing then return false end
	if self.playerArmor and self.playerArmor.self.isInArmorPlateMode then return false end
	return true
end

function LQS_WeaponPickupBaseM:OnActorDied(actor)
    if (not Lobby.isHost) then return end

    -- Drop distance check
    if (self.dropDistanceEnabled) then
        local distanceToPlayer = Vector3.Distance(actor.transform.position, Player.actor.transform.position)
        if (distanceToPlayer > self.dropDistance) then return end
    end

    -- Actor Drop
    if (self:CanBeDropped(actor.activeWeapon)) then
        if (actor ~= self.lastBotKilled) then
            if (self:ChanceSystem(actor)) then
                self:DropWeapon(actor)
            end
        end
    end
end

function LQS_WeaponPickupBaseM:ChanceSystem(actor)
    if (not self.dropChanceEnabled) then return true end
    if (self.dropChanceDontAffectPlayer and self:IsRavenMPlayer(actor)) then return true end

    -- A chance system
    -- Making it a function, because it will make the script look cleaner idk
    local luck = Random.Range(0, 100)
    if (luck < self.dropChance) then
        return true
    end
    return false
end

function LQS_WeaponPickupBaseM:Update()
	-- Main
    self:WeaponPickupMain()

    -- Only executes when the selection menu is open
    self:QueueChecker()
end

function LQS_WeaponPickupBaseM:QueueChecker()
    if (not Player.actor) then return end
    if (self:CanResetHUD()) then 
        if (not self.alreadyDisabledHUD) then
            self:ResetHUD()
            self.alreadyDisabledHUD = true
        end
        return 
    end

    -- Idk what to call this lmfaoo, it basically the thing that handles the selection menus.
    -- Like if the player moves away from the pickup the menu automatically closes, or if the weapon drop is destroyed.
    local player = Player.actor
    if (self.isMenuOpen) then
        local distanceToPickup = self.queuePickupData.transform.position - player.transform.position
        if (distanceToPickup.sqrMagnitude > 1.65) then
            self:ResetHUD()
        end
    end
    self.alreadyDisabledHUD = false
end

function LQS_WeaponPickupBaseM:CanResetHUD()
    if (self.isMenuOpen) then
        if (self.queuePickupData) then
            if (self.queuePickupData.gameObject) then
                if (not Player.actor.isDead) then
                    return false
                end
            end
        end
    end
    return true
end

function LQS_WeaponPickupBaseM:WeaponPickupMain()
    -- The base stuff
    local activeWeapon = Player.actor.activeWeapon
    local player = Player.actor

    -- Dropping and Pickup
    if (Input.GetKeyDown(self.dropKey) and self:CanDrop() and self:CanBeDropped(activeWeapon)) then
        self:DropWeapon(player)
    end

    if (Input.GetKeyDown(self.pickupKey) and self:CanPickup()) then
        self:Pickup()
    end
end

function LQS_WeaponPickupBaseM:Pickup()
    -- Picks up the weapon
    -- Launch a raycast
    local ray = PlayerCamera.fpCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
    if (self:BodycamActive()) then
        local bodycamMain = self.bodycamBase.self.bodyCam.gameObject.GetComponent(Camera)
        ray = bodycamMain.ViewportPointToRay(Vector3(0.5, 0.5, 0))
    end

    -- Launch Ray
    local pickupRay = Physics.Raycast(ray, self.pickupRange, RaycastTarget.Default)

    -- Check if its a pickup
    -- If soo pickup the weapon
    if (self:PickupCheck(pickupRay)) then
        self:PickupWeapon(pickupRay.collider.gameObject)
    end

    -- Temp disable pickup
    self.canPickup = false
    self.script.StartCoroutine(self:PickupCooldown())
end

function LQS_WeaponPickupBaseM:BodycamActive()
    -- Basically checkss if the bodycam mod exists or is it active
    if (self.bodycamBase) then
        if (self.bodycamBase.self.useBodyCam) then
            return true
        end
    end
    return false
end

function LQS_WeaponPickupBaseM:PickupCooldown()
    -- Pickup Cooldown, soo you can't pickup your old weapon accidentally
    -- when mashing the pickup key way too much.
    return function()
        coroutine.yield(WaitForSeconds(self.pickupCooldown))
        self.canPickup = true
    end
end

function LQS_WeaponPickupBaseM:PickupWeapon(obj)
    if (not obj) then return end
    local dataScript = obj.GetComponent(ScriptedBehaviour)
    if (not dataScript) then return end

    -- Picks up the weapon
    if (not self.anarchyMode) then
        -- Default Pickup System
        self:DefaultPickupSystem(dataScript.self)
    else
        -- Anarchy Pickup System
        self:AnarchyPickupSystem(dataScript.self)
    end
end

function LQS_WeaponPickupBaseM:AnarchyPickupSystem(receivedData)
    -- The anarchy pickup system
    -- Queue weapon and enable selection hud, because this allows you 
    -- to put your weapon on any slots
    self.queuePickupData = receivedData
    self:EnableHUD("anarchy")
end

function LQS_WeaponPickupBaseM:AnarchyDropWeaponSelected(selectedSlot)
	-- Only For Anarchy Pickup System
	-- Pickup data array
    self:ResetHUD()

	-- Drop weapon in the selected slot if its valid
	for _,wep in pairs(Player.actor.weaponSlots) do
		if (wep.slot == selectedSlot) then
			if (self:CanBeDropped(wep)) then
				self:DropWeapon(Player.actor, wep.slot)
                break
			end
		end
	end

	-- Give the weapon
	Player.actor.EquipNewWeaponEntry(self.queuePickupData.weaponEntry, selectedSlot, true)
	self:PickupWeaponFinal(Player.actor.activeWeapon, self.queuePickupData)
end

function LQS_WeaponPickupBaseM:DefaultPickupSystem(receivedData)
    -- The default pickup system
    -- Overlap Check
	for _,wep in pairs(Player.actor.weaponSlots) do
		if (wep.weaponEntry.slot == receivedData.weaponEntry.slot and not self:IsGear(receivedData.weaponEntry) and not self:IsLargeGear(receivedData.weaponEntry)) then
			if (self:CanBeDropped(wep)) then
				self:DropWeapon(Player.actor, wep.slot)
			end
			break
		end
	end

	-- Get the targetSlot
    -- If it fails to get the targetSlot then its possibly a gear or a heavy weapon
    local targetSlot = nil
	if (receivedData.weaponEntry.slot == WeaponSlot.Primary) then
        -- Primary
		targetSlot = 0
	elseif (receivedData.weaponEntry.slot == WeaponSlot.Secondary) then
        -- Secondary
		targetSlot = 1
    else
        -- A gear or a heavy weapon
        -- Queue the weapon
        self.queuePickupData = receivedData

        -- Setup Selection Loadout
        self:EnableHUD("default")
	end

    -- Apply the weapon
    if (targetSlot) then
        Player.actor.EquipNewWeaponEntry(receivedData.weaponEntry, targetSlot, true)
	    self:PickupWeaponFinal(Player.actor.activeWeapon, receivedData)
    end
end

function LQS_WeaponPickupBaseM:DefaultDropGearSelected(selection)
    -- Applies the selected slot
    local playerSlots = Player.actor.weaponSlots
    local targetSlot = selection
    self:ResetHUD()

    -- Now less messy! I guess..
    -- Check if the weapon is a heavy weapon
    if (self:IsLargeGear(self.queuePickupData.weaponEntry)) then
        -- If so then drop the two last gear slots to make space for the heavy one
        -- if the two ones do exists
        if (self:CanBeDropped(playerSlots[4])) then
            self:DropWeapon(Player.actor, playerSlots[4].slot)
        end
        if (self:CanBeDropped(playerSlots[5])) then
            self:DropWeapon(Player.actor, playerSlots[5].slot)
        end

        -- Change targetSlot
        targetSlot = 3
    else
        -- Else apply at with the usual actions
        local wep = playerSlots[selection]
        if (wep and not self:IsLargeGear(wep)) then
            if (self:CanBeDropped(playerSlots[wep])) then
                self:DropWeapon(Player.actor, wep.slot)
            end
        else
            targetSlot = 2
        end
    end

    -- Apply
    Player.actor.EquipNewWeaponEntry(self.queuePickupData.weaponEntry, targetSlot, true)
	self:PickupWeaponFinal(Player.actor.activeWeapon, self.queuePickupData)
end

function LQS_WeaponPickupBaseM:EnableHUD(hudType)
    -- Self explanatory.. Again
    Screen.UnlockCursor()
    Input.DisableNumberRowInputs()
    self.isMenuOpen = true

    self.canvas.SetActive(true)
    if (hudType == "default") then
        self.defaultHUD.SetActive(true)
        self.standard:SetupLoadout()
    elseif(hudType == "anarchy") then
        self.anarchyHUD.SetActive(true)
        self.anarchy:SetupLoadout()
    end
end

function LQS_WeaponPickupBaseM:ResetHUD()
	-- Self explanatory
    self.canvas.SetActive(false)
    self.anarchyHUD.SetActive(false)
    self.defaultHUD.SetActive(false)
	Screen.LockCursor()
	Input.EnableNumberRowInputs()
	self.isMenuOpen = false
end

function LQS_WeaponPickupBaseM:PickupWeaponFinal(weapon, data)
    -- Finalized action after picking up a weapon
    -- Apply ammo and spareAmmo count
    weapon.ammo = data.weaponAmmo
    weapon.spareAmmo = data.weaponSpareAmmo

    self.script.StartCoroutine(self:ApplyAltWeaponsAmmoAndSpareAmmo(weapon, data))

    -- Destroy pickup
    -- Using packet because look at below damn it..
    data:SendDestroyPacket(data.dropID)
    -- self.script.StartCoroutine(self:StartDestroyPickup(data.dropID))

    -- Trigger Compats made by RadioactiveJellyfish
    -- Quick Throw Compatibility
	if (self.quickThrow) then
		self.quickThrow.self:doDelayedEvaluate()
	end
	
	-- Universal Recoil Compatibility
	if (self.URM) then
		self.URM.self:AssignWeaponStats(weapon)
	end

    -- From RadioactiveJellyfish: Invoke the event to tell all listeners that a weapon has been picked up
	self:InvokeOnWeaponPickupEvent(weapon)
end

function LQS_WeaponPickupBaseM:ApplyAltWeaponsAmmoAndSpareAmmo(weapon, data)
    -- Using a coroutine for this because it strangely thinks that the weapon
    -- has no subweapons in it despite having some
    return function()
        coroutine.yield(WaitForSeconds(0))
        if (not weapon or not data) then return end
        for index,altWep in pairs(weapon.alternativeWeapons) do
            altWep.ammo = data.altWeaponAmmo[index]
            altWep.spareAmmo = data.altWeaponSpareAmmo[index]
        end
    end
end

function LQS_WeaponPickupBaseM:StartDestroyPickup(dataScript, dropID)
    return function()
        coroutine.yield(WaitForSeconds(0))
        dataScript:SendDestroyPacket(dropID)
    end
end

function LQS_WeaponPickupBaseM:PickupCheck(raycast)
    if (raycast) then
        if (raycast.collider.gameObject.name == "[LQS]PickupHitboxM{}(Clone)") then
            return true
        end
    end
    return false
end

function LQS_WeaponPickupBaseM:DropWeapon(actor, targetSlot)
    -- This is not the main drop weapon function
    -- This basically sends a packet to the server soo drops sync across players
    local spawnPos = Vector3.zero

    -- Check if the actor is a player
    -- If so then give a custom pos, mainly from that player's camera
    local fromPlayer = self:IsRavenMPlayer(actor)
    if (fromPlayer) then
        if (actor.isPlayer) then
            spawnPos = PlayerCamera.fpCamera.transform.position + PlayerCamera.fpCamera.transform.forward
        end
    end

    -- Send Packet
    OnlinePlayer.SendPacketToServer("lqswpbase;;" .. actor.name .. ";;dropweapon;;" .. 
    tostring(spawnPos.x) .. ";;" .. tostring(spawnPos.y) .. ";;" .. tostring(spawnPos.z) .. ";;" .. 
    tostring(fromPlayer) .. ";;" ..
    tostring(targetSlot), 
    tonumber(self.weaponPickupBaseID), true)
end

function LQS_WeaponPickupBaseM:IsRavenMPlayer(actor)
    for _,player in pairs(Lobby.players) do
        if (actor == player) then
            return true
        end
    end
    return false
end

function LQS_WeaponPickupBaseM:DropWeaponStart(data)
    -- Have to do a start version because it doesn't sync across clients
    local unwrappedData = self:UnwrapPacket(data)

    if (#unwrappedData == 0) then return end
    if (unwrappedData[1] ~= "lqswpbase") then return end
    if (unwrappedData[3] ~= "dropweapon") then return end

    -- Get the actor
    local targetActor = nil
    local dropPos = nil
    if (unwrappedData[7] == "true") then
        targetActor = OnlinePlayer.GetPlayerFromName(unwrappedData[2])
        dropPos = Vector3(
            tonumber(unwrappedData[4]),
            tonumber(unwrappedData[5]),
            tonumber(unwrappedData[6])
        )
    else
        for _,player in pairs(Lobby.players) do
            for _,botActor in pairs(ActorManager.actors) do
                if (botActor ~= player and botActor.name == unwrappedData[2]) then
                    targetActor = botActor
                end
            end
        end
    end

    -- Get the weapon target weapon
    -- If there is no specified slot then drop the active weapon
    local targetWeapon = nil
    local targetSlot = tonumber(unwrappedData[8])
    if (targetActor and targetSlot) then
        targetWeapon = targetActor.weaponSlots[targetSlot+1]
    else
        targetWeapon = targetActor.activeWeapon
    end

    -- Drop the weapon
    self:DropWeaponMP(targetActor, targetWeapon, dropPos)
end

function LQS_WeaponPickupBaseM:DropWeaponMP(actor, weapon, customPos, noForce)
    if (not weapon) then return end

    -- Drops the weapon
    local targetDropTransform = nil
    local spawnPos = Vector3.zero

    -- Gets the drop transform and spawnPos
    if (actor) then
        targetDropTransform = actor.transform
        spawnPos = Vector3(actor.transform.position.x, actor.transform.position.y + 1, actor.transform.position.z)
    end

    if (customPos and customPos ~= Vector3.zero) then
        spawnPos = customPos
    end

    -- Instantiate Pickup Object
    local weaponDrop = GameObject.Instantiate(self.pickupObject, spawnPos, Quaternion.identity)
    local weaponAmogus = weapon.weaponEntry.InstantiateImposter(weaponDrop.transform.position, Quaternion.identity)

    -- Some setups
    self:WeaponPickupObjectSetup(weaponDrop, weaponAmogus)
    local pickupData = self:SetupPickupData(weaponDrop, weapon)

    -- Remove Weapon
    -- If the actor is a player
    if (actor and actor.isPlayer) then
        actor.RemoveWeapon(weapon.slot)
    end

    -- Add force to the rigidbody
    -- If possible...
    if (targetDropTransform and pickupData and not noForce) then
        local pickupRB = pickupData.dropRB

        -- Give the actor's velocity to the rigidbody
        pickupRB.velocity = actor.velocity

        -- Throw Force
        pickupRB.AddForce(targetDropTransform.forward * self.throwForce, ForceMode.Impulse)
        pickupRB.AddForce(targetDropTransform.up * self.upwardForce, ForceMode.Impulse)

        pickupRB.AddTorque(Vector3(Random.Range(-150, 150), Random.Range(-150, 150), Random.Range(-150, 150)))
    end
end

function LQS_WeaponPickupBaseM:SetupPickupData(obj, weapon)
    if (not obj) then return end
    if (not weapon) then return end

    -- Setups the pickup data
    -- This is way different than the SP one, this one uses the legacy styled saving system
    -- So that means saving the alt weapon ammo and spare ammo is not possible in the RavenM version
    local pickupData = obj.GetComponent(ScriptedBehaviour).self
    if (pickupData) then
        -- Apply some important stuff
        -- Weapon Entry
        pickupData.weaponEntry = weapon.weaponEntry

        -- Weapon Ammo
        pickupData.weaponAmmo = weapon.ammo
        pickupData.weaponSpareAmmo = weapon.spareAmmo

        for _,altWep in pairs(weapon.alternativeWeapons) do
            pickupData.altWeaponAmmo[#pickupData.altWeaponAmmo+1] = altWep.ammo
            pickupData.altWeaponSpareAmmo[#pickupData.altWeaponSpareAmmo+1] = altWep.spareAmmo
        end

        -- Set some settings up
        -- Despawning
        if (self.canDespawn) then
            pickupData:StartLifetime(self.despawnTime)
        end

        -- Physics Freezing
        if (self.freezePhysicsWhenStopped) then
            pickupData.freezePhysicsEnabled = true
            pickupData.freezePhysicsDistance = self.freezePhysicsDistance
        end

        -- RavenM stuff
        -- Give the dropID
        pickupData.dropID = "lqswpbase" .. tostring(self.curIDIndex) .. "dropid"

        -- Update the current id index
        self.curIDIndex = self.curIDIndex + 1
        OnlinePlayer.SendPacketToServer("lqswpbase;;" .. tostring(self.curIDIndex) .. ";;updateidindex", tonumber(self.weaponPickupBaseID), true)

        -- Debugging, only in test mode
        if (Debug.isTestMode) then
            pickupData:Debug()
        end

        -- Return the pickupData script for later
        return pickupData
    end
end

function LQS_WeaponPickupBaseM:WeaponPickupObjectSetup(obj, weaponImposter)
    if (not obj) then return end
    if (not weaponImposter) then return end

    -- This setups the pickup object and bounds, nothing related with data passing
    local weaponRenderer = weaponImposter.GetComponent(Renderer)
    if (weaponRenderer) then
        -- Apply bounds size if possible
        if (not self:GreaterOrEqualScale(weaponRenderer.bounds.size, Vector3(1.9, 1.9, 1.9))) then
            if (not self:LessOrEqualScale(weaponRenderer.bounds.size, Vector3(0.2, 0.2, 0.2))) then
                obj.transform.localScale = weaponRenderer.bounds.size
            end
        end
    end

    -- Parent weaponImposter to object and rename object
    weaponImposter.transform.parent = obj.transform
end

-- These two functions are gotten off Chai's weapon pickup code should fix some weapons just vanishing when dropped
function LQS_WeaponPickupBaseM:GreaterOrEqualScale(objScale,other)
	if (objScale.x >= other.x and objScale.y >= other.y and objScale.z >= other.z) then
        return true
    else
        return false
    end
end

function LQS_WeaponPickupBaseM:LessOrEqualScale(objScale, other)
	if (objScale.x <= other.x and objScale.y <= other.y and objScale.z <= other.z) then
        return true
    else
        return false
    end
end

function LQS_WeaponPickupBaseM:CanPickup()
    if (not GameManager.isPaused) then
        if (Player.actor and not Player.actor.isDead) then
            if (self.canPickup) then
                return true
            end
        end
    end
    return false
end

function LQS_WeaponPickupBaseM:CanDrop()
    if (not GameManager.isPaused) then
        if (Player.actor and Player.actor.activeWeapon) then
            return true
        end
    end
    return false
end 

function LQS_WeaponPickupBaseM:CanBeDropped(weapon)
    if (not weapon) then return false end
    if (self.canBlacklist) then
        if (not self.blacklistedWeapons[weapon.weaponEntry.name]) then
            return true
        end
        return false
    end
    return true
end

function LQS_WeaponPickupBaseM:IsLargeGear(weapon)
	if (weapon) then
		if (weapon.slot == WeaponSlot.LargeGear) then
			return true
		end
	end
    return false
end

function LQS_WeaponPickupBaseM:IsGear(weapon)
    if (weapon) then
		if (weapon.slot == WeaponSlot.Gear) then
			return true
		end
	end
    return false
end

-- These stuff below are made by RadioactiveJellyfish
function LQS_WeaponPickupBaseM:AddOnWeaponPickupListener(owner,func)
	self.onWeaponPickUpListeners[owner] = func
end

function LQS_WeaponPickupBaseM:RemoveOnWeaponPickupListener(owner)
	self.onWeaponPickUpListeners[owner] = nil
end

function LQS_WeaponPickupBaseM:InvokeOnWeaponPickupEvent(weapon)
	for owner, func in pairs(self.onWeaponPickUpListeners) do
		func(weapon)
	end
end
