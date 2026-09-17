-- ============================================================
-- SCP Architect X | MAXIMUM CHEAT SCRIPT v4.0
-- Axiom Build | Rayfield v1 | Project Real Executor
-- https://projectreal.gg/
-- ============================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- SERVICES
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- REMOTES
local GF = ReplicatedStorage:FindFirstChild("shared/network@GlobalFunctions")
local GE = ReplicatedStorage:FindFirstChild("shared/network@GlobalEvents")

local function R(name)
    return GF and GF:FindFirstChild(name) or nil
end
local function fire(name, ...)
    local r = R(name)
    if not r then return false, "Remote yok: "..name end
    local ok, err = pcall(function() r:FireServer(...) end)
    return ok, err
end
local function notify(title, content, duration)
    Rayfield:Notify({
        Title    = title,
        Content  = content or "",
        Duration = duration or 4,
        Image    = 4483362458,
    })
end

-- TYCOON
local Tycoons = Workspace:WaitForChild("Tycoons", 5)
local CLASSES = {"Safe","Euclid","Neutralized","Keter","Thaumiel","Classified"}

local function getTycoon(name)  return Tycoons and Tycoons:FindFirstChild(name) end
local function getAllTycoons()  return Tycoons and Tycoons:GetChildren() or {} end
local function getObjects(t)   return t and t:FindFirstChild("Objects") end

local function getLocalTycoon()
    for _, t in ipairs(getAllTycoons()) do
        local a = t:GetAttribute("OwnerId") or t:GetAttribute("Owner")
        if a and tostring(a) == tostring(LP.UserId) then return t end
        local v = t:FindFirstChild("Owner") or t:FindFirstChild("PlayerId") or t:FindFirstChild("PlayerName")
        if v and (tostring(v.Value)==tostring(LP.UserId) or tostring(v.Value)==LP.Name) then return t end
    end
    return nil
end

-- COST DB
local COSTS = {
    Stairs=500,Stairs2=750,Elevator=5000,ElevatorVoid=100,
    SprinklerWall=300,SprinklerCeiling=300,WaterTank457=2000,
    Bed=800,MedicalBed=1500,OfficeChair=200,Desk=400,CubicleDesk=600,
    KitchenBuffetCounter=1200,CoffeeMachine=350,KitchenCounter=600,
    KitchenCabinet=400,KitchenCounterCorner=550,KitchenCounterSink=700,
    Printer=450,WaterDispenser=300,UniformRack=500,
    Barrier3Stud4=150,Barrier3Stud8=250,Barrier3Stud4Angled=200,
    ["Office Bin"]=100,WoodTable=300,RecyclingBin=120,
    ModernSquareTable=350,ModernRectangleTable=450,MeetingTable=800,
    TrussPillar1=200,VerticalPillar=250,VerticalPillarSmall=180,
    LargeFloodlight=600,WallPipeLarge=300,CeilingPipe1=250,CeilingPipe2=280,
    RailingFlat=200,Scaffolding=350,Radiator=280,Cone=80,
    ServerRackSingle=1200,ServerRackStack=2000,
    BarrelCrate2=120,BarrelCrate3=140,BarrelCrate4=160,
    BoxesCrate=200,GunCrateWood=500,PistolCrateWood=350,
    LargeWoodStack=250,LargeConcreteStack=400,PlasticBarrel=100,
    DEFAULT=1000,
}
local function getCost(obj)
    if COSTS[obj.Name] then return COSTS[obj.Name] end
    for k,v in pairs(COSTS) do
        if k~="DEFAULT" and obj.Name:find(k) then return v end
    end
    return COSTS.DEFAULT
end
local function fmt(n)
    local s=tostring(math.floor(n));local r,c="",0
    for i=#s,1,-1 do c=c+1;r=s:sub(i,i)..r
        if c%3==0 and i~=1 then r=","..r end
    end
    return "$"..r
end

