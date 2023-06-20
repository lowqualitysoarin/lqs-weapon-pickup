-- low_quality_soarin, RadioactiveJellyfish © 2023-2024
behaviour("WeaponPickupM")

local pickupDetected = false
local pickupRayCast = nil
local alreadyChecked = false

function WeaponPickupM:Awake()
	--Table of functions for event listeners
	self.onWeaponPickUpMListeners = {}
end

function WeaponPickupM:Start()
	-- Base
	self.weaponBoxCollider = self.targets.cubeCollider
	Lobby.AddNetworkPrefab(self.weaponBoxCollider)
	Lobby.PushNetworkPrefabs()

	-- HUD
	self.canvas = self.targets.canvas

	self.defaultHUD = self.targets.hud
	self.anarchyHUD = self.targets.anarchyHud

	self.anarchy = self.targets.anarchyInv.GetComponent(ScriptedBehaviour).self
	self.standard = self.targets.defaultInv.GetComponent(ScriptedBehaviour).self

	self.isMenuOpen = false

	-- Rigid Force
	self.throwForce = 18.7
	self.upwardForce = 8.5

	-- Data Setup
	self.droppedWeapons = {}
	self.droppedIndex = 1

	self.currentPickupData = {}

	self.dataObject = self.targets.emptyCopy

	-- Config
	self.pickupRange = self.script.mutator.GetConfigurationFloat("pickupRange")

	self.canDespawn = self.script.mutator.GetConfigurationBool("canDespawn")
	self.despawnTime = self.script.mutator.GetConfigurationFloat("despawnTime")

	self.pickupDelay = self.script.mutator.GetConfigurationFloat("pickupDelay")
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

	-- Keybinds
	self.pickupKey = string.lower(self.script.mutator.GetConfigurationString("pickupKey"))
	self.dropKey = string.lower(self.script.mutator.GetConfigurationString("dropKey"))

	-- Listeners
	GameEvents.onActorDied.AddListener(self, "OnActorDied")

	-- Compatibility
	local quickThrowObj = self.gameObject.Find("QuickThrow")
	if quickThrowObj then
		self.quickThrow = quickThrowObj.GetComponent(ScriptedBehaviour)
	end

	local armorObj = self.gameObject.Find("PlayerArmor")
	if armorObj then
		self.playerArmor = armorObj.GetComponent(ScriptedBehaviour)
	end

	self.URM = GameObject.find("RecoilPrefab(Clone)")
	self.isUsingURM = (self.URM ~= nil)

	if (self.isUsingURM) then
		self.URM = self.URM.gameObject.GetComponent(ScriptedBehaviour).self
		print("Using URM")
	else
		print("Not using URM")
	end

	-- Finishing Touches
	self.anarchyHUD.gameObject.SetActive(false)
	self.defaultHUD.gameObject.SetActive(false)

	self.canvas.gameObject.SetActive(false)
end

function WeaponPickupM:OnActorDied(actor)
	if (self.dropDistanceEnabled) then
		local distanceToPlayer = (actor.transform.position - Player.actor.transform.position).magnitude
		if (distanceToPlayer > self.dropDistance) then return end
	end

	if (self:CanBeDropped(actor.activeWeapon)) then
		if (self.dropChanceEnabled) then
			if (self.dropChanceDontAffectPlayer) then
				if (not actor.isPlayer) then
					local luck = Random.Range(0, 100)

					if (luck < self.dropChance) then
						self:DropWeapon(actor.activeWeapon, actor)
					end
				else
					self:DropWeapon(actor.activeWeapon, actor)
				end
			else
				local luck = Random.Range(0, 100)

				if (luck < self.dropChance) then
					self:DropWeapon(actor.activeWeapon, actor)
				end
			end
		else
			self:DropWeapon(actor.activeWeapon, actor)
		end
	end
end

