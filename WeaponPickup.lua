--low_quality_soarin, RadioactiveJellyfish © 2023-2024
behaviour("WeaponPickup")

local pickupDetected = false
local pickupRayCast = nil
local alreadyChecked = false

function WeaponPickup:Start()
	-- Base
	self.weaponBoxCollider = self.targets.cubeCollider

	-- Rigid Force
	self.throwForce = 18.7
	self.upwardForce = 8.5

	-- Data Setup
	self.droppedWeapons = {}
	self.droppedIndex = 1

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
end

function WeaponPickup:OnActorDied(actor)
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

function WeaponPickup:Update()
	-- Pickup Base
	-- Dropping
	if (Input.GetKeyDown(self.dropKey) and Player.actor.activeWeapon ~= nil and self:CanBeDropped(Player.actor.activeWeapon)) then
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
end

function WeaponPickup:CanBeDropped(weapon)
	if (self.canBlacklist) then
		if (weapon ~= nil) then
			if (self.blacklistedWeapons[weapon.weaponEntry.name] == true) then
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

function WeaponPickup:PickupDelay()
	coroutine.yield(WaitForSeconds(self.pickupDelay))
	self.canPickup = true
	return nil
end

function WeaponPickup:DropWeaponManual(weapon)
	-- Make Pickup Prefab
	local selectedWeapon = weapon
	local playerCam = PlayerCamera.activeCamera.transform
	local spawnPos = selectedWeapon.transform.position + playerCam.forward

	local droppedWeapon = GameObject.Instantiate(self.weaponBoxCollider, spawnPos, Quaternion.identity)
	local weaponImposter = selectedWeapon.weaponEntry.InstantiateImposter(droppedWeapon.transform.position, Quaternion.identity)

	-- Do some extra properties if weaponImposter isn't a nil
	if (weaponImposter ~= nil) then
		-- Get the renderer. If it has then set hitbox scale to renderer bounds size
		if (weaponImposter.gameObject.GetComponent(Renderer) ~= nil) then
			droppedWeapon.transform.localScale = weaponImposter.gameObject.GetComponent(Renderer).bounds.size
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

function WeaponPickup:DropWeapon(weapon, actor)
	-- Same thing on what I did above...
	-- Do a check before doing shit
	local compatChecks = self:CompatChecks()
	if (weapon ~= nil and actor ~= nil and compatChecks) then
		-- Make Pickup Prefab
		local spawnPos = Vector3(actor.transform.position.x, actor.transform.position.y + 1, actor.transform.position.z)

		local droppedWeapon = GameObject.Instantiate(self.weaponBoxCollider, spawnPos, Quaternion.identity)
		local weaponImposter = weapon.weaponEntry.InstantiateImposter(droppedWeapon.transform.position, Quaternion.identity)

		-- Do some extra properties if weaponImposter isn't a nil
	    if (weaponImposter ~= nil) then
		    -- Get the renderer. If it has then set hitbox scale to renderer bounds size
			if (weaponImposter.gameObject.GetComponent(Renderer) ~= nil) then
				droppedWeapon.transform.localScale = weaponImposter.gameObject.GetComponent(Renderer).bounds.size
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

function WeaponPickup:FindDroppedWeapon(weapon, parent)
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

function WeaponPickup:PickUpWeaponStart(weapon)
	if (weapon ~= nil) then
		-- Get The Data
		local weaponIndex = weapon.transform.GetChild(1)
		local weaponAmmo = weapon.transform.GetChild(2)
		local weaponSpareAmmo = weapon.transform.GetChild(3)

		local receivedWeapon = self.droppedWeapons[tonumber(weaponIndex.gameObject.name)]

		-- Overlap Check
		for _,wep in pairs(Player.actor.weaponSlots) do
			if (wep.weaponEntry.slot == receivedWeapon.slot) then
				self:DropWeaponManual(wep)
				break
			end
		end

		-- Applying
		if (receivedWeapon.slot == WeaponSlot.Primary) then
			Player.actor.EquipNewWeaponEntry(receivedWeapon, 0, true)
		elseif (receivedWeapon.slot == WeaponSlot.Secondary) then
			Player.actor.EquipNewWeaponEntry(receivedWeapon, 1, true)
		elseif (receivedWeapon.slot == WeaponSlot.Gear) then
			Player.actor.EquipNewWeaponEntry(receivedWeapon, 2, true)
		elseif (receivedWeapon.slot == WeaponSlot.LargeGear) then
			Player.actor.EquipNewWeaponEntry(receivedWeapon, 4, true)
		end

		local newWeapon = Player.actor.activeWeapon
	
		newWeapon.ammo = tonumber(weaponAmmo.gameObject.name)
		newWeapon.spareAmmo = tonumber(weaponSpareAmmo.gameObject.name)

		-- Destroy Pickup
		GameObject.Destroy(weapon)

		--Quick Throw Compatibility
		if self.quickThrow then
			self.quickThrow.self:doDelayedEvaluate()
		end
		--Universal Recoil Compatibility
		if self.isUsingURM then
			self.URM:AssignWeaponStats(weapon)
		end
	end
end

-- Will always return true if neither mod is present
function WeaponPickup:CompatChecks()
	if self.quickThrow and self.quickThrow.self.isThrowing then return false end
	if self.playerArmor and self.playerArmor.self.isInArmorPlateMode then return false end
	return true
end
