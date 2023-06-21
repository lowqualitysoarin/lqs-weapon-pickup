behaviour("RavenMTesting")

function RavenMTesting:Start()
	self.cube = self.targets.cube
	Lobby.AddNetworkPrefab(self.cube)
	Lobby.PushNetworkPrefabs()
end

function RavenMTesting:Update()
	if (Input.GetKeyDown(KeyCode.P)) then
		print("spawning")
		local ray = PlayerCamera.fpCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
        local spawnRay = Physics.Raycast(ray, Mathf.Infinity, RaycastTarget.ProjectileHit)
		print(spawnRay)
		if (spawnRay) then
			local gameObject = GameObjectM.Instantiate(self.cube, spawnRay.point, Quaternion.identity)
			-- gameObject.transform.position = spawnRay.point
			print("spawned!")
		end
	end
end
