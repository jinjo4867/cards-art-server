-- Nikke Neon (ID: 99900002)
local s,id=GetID()
function c99900002.initial_effect(c)
	-- 1. Special Summon Self + Send to GY (HOPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(99900002,0)) 
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(c99900002.spcon_main)
	e1:SetTarget(c99900002.sptg_main)
	e1:SetOperation(c99900002.spop_main)
	c:RegisterEffect(e1)

	-- 2. On Summon (with Encounter) -> SS from Deck (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(99900002,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	-- ใช้ id+100 เพื่อไม่ให้ชน
	e2:SetCountLimit(1,id+100) 
	e2:SetCondition(c99900002.spcon_deck)
	e2:SetTarget(c99900002.sptg_deck)
	e2:SetOperation(c99900002.spop_deck)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

local NIKKE_SET_ID = 0xc02	   
local ENCOUNTER_CARD_ID = 99900003 

-- ==================================================================
-- Filters
-- ==================================================================
function c99900002.faceup_nikke_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end

function c99900002.faceup_encounter_filter(c)
	return c:IsFaceup() and c:IsCode(ENCOUNTER_CARD_ID)
end

-- ==================================================================
-- Logic 1: SS Self & Foolish Burial
-- ==================================================================
function c99900002.spcon_main(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(c99900002.faceup_nikke_filter,tp,LOCATION_MZONE,0,1,nil)
end

function c99900002.tgfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsAbleToGrave()
end

function c99900002.sptg_main(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(c99900002.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function c99900002.spop_main(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,c99900002.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.BreakEffect()
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end

-- ==================================================================
-- Logic 2: SS from Deck (Condition: Control Encounter)
-- ==================================================================
function c99900002.spcon_deck(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(c99900002.faceup_encounter_filter,tp,LOCATION_ONFIELD,0,1,nil)
end

function c99900002.spfilter_deck(c,e,tp)
	-- ใช้ <= 1500 
	return c:IsSetCard(NIKKE_SET_ID) and c:GetAttack()<=1500 and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function c99900002.sptg_deck(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(c99900002.spfilter_deck,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function c99900002.spop_deck(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,c99900002.spfilter_deck,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end