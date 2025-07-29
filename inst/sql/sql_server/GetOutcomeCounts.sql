WITH codesets as (SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4219484,440925,4303690)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4219484,440925,4303690)
  and c.invalid_reason is null

) I
) C UNION ALL 
SELECT 3 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (37016741,37016719,4133495,4335169,436677,4229448,442077,438409,436665,4100101,440990,4294887,432590,440383,4047120,4268911,434889,4044055,43021205,375800,434903,4217365,440695,440984,4250314,436817,4313860,4338512,436381,433031,4195585,433752,436952,4168681,4333677,4151937,4130710,4297400,444100,441553,444243,4170260,4105190,4101149,374905,440374,4335159,373175,4100247,44782778,4173740,4335168,441838,4304010,4085332,4100683,4098302,4168212,4198081,4286201,435783,434010,439235,4181216,35623653,435524,435784,4207660,4152371,436667,444362,4273391,381839,374907,4231241,443782,4172646)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (37016741,37016719,4133495,4335169,436677,4229448,442077,438409,436665,4100101,440990,4294887,432590,440383,4047120,4268911,434889,4044055,43021205,375800,434903,4217365,440695,440984,4250314,436817,4313860,4338512,436381,433031,4195585,433752,436952,4168681,4333677,4151937,4130710,4297400,444100,441553,444243,4170260,4105190,4101149,374905,440374,4335159,373175,4100247,44782778,4173740,4335168,441838,4304010,4085332,4100683,4098302,4168212,4198081,4286201,435783,434010,439235,4181216,35623653,435524,435784,4207660,4152371,436667,444362,4273391,381839,374907,4231241,443782,4172646)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (133285,380375,4262580,4049477,4177975)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (133285,380375,4262580,4049477,4177975)
  and c.invalid_reason is null

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) C
),
event as ( 
SELECT C.person_id, C.condition_occurrence_id as occurrence_id, C.condition_concept_id as concept_id, C.condition_start_date as outcome_start_date
FROM 
(
  SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) C
-- End Condition Occurrence
UNION ALL
select C.person_id, C.observation_id as occurrence_id, C.observation_concept_id as concept_id, C.observation_date as outcome_start_date
from 
(
  select o.* 
  FROM @cdm_database_schema.OBSERVATION o
JOIN codesets on ((o.observation_concept_id = codesets.concept_id and codesets.codeset_id = 1))
) C
),
outcome as (SELECT  e.person_id, e.concept_id, e.outcome_start_date, ch.cohort_start_date, ch.cohort_definition_id
FROM event e, @cohort_database_schema.@cohort_table ch 
WHERE e.person_id = ch.subject_id
AND e.outcome_start_date = ch.cohort_start_date
)
select o.person_id, o.concept_id, o.outcome_start_date from outcome o, (select * from @cohort_database_schema.@cohort_table where cohort_definition_id in (@target_definition_id,@comparator_definition_id)) ch
where o.person_id = ch.subject_id
