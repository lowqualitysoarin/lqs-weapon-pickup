-- low_quality_soarin, RadioactiveJellyfish © 2023-2024
behaviour("LQS_WeaponPickup")

function LQS_WeaponPickup:Awake()
	-- Data
	self.weaponEntry = nil

	self.weaponAmmo = 0 
	self.weaponSpareAmmo = 0

	self.altWeaponAmmo = {}
	self.altWeaponSpareAmmo = {}

	-- Some components soo I don't need to do getcomponent again
	self.dropRB = self.gameObject.GetComponent(Rigidbody)

	-- Vars
	self.freezePhysicsEnabled = false
	self.playerInRange = false
	self.freezePhysicsTimer = 0
	self.freezePhysicsDistance = 150
end

function LQS_WeaponPickup:Debug()
	local weaponEntryName = "Name: " .. "<color=green>" .. self.weaponEntry.name .. "</color>"
	print("WeaponEntry:","<color=blue>" .. tostring(self.weaponEntry) .. "</color>",weaponEntryName)

	print("Ammo:","<color=yellow>" .. tostring(self.weaponAmmo) .. "</color>")
	print("SpareAmmo:","<color=yellow>" .. tostring(self.weaponSpareAmmo) .. "</color>")

	if (#self.altWeaponAmmo > 0 and #self.altWeaponSpareAmmo) then
		print("AltWeapons Ammo and SpareAmmo:")
		for index1,altAmmo in pairs(self.altWeaponAmmo) do
			for index2,altSpareAmmo in pairs(self.altWeaponSpareAmmo) do
				print("[<color=orange>" .. tostring(index1) .. "</color>]" .. " Ammo:","<color=yellow>" .. tostring(altAmmo) .. "</color>")
				print("[<color=orange>" .. tostring(index2) .. "</color>]" .. " SpareAmmo:","<color=yellow>" .. tostring(altSpareAmmo) .. "</color>")
			end
		end
	end
end

function LQS_WeaponPickup:StartLifetime(duration)
	-- Lifetime of the pickup
	GameObject.Destroy(self.gameObject, duration)
end

function LQS_WeaponPickup:Update()
	if (not self.freezePhysicsEnabled) then return end
	if (not Player.actor) then return end

	-- Distance checking for the physics freeze
	-- Nvm switching to Vector3.Distance, it causes awful perf on my end
	local distanceToPlayer = Vector3.Distance(self.transform.position, Player.actor.transform.position)
	if (distanceToPlayer > self.freezePhysicsDistance) then
		self.playerInRange = false
	else
		self.playerInRange = true
	end

	-- This is mostly some rigidbody stuff
	-- Freeze the rigidbody if the player isn't in range
	if (self.dropRB.velocity.magnitude < 1 and not self.playerInRange) then
		self.freezePhysicsTimer = self.freezePhysicsTimer + 1 * Time.deltaTime
		if (self.freezePhysicsTimer >= 5) then
			self.dropRB.isKinematic = true
		end
	else
		self.freezePhysicsTimer = 0
		self.dropRB.isKinematic = false
	end
end
