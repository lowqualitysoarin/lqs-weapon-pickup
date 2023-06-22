-- low_quality_soarin, RadioactiveJellyfish © 2023-2024
-- Weapon Pickup Rewrite, SP version.
behaviour("LQS_WeaponPickupBase")

function LQS_WeaponPickupBase:Awake()
	-- From RadioactiveJellyfish: Table of functions for event listeners
	self.onWeaponPickUpListeners = {}
end

function LQS_WeaponPickupBase:Start()
	-- Base
    self.pickupObject = self.targets.pickupObject

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

    -- Vars
    self.queuePickupData = nil
    self.isMenuOpen = false

	-- Finishing touches
    -- Compatability
    self:Compatibility()

    -- Disable selection HUDs
    self.canvas.SetActive(false)
	self.anarchyHUD.SetActive(false)
	self.defaultHUD.SetActive(false)

    -- Share Instance
    _G.LQSWeaponPickupBase = self.gameObject.GetComponent(ScriptedBehaviour).self
end

function LQS_WeaponPickupBase:CheckKeyCode(key)
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

function LQS_WeaponPickupBase:Compatibility()
    -- Redoing some of the compat checks by RadioactiveJelly
    -- Quick Throw
    local quickThrowObj = self.gameObject.Find("QuickThrow")
	if quickThrowObj then
		self.quickThrow = quickThrowObj.GetComponent(ScriptedBehaviour)
        print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base</color>: Quick Throw found!")
	end

    -- Player Armor
	local armorObj = self.gameObject.Find("PlayerArmor")
	if armorObj then
		self.playerArmor = armorObj.GetComponent(ScriptedBehaviour)
        print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base</color>: Player Armor found!")
	end

    -- Universal Recoil Mutator
	local urmObj = GameObject.find("RecoilPrefab(Clone)")
	if (urmObj) then
		self.URM = urmObj.gameObject.GetComponent(ScriptedBehaviour)
		print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base</color>: Universal Recoil Mutator found!")
	end

    -- Soarin's Bodycam
    local bodycamObj = GameObject.Find("[LQS]Bodycam(Clone)")
    if (bodycamObj) then
        self.bodycamBase = bodycamObj.GetComponent(ScriptedBehaviour)
        print("[<color=aqua>LQS</color>]<color=yellow>Weapon Pickup Base</color>: Soarin's Bodycam found!")
    end
end

-- From RadioactiveJellyfish: Will always return true if neither mod is present
function LQS_WeaponPickupBase:CompatChecks()
	if self.quickThrow and self.quickThrow.self.isThrowing then return false end
	if self.playerArmor and self.playerArmor.self.isInArmorPlateMode then return false end
	return true
end

function LQS_WeaponPickupBase:OnActorDied(actor)
    -- Drop distance check
    if (self.dropDistanceEnabled) then
        local distanceToPlayer = Vector3.Distance(actor.transform.position, Player.actor.transform.position)
        if (distanceToPlayer > self.dropDistance) then return end
    end

    -- Actor Drop
    if (self:CanBeDropped(actor.activeWeapon)) then
        if (self.dropChanceEnabled) then
            local luck = Random.Range(0, 100)

            if (self.dropChanceDontAffectPlayer) then
                if (not actor.isPlayer) then
                    if (luck < self.dropChance) then
                        self:DropWeapon(actor, actor.activeWeapon)
                    end
                else
                    self:DropWeapon(actor, actor.activeWeapon)
                end
            else
                if (luck < self.dropChance) then
                    self:DropWeapon(actor, actor.activeWeapon)
                end
            end
        else
            self:DropWeapon(actor, actor.activeWeapon)
        end
    end
end

function LQS_WeaponPickupBase:Update()
	-- Main
    self:WeaponPickupMain()

    -- Only executes when the selection menu is open
    self:QueueChecker()
end

function LQS_WeaponPickupBase:QueueChecker()
    if (not Player.actor) then return end
    if (self.queuePickupData and not self.queuePickupData.gameObject) then self:ResetHUD() return end

    -- Idk what to call this lmfaoo, it basically the thing that handles the selection menus.
    -- Like if the player moves away from the pickup the menu automatically closes, or if the weapon drop is destroyed.
    local player = Player.actor
    if (self.isMenuOpen and player and not player.isDead) then
        local distanceToPickup = self.queuePickupData.transform.position - player.transform.position
        if (distanceToPickup.sqrMagnitude > 1.65) then
            self:ResetHUD()
        end
    else
        self:ResetHUD()
    end
