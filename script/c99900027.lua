-- Burst: Trouble Shooter
-- ID: 99900027
local s,id=GetID()
local SUGAR_ID = 99900023
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	-- [แก้ไข 1] เปลี่ยน Category จาก REMOVE เป็น TODECK
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsFaceup() and c:IsCode(SUGAR_ID)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- เงื่อนไข: ต้องมี "Fixer Nikke Sugar"
	return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- กดใช้ได้เสมอ แม้ไม่มีการ์ดให้เด้ง
	if chk==0 then return true end
	
	-- [แก้ไข 2] เช็คการ์ดที่จะเด้งกลับ Deck (S/T ฝั่งตรงข้าม)
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_SZONE,nil)
	if #g>0 then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
	end
	
	-- Cannot be responded to (Spell Speed 4)
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		Duel.SetChainLimit(s.chainlm)
	end
end

function s.chainlm(e,rp,tp)
	return tp==rp
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- [แก้ไข 3] เปลี่ยนจาก Remove เป็น SendtoDeck (Shuffle)
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_SZONE,nil)
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	
	-- 2. Halve Battle Damage (Both players)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,1)
	e1:SetValue(s.damval)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	-- 3. Nikke Buffs (Indestructible + Double Attack)
	-- ใช้ Field Effect คลุมทั้งกระดาน เพื่อความเสถียร
	
	-- 3.1 Indestructible by battle
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetTargetRange(LOCATION_MZONE,0) 
	e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,NIKKE_SET_ID))
	e2:SetValue(1)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
		
	-- 3.2 Double Attack (Extra Attack)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_EXTRA_ATTACK)
	e3:SetValue(1)
	Duel.RegisterEffect(e3,tp)
	
	-- 4. Attack -> Banish Deck (Global Check)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_ATTACK_ANNOUNCE)
	e4:SetOperation(s.deckbanish)
	e4:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e4,tp)
end

function s.damval(e,re,val,r,rp,rc)
	if (r&REASON_BATTLE)~=0 then
		return val/2
	else
		return val
	end
end

function s.deckbanish(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()
	if tc and tc:IsControler(tp) and tc:IsSetCard(NIKKE_SET_ID) then
		Duel.Hint(HINT_CARD,0,id)
		
		-- Banish top 2 cards
		local g=Duel.GetDecktopGroup(1-tp,2)
		if #g>0 then
			Duel.DisableShuffleCheck()
			Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		end
	end
end