
-- Usage: set Username to the target player name (partial match, case-insensitive)
Username = ''
--[[ has auto complete btw
     i love mini scripts
    exactly 1k characters ]]
P=game:GetService"Players"R=game:GetService"ReplicatedStorage"Username=Username:lower()for a,b in ipairs(P:GetPlayers())do if b.Name:lower():sub(1,#Username)==Username then T=b;break end end;if not T then error("No player found matching: "..Username)end;Username=T.Name;print("Matched player:",Username)H=T.Character and T.Character:FindFirstChildOfClass"Humanoid"if not H then error"Target player has no Humanoid."end;HP=R:WaitForChild"Honeypot"U=require(HP)("HumanoidDescriptionUtility")O=U.GetCharacterOutfitInformationFromRigTypeAndHumanoidDescription(H.RigType,H:GetAppliedDescription())S=HP.Internal.RemoteStorage;S["EquipOutfit - RemoteEvent"]:FireServer(O)S["PublishOutfit - RemoteFunction"]:InvokeServer{SerializedDescription=O.SerializedDescription,RigType=O.RigType,IsPublic=false,ContestEntry=false,OutfitName="Wow you saved "..Username,CommentsEnabled=true,AnimationsEnabled=true}print"saved too"