end

function LQS_WeaponPickupBase:WeaponPickupMain()
    -- The base stuff
    local activeWeapon = Player.actor.activeWeapon
    local player = Player.actor

    -- Dropping and Pickup
    if (Input.GetKeyDown(self.dropKey) and self:CanDrop() and self:CanBeDropped(activeWeapon)) then
        self:DropWeapon(player, activeWeapon, true)
    end

    if (Input.GetKeyDown(self.pickupKey) and self:CanPickup()) then
        self:Pickup()
    end
end

function LQS_WeaponPickupBase:Pickup()
    -- Picks up the weapon
    -- Launch a raycast
    -- Gets the proper ray for the raycast
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

function LQS_WeaponPickupBase:BodycamActive()
    -- Basically checkss if the bodycam mod exists or is it active
    if (self.bodycamBase) then
        if (self.bodycamBase.self.useBodyCam) then
            return true
        end
    end
    return false
end

function LQS_WeaponPickupBase:PickupCooldown()
    -- Pickup Cooldown, soo you can't pickup your old weapon accidentally
    -- when mashing the pickup key way too much.
    return function()
        coroutine.yield(WaitForSeconds(self.pickupCooldown))
        self.canPickup = true
    end
end

function LQS_WeaponPickupBase:PickupWeapon(obj)
    if (not obj) then return end
    local dataScript = obj.GetComponent(ScriptedBehaviour).self
    if (not dataScript) then return end

    -- Picks up the weapon
    if (not self.anarchyMode) then
        -- Default Pickup System
        self:DefaultPickupSystem(dataScript)
    else
        -- Anarchy Pickup System
        self:AnarchyPickupSystem(dataScript)
    end
end

function LQS_WeaponPickupBase:AnarchyPickupSystem(receivedData)
    -- The anarchy pickup system
    -- Queue weapon and enable selection hud, because this allows you 
    -- to put your weapon on any slots
    self.queuePickupData = receivedData
    self:EnableHUD("anarchy")
end

function LQS_WeaponPickupBase:AnarchyDropWeaponSelected(selectedSlot)
	-- Only For Anarchy Pickup System
	-- Pickup data array
	local playerSlots = Player.actor.weaponSlots
    self:ResetHUD()

	-- Drop weapon in the selected slot if its valid
	for _,wep in pairs(playerSlots) do
		if (wep.slot == selectedSlot) then
			if (self:CanBeDropped(wep)) then
				self:DropWeapon(Player.actor, wep, true)
			end
		end
	end

	-- Give the weapon
	Player.actor.EquipNewWeaponEntry(self.queuePickupData.weaponEntry, selectedSlot, true)
	self:PickupWeaponFinal(Player.actor.activeWeapon, self.queuePickupData)
end

function LQS_WeaponPickupBase:DefaultPickupSystem(receivedData)
    -- The default pickup system
    -- Overlap Check
	for _,wep in pairs(Player.actor.weaponSlots) do
		if (wep.weaponEntry.slot == receivedData.weaponEntry.slot and not self:IsGear(receivedData.weaponEntry) and not self:IsLargeGear(receivedData.weaponEntry)) then
			if (self:CanBeDropped(wep)) then
				self:DropWeapon(Player.actor, wep, true)
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

function LQS_WeaponPickupBase:DefaultDropGearSelected(selection)
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
            self:DropWeapon(Player.actor, playerSlots[4], true)
        end
        if (self:CanBeDropped(playerSlots[5])) then
            self:DropWeapon(Player.actor, playerSlots[5], true)
        end

        -- Change targetSlot
        targetSlot = 3
    else
        -- Else apply at with the usual actions
        local wep = playerSlots[selection]
        if (wep and not self:IsLargeGear(wep)) then
            if (self:CanBeDropped(playerSlots[wep])) then
                self:DropWeapon(Player.actor, playerSlots[wep], true)
            end
        else
            targetSlot = 2
        end
    end

    -- Apply
    Player.actor.EquipNewWeaponEntry(self.queuePickupData.weaponEntry, targetSlot, true)
	self:PickupWeaponFinal(Player.actor.activeWeapon, self.queuePickupData)
end

function LQS_WeaponPickupBase:EnableHUD(hudType)
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

