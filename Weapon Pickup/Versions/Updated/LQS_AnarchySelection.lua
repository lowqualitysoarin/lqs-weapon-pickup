behaviour("LQS_AnarchySelection")

function LQS_AnarchySelection:Awake()
	-- Base
    self.weaponPickupBase = self.targets.pickupBase.GetComponent(ScriptedBehaviour).self
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

function LQS_AnarchySelection:Update()
	if (GameManager.isPaused) then return end

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

function LQS_AnarchySelection:SetupLoadout()
    -- Gets the player loadout
    local loadout = Player.actor.weaponSlots

    -- Setup Loadout Icons
	self.primaryIcon.sprite = self.noneIcon
    if (loadout[1]) then
        local wep = loadout[1].weaponEntry
        if (wep.uiSprite) then
            self.primaryIcon.sprite = wep.uiSprite
        end
    end

	self.secondaryIcon.sprite = self.noneIcon
    if (loadout[2]) then
        local wep = loadout[2].weaponEntry
        if (wep.uiSprite) then
            self.secondaryIcon.sprite = wep.uiSprite
        end
    end

	self.gear1Icon.sprite = self.noneIcon
    if (loadout[3]) then
        local wep = loadout[3].weaponEntry
        if (wep.uiSprite) then
            self.gear1Icon.sprite = wep.uiSprite
        end
    end

	self.gear2Icon.sprite = self.noneIcon
    if (loadout[4]) then
		local wep = loadout[4].weaponEntry
		if (wep.uiSprite) then
            self.gear2Icon.sprite = wep.uiSprite
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

function LQS_AnarchySelection:PrimarySelected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(0)
end

function LQS_AnarchySelection:SecondarySelected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(1)
end

function LQS_AnarchySelection:Gear1Selected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(2)
end

function LQS_AnarchySelection:Gear2Selected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(3)
end

function LQS_AnarchySelection:Gear3Selected()
    self.weaponPickupBase:AnarchyDropWeaponSelected(4)
end