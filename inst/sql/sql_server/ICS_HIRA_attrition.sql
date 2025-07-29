WITH Codesets as (
SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (317009,4235703,4279553)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (317009,4235703,4279553)
  and c.invalid_reason is null

) I
) C UNION ALL 
SELECT 2 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (42483138,36812530,36421291,40745353,36787954,21158944,36894458,21090035,42480194,36883710,35130061,42479684,35133500,783228,36787269,43291282,35135829,44120754,36894464,40892816,40142784,35898300,35831802,37002305,2069097,40142910,40142920,1356143,1356140,40830728,40734060,21085349,40152662,41174011,40156382,41048760,40754973,21089505,2070686,40144020,36882733,42482744,2071140,40144024,792484,40755794,37592046,43532281,43291091,41267401,40144035,35147990,35149212,2070702,40144037,40223712,36035528,35887474,36036727,35885804,40143326,44817882,40143708,21603284,43534839,1502099,1123813,21603285,21603281,715850,1588664,21603291,21603286,45893496,21603288,44819166,21603280,43534841,1501769,43534840,715851,715852,21603290,21603289)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (42483138,36812530,36421291,40745353,36787954,21158944,36894458,21090035,42480194,36883710,35130061,42479684,35133500,783228,36787269,43291282,35135829,44120754,36894464,40892816,40142784,35898300,35831802,37002305,2069097,40142910,40142920,1356143,1356140,40830728,40734060,21085349,40152662,41174011,40156382,41048760,40754973,21089505,2070686,40144020,36882733,42482744,2071140,40144024,792484,40755794,37592046,43532281,43291091,41267401,40144035,35147990,35149212,2070702,40144037,40223712,36035528,35887474,36036727,35885804,40143326,44817882,40143708,21603284,43534839,1502099,1123813,21603285,21603281,715850,1588664,21603291,21603286,45893496,21603288,44819166,21603280,43534841,1501769,43534840,715851,715852,21603290,21603289)
  and c.invalid_reason is null

) I
) C UNION ALL 
SELECT 3 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (21603354,21603355,21603356,1154161,43009065,1111706)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (21603354,21603355,21603356,1154161,43009065,1111706)
  and c.invalid_reason is null

) I
) C UNION ALL 
SELECT 4 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (260125,254058,4110182,4307774,260434,4052544,254677,4112673,257315,40482069,439298,256722,4110056,444084,4049965,252655,260754,4310964,443410,4133224,440431,439857,258785,255848,256723,254066,260430,258180,40482061,253790,4050872,252351,436145,261324,257582,4187218,4209097,259852,261326)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (260125,254058,4110182,4307774,260434,4052544,254677,4112673,257315,40482069,439298,256722,4110056,444084,4049965,252655,260754,4310964,443410,4133224,440431,439857,258785,255848,256723,254066,260430,258180,40482061,253790,4050872,252351,436145,261324,257582,4187218,4209097,259852,261326)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (317009)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (317009)
  and c.invalid_reason is null

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) C
),
primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
  -- Begin Drug Exposure Criteria
select C.person_id, C.drug_exposure_id as event_id, C.drug_exposure_start_date as start_date,
       COALESCE(C.DRUG_EXPOSURE_END_DATE, DATEADD(day,C.DAYS_SUPPLY,DRUG_EXPOSURE_START_DATE), DATEADD(day,1,C.DRUG_EXPOSURE_START_DATE)) as end_date,
       C.visit_occurrence_id,C.drug_exposure_start_date as sort_date
