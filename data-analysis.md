<head><base target="_blank"></head>  

# 🚖 when-riders-meet-drivers  • Data Analysis Process
<b>Seasonality of supply vs seasonality of demand in ride-hailing.  </b>

This repository details the steps of the process of a quick data analysis with the aim of understanding the matching and contrasting points in the daily and weekly seasonality of the different sides of a ride-hailing marketplace. The full `sql` code is available [here](when-riders-meet-drivers.sql).  

Tags: `product-analytics`, `sql`, `bigquery`.

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Contents -->

## Contents  

[Step 1 • Business Question](data-analysis.md#step-1--business-question)  
[Step 2 • Data Collection](data-analysis.md#step-2--data-collection)  
[Step 3 • Data Cleaning](data-analysis.md#step-3--data-cleaning)  
[Step 4 • Analysis](data-analysis.md#step-4--analysis)  
[Step 5 • Synthesis](data-analysis.md#step-5--synthesis)  

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Query Structure -->

## Query Structure  

[CTE 1 • Data collection: fetching data from the original table](data-analysis.md#cte-1--data-collection-fetching-data-from-the-original-table)  
[CTE 2 • Data cleaning: (a) finding interquartile ranges (IQR) of trip_seconds]()  
[CTE 3 • Data cleaning: (i) converting from UTC to Chicago Time, (ii) Excluding outliers: duration (trip_seconds)]()  
[CTE 4 • Data cleaning: checking results from cleaning (i) + (ii)]()  
[CTE 5 • Data cleaning: (b) aggregating partially clean data, preparing to exclude extreme hours (esp. peaks)]()  
[CTE 6 • Data cleaning: (c) finding interquartile ranges (IQR) of trip_cnt, taxi_cnt]()  
[CTE 7 • Data cleaning: (iii) based on trip_cnt, taxi_cnt, remove extreme hours from pre-cleaned (i)+(ii) data]()  
[CTE 8 • Data cleaning: (c) aggregating final clean data]()  
[CTE 9 • Data cleaning: checking results from cleaning (iii)]()  
[]()  
[]()  
[]()  
[]()  
[]()  
[]()  

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 1 -->

## Step 1 • Business Question  

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

## Step 2 • Data Collection  

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

Inspecting the `taxi_trips` table schema reeaveals that the fields needed for a quick study are available in it:
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
<br>
Query results:  <br><br>  

![when-riders-meet-drivers---sql---cte-1---query-results](https://user-images.githubusercontent.com/58894233/232664865-1c57e472-21c0-4cae-9e42-a8f8aafb59c5.png)

<br>

The other CTEs are gradually introduced below, in their respective step, and the full `sql` code is available [here](when-riders-meet-drivers.sql).  

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 3 -->

## Step 3 • Data Cleaning  

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
<br>
Query results:  <br><br>  

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
<br>
Query results:  <br><br>  

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
<br>
Query results:  <br><br>  

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
<br>
Query results:  <br><br>  

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
<br>
Query results:  <br><br>  

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
<br>
Query results:  <br><br>  

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
<br>
Query results:  <br><br>  

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
<br>
Query results:  <br><br>  

![when-riders-meet-drivers---sql---cte-9---query-results](https://user-images.githubusercontent.com/58894233/232667001-6a29f4d0-f363-4b6f-beb8-be1450ecd718.png)

<br>

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 4 -->

## Step 4 • Analysis  

(very soon! anticipated for 2023-04-18)  

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 5 -->

## Step 5 • Synthesis  

(very soon! anticipated for 2023-04-18)  

[↑](data-analysis.md#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->

