behaviour("WeaponPickupInventory")

function WeaponPickupInventory:Start()
	-- Base
    self.weaponPickupBase = self.targets.pickupBase.GetComponent(ScriptedBehaviour).self
	self.hasLargeGear = false

	-- Data
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Icons
	self.noneIcon = self.data.GetSprite("noneIcon")

	-- Buttons
    self.largeGear = self.targets.largeGear.GetComponent(Button)
    self.gear1 = self.targets.gear1.GetComponent(Button)
    self.gear2 = self.targets.gear2.GetComponent(Button)
    self.gear3 = self.targets.gear3.GetComponent(Button)

	-- UI Icons
    self.largeGearIcon = self.largeGear.transform.GetChild(0).gameObject.GetComponent(Image)
    self.gear1Icon = self.gear1.transform.GetChild(0).gameObject.GetComponent(Image)
    self.gear2Icon = self.gear2.transform.GetChild(0).gameObject.GetComponent(Image)
    self.gear3Icon = self.gear3.transform.GetChild(0).gameObject.GetComponent(Image)

    -- Listeners
    self.largeGear.onClick.AddListener(self, "LargeGearSelected")
    self.gear1.onClick.AddListener(self, "Gear1Selected")
    self.gear2.onClick.AddListener(self, "Gear2Selected")
    self.gear3.onClick.AddListener(self, "Gear3Selected")
end

function WeaponPickupInventory:Update()
	-- Number selection system
	if (Input.GetKeyDown(KeyCode.Alpha3)) then
		self:Gear1Selected()
	elseif (Input.GetKeyDown(KeyCode.Alpha4)) then
		if (self.hasLargeGear) then
			self:LargeGearSelected()
		else
			self:Gear2Selected()
		end
	elseif (Input.GetKeyDown(KeyCode.Alpha5)) then
		self:Gear3Selected()
	elseif (Input.GetKeyDown(KeyCode.Alpha6)) then
        self.weaponPickupBase:ResetHUD()
	end
end

function WeaponPickupInventory:SetupLoadout()
	-- Doing this to prevent strange nil errors 
	self:Start()

	-- Gets the player loadout
    local loadout = Player.actor.weaponSlots

	-- Setup Loadout Icons
    if (loadout[3] ~= nil) then
        local wep = loadout[3].weaponEntry

        if (wep.uiSprite ~= nil) then
            self.gear1Icon.sprite = wep.uiSprite
		else
			self.gear1Icon.sprite = self.noneIcon
        end
	else
		self.gear1Icon.sprite = self.noneIcon
    end

    if (loadout[4] ~= nil) then
		local wep = loadout[4].weaponEntry

		if (wep.slot == WeaponSlot.LargeGear) then
			self.largeGear.gameObject.SetActive(true)
			self.gear2.gameObject.SetActive(false)
			self.gear3.gameObject.SetActive(false)

			if (wep.uiSprite ~= nil) then
				self.largeGearIcon.sprite = wep.uiSprite
			else
				self.largeGearIcon.sprite = self.noneIcon
			end

			self.hasLargeGear = true
		else
			self.largeGear.gameObject.SetActive(false)
			self.gear2.gameObject.SetActive(true)
			self.gear3.gameObject.SetActive(true)

			if (wep.uiSprite ~= nil) then
				self.gear2Icon.sprite = wep.uiSprite
			else
				self.gear2Icon.sprite = self.noneIcon
			end

			self.hasLargeGear = false
		end
	else
		self.gear2Icon.sprite = self.noneIcon
		self.largeGearIcon.sprite = self.noneIcon

		self.largeGear.gameObject.SetActive(false)
		self.gear2.gameObject.SetActive(true)
		self.gear3.gameObject.SetActive(true)

		self.hasLargeGear = false
    end

    if (loadout[5] ~= nil) then
		local wep = loadout[5].weaponEntry

        if (wep.uiSprite ~= nil) then
            self.gear3Icon.sprite = wep.uiSprite
		else
			self.gear3Icon.sprite = self.noneIcon
        end
	else
		self.gear3Icon.sprite = self.noneIcon
    end
end

function WeaponPickupInventory:LargeGearSelected()
    self.weaponPickupBase:DefaultDropGearSelected(3)
end

function WeaponPickupInventory:Gear1Selected()
    self.weaponPickupBase:DefaultDropGearSelected(2)
end

function WeaponPickupInventory:Gear2Selected()
    self.weaponPickupBase:DefaultDropGearSelected(3)
end

function WeaponPickupInventory:Gear3Selected()
    self.weaponPickupBase:DefaultDropGearSelected(4)
end