behaviour("WeaponPickupLifetimeM")

function WeaponPickupLifetimeM:Start()
	self.canDespawn = true
	self.despawnTime = 140

	local basePickupScriptOBJ = GameObject.Find("[LQS]WeaponPickupMulti(Clone)")

	if (basePickupScriptOBJ ~= nil) then
		basePickupScript = basePickupScriptOBJ.GetComponent(WeaponPickup)

		if (basePickupScript ~= nil) then
			self.canDespawn = basePickupScript.canDespawn
			self.despawnTime = basePickupScript.despawnTime
		end
	end

	if (self.canDespawn) then GameObject.Destroy(self.gameObject, self.despawnTime) end
end
