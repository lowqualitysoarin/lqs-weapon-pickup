-- low_quality_soarin, RadioactiveJellyfish © 2023-2024
behaviour("LQS_WeaponPickupM")

function LQS_WeaponPickupM:Awake()
	-- Some components soo I don't need to do getcomponent again
	self.dropRB = self.gameObject.GetComponent(Rigidbody)

	-- Vars
	self.freezePhysicsEnabled = false
	self.alreadySentPacket = false
	self.playerInRange = false
	self.freezePhysicsTimer = 0
	self.freezePhysicsDistance = 150

	-- Events
    GameEventsOnline.onReceivePacket.AddListener(self,"ReceivePacket")
end

function LQS_WeaponPickupM:ReceivePacket(id, data)
	self:AssignFinalTransform(data)
end

function LQS_WeaponPickupM:Start()
	-- Apply config
	local lqsWeaponBase = _G.LQSWeaponPickupBaseM
	if (lqsWeaponBase) then
		self.weaponPickupBase = lqsWeaponBase
		self.freezePhysicsEnabled = self.weaponPickupBase.freezePhysicsWhenStopped
		self.freezePhysicsDistance = self.weaponPickupBase.freezePhysicsDistance
	end
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

function LQS_WeaponPickupM:GetFinalTransform()
	local restPosition = self.transform.position
	local restRotation = self.transform.rotation

	local dropID = self.transform.GetChild(4).gameObject.name

	OnlinePlayer.SendPacketToServer("lqswp;;" .. dropID  .. ";;assignfinalpos;;" .. 
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
	local thisDropOBJ = self.transform.GetChild(4).gameObject
	if (thisDropOBJ) then
		local thisDropID = thisDropOBJ.name
		if (unwrappedData[2] == thisDropID) then
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
