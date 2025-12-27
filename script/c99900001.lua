-- Nikke Anis (ID: 99900001)
local s,id=GetID()
function c99900001.initial_effect(c)
	-- 1. Search Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(99900001,0)) 
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(c99900001.thtg)
	e1:SetOperation(c99900001.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- 2. Special Summon (Encounter) - แก้ไขตรงนี้
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(99900001,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_HAND)
	-- ใส่ id เพื่อล็อกชื่อการ์ด
	e3:SetCountLimit(1, id) 
	e3:SetCondition(c99900001.spcon_encounter)
	e3:SetTarget(c99900001.sptg)
	e3:SetOperation(c99900001.spop)
	c:RegisterEffect(e3)
end

local NIKKE_SET_ID = 0xc02	   
local ENCOUNTER_CARD_ID = 99900003 

-- ==================================================================
-- Filters
-- ==================================================================
function c99900001.faceup_encounter_filter(c)
	return c:IsFaceup() and c:IsCode(ENCOUNTER_CARD_ID)
end

-- ==================================================================
-- Logic
-- ==================================================================
function c99900001.thfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function c99900001.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(c99900001.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function c99900001.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,c99900001.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

function c99900001.spcon_encounter(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(c99900001.faceup_encounter_filter,tp,LOCATION_ONFIELD,0,1,nil)
end

function c99900001.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function c99900001.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end