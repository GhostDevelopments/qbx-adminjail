Config = {}

-- Groups with access (uses QBox permission system, set in server.cfg with add_principal group.admin qbx.admin etc.)
Config.AllowedGroups = {'admin', 'god'}

-- Command names (configurable for language or preference)
Config.Commands = {
    jail = 'adminjail',
    release = 'adminjailrelease',
    time = 'adminjailtime',
    list = 'adminjaillist',
    menu = 'adminjailmenu'
}

-- Locations
Config.JailLocation = vector4(1642.28, 2570.56, 45.56, 98.47)  -- Example jail coords (inside prison cell)
Config.ReleaseLocation = vector4(-440.9, 6008.58, 31.72, 90.0)  -- Example release coords (Paleto Bay)

-- Controls to disable while jailed (prevents movement/attacks)
Config.DisableControls = {
    24,  -- INPUT_ATTACK
    25,  -- INPUT_AIM
    140, -- INPUT_MELEE_ATTACK_LIGHT
    141, -- INPUT_MELEE_ATTACK_HEAVY
    142, -- INPUT_MELEE_ATTACK_ALTERNATE
    257, -- INPUT_ATTACK2
    263, -- INPUT_MELEE_ATTACK1
    264  -- INPUT_MELEE_ATTACK2
}

-- Discord webhook for logging
Config.Webhook = ''  -- Paste your Discord webhook URL here

-- Optional routing buckets (isolates player in a separate instance)
Config.UseBuckets = true
Config.BucketId = 100  -- Unique bucket ID for jail

-- Language strings (configurable)
Config.Language = {
    jailed = 'You have been jailed for %s minutes. Reason: %s',
    released = 'You have been released from jail.',
    timeleft = 'You have %s minutes left in jail.',
    notjailed = 'You are not jailed.',
    noonejailed = 'No one is currently admin-jailed.',
    listheader = 'Admin-Jailed Players:',
    listitem = '- %s (ID: %s, CitizenID: %s) - Time left: %s minutes - Reason: %s',
}