-- STATE
local State = {
    copiedBase=nil, copiedCost=0, copiedFrom="none",
    speedOn=false, speedMult=2, noclipOn=false,
    infJumpOn=false, godOn=false, antiAfkOn=false,
    espOn=false, fullbrightOn=false,
    autoLikeOn=false, autoRewardOn=false,
    espFill=Color3.fromRGB(255,50,50),
    espOutline=Color3.fromRGB(255,255,0),
    conns={}, esp={},
    selBase=CLASSES[1], selTele=CLASSES[1], selTycoon=CLASSES[1],
}

-- BASE ENGINE
local function copyBase(t)
    local objs=getObjects(t); if not objs then return nil,0 end
    local primary=t:FindFirstChild("PrimaryPart")
    local bCF=primary and primary.CFrame or CFrame.new(0,0,0)
    local list,total={},0
    for _,obj in ipairs(objs:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local c=getCost(obj); total=total+c
            local rel
            if obj:IsA("Model") and obj.PrimaryPart then rel=bCF:ToObjectSpace(obj.PrimaryPart.CFrame)
            elseif obj:IsA("BasePart") then rel=bCF:ToObjectSpace(obj.CFrame) end
            table.insert(list,{name=obj.Name,relativeCFrame=rel,cost=c})
        end
    end
    return list,total
end

local function pasteBase(list)
    if not list or #list==0 then return false,"Kopyalanmış nesne yok." end
    if not getLocalTycoon() then return false,"Kendi tycoon'un yok." end
    local remote=R("placeObjects") or R("pasteObjects")
    if not remote then return false,"placeObjects remote yok." end
    local payload={}
    for _,d in ipairs(list) do table.insert(payload,{name=d.name,cframe=d.relativeCFrame}) end
    local ok,err=pcall(function() remote:FireServer(payload) end)
    return ok, ok and (#list.." nesne yapıştırıldı.") or tostring(err)
end

-- HACKS
local function applySpeed(on,mult)
    if State.conns.speed then State.conns.speed:Disconnect() end
    if not on then
        local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end end; return
    end
    State.conns.speed=RunService.Heartbeat:Connect(function()
        local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16*mult end end
    end)
end

local function applyNoclip(on)
    if State.conns.noclip then State.conns.noclip:Disconnect() end
    if not on then
        local c=LP.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end; return
    end
    State.conns.noclip=RunService.Stepped:Connect(function()
        local c=LP.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end end end
    end)
end

local function applyInfJump(on)
    if State.conns.jump then State.conns.jump:Disconnect() end
    if not on then return end
    State.conns.jump=UserInputService.JumpRequest:Connect(function()
        local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end)
end

local function applyGod(on)
    if State.conns.god then State.conns.god:Disconnect() end
    if not on then return end
    State.conns.god=RunService.Heartbeat:Connect(function()
        local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.Health=h.MaxHealth end end
    end)
end

local function applyAntiAfk(on)
    if not on then return end
    LP.Idled:Connect(function()
        local vu=game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0,0),Workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0),Workspace.CurrentCamera.CFrame)
    end)
end

local function clearESP()
    for _,h in pairs(State.esp) do if h and h.Parent then h:Destroy() end end
    State.esp={}
end
local function refreshESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local h=p.Character:FindFirstChild("_AxESP")
            if not h then
                h=Instance.new("Highlight"); h.Name="_AxESP"
                h.FillColor=State.espFill; h.OutlineColor=State.espOutline
                h.FillTransparency=0.4; h.OutlineTransparency=0
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent=p.Character; State.esp[p.Name]=h
            else h.FillColor=State.espFill; h.OutlineColor=State.espOutline end
        end
    end
end
local function applyESP(on)
    if State.conns.esp then State.conns.esp:Disconnect() end
    clearESP(); if not on then return end
    refreshESP()
    State.conns.esp=RunService.Heartbeat:Connect(refreshESP)
end

local origL={}
local function applyFullbright(on)
    if on then
        origL.B=Lighting.Brightness; origL.G=Lighting.GlobalShadows; origL.A=Lighting.Ambient
        Lighting.Brightness=5; Lighting.GlobalShadows=false; Lighting.Ambient=Color3.new(1,1,1)
        for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=false end end
    else
        Lighting.Brightness=origL.B or 1; Lighting.GlobalShadows=origL.G~=nil and origL.G or true
        Lighting.Ambient=origL.A or Color3.fromRGB(127,127,127)
        for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=true end end
    end