from 
(
  select de.* 
  FROM @cdm_database_schema.DRUG_EXPOSURE de
JOIN Codesets codesets on ((de.drug_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) C
JOIN @cdm_database_schema.PERSON P on C.person_id = P.person_id
WHERE (YEAR(C.drug_exposure_start_date) - P.year_of_birth >= 5 and YEAR(C.drug_exposure_start_date) - P.year_of_birth <= 18)
-- End Drug Exposure Criteria

  ) E
	JOIN @cdm_database_schema.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,365,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

), 
qualified_events as
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe 
),
Inclusion_0 as (
  select 0 as inclusion_rule_id, pe.person_id, pe.event_id
  FROM qualified_events pe
  
JOIN (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id 
  FROM qualified_events E
  INNER JOIN
  (
    -- Begin Correlated Criteria
select 0 as index_id, cc.person_id, cc.event_id
from (SELECT p.person_id, p.event_id 
FROM qualified_events P
JOIN (
  -- Begin Condition Occurrence Criteria
SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date,
  C.visit_occurrence_id, C.condition_start_date as sort_date
FROM 
(
  SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN Codesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 1))
) C
JOIN @cdm_database_schema.VISIT_OCCURRENCE V on C.visit_occurrence_id = V.visit_occurrence_id and C.person_id = V.person_id
WHERE V.visit_concept_id in (9202)
-- End Condition Occurrence Criteria

) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= DATEADD(day,-365,P.START_DATE) AND A.START_DATE <= DATEADD(day,0,P.START_DATE) ) cc 
GROUP BY cc.person_id, cc.event_id
HAVING COUNT(cc.event_id) >= 1
-- End Correlated Criteria

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G
-- End Criteria Group
) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
),
Inclusion_1 as 
(
  select 1 as inclusion_rule_id, pe.person_id, pe.event_id
  FROM qualified_events pe
  
JOIN (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id 
  FROM qualified_events E
  INNER JOIN
  (
    -- Begin Correlated Criteria
select 0 as index_id, p.person_id, p.event_id
from qualified_events p
LEFT JOIN (
SELECT p.person_id, p.event_id 
FROM qualified_events P
JOIN (
  -- Begin Drug Exposure Criteria
select C.person_id, C.drug_exposure_id as event_id, C.drug_exposure_start_date as start_date,
       COALESCE(C.DRUG_EXPOSURE_END_DATE, DATEADD(day,C.DAYS_SUPPLY,DRUG_EXPOSURE_START_DATE), DATEADD(day,1,C.DRUG_EXPOSURE_START_DATE)) as end_date,
       C.visit_occurrence_id,C.drug_exposure_start_date as sort_date
from 
(
  select de.* 
  FROM @cdm_database_schema.DRUG_EXPOSURE de
JOIN Codesets codesets on ((de.drug_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) C


-- End Drug Exposure Criteria

) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= DATEADD(day,-180,P.START_DATE) AND A.START_DATE <= DATEADD(day,0,P.START_DATE) ) cc on p.person_id = cc.person_id and p.event_id = cc.event_id
GROUP BY p.person_id, p.event_id
HAVING COUNT(cc.event_id) = 0
-- End Correlated Criteria

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G
-- End Criteria Group
) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
),
Inclusion_2 as 
(
  select 2 as inclusion_rule_id, pe.person_id, pe.event_id
  FROM qualified_events pe
  
JOIN (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id 
  FROM qualified_events E
  INNER JOIN
  (
    -- Begin Correlated Criteria
select 0 as index_id, p.person_id, p.event_id
from qualified_events p
LEFT JOIN (
SELECT p.person_id, p.event_id 
FROM qualified_events P
JOIN (
  -- Begin Condition Occurrence Criteria
SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date,
  C.visit_occurrence_id, C.condition_start_date as sort_date
FROM 
(
  SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN Codesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) C


-- End Condition Occurrence Criteria

) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= DATEADD(day,-7,P.START_DATE) AND A.START_DATE <= DATEADD(day,0,P.START_DATE) ) cc on p.person_id = cc.person_id and p.event_id = cc.event_id
GROUP BY p.person_id, p.event_id
HAVING COUNT(cc.event_id) = 0
-- End Correlated Criteria

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G
-- End Criteria Group
) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
),
criteria_0 as(
select q.person_id, inclusion_rule_id as inclusion_stage_0 from qualified_events q LEFT JOIN Inclusion_0 i0 ON q.person_id = i0.person_id
),
criteria_1 as (
select q.person_id, q.inclusion_stage_0, inclusion_rule_id as inclusion_stage_1 from criteria_0 q LEFT JOIN Inclusion_1 i1 ON q.person_id = i1.person_id
),
criteria_2 as ( 
select q.person_id, q.inclusion_stage_0, q.inclusion_stage_1, inclusion_rule_id as inclusion_stage_2 from criteria_1 q LEFT JOIN Inclusion_2 i2 ON q.person_id = i2.person_id
)
SELECT * from criteria_2
  
 

