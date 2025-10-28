Cyclistic Bike-Share Analysis 🚴‍♂️

## Project Overview
Analysis of Cyclistic bike-share data to understand behavioral differences between annual members and casual riders, supporting marketing strategies to convert casual riders into members.

## Business Question
**How do annual members and casual riders use Cyclistic bikes differently?**

## Key Findings
- Casual riders take **2-3x longer trips** than annual members (30-42 min vs 13-15 min)
- Casual riders show **increased usage on weekends** (leisure/recreational pattern)
- Members maintain **consistent ride patterns** throughout the week (commuting behavior)

## Dataset
- **Source**: Divvy Bikes (Chicago) historical trip data
- **Time Period**: Q1 2019 & Q1 2020
- **Total Rides Analyzed**: ~792,000 trips
- **License**: Data made available by Motivate International Inc.

## Tools & Technologies
- **R** (tidyverse, lubridate, ggplot2, scales, janitor)
- **RStudio** for analysis and visualization
- **Git/GitHub** for version control

## Project Structure
```
cyclistic-bike-share-analysis/
├── data/                    # Raw and processed data files
├── scripts/                 # R analysis scripts
├── visualizations/          # Generated charts and graphs
├── reports/                 # Final presentation and documentation
└── README.md               # Project documentation
```

## Key Visualizations
1. **Ride Volume by Day & User Type** - Shows distribution of rides
2. **Average Duration Comparison** - Highlights the 2-3x difference
3. **Weekend vs Weekday Analysis** - Reveals leisure vs commute patterns
4. **Ride Duration Distribution** - Shows usage pattern shapes
5. **Market Share Analysis** - Member vs casual rider proportions

## Recommendations
1. **Weekend Warrior Campaign** - Target recreational weekend riders with specialized messaging
2. **Cost Savings Calculator** - Demonstrate savings for longer rides to casual users
3. **Seasonal Trial Program** - Reduce commitment barrier with trial memberships

## Installation & Usage

### Prerequisites
```r
install.packages(c("tidyverse", "lubridate", "janitor", "scales"))
```

### Running the Analysis
```r
# 1. Set your working directory
setwd("path/to/cyclistic-bike-share-analysis")

# 2. Run data cleaning and analysis
source("scripts/01_data_cleaning.R")

# 3. Generate visualizations
source("scripts/02_visualizations.R")
```

## Results
- **Primary Insight**: Different usage patterns require different marketing approaches
- **Casual Rider Opportunity**: High-value conversion potential due to longer trip durations
- **Strategic Focus**: Weekend-oriented digital campaigns with cost-savings messaging

## Future Analysis
- Expand to full year data for seasonal patterns
- Hourly usage analysis to distinguish commute vs leisure times
- Popular route/station analysis for targeted campaigns
- Demographic analysis (if data becomes available)

## Author
**Spencer Zubal**
- GitHub: [@szubal311](https://github.com/szubal311)

## License
This project is for educational/portfolio purposes. Data used under license from Motivate International Inc.

## Acknowledgments
- **Google Data Analytics Professional Certificate** - Case study framework
- **Divvy Bikes** - Data provider
- **Cyclistic Team** (fictional) - Business scenario
## Project Structure
