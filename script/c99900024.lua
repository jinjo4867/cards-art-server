-- Fixer Nikke Milk
-- ID: 99900024
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Synchro Summon Procedure
	c:EnableReviveLimit()
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(s.matfilter),1,99)

	-- 1. Cannot be destroyed by battle (Immortal)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 2. Battle Removal + Hand Shuffle / Extra Banish
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	-- อัปเดต Category ให้ครอบคลุมทั้ง Remove และ ToDeck
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) 
	e2:SetCode(EVENT_BATTLED) 
	e2:SetCondition(s.batcon)
	e2:SetTarget(s.battg)
	e2:SetOperation(s.batop)
	c:RegisterEffect(e2)
end

function s.matfilter(c)
	return c:IsSetCard(NIKKE_SET_ID)
end

-- =======================================================================
-- [Effect 2] Logic: Banish Monster -> Check Hand -> Hand Shuffle OR Extra Banish
-- =======================================================================
function s.batcon(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	return bc and bc:IsControler(1-tp)
end

function s.battg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- Trigger Forced (ทำงานเสมอ)
	
	local bc=e:GetHandler():GetBattleTarget()
	if bc then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,bc,1,0,0)
	end
	-- แจ้งระบบว่าอาจจะมีการเด้งเข้าเด็ค หรือ รีมูฟ
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,1-tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,0,1-tp,LOCATION_EXTRA)
end

function s.batop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	
	-- 1. จัดการมอนสเตอร์คู่กรณี (Banish)
	if bc then
		if Duel.Remove(bc,POS_FACEUP,REASON_EFFECT)>0 then
			
			-- 2. เช็คการ์ดบนมือฝ่ายตรงข้าม
			local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
			
			if #hg>0 then
				-- [กรณี A] มีการ์ดบนมือ -> สุ่มสับเข้าเด็ค 1 ใบ
				Duel.BreakEffect()
				-- สุ่มเลือก 1 ใบ
				local sg=hg:RandomSelect(tp,1)
				-- ส่งเข้าเด็คแบบสับ (Shuffle)
				Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
				
			else
				-- [กรณี B] มือโล่ง -> สุ่มรีมูฟ Extra Deck 1 ใบ
				local eg=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
				if #eg>0 then
					Duel.BreakEffect()
					-- สุ่มเลือก 1 ใบจาก Extra Deck
					local sg=eg:RandomSelect(tp,1)
					-- รีมูฟ (Face-up)
					Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
				end
			end
		end
	end
end