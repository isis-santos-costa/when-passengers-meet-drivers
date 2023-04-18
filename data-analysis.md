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

#

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
--------------------------------------------------------------------------------------------------------------------------
-- CTE 1 • Data collection: fetching data from the original table
--------------------------------------------------------------------------------------------------------------------------
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

The other CTEs are gradually introduced below, in their respective step, and the full `sql` code is available [here](when-riders-meet-drivers.sql).  

[↑](data-analysis.md#contents)

#

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 3 -->

## Step 3 • Data Cleaning  

(very soon! anticipated for 2023-04-18)  

[↑](data-analysis.md#contents)

#

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 4 -->

## Step 4 • Analysis  

(very soon! anticipated for 2023-04-18)  

[↑](data-analysis.md#contents)

#

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 5 -->

## Step 5 • Synthesis  

(very soon! anticipated for 2023-04-18)  

[↑](data-analysis.md#contents)

#

<!---------------------------------------------------------------------------------------------------------------------------------------->

___

