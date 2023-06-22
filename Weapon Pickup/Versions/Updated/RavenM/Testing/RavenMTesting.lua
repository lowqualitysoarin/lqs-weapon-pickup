behaviour("RavenMTesting")

function RavenMTesting:Start()
	self.cube = self.targets.cube
	self.sphere = self.targets.sphere

	GameEventsOnline.onSendPacket.AddListener(self, "SendPacket")
	GameEventsOnline.onReceivePacket.AddListener(self, "ReceivePacket")
end

function RavenMTesting:SendPacket(id, data)
	self:SpawnObject(data)
end

function RavenMTesting:ReceivePacket(id, data)
	self:SpawnObject(data)
end

function RavenMTesting:PacketUnwrapper(data)
	local unwrappedData = {}
	for word in string.gmatch(data, "([^;;]+)") do
		unwrappedData[#unwrappedData+1] = word
	end
	return unwrappedData
end

function RavenMTesting:SpawnObject(data)
	local data = self:PacketUnwrapper(data)

	if (data[1] ~= "ravenmtesting") then return end
	if (data[2] ~= "spawnobject") then return end

	local targetActor = OnlinePlayer.GetPlayerFromName(data[3])
	if (targetActor) then
		local gameObject = GameObject.Instantiate(self.cube, Vector3.zero, Quaternion.identity)
		local newSphere = GameObject.Instantiate(self.sphere, gameObject.transform)

		Lobby.AddNetworkPrefab(gameObject)
		Lobby.PushNetworkPrefabs()

		local targetPos = Vector3(
			tonumber(data[4]),
			tonumber(data[5]),
			tonumber(data[6])
		)
		local finalObj = GameObjectM.Instantiate(gameObject, targetPos, Quaternion.identity)
	end
end

function RavenMTesting:Update()
	if (Input.GetKeyDown(KeyCode.P)) then
		local ray = PlayerCamera.fpCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
        local spawnRay = Physics.Raycast(ray, Mathf.Infinity, RaycastTarget.ProjectileHit)
		if (spawnRay) then
			OnlinePlayer.SendPacketToServer("ravenmtesting;;spawnobject;;" .. Player.actor.name .. 
			";;" .. tostring(spawnRay.point.x) .. ";;" .. tostring(spawnRay.point.y) .. ";;" .. tostring(spawnRay.point.z), 1984, true)
		end
	end
end
