<!-- [![Stars](https://img.shields.io/github/stars/isis-santos-costa/when-riders-meet-drivers?style=social)](https://github.com/isis-santos-costa/when-riders-meet-drivers/)  -->
<!--  
[![lines of code](https://img.shields.io/tokei/lines/github/isis-santos-costa/when-riders-meet-drivers?color=purple)](https://github.com/isis-santos-costa/when-riders-meet-drivers/) -->
<!-- [![files](https://img.shields.io/github/directory-file-count/isis-santos-costa/when-riders-meet-drivers?color=lightgrey)](https://github.com/isis-santos-costa/when-riders-meet-drivers/) -->
<!-- 
[![contributors](https://img.shields.io/github/contributors/isis-santos-costa/when-riders-meet-drivers?color=lightgrey)](https://www.linkedin.com/in/isis-santos-costa/) -->

[![pull requests](https://img.shields.io/github/issues-pr-closed/isis-santos-costa/when-riders-meet-drivers?color=brightgreen)](https://github.com/isis-santos-costa/when-riders-meet-drivers/pulls?q=is%3Apr)
[![commit activity](https://img.shields.io/github/commit-activity/y/isis-santos-costa/when-riders-meet-drivers)](https://github.com/isis-santos-costa/when-riders-meet-drivers/)
[![Data Analyst](https://img.shields.io/badge/%20data%20analyst-%E2%98%95-purple)](https://www.linkedin.com/in/isis-santos-costa/)   

<!-- <div id="user-content-toc"><ul><summary><h2 style="display: inline-block;">💹 when-riders-meet-drivers • Creating predictability to GROW REVENUE</h2></summary></ul></div> -->

# When Riders Meet Drivers
💹 __*Seasonal patterns as a lever to GROW REVENUE in the ride-hailing business • 2023*__

This repository presents how **sharing predictability with partners** can convert into revenue in the ride-hailing business. Predictability here is derived from seasonal patterns at the matching and contrasting points in the daily and weekly seasonality of the different sides of a ride-hailing marketplace.  

A summary of results is presented below.  
The full analysis (business question, data collection & cleaning, analysis & synthesis) is available **[here](data-analysis.md)**.  
The SQL code ran in the study is available [here](when-riders-meet-drivers.sql), and on [BigQuery](https://console.cloud.google.com/bigquery?sq=547152705700:2c2438efe4534dfab31839bfa6bdb742).  

Tags: `product-analytics`, `sql`, `bigquery`.  

___

<!-- -------------------------------------------------------------------------------------------------------------------------------------->
<!-- Intro -->
**What is the mission of a marketplace?**  
A marketplace dedicates to making supply meet demand. This mission usually comes with some added requirements, of lesser or greater importance depending on the market that it serves, which may require or value safety, timeliness, accuracy, quality.  

This repository is part of a study on **ride-hailing** marketplaces. In that field of business, **timeliness** is key. Focusing on the issue, **a data visualization prototype is presented here**, designed to bring to light the points of correspondence and contrast in the daily and weekly schedules of the different sides of a ride-hailing app.  

Specifically, the search is for insights on the following questions:  

> <i> « Are there any significant differences between preferred drivers' schedules and passengers' needs? » </i>  
> <i> « If so, when do the most critical disparities occur? » </i> 

Given that ride-hailing data is kept confidential by businesses, the supply-demand dynamics of a city-hall regulated taxi market is taken as an approximation, for which data is available from Google BigQuery public datasets.

[↑](#when-riders-meet-drivers)   

___

<!-- ----------------------------------------------------------------------------------------------------------------------------------- -->
<!-- Operational tool ⇒ Supply-demand synchronicity -->

## Operational Tool &nbsp; ⇒ &nbsp; Supply-Demand Synchronicity  

Seasonality studies applied to the ride-hailing business are illustrated in the figure below (approximate here by the Chicago Taxi market, for which public data is available). On the left, we see the typical **weekly schedule of drivers (supply)**. On the right, the same is presented for **passengers (demand)**. In each image, the numbers on the vertical axis are the hours of the day, with the days of week in the columns. Color coding represents relative intensity, with green for low, white for medium, and red for high. So, the image on the left side, for instance, shows that the peak supply time, when there is the highest number of drivers on the streets, is from 1:00 pm to 2:00 pm on Fridays.  

![when-riders-meet-drivers---sql---cte-11---to-G-Sheets---6-Supply-Demand-5](https://user-images.githubusercontent.com/58894233/232947737-88196b46-292c-4045-ae83-a6ed45d6457e.png)  
  
Combining both sides — supply and demand — into a single net surplus figure, and attaching to it a table summarizing estimated results of **planned operations scenarios**, provides a practical **Action Board**, such as the one below:

![when-riders-meet-drivers---1---action-board](https://github.com/isis-santos-costa/when-riders-meet-drivers/assets/58894233/fd77eef6-3c3d-4815-96fe-f3906e831380)  

[↑](#when-riders-meet-drivers)   

___

<!-- ----------------------------------------------------------------------------------------------------------------------------------- -->
<!-- Data Analysis -->

## Data Analysis  

The full data analysis (business question, data collection & cleaning, analysis & synthesis) is available **[here](data-analysis.md)**.  
The SQL code ran in the study is available [here](when-riders-meet-drivers.sql), and on [BigQuery](https://console.cloud.google.com/bigquery?sq=547152705700:2c2438efe4534dfab31839bfa6bdb742).  

[↑](#when-riders-meet-drivers)   

___

