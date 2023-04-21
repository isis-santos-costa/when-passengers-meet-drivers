<head><base target="_blank"></head>  

# 🚖 when-riders-meet-drivers  • Data analysis process
<b>Seasonality of supply vs seasonality of demand in ride-hailing.  </b>

This repository details the steps of the process of a quick data analysis with the aim of understanding the matching and contrasting points in the daily and weekly seasonality of the different sides of a ride-hailing marketplace. The full `sql` code is available [here](when-riders-meet-drivers.sql).  

Tags: `product-analytics`, `sql`, `bigquery`.

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Contents -->

## Contents  

[Step 1 • Business question](data-analysis.md#step-1--business-question)  
[Step 2 • Data collection](data-analysis.md#step-2--data-collection)  
[Step 3 • Data cleaning](data-analysis.md#step-3--data-cleaning)  
[Step 4 • Analysis](data-analysis.md#step-4--analysis)  
[Step 5 • Synthesis](data-analysis.md#step-5--synthesis)  

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Query structure -->

## Query structure  

[CTE &nbsp;&nbsp;1 • Data collection: fetching data from the original table](data-analysis.md#cte-1--data-collection-fetching-data-from-the-original-table)  
[CTE &nbsp;&nbsp;2 • Data cleaning: (a) finding interquartile ranges (IQR) of trip_seconds](data-analysis.md#cte-2--data-cleaning-a-finding-interquartile-ranges-iqr-of-trip_seconds)  
[CTE &nbsp;&nbsp;3 • Data cleaning: (i) converting from UTC to Chicago Time, (ii) Excluding outliers: duration (trip_seconds)](data-analysis.md#cte-3--data-cleaning-i-converting-from-utc-to-chicago-time-ii-excluding-outliers-duration-trip_seconds)  
[CTE &nbsp;&nbsp;4 • Data cleaning: checking results from cleaning (i) + (ii)](data-analysis.md#cte-4--data-cleaning-checking-results-from-cleaning-i--ii)  
[CTE &nbsp;&nbsp;5 • Data cleaning: (b) aggregating partially clean data, preparing to exclude extreme hours (esp. peaks)](data-analysis.md#cte-5--data-cleaning-b-aggregating-partially-clean-data-preparing-to-exclude-extreme-hours-esp-peaks)  
[CTE &nbsp;&nbsp;6 • Data cleaning: (c) finding interquartile ranges (IQR) of trip_cnt, taxi_cnt](data-analysis.md#cte-6--data-cleaning-c-finding-interquartile-ranges-iqr-of-trip_cnt-taxi_cnt)  
[CTE &nbsp;&nbsp;7 • Data cleaning: (iii) based on trip_cnt, taxi_cnt, remove extreme hours from pre-cleaned (i)+(ii) data](data-analysis.md#cte-7--data-cleaning-iii-based-on-trip_cnt-taxi_cnt-remove-extreme-hours-from-pre-cleaned-iii-data)  
[CTE &nbsp;&nbsp;8 • Data cleaning: (c) aggregating final clean data](data-analysis.md#cte-8--data-cleaning-c-aggregating-final-clean-data)  
[CTE &nbsp;&nbsp;9 • Data cleaning: checking results from cleaning (iii)](data-analysis.md#cte-9--data-cleaning-checking-results-from-cleaning-iii)  
[CTE 10 • Data analysis: typical duration of trips, according to clean data](data-analysis.md#cte-10--data-analysis-typical-duration-of-trips-according-to-clean-data)  
[CTE 11 • Data analysis: hourly count of trips (demand) + (estimated) Hourly count of possible trips (supply)](data-analysis.md#cte-11--data-analysis-hourly-count-of-trips-demand--estimated-hourly-count-of-possible-trips-supply)  

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 1 -->

## Step 1 • Business question  

The search in this analysis is for a quick insight into the following question:

> <i> « Are there any significant differences between favorite drivers' schedules and passengers' needs? » </i>  
>> <i> « If so, when do the most critical imbalances occur? » </i>  

Why would the company care about this issue?  

The duty of a markteplace is to make supply meet demand and vice versa. In some cases, « when » it happens may be secondary. Take, for example, the purchase of a totally specific item found only abroad. In the absence of another option, the customer may be willing to wait a long time (I myself have once waited months). In some cases, on the other hand, timimg may be non-negotiable. Imagine waiting for a car to go to work, for instance. Five minutes most probably make a difference, and anything over fifteen minutes has a high chance of entering the deal-breaker zone.  

This is where seasonality plays a role in the ride-hailing business. In order to make customers happy, it is not enough, in this case, to acquire a sufficient global number of drivers to meet passangers' requests, and to acquire a sufficient number of passangers to guarantee the drivers' income: one side's availability has to take place at the same time as the need for the other side (± no more than a few minutes).

Becoming data-informed about each side's natural preferences equips the business to intentionally, thoughtfully, introduce incentives and create advantages so that one side is attracted to the organic schedule of the other side.

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 2 -->

## Step 2 • Data collection  

While ideal data for this analysis is actual product data from a ride-hailing app, such data is kept private by companies. The supply-demand dynamics of a city-hall regulated taxi market is therefore taken as an approximation.  

Taxi operations data is available in [BigQuery public datasets](https://console.cloud.google.com/marketplace/browse?filter=solution-type:dataset):

https://user-images.githubusercontent.com/58894233/232629098-d7089ba6-a8bf-4392-809e-8c015bffaad9.mp4

<br>

You will see that searching for « taxi » on Google Cloud Marketplace for datasets returns two entries <sub>(as of 2023-04-17)</sub>:
* [Chicago Taxi Trips](https://console.cloud.google.com/marketplace/product/city-of-chicago-public-data/chicago-taxi-trips)
* [NYC TLC Trips](https://console.cloud.google.com/marketplace/product/city-of-new-york/nyc-tlc-trips)

<br>

Clicking on « view dataset » opens it on BigQuery, where it is possible to see different structures for the collection of these datasets.  

<br>

The dataset « NYC TLC Trips » has <b>separate tables</b> for each year and line of business:  

![when-riders-meet-drivers---dataset-1-highlighted](https://user-images.githubusercontent.com/58894233/232633376-1507a50a-b41a-4a03-8d81-d940fb843b74.png)

<br>

The dataset « Chicago Taxi Trips », in turn, has the whole data collected in a <b>single table</b>:  

![when-riders-meet-drivers---dataset-2-highlighted](https://user-images.githubusercontent.com/58894233/232633677-31d77026-da42-4e55-9505-c089d8742504.png)

<br>

Inspecting the `taxi_trips` table schema reveals that the fields needed for a quick study are available in it:
* unique_key
* taxi_id
* trip_start_timestamp
* trip_seconds (duration)

<br>

![when-riders-meet-drivers---dataset-3-highlighted](https://user-images.githubusercontent.com/58894233/232634944-c0462a65-fb5e-4dde-b2bd-1cc5a40c8f56.png)

<br>

Considering agility, only the <b>[« Chicago Taxi Trips »](https://console.cloud.google.com/marketplace/product/city-of-chicago-public-data/chicago-taxi-trips/) dataset has been chosen for the study</b>. In this way, all necessary that can be retrived fetching just `` FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips` ``. Data from the « NYC TLC Trips » dataset may be added for validation and further elaboration in the future.  

<br>

Data is retrived from BigQuery public data in the first Common Table Expression (CTE) of the query, as follows:  

<br>

### CTE 1 • Data collection: fetching data from the original table

```sql
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
```  

<br>

Calling CTE 1:  
```sql
SELECT COUNT(*) AS record_cnt FROM raw_data
```  
![when-riders-meet-drivers---sql---cte-1---query-results](https://user-images.githubusercontent.com/58894233/232664865-1c57e472-21c0-4cae-9e42-a8f8aafb59c5.png)

<br>

The other CTEs are gradually introduced below, in their respective step, and the full `sql` code is available [here](when-riders-meet-drivers.sql).  

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 3 -->

## Step 3 • Data cleaning  

Data cleaning is performed in CTE-2 to CTE-9, comprising the following tasks:  

<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (i) &nbsp;&nbsp;&nbsp; Convert from UTC to local (Chicago) Time  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (ii) &nbsp;&nbsp; Exclude outliers: duration (trip_seconds)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (iii) &nbsp; Exclude outliers: hours with extreme loads/scarcity of supply or demand  

<br>

### CTE 2 • Data cleaning: (a) finding interquartile ranges (IQR) of trip_seconds

```sql
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
```  

<br>

Calling CTE 2:  
```sql
SELECT * FROM data_cleaning_trip_seconds_iqr
```  
![when-riders-meet-drivers---sql---cte-2---query-results](https://user-images.githubusercontent.com/58894233/232666745-fc156780-1e88-4be6-9969-fcb7897f49c8.png)

<br>

### CTE 3 • Data cleaning: (i) converting from UTC to Chicago Time, (ii) Excluding outliers: duration (trip_seconds)

```sql
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
```  

<br>

Calling CTE 3:  
```sql
SELECT COUNT(*) FROM data_cleaned_from_duration_outliers
```  
![when-riders-meet-drivers---sql---cte-3---query-results](https://user-images.githubusercontent.com/58894233/232666776-6462df6c-f87f-43fe-a790-bd02d6452127.png)

<br>

### CTE 4 • Data cleaning: checking results from cleaning (i) + (ii)

```sql
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
```  

<br>

Calling CTE 4:  
```sql
SELECT * FROM data_cleaning_duration_outliers_results
```  
![when-riders-meet-drivers---sql---cte-4---query-results](https://user-images.githubusercontent.com/58894233/232666807-c3693ff2-5ef8-4b08-9c0a-61688af83f1f.png)

<br>

### CTE 5 • Data cleaning: (b) aggregating partially clean data, preparing to exclude extreme hours (esp. peaks)

```sql
-------------------------------------------------------------------------------------------------------------------------------
-- CTE 5 • Data cleaning: (b) aggregating partially clean data, preparing to exclude extreme hours (esp. peaks)
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_agg AS (
  SELECT
      DATETIME_TRUNC(trip_start_local_datetime, HOUR) AS trip_start_local_datehour
    , COUNT(DISTINCT unique_key) AS trip_cnt
    , COUNT(DISTINCT taxi_id) AS taxi_cnt
    FROM data_cleaned_from_duration_outliers
    GROUP BY trip_start_local_datehour
)
```  

<br>

Calling CTE 5:  
```sql
SELECT COUNT(*) FROM data_cleaning_agg
```  
![when-riders-meet-drivers---sql---cte-5---query-results](https://user-images.githubusercontent.com/58894233/232666839-341cef6f-17ad-4351-bf76-86691456857e.png)

<br>

### CTE 6 • Data cleaning: (c) finding interquartile ranges (IQR) of trip_cnt, taxi_cnt

```sql
-------------------------------------------------------------------------------------------------------------------------------
-- CTE 6 • Data cleaning: (c) finding interquartile ranges (IQR) of trip_cnt, taxi_cnt
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
```  

<br>

Calling CTE 6:  
```sql
SELECT * FROM data_cleaning_trips_taxis_iqr
```  
![when-riders-meet-drivers---sql---cte-6---query-results](https://user-images.githubusercontent.com/58894233/232666871-8241b05b-0cf1-4321-9a4f-320a5949e4e3.png)

<br>

### CTE 7 • Data cleaning: (iii) based on trip_cnt, taxi_cnt, remove extreme hours from pre-cleaned (i)+(ii) data

```sql
-------------------------------------------------------------------------------------------------------------------------------
-- CTE 7 • Data cleaning: (iii) based on trip_cnt, taxi_cnt, remove extreme hours from pre-cleaned (i)+(ii) data
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
```  

<br>

Calling CTE 7:  
```sql
SELECT COUNT(*) FROM clean_data
```  
![when-riders-meet-drivers---sql---cte-7---query-results](https://user-images.githubusercontent.com/58894233/232666918-cbc199a1-90be-456a-9e67-e6cc2da454ee.png)

<br>

### CTE 8 • Data cleaning: (c) aggregating final clean data

```sql
-------------------------------------------------------------------------------------------------------------------------------
-- CTE 8 • Data cleaning: (c) aggregating final clean data
-------------------------------------------------------------------------------------------------------------------------------
, data_cleaning_agg_clean_data AS (
  SELECT
      DATETIME_TRUNC(trip_start_local_datetime, HOUR) AS trip_start_local_datehour
    , COUNT(DISTINCT unique_key) AS trip_cnt
    , COUNT(DISTINCT taxi_id) AS taxi_cnt
    FROM clean_data
    GROUP BY trip_start_local_datehour
)
```  

<br>

Calling CTE 8:  
```sql
SELECT COUNT(*) FROM data_cleaning_agg_clean_data
```  
![when-riders-meet-drivers---sql---cte-8---query-results](https://user-images.githubusercontent.com/58894233/232666971-556439d3-41f5-4209-ae00-c2ee9f92c514.png)

<br>

### CTE 9 • Data cleaning: checking results from cleaning (iii)

```sql
-------------------------------------------------------------------------------------------------------------------------------
-- CTE 9 • Data cleaning: checking results from cleaning (iii)
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
```  

<br>

Calling CTE 9:  
```sql
SELECT * FROM data_cleaning_results
```  
![when-riders-meet-drivers---sql---cte-9---query-results](https://user-images.githubusercontent.com/58894233/232667001-6a29f4d0-f363-4b6f-beb8-be1450ecd718.png)

<br>

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 4 -->

## Step 4 • Analysis  

In the step of actual analysis, the goal is to generate a list of the hourly levels of supply and demand, with their corresponding time, 
and then pivot it into days of week by hours of the day, for a final picture of a typical weekly schedule of each side.  

The hourly demand for this list is directly obtained from the clean dataset, 
by simply summing up the hourly count of the trips' `unique_key`.  

Hourly values for the supply side, on the other hand, have to be estimated. 

With the relevant **Product Data** available, the hourly supply could be defined as `availability_of_drivers_in_minutes` (total sum) 
multiplied by the `typical_trip_minutes` (duration). As the total time that drivers are in service is not available from our 
<b>[« Chicago Taxi Trips »](https://console.cloud.google.com/marketplace/product/city-of-chicago-public-data/chicago-taxi-trips/)</b> 
dataset, an estimation for it is performed based on the trips taken. 

The supply numbers that can be directly extracted from the dataset are unique taxi counts. Considering that a single taxi may be able to 
take multiple trips in an hour, a model is applied to estimate how many trips each taxi was expected to be able to perform. Taking into 
consideration a factor of [2/3](https://www.uberpeople.net/threads/what-is-your-idle-time-and-idle-running-in-km-as-uber-driver.146607/) 
for the drivers' idle time, an estimated `availability_of_drivers_in_minutes` is obtained directly from trips taken, dividing this number by the 
`drivers_idle_time`.  

##### ⚠️ It is important to notice, though, that using the number of trips actually performed to estimate supply is expected to **flatten out** the difference between supply and demand that shall, in fact, occur. So, any potential gains found out in this study are expected to be observed at a higher intensity if product data is available foor the analysis. The framework of the analysis is independent of it, and fully applicable in a business scenario.  

CTEs 10 e 11 combined perform the described approach, fetching an hourly list of 89k+ records from Dec 2012 to Apr 2023:  

<br>

### CTE 10 • Data analysis: typical duration of trips, according to clean data

```sql
-------------------------------------------------------------------------------------------------------------------------------
-- CTE 10 • Data analysis: typical duration of trips, according to clean data
-------------------------------------------------------------------------------------------------------------------------------
, typical_trip_seconds AS 
  (SELECT APPROX_QUANTILES(trip_seconds, 4)[OFFSET(1)] AS median_trip_seconds FROM clean_data)
)
```  

<br>

### CTE 11 • Data analysis: hourly count of trips (demand) + (estimated) Hourly count of possible trips (supply)

```sql
-------------------------------------------------------------------------------------------------------------------------------
-- CTE 11 • Data analysis: hourly count of trips (demand) + (estimated) Hourly count of possible trips (supply)
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
```  

<br>

Calling CTE 11:  
```sql
SELECT * FROM hourly_supply_demand ORDER BY 1
```  

![when-riders-meet-drivers---sql---cte-11a---query-results](https://user-images.githubusercontent.com/58894233/232925819-594d12de-d8ff-438b-bb58-88933e16a2a8.png)  

<br>

The generated list is in a convenient format to be pivoted on a spreadsheet. Making use of the convenient feature of saving directly from the cloud console, the 
results were exported to Google Sheets:  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---1](https://user-images.githubusercontent.com/58894233/232926033-77ee1e51-f8a7-49c6-befc-ace2a99157cb.png)  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---2](https://user-images.githubusercontent.com/58894233/232926253-f73a9c5d-3427-4397-9010-12e1908df104.png)  

<br>

On Google Sheets, generating a pivot table is a fast way to arrange the data in the wanted format: hours of day x days of week.  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---3](https://user-images.githubusercontent.com/58894233/232926563-8edfd33f-9a35-4f35-93c0-4dad9dbe7154.png)  

<br>

For supply:  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---5-Supply](https://user-images.githubusercontent.com/58894233/232926674-be728343-5210-4986-bcc7-b07a56c1b1db.png)  

<br>

For demand:  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---4-Demand](https://user-images.githubusercontent.com/58894233/232926582-af61a09b-91b5-4a5c-ac37-04019bb91023.png)  

<br>

Showing the tables for supply and demand side-by-side enables the comparison of the typical schedules of passengers and drivers:  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---6-Supply-Demand-1](https://user-images.githubusercontent.com/58894233/232929528-e36d5fa1-0f3e-415d-9df3-c8245c9f2bb9.png)

<br>

⚠️ As mentioned [above](data-analysis.md#%EF%B8%8F-it-is-important-to-notice-though-that-using-the-number-of-trips-actually-performed-to-estimate-supply-is-expected-to-flatten-out-the-difference-between-supply-and-demand-that-shall-in-fact-occur-so-any-potential-gains-found-out-in-this-study-are-expected-to-be-observed-at-a-higher-intensity-if-product-data-is-available-foor-the-analysis-the-framework-of-the-analysis-is-independent-of-it-and-fully-applicable-in-a-business-scenario), the difference between the organic schedules of supply and demand have been toned down here by the fact that demand has been included in the estimation of demand. It is though possible, from the chosen data and the designed framework, to detect opportunities of increasing the synchonicity between schedules of the different sides of the marketplace.  

The darker red area close to the right bottom of the demand side indicates a possible trend of passengers' behavior on weekend nights not being organically met by the supply side.  

Similarly, an added availability of drivers in the early mornings of week days is found to have no correspondent proportional increase from the demand side.  

From this point, it is possible to further summarize data in a single piece, converting it into a visualization that emphasizes the most critical points, when the highest imbalance between supply and demand occurs. For convenience, the trigger to sign action may be defined as entry parameters, as follows:

1. Look at seasonality of Supply and seasonality of Demand  
2. Calculate typical % ditributions  
3. Scale % distribution of volumes to a [0,1] interval  
4. Calculate the difference between the scaled Supply and Demand distributions  
5. Highlight action items  

### 1. Look at seasonality of Supply and seasonality of Demand  
![when-riders-meet-drivers---1](https://user-images.githubusercontent.com/58894233/233520599-1bd332d9-3047-454d-91e6-16f105737f31.png)

### 2. Calculate typical % ditributions  
![when-riders-meet-drivers---2](https://user-images.githubusercontent.com/58894233/233520615-ab850161-1cbd-43ed-972a-26c6911b3f8e.png)
![when-riders-meet-drivers---2a](https://user-images.githubusercontent.com/58894233/233520647-4c6efdc1-584e-44ca-b796-110c5cee92fd.png)

### 3. Scale % distribution of volumes to a [0,1] interval  
![when-riders-meet-drivers---3](https://user-images.githubusercontent.com/58894233/233520659-3fa465fd-bc46-4ee4-9102-dd7fae62a438.png)

### 4. Calculate the difference between the scaled Supply and Demand distributions  
![when-riders-meet-drivers---4](https://user-images.githubusercontent.com/58894233/233520678-e39c8b48-9f36-4804-b930-ac2c94192193.png)

### 5. Highlight action items  
![when-riders-meet-drivers---5](https://user-images.githubusercontent.com/58894233/233520691-07d617bb-1d0f-4338-8482-e422c272afb5.png)

<br>

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 5 -->

## Step 5 • Synthesis  

Being in charge of the **operation of a marketplace** is a challenging task, loaded with **even greater levels of uncertainty** than those natural to any business, as, in this case, in addition to the lack of control over the demand side, there is also no control over the supply side.  

The study presented in this repository introduces a **framework** for applying the concept of **seasonality** in navigating and managing such unusual levels of uncertainty. Seasonality arises when repeated events occur following a defined temporal pattern, with a fixed frequency, drawing foreseeable cycles and, thus, **introducing predictability** into a system.  

By carrying out seasonality studies, we can separate into conceptual 'buckets' of knowledge what we can anticipate about a system from its erractic part. When it comes to **consumer markets**, seasonality includes some pretty **robust** and consistently **stable patterns of behavior**, especially those related to nature's cycles. For thousands of years, we humankind have been mostly active during the day, resting during the night.

This **stability** in end-user seasonal patterns comes in handy for **Strategy** teams in the quest to design products and services to improve lives.  

The figure below illustrates the application of seasonality studies to the ride-hailing business (approximate here by the Chicago Taxi market, for which public data is available). On the left, we see the typical weekly schedule of drivers (supply), on the right, the same for passengers (demand). In each image, the numbers on the vertical axis are the hours of the day, with the days of week in the columns. Color coding represents relative intensity, with green for low, white for medium, and red for high. So, the image on the left side, for instance, shows that the peak supply time, when there is the highest number of drivers on the streets, is from 1:00 pm to 2:00 pm on Fridays.  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---6-Supply-Demand-5](https://user-images.githubusercontent.com/58894233/232947737-88196b46-292c-4045-ae83-a6ed45d6457e.png)  

<br>

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->