end

local function teleport(t)
    local c=LP.Character; if not c then return end
    local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
    local primary=t:FindFirstChild("PrimaryPart")
    if primary then root.CFrame=primary.CFrame+Vector3.new(0,6,0); return end
    local maps=t:FindFirstChild("Maps")
    if maps then local ext=maps:FindFirstChild("Exterior"); if ext then root.CFrame=ext.CFrame+Vector3.new(0,6,0) end end
end

local function startAutoLike()
    local function doLike()
        for _,t in ipairs(getAllTycoons()) do
            pcall(function() R("likeViewedBase"):FireServer(t.Name) end)
            task.wait(0.1)
        end
    end
    doLike()
    task.delay(30,function() if State.autoLikeOn then doLike(); startAutoLike() end end)
end

-- ============================================================
-- RAYFIELD WINDOW
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name             = "SCP Architect X | Axiom v4.0",
    LoadingTitle     = "Axiom Cheat Suite",
    LoadingSubtitle  = "Project Real | Full Coverage",
    ConfigurationSaving = { Enabled=true, FolderName="AxiomSCPX", FileName="config" },
    KeySystem        = false,
})

-- ============================================================
-- TAB 1: BASE KOPYALA
-- ============================================================
local BaseTab = Window:CreateTab("Base Kopyala", 4483362458)

