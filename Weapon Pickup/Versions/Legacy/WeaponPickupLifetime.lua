behaviour("WeaponPickupLifetime")

function WeaponPickupLifetime:Start()
	-- Rigidbody
	self.rb = self.gameObject.GetComponent(Rigidbody)

	-- Lifetime
	self.canDespawn = true
	self.despawnTime = 140

	-- Optimisation Sake
	self.disablePhysicsTime = 5
	self.disablePhysicsTimer = 0
	self.disablePhysicsDist = 25

	self.playerInRange = false
	self.canFreeze = true

	-- Weapon Pickup Base
	local basePickupScriptOBJ = GameObject.Find("[LQS]WeaponPickup(Clone)")

	if (basePickupScriptOBJ ~= nil) then
		self.basePickupScript = basePickupScriptOBJ.GetComponent(WeaponPickup)

		if (self.basePickupScript ~= nil) then
			self.canDespawn = self.basePickupScript.canDespawn
			self.despawnTime = self.basePickupScript.despawnTime
			self.canFreeze = self.basePickupScript.freezePhysicsWhenStopped
			self.disablePhysicsDist = self.basePickupScript.freezePhysicsDistance
		end
	end

	-- Destroy Timer
	if (self.canDespawn) then GameObject.Destroy(self.gameObject, self.despawnTime) end
end

function WeaponPickupLifetime:Update()
	-- Freezing
	if (self.canFreeze) then
		-- Disable the physics when it stops moving
		if (self.rb.velocity.magnitude < 1 and not self.playerInRange) then
			self.disablePhysicsTimer = self.disablePhysicsTimer + 1 * Time.deltaTime
	
			if (self.disablePhysicsTimer >= self.disablePhysicsTime) then
				self.rb.isKinematic = true
			end
		else
			self.disablePhysicsTimer = 0
			self.rb.isKinematic = false
		end
	
		-- Re-Enable the physics when the player is in Range
		if (Player.actor.transform) then
			-- Get Distance To Player
			local distanceToPlayer = (Player.actor.transform.position - self.gameObject.transform.position).magnitude
	
			if (distanceToPlayer > self.disablePhysicsDist) then
				self.playerInRange = false
			else
				self.playerInRange = true
			end
		end
	end
end