function WeaponPickupM:Update()
	-- Pickup Base
	-- Dropping
	if (Input.GetKeyDown(self.dropKey) and Player.actor.activeWeapon and self:CanBeDropped(Player.actor.activeWeapon)) then
		self:DropWeaponManual(Player.actor.activeWeapon)
	end

	-- Picking Up
	if (Input.GetKeyDown(self.pickupKey) and self.canPickup) then
		-- Launching ray when the use key is pressed, since always casting a ray is kinda unoptimised they say...
		local pickupRay = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
	    pickupRayCast = Physics.Spherecast(pickupRay, 0.25, self.pickupRange, RaycastTarget.Default)

		if (pickupRayCast ~= nil) then
			-- Do validation if the object that the raycast got is a pickup hitbox.
			if (pickupRayCast.collider.gameObject.name == "[LQS]PickupHitbox{}(Clone)") then
				pickupDetected = true
			else
				pickupDetected = false
				alreadyChecked = false
			end

			-- Compatibility check by RadioactiveJello
			local compatChecks = self:CompatChecks()

			-- If pickup is valid then pick up the weapon.
			if (pickupDetected and compatChecks) then
				local currentPickup = pickupRayCast.collider.gameObject
				self:PickUpWeaponStart(currentPickup)
				self.canPickup = false
				self.script.StartCoroutine("PickupDelay")
			end
		end
	end

	-- Close the menu when the player gets far from the pickup
	if (#self.currentPickupData > 0 and self.isMenuOpen) then
		if (self.currentPickupData[2] and self.isMenuOpen) then
			local distanceToPickup = (Player.actor.transform.position - self.currentPickupData[2].transform.position).magnitude

			if (distanceToPickup > 1.65) then
				self:ResetHUD()
			end
		elseif (not self.currentPickupData[2] and self.isMenuOpen) then
			self:ResetHUD()
		end
	elseif (#self.currentPickupData <= 0 and self.isMenuOpen) then
		self:ResetHUD()
	end

	-- Closes the menu when the player dies
	if (Player.actor.isDead and self.isMenuOpen) then
		self:ResetHUD()
	end
end

function WeaponPickupM:CanBeDropped(weapon)
	if (self.canBlacklist) then
		if (weapon ~= nil) then
			if (self.blacklistedWeapons[weapon.weaponEntry.name]) then
				return false
			else
				return true
			end
		else
			return false
		end
	else
		return true
	end
end

function WeaponPickupM:PickupDelay()
	coroutine.yield(WaitForSeconds(self.pickupDelay))
	self.canPickup = true
	return nil
end

function WeaponPickupM:DropWeaponManual(weapon)
	-- Make Pickup Prefab
	local selectedWeapon = weapon
	local playerCam = PlayerCamera.activeCamera.transform
	local spawnPos = playerCam.transform.position + playerCam.forward

	-- Add Model to network
	local weaponModel = self:GetTPModel()
	Lobby.AddNetworkPrefab(weaponModel)
	Lobby.PushNetworkPrefabs()

	local droppedWeapon = GameObjectM.Instantiate(self.weaponBoxCollider, spawnPos, Quaternion.identity)
	local weaponImposter = GameObjectM.Instantiate(weaponModel, droppedWeapon.position, Quaternion.identity)

	-- Do some extra properties if weaponImposter isn't a nil
	if (weaponImposter) then
		-- Get the renderer. If it has then set hitbox scale to renderer bounds size
		if (weaponImposter.gameObject.GetComponent(Renderer)) then
			local weaponRenderer = weaponImposter.gameObject.GetComponent(Renderer)

			-- Check the bounds size of the weapon. If it passes then use the fixed values for the hitbox scale
			-- Means it doesn't have a correct renderer size
			if (not self:GreaterOrEqualScale(weaponRenderer.bounds.size, Vector3(1.9, 1.9, 1.9))) then
				if (not self:LessOrEqualScale(weaponRenderer.bounds.size, Vector3(0.2, 0.2, 0.2))) then
					droppedWeapon.transform.localScale = weaponRenderer.bounds.size
				end
			end
		end

		-- Parent the weaponImposter to the hitbox after scaling
		weaponImposter.transform.parent = droppedWeapon.transform
	end

	local droppedRB = droppedWeapon.gameObject.GetComponent(Rigidbody)

	-- Data Setup (Jesus christ I'm sorry I really have to do this again...)
	-- Weapon
	self:FindDroppedWeapon(selectedWeapon, droppedWeapon)

	-- Ammo
	local weaponAmmo = GameObject.Instantiate(self.dataObject, droppedWeapon.transform)
	local weaponSpareAmmo = GameObject.Instantiate(self.dataObject, droppedWeapon.transform)

	weaponAmmo.name = selectedWeapon.ammo
	weaponSpareAmmo.name = selectedWeapon.spareAmmo
	
	-- Finishing Touches
	droppedRB.AddForce(playerCam.forward * self.throwForce, ForceMode.Impulse)
	droppedRB.AddForce(playerCam.up * self.upwardForce, ForceMode.Impulse)

	local randomRot = Random.Range(-150, 150)
	droppedRB.AddTorque(Vector3(randomRot, randomRot, randomRot))

	-- Remove Weapon
	local droppedWeaponSlot = selectedWeapon.gameObject.GetComponent(Weapon).slot
	Player.actor.removeWeapon(droppedWeaponSlot)

	if self.quickThrow then
		self.quickThrow.self:doDelayedEvaluate()
	end
end

function WeaponPickupM:GetTPModel(weapon)
	-- Get The Children Objects
	local childrenObjects = weapon.gameObject.GetComponentsInChildren(Transform)

	-- Jesus please forgive me RavenM doesn't have much support with scripting.
	local possibleUsableObject = nil
	if (#childrenObjects > 0) then
		for _,obj in pairs(childrenObjects) do
			if (obj.gameObject.name ~= "Armature") then
				if (obj.gameObject.GetComponent(Renderer)) then
					if (not obj.gameObject.GetComponent(SkinnedMeshRenderer)) then
						if (obj.gameObject.name ~= "Reload Audio") then
							if (not obj.gameObject.GetComponent(AudioSource)) then
								if (obj.transform.childCount > 0) then
									possibleUsableObject = obj
								    break
								end
							end
						end
					end
				end
			end
		end
	end
	-- Give the result
	return possibleUsableObject
end

function WeaponPickupM:DropWeapon(weapon, actor)
	-- Same thing on what I did above...
	-- Do a check before doing shit
	local compatChecks = self:CompatChecks()
	if (weapon and actor and compatChecks) then
		-- Make Pickup Prefab
		local spawnPos = Vector3(actor.transform.position.x, actor.transform.position.y + 1, actor.transform.position.z)

		local droppedWeapon = GameObject.Instantiate(self.weaponBoxCollider, spawnPos, Quaternion.identity)
		local weaponImposter = weapon.weaponEntry.InstantiateImposter(droppedWeapon.transform.position, Quaternion.identity)

		-- Do some extra properties if weaponImposter isn't a nil
	    if (weaponImposter) then
		    -- Get the renderer. If it has then set hitbox scale to renderer bounds size
			if (weaponImposter.gameObject.GetComponent(Renderer)) then
				local weaponRenderer = weaponImposter.gameObject.GetComponent(Renderer)
	
				-- Check the bounds size of the weapon. If it passes then use the fixed values for the hitbox scale
				-- Means it doesn't have a correct renderer size
				if (not self:GreaterOrEqualScale(weaponRenderer.bounds.size, Vector3(1.9, 1.9, 1.9))) then
					if (not self:LessOrEqualScale(weaponRenderer.bounds.size, Vector3(0.2, 0.2, 0.2))) then
						droppedWeapon.transform.localScale = weaponRenderer.bounds.size
					end
				end
			end
	
			-- Parent the weaponImposter to the hitbox after scaling
			weaponImposter.transform.parent = droppedWeapon.transform
	    end
	
		local droppedRB = droppedWeapon.gameObject.GetComponent(Rigidbody)
	
		-- Data Setup
		-- Weapon
		self:FindDroppedWeapon(weapon, droppedWeapon)
	
		-- Ammo (This ones randomized)
		if (not actor.isPlayer) then
			local weaponAmmo = GameObject.Instantiate(self.dataObject, droppedWeapon.transform)
			local weaponSpareAmmo = GameObject.Instantiate(self.dataObject, droppedWeapon.transform)
		
			local randomAmmo = math.random(0, weapon.maxAmmo)
			local randomSpare = math.random(0, weapon.maxSpareAmmo)

			weaponAmmo.name = randomAmmo
			weaponSpareAmmo.name = randomSpare
		else
			local weaponAmmo = GameObject.Instantiate(self.dataObject, droppedWeapon.transform)
			local weaponSpareAmmo = GameObject.Instantiate(self.dataObject, droppedWeapon.transform)
		
			weaponAmmo.name = weapon.ammo
			weaponSpareAmmo.name = weapon.spareAmmo
		end
	
		-- Finishing Touches
		droppedRB.AddForce(actor.transform.forward * self.throwForce, ForceMode.Impulse)
		droppedRB.AddForce(actor.transform.up * self.upwardForce, ForceMode.Impulse)
	
		local randomRot = Random.Range(-150, 150)
		droppedRB.AddTorque(Vector3(randomRot, randomRot, randomRot))
	end
end

-- These two functions are gotten off Chai's weapon pickup code should fix some weapons just vanishing when dropped
function WeaponPickupM:GreaterOrEqualScale(objScale,other)
	if (objScale.x >= other.x and objScale.y >= other.y and objScale.z >= other.z) then
        return true
    else
        return false
    end
end

function WeaponPickupM:LessOrEqualScale(objScale, other)
	if (objScale.x <= other.x and objScale.y <= other.y and objScale.z <= other.z) then
        return true
    else
        return false
    end
end

function WeaponPickupM:FindDroppedWeapon(weapon, parent)
	for ind,wep in pairs(WeaponManager.allWeapons) do
		if (wep.name == weapon.weaponEntry.name and wep.uiSprite == weapon.weaponEntry.uiSprite) then
			self.droppedWeapons[#self.droppedWeapons+1] = wep
			break
		end
	end
	
	local weaponIndexObj = GameObject.Instantiate(self.dataObject, parent.transform)
	weaponIndexObj.name = self.droppedIndex

	self.droppedIndex = self.droppedIndex + 1
end

function WeaponPickupM:PickUpWeaponStart(weapon)
	if (weapon ~= nil) then
		-- Get The Data
		local weaponIndex = weapon.transform.GetChild(1)
		local weaponAmmo = weapon.transform.GetChild(2)
		local weaponSpareAmmo = weapon.transform.GetChild(3)

		local receivedWeapon = self.droppedWeapons[tonumber(weaponIndex.gameObject.name)]

		-- Assign Weapon
		if (not self.anarchyMode) then
			-- Regular Pickup System
			-- Weapons go to their proper slots
			self:DefaultPickupSystem(receivedWeapon, weapon, weaponAmmo, weaponSpareAmmo)
		else
			-- Anarchy Pickup System
			-- You can put weapons in any slots
			self:AnarchyPickupSystem(receivedWeapon, weapon, weaponAmmo, weaponSpareAmmo)
		end
	end
end

function WeaponPickupM:DefaultPickupSystem(receivedWeapon, weaponDrop, weaponAmmo, weaponSpareAmmo)
	-- The Default Pickup System
	-- Overlap Check
	for _,wep in pairs(Player.actor.weaponSlots) do
		if (wep.weaponEntry.slot == receivedWeapon.slot and receivedWeapon.slot ~= WeaponSlot.Gear and receivedWeapon.slot ~= WeaponSlot.LargeGear) then
			if (self:CanBeDropped(wep)) then
				self:DropWeaponManual(wep)
			end
			break
		end
	end

	-- Applying
	if (receivedWeapon.slot == WeaponSlot.Primary) then
		Player.actor.EquipNewWeaponEntry(receivedWeapon, 0, true)
		self:PickupWeaponFinish(Player.actor.activeWeapon, weaponDrop, weaponAmmo, weaponSpareAmmo)
	elseif (receivedWeapon.slot == WeaponSlot.Secondary) then
		Player.actor.EquipNewWeaponEntry(receivedWeapon, 1, true)
		self:PickupWeaponFinish(Player.actor.activeWeapon, weaponDrop, weaponAmmo, weaponSpareAmmo)
	end

	-- If the weapon is a gear or large gear then open up the inventory
	if (receivedWeapon.slot == WeaponSlot.Gear or receivedWeapon.slot == WeaponSlot.LargeGear) then
		-- Inventory setup
		self.canvas.gameObject.SetActive(true)

		self.anarchyHUD.gameObject.SetActive(false)
		self.defaultHUD.gameObject.SetActive(true)

		Screen.UnlockCursor()
		Input.DisableNumberRowInputs()

		-- Trigger bool
		self.isMenuOpen = true

		-- Setup Loadout Icons
		self.standard:SetupLoadout()

		-- Pass the current pickup data
		self.currentPickupData = {
			receivedWeapon,
			weaponDrop,
			weaponAmmo,
			weaponSpareAmmo
		}
	end
end

function WeaponPickupM:DefaultDropGearSelected(selectedSlot)
	-- Pickup data array
	local pickupData = self.currentPickupData
	local playerSlots = Player.actor.weaponSlots

	-- Reset HUD
	self:ResetHUD()

	-- Only for the default pickup system
	if (selectedSlot == 2) then
		if (not self:IsLargeGear(pickupData[1])) then
			-- Drop gear if the slot has one
			if (playerSlots[3]) then
				if (self:CanBeDropped(playerSlots[3])) then
					self:DropWeaponManual(playerSlots[3])
				end
			end
		
			-- Pickup new gear
			Player.actor.EquipNewWeaponEntry(pickupData[1], 2, true)
		else
			-- Drop two gears for the large one
			if (playerSlots[4]) then
				if (self:CanBeDropped(playerSlots[4])) then
					self:DropWeaponManual(playerSlots[4])
				end
			end

			if (playerSlots[5]) then
				if (self:CanBeDropped(playerSlots[5])) then
					self:DropWeaponManual(playerSlots[5])
				end
			end

			-- Pickup large gear
			Player.actor.EquipNewWeaponEntry(pickupData[1], 3, true)
		end

		self:PickupWeaponFinish(Player.actor.activeWeapon, pickupData[2], pickupData[3], pickupData[4])
	elseif (selectedSlot == 3) then
		if (not self:IsLargeGear(pickupData[1])) then
			-- Drop gear if the slot has one
			if (playerSlots[4]) then
				if (self:CanBeDropped(playerSlots[4])) then
					self:DropWeaponManual(playerSlots[4])
				end
			end
		
			-- Pickup new gear
			Player.actor.EquipNewWeaponEntry(pickupData[1], 3, true)
		else
			-- Drop two gears for the large one
			if (playerSlots[4]) then
				if (self:CanBeDropped(playerSlots[4])) then
					self:DropWeaponManual(playerSlots[4])
				end
			end

			if (playerSlots[5]) then
				if (self:CanBeDropped(playerSlots[5])) then
					self:DropWeaponManual(playerSlots[5])
				end
			end

			-- Pickup large gear
			Player.actor.EquipNewWeaponEntry(pickupData[1], 3, true)
		end

		-- Finish Pickup System
		self:PickupWeaponFinish(Player.actor.activeWeapon, pickupData[2], pickupData[3], pickupData[4])
	elseif (selectedSlot == 4) then
		if (not self:IsLargeGear(pickupData[1])) then
			-- Drop gear if the slot has one
			if (playerSlots[5]) then
				if (self:CanBeDropped(playerSlots[5])) then
					self:DropWeaponManual(playerSlots[5])
				end
			end
	
			-- Pickup new gear
			Player.actor.EquipNewWeaponEntry(pickupData[1], 4, true)
		else
			-- Drop two gears for the large one
			if (playerSlots[4]) then
				if (self:CanBeDropped(playerSlots[4])) then
					self:DropWeaponManual(playerSlots[4])
				end
			end

			if (playerSlots[5]) then
				if (self:CanBeDropped(playerSlots[5])) then
					self:DropWeaponManual(playerSlots[5])
				end
			end

			-- Pickup large gear
			Player.actor.EquipNewWeaponEntry(pickupData[1], 3, true)
		end

		-- Finish Pickup System
		self:PickupWeaponFinish(Player.actor.activeWeapon, pickupData[2], pickupData[3], pickupData[4])
	end
end

function WeaponPickupM:IsLargeGear(weapon)
	if (weapon) then
		if (weapon.slot == WeaponSlot.LargeGear) then
			return true
		else
			return false
		end
	else
		return false
	end
end

function WeaponPickupM:AnarchyPickupSystem(receivedWeapon, weaponDrop, weaponAmmo, weaponSpareAmmo)
	-- Anarchy Pickup System
	-- Setup Some Stuff
	self.canvas.gameObject.SetActive(true)

	self.anarchyHUD.gameObject.SetActive(true)
	self.defaultHUD.gameObject.SetActive(false)

	Screen.UnlockCursor()
	Input.DisableNumberRowInputs()

	-- Trigger bool
	self.isMenuOpen = true

	-- Setup Loadout Icons
	self.anarchy:SetupLoadout()

	-- Pass the current pickup data
	self.currentPickupData = {
		receivedWeapon,
		weaponDrop,
		weaponAmmo,
		weaponSpareAmmo
	}
end

function WeaponPickupM:AnarchyDropWeaponSelected(selectedSlot)
	-- Only For Anarchy Pickup System
	-- Pickup data array
	local pickupData = self.currentPickupData
	local playerSlots = Player.actor.weaponSlots

	-- Drop weapon in the selected slot if its valid
	for _,wep in pairs(playerSlots) do
		if (wep.slot == selectedSlot) then
			if (self:CanBeDropped(wep)) then
				self:DropWeaponManual(wep)
			end
		end
	end

	-- Reset HUD
	self:ResetHUD()

	-- Give the weapon
	Player.actor.EquipNewWeaponEntry(pickupData[1], selectedSlot, true)
	self:PickupWeaponFinish(Player.actor.activeWeapon, pickupData[2], pickupData[3], pickupData[4])
end

function WeaponPickupM:ResetHUD()
	-- Self Explanatory
	self.anarchyHUD.gameObject.SetActive(false)
	self.defaultHUD.gameObject.SetActive(false)

	self.canvas.gameObject.SetActive(false)

	Screen.LockCursor()
	Input.EnableNumberRowInputs()

	-- Trigger bool
	self.isMenuOpen = false
end

function WeaponPickupM:PickupWeaponFinish(weapon, weaponDrop, weaponAmmo, weaponSpareAmmo)
	-- Apply Weapon Ammo Data
	weapon.ammo = tonumber(weaponAmmo.gameObject.name)
	weapon.spareAmmo = tonumber(weaponSpareAmmo.gameObject.name)

	-- Destroy Pickup
	GameObject.Destroy(weaponDrop)

	-- Quick Throw Compatibility
	if self.quickThrow then
		self.quickThrow.self:doDelayedEvaluate()
	end
	
	-- Universal Recoil Compatibility
	if self.isUsingURM then
		self.URM:AssignWeaponStats(weapon)
	end

	--Invoke the event to tell all listeners that a weapon has been picked up
	self:InvokeOnWeaponPickupMEvent(weapon)
end

--Will always return true if neither mod is present
function WeaponPickupM:CompatChecks()
	if self.quickThrow and self.quickThrow.self.isThrowing then return false end
	if self.playerArmor and self.playerArmor.self.isInArmorPlateMode then return false end
	return true
end

function WeaponPickupM:AddOnWeaponPickupMListener(owner,func)
	self.onWeaponPickUpMListeners[owner] = func
end

function WeaponPickupM:RemoveOnWeaponPickupMListener(owner)
	self.onWeaponPickUpMListeners[owner] = nil
end

--Call all functions in the table
function WeaponPickupM:InvokeOnWeaponPickupMEvent(weapon)
	for owner, func in pairs(self.onWeaponPickUpMListeners) do
		func(weapon)
	end
end