-- low_quality_soarin, RadioactiveJellyfish © 2023-2024
behaviour("LQS_WeaponPickupM")

function LQS_WeaponPickupM:Awake()
	-- Some components soo I don't need to do getcomponent again
	self.dropRB = self.gameObject.GetComponent(Rigidbody)

	-- Vars
	self.freezePhysicsEnabled = false
	self.playerInRange = false
	self.freezePhysicsTimer = 0
	self.freezePhysicsDistance = 150
end

function LQS_WeaponPickupM:Start()
	-- Apply config
	local lqsWeaponBase = _G.LQSWeaponPickupBase
	if (lqsWeaponBase) then
		self.freezePhysicsEnabled = lqsWeaponBase.freezePhysicsWhenStopped
		self.freezePhysicsDistance = lqsWeaponBase.freezePhysicsDistance
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
