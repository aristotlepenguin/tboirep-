function TutorialMod:RenderLineOne()
    Isaac.RenderText("try to conole: spawn frozen...", 100, 100, 1, 1, 1, 1)
end

TutorialMod:AddCallback(ModCallbacks.MC_POST_RENDER, TutorialMod.RenderLineOne)