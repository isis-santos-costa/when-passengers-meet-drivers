-- ****************************************************************************************************************************
-- when_riders_meet_drivers.sql 
-- Purpose: understand ride-hailing seasonality of supply vs seasonality of demand, in hours, for each day of the week
-- Approach: using "Chicago Taxi Trips" from BiqQuery Public Data, assuming it shows a behavior similar to ride-hailing
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-04-18
-- ****************************************************************************************************************************

-------------------------------------------------------------------------------------------------------------------------------
-- Function 1 • Get day of week from datetime
-------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION dayOfWeek(x DATETIME) AS (
  ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][ORDINAL(EXTRACT(DAYOFWEEK FROM x))]
);

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 1 • Data collection: fetching data from the original table
-------------------------------------------------------------------------------------------------------------------------------
WITH raw_data AS (
  SELECT
    unique_key               -- REQUIRED  STRING      Unique identifier for the trip.
    , taxi_id                -- REQUIRED  STRING      A unique identifier for the taxi.
    , trip_start_timestamp   -- NULLABLE  TIMESTAMP   When the trip started, rounded to nearest 15 minutes.
    , trip_seconds           -- NULLABLE  INTEGER     Duration of the trip in seconds.
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
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(2)] median_trip_seconds
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
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(2)] median_trip_seconds
  , AVG(trip_seconds) avg_trip_seconds
  , MIN(trip_seconds) min_trip_seconds
  , MAX(trip_seconds) max_trip_seconds 
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] q1_trip_seconds
  , APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] q3_trip_seconds
  , ( APPROX_QUANTILES(trip_seconds, 4)[OFFSET(3)] - APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] ) iqr_trip_seconds
  FROM data_cleaned_from_duration_outliers
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 5 • Data cleaning: (b) aggregating partially clean data, preparing to exclude extreme hours (esp. peaks)
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_agg AS (
  SELECT
      DATETIME_TRUNC(trip_start_local_datetime, HOUR) AS trip_start_local_datehour
    , COUNT(DISTINCT unique_key) AS hourly_trip_cnt
    , COUNT(DISTINCT taxi_id) AS hourly_taxi_cnt
    FROM data_cleaned_from_duration_outliers
    GROUP BY trip_start_local_datehour
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 6 • Data cleaning: (c) finding interquartile ranges (IQR) of hourly_trip_cnt, hourly_taxi_cnt
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_trips_taxis_iqr AS (
  SELECT
      APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(1)] AS hourly_trip_cnt_iqr_lower
    , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(2)] AS hourly_trip_cnt_med
    , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(3)] AS hourly_trip_cnt_iqr_upper
    , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(1)] AS hourly_trip_cnt_iqr
    , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(1)] AS hourly_taxi_cnt_iqr_lower
    , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(2)] AS hourly_taxi_cnt_med
    , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(3)] AS hourly_taxi_cnt_iqr_upper
    , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(1)] AS hourly_taxi_cnt_iqr
    FROM data_cleaning_agg
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 7 • Data cleaning: (iii) based on hourly_trip_cnt, hourly_taxi_cnt, remove extreme hours from pre-cleaned (i)+(ii) data
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
  WHERE (hourly_trip_cnt BETWEEN hourly_trip_cnt_iqr_lower - 1.5 * hourly_trip_cnt_iqr
                      AND hourly_trip_cnt_iqr_upper + 1.5 * hourly_trip_cnt_iqr)
    AND (hourly_taxi_cnt BETWEEN hourly_taxi_cnt_iqr_lower - 1.5 * hourly_taxi_cnt_iqr
                      AND hourly_taxi_cnt_iqr_upper + 1.5 * hourly_taxi_cnt_iqr)
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 8 • Data cleaning: (c) aggregating final clean data
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_agg_clean_data AS (
  SELECT
      DATETIME_TRUNC(trip_start_local_datetime, HOUR) AS trip_start_local_datehour
    , COUNT(DISTINCT unique_key) AS hourly_trip_cnt
    , COUNT(DISTINCT taxi_id) AS hourly_taxi_cnt
    FROM clean_data
    GROUP BY trip_start_local_datehour
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 9 • Data cleaning: checking results from cleaning (iii)
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_results AS (
  SELECT
  'data_cleaning_agg' AS cte
  , COUNT(*) record_cnt
  , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(2)] median_hourly_trip_cnt
  , AVG(hourly_trip_cnt) avg_hourly_trip_cnt
  , MIN(hourly_trip_cnt) min_hourly_trip_cnt
  , MAX(hourly_trip_cnt) max_hourly_trip_cnt
  , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(1)] q1_hourly_trip_cnt
  , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(3)] q3_hourly_trip_cnt
  , ( APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(1)] ) iqr_hourly_trip_cnt
  , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(2)] median_hourly_taxi_cnt
  , AVG(hourly_taxi_cnt) avg_hourly_taxi_cnt
  , MIN(hourly_taxi_cnt) min_hourly_taxi_cnt
  , MAX(hourly_taxi_cnt) max_hourly_taxi_cnt
  , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(1)] q1_hourly_taxi_cnt
  , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(3)] q3_hourly_taxi_cnt
  , ( APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(1)] ) iqr_hourly_taxi_cnt
  FROM data_cleaning_agg
  UNION ALL
  SELECT
  'data_cleaning_agg_clean_data' AS cte
  , COUNT(*) record_cnt
  , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(2)] median_hourly_trip_cnt
  , AVG(hourly_trip_cnt) avg_hourly_trip_cnt
  , MIN(hourly_trip_cnt) min_hourly_trip_cnt
  , MAX(hourly_trip_cnt) max_hourly_trip_cnt
  , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(1)] q1_hourly_trip_cnt
  , APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(3)] q3_hourly_trip_cnt
  , ( APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(hourly_trip_cnt, 4)[OFFSET(1)] ) iqr_hourly_trip_cnt
  , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(2)] median_hourly_taxi_cnt
  , AVG(hourly_taxi_cnt) avg_hourly_taxi_cnt
  , MIN(hourly_taxi_cnt) min_hourly_taxi_cnt
  , MAX(hourly_taxi_cnt) max_hourly_taxi_cnt
  , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(1)] q1_hourly_taxi_cnt
  , APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(3)] q3_hourly_taxi_cnt
  , ( APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(3)] - APPROX_QUANTILES(hourly_taxi_cnt, 4)[OFFSET(1)] ) iqr_hourly_taxi_cnt
  FROM data_cleaning_agg_clean_data
)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 10 • Typical duration of trips, according to clean data
-------------------------------------------------------------------------------------------------------------------------------
, typical_trip_seconds AS 
  (SELECT APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] AS median_trip_seconds FROM clean_data)

