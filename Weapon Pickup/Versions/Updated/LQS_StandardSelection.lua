behaviour("LQS_StandardSelection")

function LQS_StandardSelection:Awake()
	-- Putting this on awake to prevent nil errors
	-- Base
    self.weaponPickupBase = self.targets.pickupBase.GetComponent(ScriptedBehaviour).self
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

	-- Vars
	self.hasLargeGear = false
end

function LQS_StandardSelection:Update()
	if (GameManager.isPaused) then return end

	-- Number selection system
	if (Input.GetKeyDown(KeyCode.Alpha3)) then
		self:Gear1Selected()
	elseif (Input.GetKeyDown(KeyCode.Alpha4)) then
		if (self.hasLargeGear) then
			self:LargeGearSelected()
		else
			self:Gear2Selected()
		end
	elseif (Input.GetKeyDown(KeyCode.Alpha5) and not self.hasLargeGear) then
		self:Gear3Selected()
	elseif (Input.GetKeyDown(KeyCode.Alpha6)) then
        self.weaponPickupBase:ResetHUD()
	end
end

function LQS_StandardSelection:SetupLoadout()
	-- Gets the player loadout
    local loadout = Player.actor.weaponSlots
	self.hasLargeGear = false

	-- Setup Loadout Icons
	self.gear1Icon.sprite = self.noneIcon
    if (loadout[3]) then
		local wep = loadout[3].weaponEntry
        if (wep.uiSprite) then
            self.gear1Icon.sprite = wep.uiSprite
        end
    end

	self.largeGear.gameObject.SetActive(false)
	self.gear2.gameObject.SetActive(true)
	self.gear3.gameObject.SetActive(true)

	self.gear2Icon.sprite = self.noneIcon
    if (loadout[4]) then
		local wep = loadout[4].weaponEntry
		if (wep.uiSprite) then
			self.gear2Icon.sprite = wep.uiSprite
		end

		if (wep.slot == WeaponSlot.LargeGear) then
			self.largeGear.gameObject.SetActive(true)
			self.gear2.gameObject.SetActive(false)
			self.gear3.gameObject.SetActive(false)

			self.largeGearIcon.sprite = self.noneIcon
			if (wep.uiSprite) then
				self.largeGearIcon.sprite = wep.uiSprite
			end

			self.hasLargeGear = true
		end
    end

	self.gear3Icon.sprite = self.noneIcon
    if (loadout[5]) then
		local wep = loadout[5].weaponEntry
        if (wep.uiSprite) then
            self.gear3Icon.sprite = wep.uiSprite
        end
    end
end

function LQS_StandardSelection:LargeGearSelected()
    self.weaponPickupBase:DefaultDropGearSelected(3)
end

function LQS_StandardSelection:Gear1Selected()
    self.weaponPickupBase:DefaultDropGearSelected(2)
end

function LQS_StandardSelection:Gear2Selected()
    self.weaponPickupBase:DefaultDropGearSelected(3)
end

function LQS_StandardSelection:Gear3Selected()
    self.weaponPickupBase:DefaultDropGearSelected(4)
end