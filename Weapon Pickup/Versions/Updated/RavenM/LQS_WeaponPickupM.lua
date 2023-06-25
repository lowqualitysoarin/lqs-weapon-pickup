-- low_quality_soarin, RadioactiveJellyfish © 2023-2024
behaviour("LQS_WeaponPickupM")

function LQS_WeaponPickupM:Awake()
	-- Data
	self.dropID = nil
	self.weaponEntry = nil

	self.weaponAmmo = 0
	self.weaponSpareAmmo = 0

	self.altWeaponAmmo = {}
	self.altWeaponSpareAmmo = {}

	-- Some components soo I don't need to do getcomponent again
	self.dropRB = self.gameObject.GetComponent(Rigidbody)

	-- Vars
	self.freezePhysicsEnabled = false
	self.alreadySentPacket = false
	self.playerInRange = false
	self.freezePhysicsTimer = 0
	self.freezePhysicsDistance = 150
end

function LQS_WeaponPickupM:Start()
	-- Events
    GameEventsOnline.onReceivePacket.AddListener(self,"ReceivePacket")
	GameEventsOnline.onSendPacket.AddListener(self,"SendPacket")

	-- Get the weapon pickup base's script
	self.weaponPickupBase = _G.LQSWeaponPickupBaseM
end

function LQS_WeaponPickupM:Debug()
	local weaponEntryName = "Name: " .. "<color=green>" .. self.weaponEntry.name .. "</color>"
	print("WeaponEntry:","<color=blue>" .. tostring(self.weaponEntry) .. "</color>",weaponEntryName)

	print("Ammo:","<color=yellow>" .. tostring(self.weaponAmmo) .. "</color>")
	print("SpareAmmo:","<color=yellow>" .. tostring(self.weaponSpareAmmo) .. "</color>")

	if (#self.altWeaponAmmo > 0 and #self.altWeaponSpareAmmo > 0) then
		print("AltWeapons Ammo and SpareAmmo:")
		for index1,altAmmo in pairs(self.altWeaponAmmo) do
			for index2,altSpareAmmo in pairs(self.altWeaponSpareAmmo) do
				print("[<color=orange>" .. tostring(index1) .. "</color>]" .. " Ammo:","<color=yellow>" .. tostring(altAmmo) .. "</color>")
				print("[<color=orange>" .. tostring(index2) .. "</color>]" .. " SpareAmmo:","<color=yellow>" .. tostring(altSpareAmmo) .. "</color>")
			end
		end
	end

	print("Drop ID:", "<color=aqua>" .. self.dropID .. "</color>")
end

function LQS_WeaponPickupM:StartLifetime(duration)
	-- Lifetime of the pickup
	GameObject.Destroy(self.gameObject, duration)
end

function LQS_WeaponPickupM:SendPacket(id, data)
	self:DestroyPickup(data)
end

function LQS_WeaponPickupM:ReceivePacket(id, data)
	self:DestroyPickup(data)
	self:AssignFinalTransform(data)
end

function LQS_WeaponPickupM:Update()
	if (not self.freezePhysicsEnabled) then return end
	if (not Player.actor) then return end

	-- Distance checking for the physics freeze
	-- I'm using sqrMagnitude since its more optimised they say
	local distanceToPlayer = self.transform.position - Player.actor.transform.position
	if (distanceToPlayer.sqrMagnitude > self.freezePhysicsDistance) then
		self.playerInRange = false
	else
		self.playerInRange = true
	end

	-- This is mostly some rigidbody stuff
	if (self.dropRB.velocity.magnitude < 1) then
		-- Freeze the rigidbody if the player isn't in range
		if (not self.playerInRange) then
			self.freezePhysicsTimer = self.freezePhysicsTimer + 1 * Time.deltaTime
			if (self.freezePhysicsTimer >= 5) then
				self.dropRB.isKinematic = true
			end
		end

		-- Update the current transform through all clients
	    -- Only works if the object isn't moving on the host's end, doing this here. Because in update it results a accurate position/rotation view on all
	    -- clients. But in exchange of having the worst frames as possible on the clients. The host don't experience lag at all
	    if (Lobby.isHost and self.weaponPickupBase and not self.alreadySentPacket) then
	    	self:GetFinalTransform()
	    end 
	else
		self.freezePhysicsTimer = 0
		self.dropRB.isKinematic = false
		self.alreadySentPacket = false
	end
end

function LQS_WeaponPickupM:SendDestroyPacket(dropID)
	-- Just realised packets aren't universal lol
	OnlinePlayer.SendPacketToServer("lqswp;;" .. dropID .. ";;weaponpickedup", tonumber(self.weaponPickupBase.weaponPickupBaseID), true)
end

function LQS_WeaponPickupM:DestroyPickup(data)
	-- Basically destroys the pickup
	-- If the id in the packet matches with the pickup's dropID
	-- Then the drop destroys it self
	if (not self.weaponPickupBase) then return end
	local unwrappedData = self.weaponPickupBase:UnwrapPacket(data)

	if (#unwrappedData == 0) then return end
	if (unwrappedData[1] ~= "lqswp") then return end
	if (unwrappedData[3] ~= "weaponpickedup") then return end

	if (unwrappedData[2] == self.dropID) then
		GameObject.Destroy(self.gameObject)
	end
end

function LQS_WeaponPickupM:GetFinalTransform()
	local restPosition = self.transform.position
	local restRotation = self.transform.rotation

	OnlinePlayer.SendPacketToServer("lqswp;;" .. self.dropID  .. ";;assignfinalpos;;" .. 
	tostring(restPosition.x) .. ";;" .. tostring(restPosition.y) .. ";;" .. tostring(restPosition.z) .. ";;" ..
    tostring(restRotation.eulerAngles.x) .. ";;" .. tostring(restRotation.eulerAngles.y) .. ";;" .. tostring(restRotation.eulerAngles.z), 
	tonumber(self.weaponPickupBase.weaponPickupBaseID), true)

	self.alreadySentPacket = true
end

function LQS_WeaponPickupM:AssignFinalTransform(data)
	-- This basically assigns the final pos of the
	if (not self.weaponPickupBase) then return end
	local unwrappedData = self.weaponPickupBase:UnwrapPacket(data)

	if (#unwrappedData == 0) then return end
	if (unwrappedData[1] ~= "lqswp") then return end
	if (unwrappedData[3] ~= "assignfinalpos") then return end

	-- Have to do more checking on this piece of shit because the clients
	-- do get errors for some strange reasons
	if (unwrappedData[2] == self.dropID) then
		local foundFinalPos = Vector3(
			tonumber(unwrappedData[4]),
			tonumber(unwrappedData[5]),
			tonumber(unwrappedData[6])
		)
		local foundFinalRot = Vector3(
			tonumber(unwrappedData[7]),
			tonumber(unwrappedData[8]),
			tonumber(unwrappedData[9])
		)

		self.script.StartCoroutine(self:LerpToFinal(foundFinalPos, Quaternion.Euler(foundFinalRot)))
	end
end

function LQS_WeaponPickupM:LerpToFinal(pos, rot)
	-- Lerps to the final pos, the one in the host's end
	return function()
		local time = 0
		local thisTransform = self.transform

		while (time < 3.5) do
			thisTransform.position = Vector3.Lerp(thisTransform.position, pos, time / 3.5)
			thisTransform.rotation = Quaternion.Lerp(thisTransform.rotation, rot, time / 3.5)
			time = time + 1 * Time.deltaTime

			coroutine.yield(WaitForSeconds(0))
		end
	end
end
