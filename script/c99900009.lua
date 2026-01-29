-- Nikke TACTICAL!
-- ID: 99900009
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Activate Effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsCode(id) and c:IsSSetable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft = Duel.GetLocationCount(tp,LOCATION_SZONE)
	if e:GetHandler():IsLocation(LOCATION_HAND) then
		ft = ft - 1
	end

	local b1 = Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) 
		and ft >= 1
	
	local b2 = Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,2,nil) 
		and ft >= 2
		and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler())

	if chk==0 then return b1 or b2 end

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp, aux.Stringid(id,1), aux.Stringid(id,2))
	elseif b1 then
		op=Duel.SelectOption(tp, aux.Stringid(id,1))
	else
		op=Duel.SelectOption(tp, aux.Stringid(id,2)) + 1
	end
	
	if not b1 and b2 then op = 1 end
	
	e:SetLabel(op)
	
	if op==1 then
		Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST+REASON_DISCARD, nil)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)

	local g=nil
	local ct=0

	if op==0 then
		g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
		ct=1
	else
		g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
		ct=2
	end
	
	if #g < ct then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE) < ct then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local sg=g:Select(tp,ct,ct,nil)
	if #sg>0 then
		
		-- [แก้ไข] ย้าย ConfirmCards มาตรงนี้ (โชว์ก่อน Set)
		-- ทำให้การ์ดถูกโชว์ตั้งแต่ตอนอยู่ใน Deck หน้าต่างจะเด้งขึ้นมาชัดเจน
		-- แล้วพอ Set ลงสนาม ก็จะคว่ำลงไปสวยๆ ไม่ต้องพลิกขึ้นมาอีก
		if op==1 then
			Duel.ConfirmCards(1-tp,sg)
		end
		
		-- ทำการ Set การ์ด (คว่ำลงสนาม)
		Duel.SSet(tp,sg)
		
		if op==1 then
			local tc=sg:GetFirst()
			for tc in aux.Next(sg) do
				if tc:IsType(TYPE_TRAP) then
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
					e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
				end
			end
			-- ลบ ConfirmCards ตรงนี้ออกไปแล้ว เพราะเราโชว์ไปแล้วข้างบน
		end
	end
end