--low_quality_soarin © 2022-2023
behaviour("WeaponPickupM")

local pickupDetected = false
local pickupRayCast = nil
local alreadyChecked = false

function WeaponPickupM:Start()
	-- Base
	self.weaponBoxCollider = self.targets.cubeCollider

	-- Rigid Force
	self.throwForce = 18.7
	self.upwardForce = 8.5
	self.pickupRange = 1.6

	-- Data Setup
	self.droppedWeapons = {}
	self.droppedIndex = 1

	self.dataObject = self.targets.emptyCopy

	-- Config
	self.canDespawn = self.script.mutator.GetConfigurationBool("canDespawn")
	self.despawnTime = self.script.mutator.GetConfigurationFloat("despawnTime")

	self.pickupDelay = self.script.mutator.GetConfigurationFloat("pickupDelay")
	self.canPickup = true

	-- Keybinds
	self.pickupKey = string.lower(self.script.mutator.GetConfigurationString("pickupKey"))
	self.dropKey = string.lower(self.script.mutator.GetConfigurationString("dropKey"))

	-- Listeners
	GameEvents.onActorDied.AddListener(self, "OnActorDied")
end

function WeaponPickupM:OnActorDied(actor)
	self:DropWeapon(actor.activeWeapon, actor)
end

function WeaponPickupM:Update()
	-- Pickup Base
	local pickupRay = Ray(PlayerCamera.activeCamera.transform.position, PlayerCamera.activeCamera.transform.forward)
	pickupRayCast = Physics.Spherecast(pickupRay, 0.25, self.pickupRange, RaycastTarget.Default)
	
	if (Input.GetKeyDown(self.dropKey) and Player.actor.activeWeapon ~= nil and self.canPickup) then
		self:DropWeaponManual(Player.actor.activeWeapon)
		self.canPickup = false
		self.script.StartCoroutine("PickupDelay")
	end

	if (pickupRayCast ~= nil) then
		if (pickupRayCast.collider.gameObject.name == "[LQS]PickupHitboxMP{}(Clone)") then
			pickupDetected = true
		else
			pickupDetected = false
			alreadyChecked = false
		end

		if (Input.GetKeyDown(self.pickupKey) and pickupDetected) then
			local currentPickup = pickupRayCast.collider.gameObject
			self:PickUpWeaponStart(currentPickup)
		end
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
	local spawnPos = selectedWeapon.transform.position + playerCam.forward

	local droppedWeapon = GameObjectM.Instantiate(self.weaponBoxCollider, spawnPos)

	-- Bounds Scaling
	local weaponImposter = nil

	-- Get The Weapon Model (Doing this way since RavenM doesn't have support for Instantiating imposters for weapons)
	if (self:GetTPModel(weapon) == nil) then return end

	local decoy = GameObjectM.Instantiate(self:GetTPModel(weapon).gameObject, spawnPos)
	decoy.transform.position = Vector3.zero
	decoy.transform.rotation = Quaternion.Euler(Vector3.zero)

	weaponImposter = decoy

	if (weaponImposter ~= nil and weaponImposter.gameObject.GetComponent(Renderer) ~= nil) then
		droppedWeapon.transform.localScale = weaponImposter.gameObject.GetComponent(Renderer).bounds.size
		weaponImposter.transform.parent = droppedWeapon.transform

		droppedWeapon.transform.position = spawnPos
	end

	local droppedRB = droppedWeapon.gameObject.GetComponent(Rigidbody)

	-- Data Setup (Jesus christ I'm sorry I really have to do this again...)
	-- Weapon
	self:FindDroppedWeapon(selectedWeapon, droppedWeapon)

	-- Ammo
	local weaponAmmo = GameObjectM.Instantiate(self.dataObject)
	local weaponSpareAmmo = GameObjectM.Instantiate(self.dataObject)

	weaponAmmo.name = selectedWeapon.ammo
	weaponSpareAmmo.name = selectedWeapon.spareAmmo

	weaponAmmo.transform.parent = droppedWeapon.transform
	weaponSpareAmmo.transform.parent = droppedWeapon.transform
	
	--Finishing Touches

	droppedRB.AddForce(playerCam.forward * self.throwForce, ForceMode.Impulse)
	droppedRB.AddForce(playerCam.up * self.upwardForce, ForceMode.Impulse)

	local randomRot = Random.Range(-150, 150)
	droppedRB.AddTorque(Vector3(randomRot, randomRot, randomRot))

	-- Remove Weapon
	local droppedWeaponSlot = selectedWeapon.gameObject.GetComponent(Weapon).slot
	Player.actor.removeWeapon(droppedWeaponSlot)
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
	if (weapon ~= nil and actor ~= nil) then
		-- Make Pickup Prefab
		local spawnPos = Vector3(actor.transform.position.x, actor.transform.position.y + 1, actor.transform.position.z)

		local droppedWeapon = GameObjectM.Instantiate(self.weaponBoxCollider, spawnPos)
	
		-- Bounds Scaling
		local weaponImposter = nil

		-- Get The Weapon Model (Doing this way since RavenM doesn't have support for Instantiating imposters for weapons)
		if (self:GetTPModel(weapon) == nil) then return end

		local decoy = GameObjectM.Instantiate(self:GetTPModel(weapon).gameObject, spawnPos)
		decoy.transform.position = Vector3.zero
		decoy.transform.rotation = Quaternion.Euler(Vector3.zero)
	
		weaponImposter = decoy
	
		if (weaponImposter ~= nil and weaponImposter.gameObject.GetComponent(Renderer) ~= nil) then
			droppedWeapon.transform.localScale = weaponImposter.gameObject.GetComponent(Renderer).bounds.size
			weaponImposter.transform.parent = droppedWeapon.transform
	
			droppedWeapon.transform.position = spawnPos
		end

		local droppedRB = droppedWeapon.gameObject.GetComponent(Rigidbody)
	
		-- Data Setup
		-- Weapon
		self:FindDroppedWeapon(weapon, droppedWeapon)
	
		-- Ammo (This ones randomized)
		local weaponAmmo = GameObjectM.Instantiate(self.dataObject)
		local weaponSpareAmmo = GameObjectM.Instantiate(self.dataObject)
	
		local randomAmmo = math.random(0, weapon.maxAmmo)
		local randomSpare = math.random(0, weapon.maxSpareAmmo)
	
		weaponAmmo.name = randomAmmo
		weaponSpareAmmo.name = randomSpare

		weaponAmmo.transform.parent = droppedWeapon.transform
		weaponSpareAmmo.transform.parent = droppedWeapon.transform
	
		-- Finishing Touches
	
		droppedRB.AddForce(actor.transform.forward * self.throwForce, ForceMode.Impulse)
		droppedRB.AddForce(actor.transform.up * self.upwardForce, ForceMode.Impulse)
	
		local randomRot = Random.Range(-150, 150)
		droppedRB.AddTorque(Vector3(randomRot, randomRot, randomRot))
	end
end

function WeaponPickupM:FindDroppedWeapon(weapon, parent)
	for ind,wep in pairs(WeaponManager.allWeapons) do
		if (wep.name == weapon.weaponEntry.name and wep.uiSprite == weapon.weaponEntry.uiSprite) then
			self.droppedWeapons[#self.droppedWeapons+1] = wep
			break
		end
	end
	
	local weaponIndexObj = GameObjectM.Instantiate(self.dataObject)
	local weaponSlot = GameObjectM.Instantiate(self.dataObject)

	weaponIndexObj.transform.parent = parent.transform
	weaponSlot.transform.parent = parent.transform

	weaponSlot.gameObject.name = weapon.slot
	weaponIndexObj.gameObject.name = self.droppedIndex

	self.droppedIndex = self.droppedIndex + 1
end

function WeaponPickupM:PickUpWeaponStart(weapon)
	if (weapon ~= nil) then
		--Get The Data
		local weaponIndex = weapon.transform.GetChild(1)
		local weaponSlot = weapon.transform.GetChild(2)
		local weaponAmmo = weapon.transform.GetChild(3)
		local weaponSpareAmmo = weapon.transform.GetChild(4)

		-- Overlap Check
		for _,wep in pairs(Player.actor.weaponSlots) do
			if (wep.slot == tonumber(weaponSlot.gameObject.name)) then
				self:DropWeaponManual(wep)
				break
			end
		end

		-- Applying
		local finalWeaponIndex = tonumber(weaponIndex.gameObject.name)

		Player.actor.EquipNewWeaponEntry(self.droppedWeapons[finalWeaponIndex], tonumber(weaponSlot.gameObject.name), true)
		local newWeapon = Player.actor.activeWeapon
	
		newWeapon.ammo = tonumber(weaponAmmo.gameObject.name)
		newWeapon.spareAmmo = tonumber(weaponSpareAmmo.gameObject.name)

		-- Destroy Pickup
		GameObject.Destroy(weapon)
	end
end