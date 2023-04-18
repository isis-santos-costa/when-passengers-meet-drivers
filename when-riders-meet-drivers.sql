-- ****************************************************************************************************************************
-- when_riders_meet_drivers.sql
-- Purpose: understand ride-hailing seasonality of supply vs seasonality of demand, in hours, for each day of the week
-- Approach: using "Chicago Taxi Trips" from BiqQuery Public Data, assuming it shows a behavior similar to ride-hailing
-- Author: Isis Santos Costa
-- Date: 2023-04-16
-- ****************************************************************************************************************************

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 1 • Data collection: fetching data from the original table
-------------------------------------------------------------------------------------------------------------------------------
WITH raw_data AS (
  SELECT
    unique_key	            -- REQUIRED	STRING	    Unique identifier for the trip.
    , taxi_id	              -- REQUIRED	STRING	    A unique identifier for the taxi.
    , trip_start_timestamp  -- NULLABLE	TIMESTAMP   When the trip started, rounded to nearest 15 minutes.
    , trip_seconds	        -- NULLABLE	INTEGER	    Duration of the trip in seconds.
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 2 • Data cleaning: (a) finding interquartile ranges (IQR) of trip_seconds
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_trip_seconds_iqr AS (
  SELECT
      APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] AS trip_seconds_iqr_lower
    , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(2)] AS trip_seconds_med
    , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] AS trip_seconds_iqr_upper
    , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] - APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] AS trip_seconds_iqr
    FROM raw_data
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 3 • Data cleaning: (i) converting from UTC to Chicago Time, (ii) Excluding outliers: duration (trip_seconds)
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaned_from_duration_outliers AS (
    SELECT
    unique_key
    , taxi_id
    , DATETIME(trip_start_timestamp, 'America/Chicago') AS trip_start_local_datetime
    , trip_seconds
  FROM raw_data, data_cleaning_trip_seconds_iqr
  WHERE (trip_seconds BETWEEN trip_seconds_iqr_lower - 1.5 * trip_seconds_iqr
                          AND trip_seconds_iqr_upper + 1.5 * trip_seconds_iqr)
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 4 • Data cleaning: checking results from cleaning (i) + (ii)
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_duration_outliers_results AS (
  SELECT
  'raw_data' AS cte
  , COUNT(*) record_cnt
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(2)] med_trip_seconds
  , AVG(trip_seconds) avg_trip_seconds
  , MIN(trip_seconds) min_trip_seconds
  , MAX(trip_seconds) max_trip_seconds 
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] q1_trip_seconds
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] q3_trip_seconds
  , ( APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] - APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] ) iqr_trip_seconds
  FROM raw_data
  UNION ALL
  SELECT
  'data_cleaned_from_duration_outliers' AS cte
  , COUNT(*) record_cnt
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(2)] med_trip_seconds
  , AVG(trip_seconds) avg_trip_seconds
  , MIN(trip_seconds) min_trip_seconds
  , MAX(trip_seconds) max_trip_seconds 
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] q1_trip_seconds
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] q3_trip_seconds
  , ( APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] - APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] ) iqr_trip_seconds
  FROM data_cleaned_from_duration_outliers
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 5 • Data cleaning: (b) Aggregating partially clean data, preparing to exclude extreme hours (esp. peaks)
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_agg AS (
  SELECT
      DATETIME_TRUNC(trip_start_local_datetime, HOUR) AS trip_start_local_datehour
    , COUNT(DISTINCT unique_key) AS trip_cnt
    , COUNT(DISTINCT taxi_id) AS taxi_cnt
    FROM data_cleaned_from_duration_outliers
    GROUP BY trip_start_local_datehour
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 6 • Data cleaning: (c) Finding interquartile ranges (IQR) of trip_cnt, taxi_cnt
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_trips_taxis_iqr AS (
  SELECT
      APPROX_QUANTILES(trip_cnt, 4)[OFFSET(1)] AS trip_cnt_iqr_lower
    , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(2)] AS trip_cnt_med
    , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(3)] AS trip_cnt_iqr_upper
    , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(trip_cnt, 4)[OFFSET(1)] AS trip_cnt_iqr
    , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(1)] AS taxi_cnt_iqr_lower
    , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(2)] AS taxi_cnt_med
    , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(3)] AS taxi_cnt_iqr_upper
    , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(1)] AS taxi_cnt_iqr
    FROM data_cleaning_agg
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 7 • Data cleaning: (iii) Based on trip_cnt, taxi_cnt, remove extreme hours from pre-cleaned (i)+(ii) data
-------------------------------------------------------------------------------------------------------------------------------
, clean_data AS (
    SELECT
    trip_start_local_datetime
    , unique_key
    , taxi_id
    , trip_seconds
  FROM data_cleaned_from_duration_outliers, data_cleaning_trips_taxis_iqr
  JOIN data_cleaning_agg
    ON data_cleaning_agg.trip_start_local_datehour = DATETIME_TRUNC(trip_start_local_datetime, HOUR)
  WHERE (trip_cnt BETWEEN trip_cnt_iqr_lower - 1.5 * trip_cnt_iqr
                      AND trip_cnt_iqr_upper + 1.5 * trip_cnt_iqr)
    AND (taxi_cnt BETWEEN taxi_cnt_iqr_lower - 1.5 * taxi_cnt_iqr
                      AND taxi_cnt_iqr_upper + 1.5 * taxi_cnt_iqr)
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 8 • Data cleaning: (c) Aggregating final clean data
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_agg_clean_data AS (
  SELECT
      DATETIME_TRUNC(trip_start_local_datetime, HOUR) AS trip_start_local_datehour
    , COUNT(DISTINCT unique_key) AS trip_cnt
    , COUNT(DISTINCT taxi_id) AS taxi_cnt
    FROM clean_data
    GROUP BY trip_start_local_datehour
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 9 • Data cleaning: results from step (iii)
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_results AS (
  SELECT
  'data_cleaning_agg' AS cte
  , COUNT(*) record_cnt
  , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(2)] med_trip_cnt
  , AVG(trip_cnt) avg_trip_cnt
  , MIN(trip_cnt) min_trip_cnt
  , MAX(trip_cnt) max_trip_cnt
  , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(1)] q1_trip_cnt
  , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(3)] q3_trip_cnt
  , ( APPROX_QUANTILES(trip_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(trip_cnt, 4)[OFFSET(1)] ) iqr_trip_cnt
  , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(2)] med_taxi_cnt
  , AVG(taxi_cnt) avg_taxi_cnt
  , MIN(taxi_cnt) min_taxi_cnt
  , MAX(taxi_cnt) max_taxi_cnt
  , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(1)] q1_taxi_cnt
  , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(3)] q3_taxi_cnt
  , ( APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(1)] ) iqr_taxi_cnt
  FROM data_cleaning_agg
  UNION ALL
  SELECT
  'data_cleaning_agg_clean_data' AS cte
  , COUNT(*) record_cnt
  , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(2)] med_trip_cnt
  , AVG(trip_cnt) avg_trip_cnt
  , MIN(trip_cnt) min_trip_cnt
  , MAX(trip_cnt) max_trip_cnt
  , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(1)] q1_trip_cnt
  , APPROX_QUANTILES(trip_cnt, 4)[OFFSET(3)] q3_trip_cnt
  , ( APPROX_QUANTILES(trip_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(trip_cnt, 4)[OFFSET(1)] ) iqr_trip_cnt
  , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(2)] med_taxi_cnt
  , AVG(taxi_cnt) avg_taxi_cnt
  , MIN(taxi_cnt) min_taxi_cnt
  , MAX(taxi_cnt) max_taxi_cnt
  , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(1)] q1_taxi_cnt
  , APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(3)] q3_taxi_cnt
  , ( APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(taxi_cnt, 4)[OFFSET(1)] ) iqr_taxi_cnt
  FROM data_cleaning_agg_clean_data
)

-------------------------------------------------------------------------------------------------------------------------------
-- Unit tests
-------------------------------------------------------------------------------------------------------------------------------
-- SELECT COUNT(*) AS record_cnt FROM raw_data                    -- 194,639,776
-- SELECT * FROM data_cleaning_trip_seconds_iqr
-- SELECT COUNT(*) FROM data_cleaned_from_duration_outliers       -- 179,716,634
-- SELECT * FROM data_cleaning_duration_outliers_results          -- 179,716,634
-- SELECT COUNT(*) FROM data_cleaning_agg                         --      89,788 (2012-12-31 to 2023-03-31)
-- SELECT * FROM data_cleaning_trips_taxis_iqr
-- SELECT COUNT(*) FROM clean_data                                -- 176,677,544
-- SELECT COUNT(*) FROM data_cleaning_agg_clean_data              --      89,441
-- SELECT * FROM data_cleaning_results
-- SELECT * FROM typical_trip_seconds
   SELECT * FROM data_cleaning_results

-----------------------------------------------------------------------------------------------------------------