BaseTab:CreateSection("Hedef Tycoon")
BaseTab:CreateDropdown({
    Name="Kopyalanacak Tycoon", Options=CLASSES, CurrentOption=CLASSES[1],
    Flag="selBase", Callback=function(v) State.selBase=v end,
})
BaseTab:CreateButton({ Name="Analiz Et & Kopyala", Callback=function()
    local t=getTycoon(State.selBase)
    if not t then notify("Hata",State.selBase.." bulunamadı."); return end
    local list,total=copyBase(t)
    if not list or #list==0 then notify("Bilgi","Objects boş — tycoon'a ışınlan ve bekle.",6); return end
    State.copiedBase=list; State.copiedCost=total; State.copiedFrom=State.selBase
    notify("Kopyalandı!",State.selBase.." → "..#list.." nesne | "..fmt(total),6)
end})
BaseTab:CreateButton({ Name="Kendi Base'ime Yapıştır (Toplu)", Callback=function()
    if not State.copiedBase then notify("Hata","Önce kopyala."); return end
    local ok,msg=pasteBase(State.copiedBase)
    notify(ok and "Yapıştırıldı!" or "Hata",msg,5)
end})
BaseTab:CreateButton({ Name="Tek Tek Yapıştır (Stabil)", Callback=function()
    if not State.copiedBase then notify("Hata","Önce kopyala."); return end
    if not getLocalTycoon() then notify("Hata","Kendi tycoon'un yok."); return end
    local remote=R("placeObjects") or R("pasteObjects")
    if not remote then notify("Hata","Remote yok."); return end
    local s,f=0,0
    for _,d in ipairs(State.copiedBase) do
        local ok=pcall(function() remote:FireServer({{name=d.name,cframe=d.relativeCFrame}}) end)
        if ok then s=s+1 else f=f+1 end
        task.wait(0.05)
    end
    notify("Tek Tek Yapıştır",s.." başarılı | "..f.." başarısız",6)
end})
BaseTab:CreateSection("Maliyet")
BaseTab:CreateButton({ Name="Kopyalanan Maliyeti Göster", Callback=function()
    if not State.copiedBase then notify("Bilgi","Henüz kopyalanmadı."); return end
    notify("Maliyet: "..State.copiedFrom,#State.copiedBase.." nesne | "..fmt(State.copiedCost),6)
end})
BaseTab:CreateSection("Yönetim")
BaseTab:CreateButton({ Name="Base Wipe (wipeBuilds)", Callback=function()
    local ok,err=fire("wipeBuilds"); notify(ok and "Wipe Edildi" or "Hata",ok and "Base temizlendi." or tostring(err))
end})
BaseTab:CreateButton({ Name="Tycoon Recover", Callback=function()
    local ok,err=fire("recoverTycoon"); notify(ok and "Recover Başladı" or "Hata",tostring(err))
end})
BaseTab:CreateButton({ Name="Tycoon Export", Callback=function()
    local myT=getLocalTycoon(); if not myT then notify("Hata","Tycoon yok."); return end
    local ok,err=fire("exportTycoon",myT.Name); notify(ok and "Export Başladı" or "Hata",tostring(err))
end})
BaseTab:CreateButton({ Name="Blueprint Kaydet", Callback=function()
    if not State.copiedBase then notify("Hata","Önce kopyala."); return end
    local ok,err=fire("saveBlueprint",{name="AxiomBP_"..os.time(),objects=State.copiedBase})
    notify(ok and "Blueprint Kaydedildi" or "Hata",tostring(err))
end})

-- ============================================================
-- TAB 2: OYUNCU
-- ============================================================
local PlayerTab = Window:CreateTab("Oyuncu", 4483362458)

PlayerTab:CreateSection("Hareket")
PlayerTab:CreateToggle({ Name="Speed Hack", CurrentValue=false, Flag="speedOn",
    Callback=function(v) State.speedOn=v; applySpeed(v,State.speedMult) end})
PlayerTab:CreateSlider({ Name="Hız Çarpanı", Range={1,25}, Increment=1, CurrentValue=2, Flag="speedMult",
    Callback=function(v) State.speedMult=v; if State.speedOn then applySpeed(true,v) end end})
PlayerTab:CreateToggle({ Name="Noclip", CurrentValue=false, Flag="noclipOn",
    Callback=function(v) State.noclipOn=v; applyNoclip(v) end})
PlayerTab:CreateToggle({ Name="Sonsuz Zıplama", CurrentValue=false, Flag="infJumpOn",
    Callback=function(v) State.infJumpOn=v; applyInfJump(v) end})
PlayerTab:CreateToggle({ Name="Godmode (Client Health Lock)", CurrentValue=false, Flag="godOn",
    Callback=function(v) State.godOn=v; applyGod(v) end})
PlayerTab:CreateToggle({ Name="Anti-AFK", CurrentValue=false, Flag="antiAfkOn",
    Callback=function(v) State.antiAfkOn=v; applyAntiAfk(v) end})
PlayerTab:CreateSection("Işınlanma")
PlayerTab:CreateDropdown({ Name="Tycoon Seç", Options=CLASSES, CurrentOption=CLASSES[1], Flag="selTele",
    Callback=function(v) State.selTele=v end})
PlayerTab:CreateButton({ Name="Seçilen Tycoon'a Işınlan", Callback=function()
    local t=getTycoon(State.selTele)
    if t then teleport(t); notify("Işınlandı",State.selTele,2)
    else notify("Hata","Tycoon bulunamadı.") end
end})
PlayerTab:CreateButton({ Name="Kendi Tycoon'uma Işınlan", Callback=function()
    local myT=getLocalTycoon()
    if myT then teleport(myT); notify("Işınlandı",myT.Name,2)
    else notify("Hata","Kendi tycoon'un yok.") end
end})
PlayerTab:CreateSection("Kamera")
PlayerTab:CreateSlider({ Name="FOV", Range={40,130}, Increment=1, CurrentValue=70, Flag="fov",
    Callback=function(v) Workspace.CurrentCamera.FieldOfView=v end})

-- ============================================================
-- TAB 3: GÖRSEL
-- ============================================================
local VisualTab = Window:CreateTab("Görsel", 4483362458)

VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({ Name="Player ESP", CurrentValue=false, Flag="espOn",
    Callback=function(v) State.espOn=v; applyESP(v) end})
VisualTab:CreateColorPicker({ Name="ESP Dolgu Rengi", Color=Color3.fromRGB(255,50,50), Flag="espFill",
    Callback=function(v) State.espFill=v end})
VisualTab:CreateColorPicker({ Name="ESP Kenar Rengi", Color=Color3.fromRGB(255,255,0), Flag="espOutline",
    Callback=function(v) State.espOutline=v end})
VisualTab:CreateSection("Ortam")
VisualTab:CreateToggle({ Name="Fullbright", CurrentValue=false, Flag="fbOn",
    Callback=function(v) applyFullbright(v) end})
VisualTab:CreateSection("Beğeni Botu")
VisualTab:CreateToggle({ Name="Auto Like (her 30sn)", CurrentValue=false, Flag="autoLikeOn",
    Callback=function(v) State.autoLikeOn=v; if v then startAutoLike() end end})
VisualTab:CreateButton({ Name="Anlık Herkesi Beğen", Callback=function()
    local count=0
    for _,t in ipairs(getAllTycoons()) do
        local ok=pcall(function() R("likeViewedBase"):FireServer(t.Name) end)
        if ok then count=count+1 end; task.wait(0.1)
    end
    notify("Beğenildi",count.." tycoon beğenildi.",4)
end})

-- ============================================================
-- TAB 4: NPC
-- ============================================================
local NPCTab = Window:CreateTab("NPC", 4483362458)

NPCTab:CreateSection("Toplu Kontrol")
NPCTab:CreateButton({ Name="Tüm NPC'leri Kovur", Callback=function()
    local ok,err=fire("fireAllNPCs"); notify(ok and "NPC'ler Kovuldu" or "Hata",ok and "Tüm NPC işten çıktı." or tostring(err))
end})
NPCTab:CreateButton({ Name="Tüm NPC Komutlarını Temizle", Callback=function()
    local ok,err=fire("clearAllNPCCommands"); notify(ok and "Temizlendi" or "Hata",tostring(err))
end})
NPCTab:CreateButton({ Name="NPC Talep Et", Callback=function()
    local r=GE and GE:FindFirstChild("requestNPCs"); if not r then notify("Hata","Remote yok."); return end
    local ok,err=pcall(function() r:FireServer() end); notify(ok and "NPC Talep Edildi" or "Hata",tostring(err))
end})
NPCTab:CreateButton({ Name="NPC Debug", Callback=function()
    local ok,err=fire("debugNPC"); notify(ok and "Debug Atıldı" or "Hata",tostring(err))
end})

-- ============================================================
-- TAB 5: TYCOON
-- ============================================================
local TycoonTab = Window:CreateTab("Tycoon", 4483362458)

TycoonTab:CreateSection("Tycoon Seç")
TycoonTab:CreateDropdown({ Name="Hedef Tycoon", Options=CLASSES, CurrentOption=CLASSES[1], Flag="selTycoon",
    Callback=function(v) State.selTycoon=v end})
TycoonTab:CreateButton({ Name="Tüm Tycoon'ları Tara", Callback=function()
    local lines={}
    for _,t in ipairs(getAllTycoons()) do
        local objs=getObjects(t); local cnt=objs and #objs:GetChildren() or 0
        table.insert(lines,t.Name.." | "..cnt.." nesne")
    end
    notify("Tycoon Tarama",table.concat(lines,"\n"),8)
end})
TycoonTab:CreateButton({ Name="Tycoon Oluştur (Safe)", Callback=function()
    local ok,err=fire("createTycoon","Safe"); notify(ok and "Oluşturuldu" or "Hata",ok and "Safe tycoon oluşturuldu." or tostring(err))
end})
TycoonTab:CreateButton({ Name="Tycoon Yükle", Callback=function()
    local ok,err=fire("loadTycoon",State.selTycoon); notify(ok and "Yüklendi" or "Hata",ok and State.selTycoon.." yüklendi." or tostring(err))
end})
TycoonTab:CreateSection("Simülasyon")
TycoonTab:CreateToggle({ Name="Simülasyonu Durdur", CurrentValue=false, Flag="simPause",
    Callback=function(v)
        fire("setSimulationPaused",v)
        notify(v and "Simülasyon Durdu" or "Simülasyon Devam","setSimulationPaused: "..tostring(v))
    end})
TycoonTab:CreateSection("Co-op")
TycoonTab:CreateButton({ Name="Co-op'tan Ayrıl", Callback=function()
    local ok,err=fire("leaveCoopTycoon"); notify(ok and "Ayrıldı" or "Hata",tostring(err))
end})
TycoonTab:CreateButton({ Name="Tesis Sorunlarını Göster", Callback=function()
    local r=R("getTycoonIssues"); if not r then notify("Hata","Remote yok."); return end
    local conn; conn=r.OnClientEvent:Connect(function(data)
        conn:Disconnect()
        if data then
            local lines={}; for k,v in pairs(data) do table.insert(lines,tostring(k)..": "..tostring(v)) end
            notify("Tycoon Issues",table.concat(lines," | "),8)
        end
    end)
    r:FireServer(State.selTycoon)
end})

-- ============================================================
-- TAB 6: ÖDÜLLER
-- ============================================================
local RewardTab = Window:CreateTab("Ödüller", 4483362458)

RewardTab:CreateSection("Manuel")
RewardTab:CreateButton({ Name="Daily Reward Al", Callback=function()
    local ok,err=fire("claimDailyReward"); notify(ok and "Daily Alındı!" or "Hata",ok and "Claim başarılı." or tostring(err))
end})
RewardTab:CreateButton({ Name="Video Reward Al", Callback=function()
    local ok,err=fire("doVideoReward"); notify(ok and "Video Reward Alındı!" or "Hata",tostring(err))
end})
RewardTab:CreateButton({ Name="Group Reward Al", Callback=function()
    local ok,err=fire("claimGroupReward"); notify(ok and "Group Reward Alındı!" or "Hata",tostring(err))
end})
RewardTab:CreateSection("Otomatik")
RewardTab:CreateToggle({ Name="Auto Daily+Video+Group (60sn)", CurrentValue=false, Flag="autoRewardOn",
    Callback=function(v)
        State.autoRewardOn=v
        if v then
            local function loop()
                if not State.autoRewardOn then return end
                fire("claimDailyReward"); task.wait(1)
                fire("doVideoReward");    task.wait(1)
                fire("claimGroupReward")
                task.delay(60,loop)
            end
            loop()
        end
    end})
RewardTab:CreateSection("Quest")
RewardTab:CreateButton({ Name="Mevcut Quest'i Tamamla", Callback=function()
    local ok,err=fire("completeQuest"); notify(ok and "Quest Tamamlandı!" or "Hata",ok and "XP ve para verildi." or tostring(err))
end})
RewardTab:CreateButton({ Name="Sonraki SCP Quest Başlat", Callback=function()
    local ok,err=fire("startPlaceNextScpQuest"); notify(ok and "Quest Başladı" or "Hata",tostring(err))
end})
RewardTab:CreateSection("Leaderboard")
RewardTab:CreateButton({ Name="Leaderboard Çek", Callback=function()
    local r=R("getLeaderboard"); if not r then notify("Hata","Remote yok."); return end
    local conn; conn=r.OnClientEvent:Connect(function(data)
        conn:Disconnect()
        if data then
            local lines={}
            for i,e in ipairs(data) do
                if i>10 then break end
                table.insert(lines,"#"..i.." | "..(e.name or "?").." | "..(e.score and fmt(e.score) or "?"))
            end
            notify("Leaderboard Top 10",table.concat(lines,"\n"),10)
        end
    end)
    r:FireServer()
end})

-- ============================================================
-- TAB 7: ADMIN / EVENT
-- ============================================================
local AdminTab = Window:CreateTab("Admin/Event", 4483362458)

AdminTab:CreateSection("Facility Events")
AdminTab:CreateButton({ Name="Facility Lockdown", Callback=function()
    local ok,err=fire("triggerFacilityLockdown"); notify(ok and "LOCKDOWN BAŞLADI!" or "Hata",ok and "Tesis kilitlendi." or tostring(err))
end})
AdminTab:CreateButton({ Name="Alarmları Aç", Callback=function()
    local ok,err=fire("setFacilityAlarms",true); notify(ok and "Alarmlar Açıldı" or "Hata",tostring(err))
end})
AdminTab:CreateButton({ Name="Alarmları Kapat", Callback=function()
    local ok,err=fire("setFacilityAlarms",false); notify(ok and "Alarmlar Kapatıldı" or "Hata",tostring(err))
end})
AdminTab:CreateButton({ Name="Breach Tetikle", Callback=function()
    local ok,err=fire("adminTriggerBreach"); notify(ok and "BREACH BAŞLADI!" or "Hata",ok and "SCP breach aktif." or tostring(err))
end})
AdminTab:CreateButton({ Name="Riot Tetikle", Callback=function()
    local ok,err=fire("adminTriggerRiot"); notify(ok and "RIOT BAŞLADI!" or "Hata",ok and "Riot event aktif." or tostring(err))
end})
AdminTab:CreateButton({ Name="Bomba Aktifleştir", Callback=function()
    local ok,err=fire("activateBomb"); notify(ok and "Bomba Aktif!" or "Hata",tostring(err))
end})
AdminTab:CreateSection("RP Admin")
AdminTab:CreateButton({ Name="RP Breach Başlat", Callback=function()
    local ok,err=fire("rpAdminStartBreach"); notify(ok and "RP Breach Başladı" or "Hata",tostring(err))
end})
AdminTab:CreateButton({ Name="RP Breach Durdur", Callback=function()
    local ok,err=fire("rpAdminStopBreach"); notify(ok and "RP Breach Durdu" or "Hata",tostring(err))
end})
AdminTab:CreateButton({ Name="RP Sunucu Restart", Callback=function()
    local ok,err=fire("rpAdminRestart"); notify(ok and "RP Restart" or "Hata",tostring(err))
end})
AdminTab:CreateButton({ Name="Admin Para Ekle", Callback=function()
    local ok,err=fire("adminAddMoney",999999)
    notify(ok and "Para Eklendi" or "Admin Yetki Gerekli",ok and fmt(999999).." eklendi." or tostring(err))
end})

-- ============================================================
-- TAB 8: ÇEŞİTLİ
-- ============================================================
local MiscTab = Window:CreateTab("Çeşitli", 4483362458)

MiscTab:CreateSection("Genel")
MiscTab:CreateButton({ Name="Tüm Bildirimleri Kapat", Callback=function()
    local ok,err=fire("dismissAllNotifications"); notify(ok and "Bildirimler Kapatıldı" or "Hata",tostring(err))
end})
MiscTab:CreateButton({ Name="Para Çarpanı Göster", Callback=function()
    local r=R("getMoneyMultiplier"); if not r then notify("Hata","Remote yok."); return end
    local conn; conn=r.OnClientEvent:Connect(function(data)
        conn:Disconnect(); notify("Para Çarpanı","x"..tostring(data),5)
    end)
    r:FireServer()
end})
MiscTab:CreateButton({ Name="Tutorial Yeniden Başlat", Callback=function()
    local ok,err=fire("restartTutorial"); notify(ok and "Tutorial Başladı" or "Hata",tostring(err))
end})
MiscTab:CreateButton({ Name="Ayarları Sıfırla", Callback=function()
    local ok,err=fire("resetSettings"); notify(ok and "Ayarlar Sıfırlandı" or "Hata",tostring(err))
end})
MiscTab:CreateSection("Proxy View")
MiscTab:CreateButton({ Name="Proxy View İste", Callback=function()
    local ok,err=fire("requestProxyView",State.selTycoon); notify(ok and "Proxy View Aktif" or "Hata",tostring(err))
end})
MiscTab:CreateButton({ Name="Proxy View'dan Çık", Callback=function()
    local ok,err=fire("requestExitProxyView"); notify(ok and "Çıkıldı" or "Hata",tostring(err))
end})
MiscTab:CreateSection("Nesne")
MiscTab:CreateButton({ Name="Tüm Nesneleri Sil (deleteObjects)", Callback=function()
    local ok,err=fire("deleteObjects"); notify(ok and "Nesneler Silindi" or "Hata",tostring(err))
end})
MiscTab:CreateButton({ Name="Nesneleri Gizle/Göster", Callback=function()
    local ok,err=fire("setObjectsEnabled",State.selTycoon,false); notify(ok and "Nesneler Gizlendi" or "Hata",tostring(err))
end})

-- INIT
Rayfield:Notify({
    Title   = "SCP Architect X | Axiom v4.0",
    Content = "Yüklendi. "..#getAllTycoons().." tycoon aktif. RightShift → menü kapat.",
    Duration = 6,
    Image   = 4483362458,
})