-------------------------------------------------------------------------------------------------------------------------------
-- CTE 11 • Hourly count of trips (demand) + (estimated) Hourly count of possible trips (supply)
-------------------------------------------------------------------------------------------------------------------------------
-- Model
-- hourly_trips_supply: total #trips in 1hr that could have happened, based on drivers' availability and typical trip duration
-- hourly_trips_supply =
--   = estimated_number_of_taxis_available_in_the_hour × potential_number_of_trips_per_hour_per_driver
--
-- estimated_number_of_taxis_available_in_the_hour = 
--   = number_of_taxis_w_trips_in_the_hour ÷ drivers_typical_idle_time
-- 
-- potential_number_of_trips_per_hour_per_driver =
--   = 60 ÷ typical_trip_minutes
-------------------------------------------------------------------------------------------------------------------------------
-- Assumption
-- drivers_idle_time = 2/3
-- Ref.: https://www.uberpeople.net/threads/what-is-your-idle-time-and-idle-running-in-km-as-uber-driver.146607/
-------------------------------------------------------------------------------------------------------------------------------
-- Note on impact of Model & Assumption on findings
-- These are only applied in getting realistic absolute numbers, not impacting findings of the analysis [based on proportion]
-------------------------------------------------------------------------------------------------------------------------------
, hourly_supply_demand AS (
  SELECT
      DATETIME_TRUNC(trip_start_local_datetime, HOUR) AS trip_start_local_datehour
    , dayOfWeek(trip_start_local_datetime) AS trip_start_local_dayofweek
    , EXTRACT(HOUR FROM trip_start_local_datetime) AS trip_start_local_hour
    , (median_trip_seconds / 60.0) AS typical_trip_minutes
    , CAST(FLOOR(60 / (median_trip_seconds / 60.0)) AS INT64) AS potential_number_of_trips_per_hour_per_driver
    , COUNT(DISTINCT unique_key) AS hourly_trips_demand
    , CAST(FLOOR((COUNT(DISTINCT taxi_id)/(2/3)) * FLOOR(60/(AVG(median_trip_seconds)/60.0))) AS INT64) AS hourly_trips_supply
  FROM clean_data, typical_trip_seconds
  GROUP BY 1, 2, 3, 4, 5
)

-------------------------------------------------------------------------------------------------------------------------------
-- Unit tests / Final query
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
   SELECT * FROM hourly_supply_demand ORDER BY 1
-------------------------------------------------------------------------------------------------------------------------------

