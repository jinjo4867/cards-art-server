-- Nikke Marian (ID: 99900008)
local s,id=GetID()
function c99900008.initial_effect(c)
	-- 1. On Summon: Search & Discard (Unlimited)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(99900008,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(c99900008.thtg)
	e1:SetOperation(c99900008.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- 2. Sent from Hand/Deck to GY: Excavate
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(99900008,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_DECKDES)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(c99900008.exccon)
	e3:SetTarget(c99900008.exctg)
	e3:SetOperation(c99900008.excop)
	c:RegisterEffect(e3)

	-- 3. GY Banish: Revive (Except Marian)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(99900008,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(c99900008.sptg)
	e4:SetOperation(c99900008.spop)
	c:RegisterEffect(e4)
end

local NIKKE_SET_ID = 0xc02

-- ==================================================================
-- Logic 1: Search & Discard
-- ==================================================================
function c99900008.thfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and not c:IsCode(id) and c:IsAbleToHand()
end

function c99900008.dcfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsDiscardable()
end

function c99900008.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(c99900008.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,LOCATION_HAND)
end

function c99900008.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,c99900008.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 then
			Duel.ConfirmCards(1-tp,g)
			Duel.ShuffleHand(tp)
			Duel.BreakEffect()
			if Duel.IsExistingMatchingCard(c99900008.dcfilter,tp,LOCATION_HAND,0,1,nil) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
				local dg=Duel.SelectMatchingCard(tp,c99900008.dcfilter,tp,LOCATION_HAND,0,1,1,nil)
				Duel.SendtoGrave(dg,REASON_EFFECT+REASON_DISCARD)
			end
		end
	end
end

-- ==================================================================
-- Logic 2: Excavate (Updated Condition)
-- ==================================================================
function c99900008.exccon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- ลบ c:IsReason(REASON_EFFECT)
	return c:IsPreviousLocation(LOCATION_HAND) or c:IsPreviousLocation(LOCATION_DECK)
end

function c99900008.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,LOCATION_DECK)
end

function c99900008.excop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then return end
	Duel.ConfirmDecktop(tp,3)
	local g=Duel.GetDecktopGroup(tp,3)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:FilterSelect(tp,c99900008.thfilter,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
			Duel.ShuffleHand(tp)
		end
	end
	Duel.ShuffleDeck(tp)
end

-- ==================================================================
-- Logic 3: Revive
-- ==================================================================
function c99900008.spfilter(c,e,tp)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsLevelBelow(4) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end

function c99900008.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and c99900008.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(c99900008.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,c99900008.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function c99900008.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
	end
end