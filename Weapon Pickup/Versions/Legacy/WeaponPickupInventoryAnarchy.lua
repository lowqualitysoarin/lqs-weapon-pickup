behaviour("WeaponPickupInventoryAnarchy")

function WeaponPickupInventoryAnarchy:Start()
	-- Base
    self.weaponPickupBase = self.targets.pickupBase.GetComponent(ScriptedBehaviour).self

    -- Data
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Icons
	self.noneIcon = self.data.GetSprite("noneIcon")

    -- Buttons
    self.primaryButton = self.targets.primary.GetComponent(Button)
    self.secondaryButton = self.targets.secondary.GetComponent(Button)
    self.gear1 = self.targets.gear1.GetComponent(Button)
    self.gear2 = self.targets.gear2.GetComponent(Button)
    self.gear3 = self.targets.gear3.GetComponent(Button)

    -- UI Icons
    self.primaryIcon = self.primaryButton.transform.GetChild(0).gameObject.GetComponent(Image)
    self.secondaryIcon = self.secondaryButton.transform.GetChild(0).gameObject.GetComponent(Image)
    self.gear1Icon = self.gear1.transform.GetChild(0).gameObject.GetComponent(Image)
    self.gear2Icon = self.gear2.transform.GetChild(0).gameObject.GetComponent(Image)
    self.gear3Icon = self.gear3.transform.GetChild(0).gameObject.GetComponent(Image)

    -- Listeners
    self.primaryButton.onClick.AddListener(self, "PrimarySelected")
    self.secondaryButton.onClick.AddListener(self, "SecondarySelected")
    self.gear1.onClick.AddListener(self, "Gear1Selected")
    self.gear2.onClick.AddListener(self, "Gear2Selected")
    self.gear3.onClick.AddListener(self, "Gear3Selected")
end

function WeaponPickupInventoryAnarchy:Update()
	-- Number selection system
    if (Input.GetKeyDown(KeyCode.Alpha1)) then
        self:PrimarySelected()
    elseif (Input.GetKeyDown(KeyCode.Alpha2)) then
        self:SecondarySelected()
    elseif (Input.GetKeyDown(KeyCode.Alpha3)) then
		self:Gear1Selected()
	elseif (Input.GetKeyDown(KeyCode.Alpha4)) then
		self:Gear2Selected()
	elseif (Input.GetKeyDown(KeyCode.Alpha5)) then
		self:Gear3Selected()
    elseif (Input.GetKeyDown(KeyCode.Alpha6)) then
        self.weaponPickupBase:ResetHUD()
	end
end

function WeaponPickupInventoryAnarchy:SetupLoadout()
    -- Doing this to prevent strange nil errors 
	self:Start()

    -- Gets the player loadout
    local loadout = Player.actor.weaponSlots

    -- Setup Loadout Icons
    if (loadout[1] ~= nil) then
        local wep = loadout[1].weaponEntry

        if (wep.uiSprite ~= nil) then
            self.primaryIcon.sprite = wep.uiSprite
        else
			self.primaryIcon.sprite = self.noneIcon
        end
    else
        self.primaryIcon.sprite = self.noneIcon
    end

    if (loadout[2] ~= nil) then
        local wep = loadout[2].weaponEntry

        if (wep.uiSprite ~= nil) then
            self.secondaryIcon.sprite = wep.uiSprite
        else
			self.secondaryIcon.sprite = self.noneIcon
        end
    else
        self.secondaryIcon.sprite = self.noneIcon
    end

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

		if (wep.uiSprite ~= nil) then
            self.gear2Icon.sprite = wep.uiSprite
        else
            self.gear2Icon.sprite = self.noneIcon
        end
	else
		self.gear2Icon.sprite = self.noneIcon
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

function WeaponPickupInventoryAnarchy:PrimarySelected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(0)
end

function WeaponPickupInventoryAnarchy:SecondarySelected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(1)
end

function WeaponPickupInventoryAnarchy:Gear1Selected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(2)
end

function WeaponPickupInventoryAnarchy:Gear2Selected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(3)
end

function WeaponPickupInventoryAnarchy:Gear3Selected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(4)
end