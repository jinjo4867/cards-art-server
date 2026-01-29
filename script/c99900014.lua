-- Tactical Nikke Vesti (ID: 99900014)
local s,id=GetID()
function c99900014.initial_effect(c)
	c:EnableReviveLimit()
	-- Bypass Fusion Procedure
	
	-- 1. Search + Draw
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 2. Auto Battle Buff
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xc02))
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)
end

function s.thfilter(c)
	return c:IsSetCard(0xc02) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	
	if Duel.GetFlagEffect(tp,99900009)>0 then
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 then
			Duel.ConfirmCards(1-tp,g)
			if Duel.GetFlagEffect(tp,99900009)>0 and Duel.IsPlayerCanDraw(tp,1) then
				Duel.BreakEffect()
				Duel.Draw(tp,1,REASON_EFFECT)
			end
		end
	end
end

-- ฟังก์ชันคำนวณพลัง
function s.atkval(e,c)
	-- 1. ต้องอยู่ในช่วงคำนวณความเสียหาย
	if Duel.GetCurrentPhase()~=PHASE_DAMAGE_CAL then return 0 end
	
	local attacker = Duel.GetAttacker() -- คนสั่งตี
	local bc = c:GetBattleTarget() -- คู่กรณี (ศัตรู)

	-- 2. เช็คเงื่อนไข:
	-- ต้องมีคู่กรณี (bc)
	-- คนสั่งตี (attacker) ต้องเป็นฝ่ายตรงข้าม (1-e:GetHandlerPlayer())
	if bc and attacker and attacker:IsControler(1-e:GetHandlerPlayer()) then
		local val = bc:GetAttack()/2
		if val<0 then return 0 end
		return val
	end
	
	-- ถ้าเราเป็นคนสั่งตี (attacker คือเรา) จะข้ามมาตรงนี้ -> return 0 (ไม่เพิ่มพลัง)
	return 0
end