function LQS_WeaponPickupBase:ResetHUD()
	-- Self explanatory
    self.canvas.SetActive(false)
    self.anarchyHUD.SetActive(false)
    self.defaultHUD.SetActive(false)
	Screen.LockCursor()
	Input.EnableNumberRowInputs()
	self.isMenuOpen = false
end

function LQS_WeaponPickupBase:PickupWeaponFinal(weapon, data)
    -- Finalized action after picking up a weapon
    -- Apply ammo and spareAmmo count
    weapon.ammo = data.weaponAmmo
    weapon.spareAmmo = data.weaponSpareAmmo

    self.script.StartCoroutine(self:ApplyAltWeaponsAmmoAndSpareAmmo(weapon, data))

    -- Destroy pickup
    GameObject.Destroy(data.gameObject)

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

function LQS_WeaponPickupBase:ApplyAltWeaponsAmmoAndSpareAmmo(weapon, data)
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

function LQS_WeaponPickupBase:PickupCheck(raycast)
    if (raycast) then
        if (raycast.collider.gameObject.name == "[LQS]PickupHitbox{}(Clone)") then
            return true
        end
    end
    return false
end

function LQS_WeaponPickupBase:DropWeapon(actor, weapon, isManual, noForce)
    if (not weapon) then return end

    -- Drops the weapon
    local targetDropTransform = nil
    local spawnPos = Vector3.zero

    -- Gets the drop transform and spawnPos
    if (actor) then
        targetDropTransform = actor.transform
        spawnPos = Vector3(actor.transform.position.x, actor.transform.position.y + 1, actor.transform.position.z)
    end

    -- Change some variable settings above if it is manual
    if (isManual) then
        targetDropTransform = PlayerCamera.fpCamera.transform
        spawnPos = targetDropTransform.transform.position + targetDropTransform.forward
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

function LQS_WeaponPickupBase:SetupPickupData(obj, weapon)
    if (not obj) then return end
    if (not weapon) then return end

    -- Setups the pickup data
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

        -- Debugging, only in test mode
        if (Debug.isTestMode) then
            pickupData:Debug()
        end

        -- Return the pickupData script for later
        return pickupData
    end
end

function LQS_WeaponPickupBase:WeaponPickupObjectSetup(obj, weaponImposter)
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

    -- Parent weaponImposter to object
    weaponImposter.transform.parent = obj.transform
end

-- These two functions are gotten off Chai's weapon pickup code should fix some weapons just vanishing when dropped
function LQS_WeaponPickupBase:GreaterOrEqualScale(objScale,other)
	if (objScale.x >= other.x and objScale.y >= other.y and objScale.z >= other.z) then
        return true
    else
        return false
    end
end

function LQS_WeaponPickupBase:LessOrEqualScale(objScale, other)
	if (objScale.x <= other.x and objScale.y <= other.y and objScale.z <= other.z) then
        return true
    else
        return false
    end
end

function LQS_WeaponPickupBase:CanPickup()
    if (not GameManager.isPaused) then
        if (Player.actor and not Player.actor.isDead) then
            if (self.canPickup) then
                return true
            end
        end
    end
    return false
end

function LQS_WeaponPickupBase:CanDrop()
    if (not GameManager.isPaused) then
        if (Player.actor and Player.actor.activeWeapon) then
            return true
        end
    end
    return false
end 

function LQS_WeaponPickupBase:CanBeDropped(weapon)
    if (not weapon) then return false end
    if (self.canBlacklist) then
        if (not self.blacklistedWeapons[weapon.weaponEntry.name]) then
            return true
        end
        return false
    end
    return true
end

function LQS_WeaponPickupBase:IsLargeGear(weapon)
	if (weapon) then
		if (weapon.slot == WeaponSlot.LargeGear) then
			return true
		end
	end
    return false
end

function LQS_WeaponPickupBase:IsGear(weapon)
    if (weapon) then
		if (weapon.slot == WeaponSlot.Gear) then
			return true
		end
	end
    return false
end

-- These stuff below are made by RadioactiveJellyfish
function LQS_WeaponPickupBase:AddOnWeaponPickupListener(owner,func)
	self.onWeaponPickUpListeners[owner] = func
end

function LQS_WeaponPickupBase:RemoveOnWeaponPickupListener(owner)
	self.onWeaponPickUpListeners[owner] = nil
end

function LQS_WeaponPickupBase:InvokeOnWeaponPickupEvent(weapon)
	for owner, func in pairs(self.onWeaponPickUpListeners) do
		func(weapon)
	end
end
