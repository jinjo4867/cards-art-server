-- Nikke ENCOUNTER! (ID: 99900003)
local s,id=GetID()
function c99900003.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ==================================================================
	-- 1. Protection Suite (5 พรคุ้มกันช่วง Battle Phase)
	-- ==================================================================
	
	-- 1.1 กันทำลายจากเอฟเฟค (Indestructible by Effect)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(c99900003.prot_tg)
	e1:SetCondition(c99900003.prot_con)
	e1:SetValue(c99900003.ind_val)
	c:RegisterEffect(e1)

	-- 1.2 กัน Banish (Cannot be Banished)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_REMOVE)
	e2:SetValue(c99900003.limit_val)
	c:RegisterEffect(e2)

	-- 1.3 กันเด้งขึ้นมือ (Cannot return to Hand)
	local e3=e1:Clone()
	e3:SetCode(EFFECT_CANNOT_TO_HAND)
	e3:SetValue(c99900003.limit_val)
	c:RegisterEffect(e3)

	-- 1.4 กันเด้งเข้ากอง (Cannot return to Deck)
	local e4=e1:Clone()
	e4:SetCode(EFFECT_CANNOT_TO_DECK)
	e4:SetValue(c99900003.limit_val)
	c:RegisterEffect(e4)

	-- 1.5 กันแย่งการควบคุม (Cannot Change Control)
	local e5=e1:Clone()
	e5:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	-- อันนี้ไม่ต้องมี Value แค่ Active ก็กันได้เลย
	c:RegisterEffect(e5)

	-- ==================================================================
	-- ส่วนเอฟเฟคเดิม (Debuff / Buff / Retrieve)
	-- ==================================================================

	-- 2. ATK Debuff
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_UPDATE_ATTACK)
	e6:SetRange(LOCATION_SZONE)
	e6:SetTargetRange(0,LOCATION_MZONE)
	e6:SetCondition(c99900003.debuffcon)
	e6:SetValue(-500)
	c:RegisterEffect(e6)

	-- 3. Send to GY -> Buff
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(99900003,0))
	e7:SetCategory(CATEGORY_ATKCHANGE)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_SZONE)
	e7:SetCost(c99900003.atkcost)
	e7:SetOperation(c99900003.atkop)
	c:RegisterEffect(e7)

	-- 4. GY Banish -> Retrieve
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(99900003,1))
	e8:SetCategory(CATEGORY_TOHAND)
	e8:SetType(EFFECT_TYPE_IGNITION)
	e8:SetRange(LOCATION_GRAVE)
	e8:SetCost(aux.bfgcost)
	e8:SetTarget(c99900003.thtg)
	e8:SetOperation(c99900003.thop)
	c:RegisterEffect(e8)
end

local NIKKE_SET_ID = 0xc02

-- ==================================================================
-- Logic 1: Protection (ช่วง Battle Phase เท่านั้น)
-- ==================================================================

-- เงื่อนไข: เฉพาะช่วง Battle Phase
function c99900003.prot_con(e)
	local ph=Duel.GetCurrentPhase()
	return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

-- เป้าหมาย: เฉพาะมอนสเตอร์ Nikke (0xc02)
function c99900003.prot_tg(e,c)
	return c:IsSetCard(NIKKE_SET_ID)
end

-- Value สำหรับกันทำลาย: ต้องเป็นเอฟเฟคของคู่แข่ง (1-tp) เท่านั้น
function c99900003.ind_val(e,re,rp)
	return rp==1-e:GetHandlerPlayer()
end

-- Value สำหรับกัน Banish/Bounce: คืนค่าเป็น Player ID ของคู่แข่ง (แปลว่า "คู่แข่งห้ามทำ")
function c99900003.limit_val(e,re,rp)
	return 1-e:GetHandlerPlayer()
end

-- ==================================================================
-- Logic 2: Debuff
-- ==================================================================
function c99900003.debuffcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(c99900003.check_high_atk,tp,0,LOCATION_MZONE,1,nil,tp)
end

function c99900003.check_high_atk(c,tp)
	local atk=c:GetAttack()
	return c:IsFaceup() and Duel.IsExistingMatchingCard(c99900003.check_low_atk,tp,LOCATION_MZONE,0,1,nil,atk)
end

function c99900003.check_low_atk(c,limit_atk)
	return c:IsFaceup() and c:GetAttack() < limit_atk
end

-- ==================================================================
-- Logic 3: Buff
-- ==================================================================
function c99900003.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

function c99900003.faceup_nikke_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end

function c99900003.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(c99900003.faceup_nikke_filter,tp,LOCATION_MZONE,0,nil)
	local tc=g:GetFirst()
	while tc do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		tc=g:GetNext()
	end
end

-- ==================================================================
-- Logic 4: Retrieve
-- ==================================================================
function c99900003.thfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsAbleToHand()
end

function c99900003.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and c99900003.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(c99900003.thfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,c99900003.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function c99900003.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end