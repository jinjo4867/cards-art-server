-- Fixer Nikke Frima
-- ID: 99900025
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Synchro Summon Procedure
	c:EnableReviveLimit()
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(s.matfilter),1,99)

	-- 1. Flip Face-down (Ignition)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.postg)
	e1:SetOperation(s.posop)
	c:RegisterEffect(e1)

	-- 2. Floodgate: Negate effects of Defense Position monsters (Skill Drain Logic)
	-- ส่วนที่ 1: Disable Effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetTarget(s.distg)
	c:RegisterEffect(e2)
	-- ส่วนที่ 2: Disable Activated Effect
	local e3=e2:Clone()
	e3:SetCode(EFFECT_DISABLE_EFFECT)
	c:RegisterEffect(e3)

	-- 3. Tax: Pay 300 LP to Attack
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_ATTACK_COST)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetTargetRange(0,1) -- ฝ่ายตรงข้ามเท่านั้น
	e4:SetCost(s.taxcost)
	e4:SetOperation(s.taxop)
	c:RegisterEffect(e4)

	-- 4. Tax: Pay 300 LP to Activate Effects
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_ACTIVATE_COST)
	e5:SetRange(LOCATION_MZONE)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetTargetRange(0,1) -- ฝ่ายตรงข้ามเท่านั้น
	e5:SetCost(s.taxcost)
	e5:SetOperation(s.taxop)
	c:RegisterEffect(e5)
end

-- =======================================================================
-- [Synchro Material Filter]
-- =======================================================================
function s.matfilter(c)
	return c:IsSetCard(NIKKE_SET_ID)
end

-- =======================================================================
-- [Effect 1] Flip Face-down Logic
-- =======================================================================
function s.nikkefilter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end

function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ct=Duel.GetMatchingGroupCount(s.nikkefilter,tp,LOCATION_MZONE,0,nil)
		return ct>0 and Duel.IsExistingMatchingCard(Card.IsCanTurnSet,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_POSITION,nil,1,1-tp,LOCATION_MZONE)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.nikkefilter,tp,LOCATION_MZONE,0,nil)
	if ct==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local g=Duel.SelectMatchingCard(tp,Card.IsCanTurnSet,tp,0,LOCATION_MZONE,1,ct,nil)
	
	if #g>0 then
		Duel.HintSelection(g)
		if Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)>0 then
			local og=Duel.GetOperatedGroup()
			for tc in aux.Next(og) do
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
	end
end

-- =======================================================================
-- [Effect 2] Skill Drain Logic for Defense Monsters
-- =======================================================================
function s.distg(e,c)
	return c:IsPosition(POS_DEFENSE)
end

-- =======================================================================
-- [Effect 3 & 4] Tax System (Modified to 300)
-- =======================================================================
function s.taxcost(e,te,tp)
	return Duel.CheckLPCost(tp,300) -- เช็คว่ามี 300 ไหม
end
function s.taxop(e,tp,eg,ep,ev,re,r,rp)
	Duel.PayLPCost(tp,300) -- จ่าย 300
end