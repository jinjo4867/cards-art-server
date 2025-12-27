-- Tactical Nikke Eunhwa (ID: 99900013)
local s,id=GetID()
function c99900013.initial_effect(c)
	c:EnableReviveLimit()
	-- Bypass Fusion Procedure
	
	-- 1. On Summon: Send Highest Stat to GY + Burn (Max of ATK/DEF)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)

	-- 2. Sniper Zone (Continuous Negate)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING) -- ทำงานตอนเอฟเฟคกำลังจะออกผล
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.negcon)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- Logic 1: Send Highest Stat
function s.tgfilter(c)
	return c:IsFaceup() and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_MZONE)
	if Duel.GetFlagEffect(tp,99900009)>0 then
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0) 
	end
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end
	local max_stat = 0
	for tc in aux.Next(g) do
		local val = math.max(tc:GetAttack(), tc:GetDefense())
		if val > max_stat then max_stat = val end
	end
	local sg = g:Filter(function(c) return math.max(c:GetAttack(), c:GetDefense()) == max_stat end, nil)
	if #sg>0 then
		local tc = sg:Select(tp,1,1,nil):GetFirst()
		local val = math.max(tc:GetAttack(), tc:GetDefense())
		if Duel.SendtoGrave(tc,REASON_EFFECT)~=0 and Duel.GetFlagEffect(tp,99900009)>0 then
			if val > 0 then
				Duel.Damage(1-tp,val/2,REASON_EFFECT)
			end
		end
	end
end

-- Logic 2: Continuous Negate
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local loc=re:GetActivateLocation()
	-- เช็คแค่ว่า: คู่แข่งใช้ + มาจากมือ/สุสาน + เป็นเอฟเฟคมอนสเตอร์/เวท/กับดัก
	-- เอา IsChainNegatable ออก หยุด Effect โดยตรง
	return rp==1-tp 
		and (loc==LOCATION_HAND or loc==LOCATION_GRAVE)
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) -- กันกรณี Eunhwa ตายแล้ว
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToGrave,1-tp,LOCATION_ONFIELD,0,nil)
	
	local paid = false
	if #g>0 then
		if Duel.SelectYesNo(1-tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TOGRAVE)
			local sg=g:Select(1-tp,1,1,nil)
			if #sg>0 then
				Duel.SendtoGrave(sg,REASON_EFFECT)
				paid = true
			end
		end
	end
	
	if not paid then
		Duel.Hint(HINT_CARD,0,id)
		-- ใช้ NegateEffect
		Duel.NegateEffect(ev) 
	end
end