# ==============================
# 🚲 Divvy Ride Data Processing
# ==============================

# --- Load Required Libraries ---
library(tidyverse)
library(lubridate)
library(janitor)
library(scales)

# --- Resolve function conflicts (optional but safe) ---
conflicted::conflict_prefer("filter", "dplyr")
conflicted::conflict_prefer("lag", "dplyr")

# --- 1. Import Raw Data ---
q1_2019 <- read_csv("Divvy_Trips_2019_Q1.csv")
q1_2020 <- read_csv("Divvy_Trips_2020_Q1.csv", col_types = cols(.default = "c"))

# --- 2. Clean and Align 2019 Data ---
q1_2019_clean <- q1_2019 %>%
  rename(
    ride_id = trip_id,
    rideable_type = bikeid,
    started_at = start_time,
    ended_at = end_time,
    start_station_id = from_station_id,
    start_station_name = from_station_name,
    end_station_id = to_station_id,
    end_station_name = to_station_name,
    member_casual = usertype
  ) %>%
  mutate(
    started_at = mdy_hm(started_at),
    ended_at = mdy_hm(ended_at),
    member_casual = ifelse(member_casual == "Subscriber", "member", "casual"),
    rideable_type = "docked_bike",
    ride_length = as.numeric(difftime(ended_at, started_at, units = "secs")),
    start_lat = NA, start_lng = NA, end_lat = NA, end_lng = NA
  ) %>%
  select(
    ride_id, rideable_type, started_at, ended_at,
    start_station_name, start_station_id,
    end_station_name, end_station_id,
    start_lat, start_lng, end_lat, end_lng,
    member_casual, ride_length
  )

# --- 3. Clean 2020 Data ---
q1_2020 <- q1_2020 %>%
  mutate(
    started_at = mdy_hm(started_at, tz = "America/Chicago"),
    ended_at = mdy_hm(ended_at, tz = "America/Chicago"),
    ride_length = as.numeric(difftime(ended_at, started_at, units = "secs"))
  )

# --- 4. Ensure Consistent Data Types ---
id_cols <- c("ride_id", "start_station_id", "end_station_id")

q1_2019_clean <- q1_2019_clean %>%
  mutate(across(all_of(id_cols), as.character))

q1_2020 <- q1_2020 %>%
  mutate(across(all_of(id_cols), as.character))

# --- 5. Combine Datasets ---
all_trips <- bind_rows(q1_2019_clean, q1_2020)

# Remove unused geographic columns
all_trips_v2 <- all_trips %>%
  select(-c(start_lat, start_lng, end_lat, end_lng)) %>%
  filter(ride_length >= 0)

# --- 6. Add Weekday Column ---
all_trips_v2 <- all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE, week_start = 1))  # Monday = 1

# --- 7. Compute Descriptive Ride Statistics ---
ride_stats <- all_trips_v2 %>%
  group_by(member_casual, weekday) %>%
  summarise(
    mean_ride = mean(ride_length, na.rm = TRUE),
    median_ride = median(ride_length, na.rm = TRUE),
    min_ride = min(ride_length, na.rm = TRUE),
    max_ride = max(ride_length, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = c(mean_ride, median_ride, min_ride, max_ride),
    names_to = "stat_type",
    values_to = "ride_length_sec"
  ) %>%
  mutate(ride_length_min = ride_length_sec / 60)  # Convert to minutes

# ==============================
# 📊 Additional Cyclistic Visualizations
# ==============================
# Run these after your main analysis script

library(tidyverse)
library(scales)

# --- VISUALIZATION 1: Total Rides by User Type & Day ---
# Shows volume differences between members and casual riders

ride_volume <- all_trips_v2 %>%
  group_by(member_casual, weekday) %>%
  summarise(total_rides = n(), .groups = "drop")

viz1_volume <- ggplot(ride_volume, aes(x = weekday, y = total_rides, fill = member_casual)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(
    values = c("casual" = "#FF6B6B", "member" = "#4ECDC4"),
    labels = c("Casual Riders", "Annual Members")
  ) +
  labs(
    title = "Total Rides by Day of Week and User Type",
    subtitle = "Q1 2019 & 2020 Combined Data",
    x = "Day of the Week",
    y = "Number of Rides",
    fill = "User Type"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

viz1_volume

# Save the plot
ggsave("viz1_ride_volume.png", viz1_volume, width = 10, height = 6, dpi = 300)

# --- VISUALIZATION 2: Average Ride Length Comparison ---
# Clean comparison of mean ride length

avg_comparison <- all_trips_v2 %>%
  group_by(member_casual, weekday) %>%
  summarise(avg_duration_min = mean(ride_length, na.rm = TRUE) / 60, .groups = "drop")

viz2_avg <- ggplot(avg_comparison, aes(x = weekday, y = avg_duration_min, 
                                       color = member_casual, group = member_casual)) +
  geom_line(size = 1.5, alpha = 0.8) +
  geom_point(size = 3) +
  scale_color_manual(
    values = c("casual" = "#FF6B6B", "member" = "#4ECDC4"),
    labels = c("Casual Riders", "Annual Members")
  ) +
  labs(
    title = "Average Ride Duration by Day of Week",
    subtitle = "Casual riders consistently take longer trips, especially on weekends",
    x = "Day of the Week",
    y = "Average Ride Duration (minutes)",
    color = "User Type"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

viz2_avg

ggsave("viz2_avg_duration.png", viz2_avg, width = 10, height = 6, dpi = 300)

# --- VISUALIZATION 3: Ride Duration Distribution ---
# Histogram showing the shape of usage patterns

# Sample data for performance (use full dataset if your system can handle it)
set.seed(123)
sample_trips <- all_trips_v2 %>%
  filter(ride_length > 0, ride_length < 7200) %>%  # Filter 0-2 hours for clarity
  sample_n(min(50000, n()))

viz3_distribution <- ggplot(sample_trips, aes(x = ride_length / 60, fill = member_casual)) +
  geom_histogram(alpha = 0.6, position = "identity", bins = 50) +
  scale_fill_manual(
    values = c("casual" = "#FF6B6B", "member" = "#4ECDC4"),
    labels = c("Casual Riders", "Annual Members")
  ) +
  scale_x_continuous(breaks = seq(0, 120, 15)) +
  labs(
    title = "Distribution of Ride Durations",
    subtitle = "Most rides are under 60 minutes, but casual riders have longer tail",
    x = "Ride Duration (minutes)",
    y = "Number of Rides",
    fill = "User Type"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top",
    panel.grid.minor = element_blank()
  ) +
  facet_wrap(~member_casual, ncol = 1, scales = "free_y")

viz3_distribution

ggsave("viz3_distribution.png", viz3_distribution, width = 10, height = 8, dpi = 300)

# --- VISUALIZATION 4: Weekend vs Weekday Summary ---
# Simple comparison showing the key insight

weekend_comparison <- all_trips_v2 %>%
  mutate(day_type = ifelse(weekday %in% c("Sat", "Sun"), "Weekend", "Weekday")) %>%
  group_by(member_casual, day_type) %>%
  summarise(
    avg_duration_min = mean(ride_length, na.rm = TRUE) / 60,
    total_rides = n(),
    .groups = "drop"
  )

viz4_weekend <- ggplot(weekend_comparison, aes(x = day_type, y = avg_duration_min, fill = member_casual)) +
  geom_col(position = "dodge", width = 0.7, alpha = 0.8) +
  geom_text(aes(label = round(avg_duration_min, 1)), 
            position = position_dodge(width = 0.7), 
            vjust = -0.5, size = 4, fontface = "bold") +
  scale_fill_manual(
    values = c("casual" = "#FF6B6B", "member" = "#4ECDC4"),
    labels = c("Casual Riders", "Annual Members")
  ) +
  labs(
    title = "Weekend vs Weekday: Average Ride Duration",
    subtitle = "Casual riders show dramatic increase on weekends",
    x = NULL,
    y = "Average Ride Duration (minutes)",
    fill = "User Type"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  ylim(0, max(weekend_comparison$avg_duration_min) * 1.15)

viz4_weekend

ggsave("viz4_weekend_comparison.png", viz4_weekend, width = 10, height = 6, dpi = 300)

# --- VISUALIZATION 5: Ride Volume Percentage ---
# Shows market share by user type

market_share <- all_trips_v2 %>%
  count(member_casual) %>%
  mutate(percentage = n / sum(n) * 100)

viz5_share <- ggplot(market_share, aes(x = "", y = percentage, fill = member_casual)) +
  geom_col(width = 1, color = "white", size = 2) +
  coord_polar("y") +
  scale_fill_manual(
    values = c("casual" = "#FF6B6B", "member" = "#4ECDC4"),
    labels = c("Casual Riders", "Annual Members")
  ) +
  geom_text(aes(label = paste0(round(percentage, 1), "%")), 
            position = position_stack(vjust = 0.5),
            size = 6, fontface = "bold", color = "white") +
  labs(
    title = "Market Share: Members vs Casual Riders",
    subtitle = "Q1 2019-2020 Combined",
    fill = "User Type"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

viz5_share

ggsave("viz5_market_share.png", viz5_share, width = 8, height = 8, dpi = 300)

# --- VISUALIZATION 6: Summary Statistics Table ---
# Create a nice summary table

summary_table <- all_trips_v2 %>%
  group_by(member_casual) %>%
  summarise(
    `Total Rides` = scales::comma(n()),
    `Avg Duration (min)` = round(mean(ride_length, na.rm = TRUE) / 60, 1),
    `Median Duration (min)` = round(median(ride_length, na.rm = TRUE) / 60, 1),
    `Max Duration (min)` = round(max(ride_length, na.rm = TRUE) / 60, 1),
    .groups = "drop"
  ) %>%
  rename(`User Type` = member_casual)

# Print the table
print(summary_table)

# Save as CSV for easy insertion into presentation
write.csv(summary_table, "summary_statistics_table.csv", row.names = FALSE)

# --- BONUS: Create a data summary for presentation ---
presentation_summary <- list(
  total_rides = scales::comma(nrow(all_trips_v2)),
  casual_avg_min = round(mean(all_trips_v2$ride_length[all_trips_v2$member_casual == "casual"], na.rm = TRUE) / 60, 1),
  member_avg_min = round(mean(all_trips_v2$ride_length[all_trips_v2$member_casual == "member"], na.rm = TRUE) / 60, 1),
  casual_pct = round(sum(all_trips_v2$member_casual == "casual") / nrow(all_trips_v2) * 100, 1),
  member_pct = round(sum(all_trips_v2$member_casual == "member") / nrow(all_trips_v2) * 100, 1)
)

cat("\n=== KEY NUMBERS FOR YOUR PRESENTATION ===\n")
cat("Total Rides Analyzed:", presentation_summary$total_rides, "\n")
cat("Casual Rider Avg Duration:", presentation_summary$casual_avg_min, "minutes\n")
cat("Member Avg Duration:", presentation_summary$member_avg_min, "minutes\n")
cat("Casual Riders:", presentation_summary$casual_pct, "% of total rides\n")
cat("Members:", presentation_summary$member_pct, "% of total rides\n")
cat("=========================================\n")

# Save all key numbers
saveRDS(presentation_summary, "presentation_key_numbers.rds")

cat("\n✅ All visualizations created and saved!\n")
cat("📁 Files created:\n")
cat("   - viz1_ride_volume.png\n")
cat("   - viz2_avg_duration.png\n")
cat("   - viz3_distribution.png\n")
cat("   - viz4_weekend_comparison.png\n")
cat("   - viz5_market_share.png\n")
cat("   - summary_statistics_table.csv\n")
cat("   - presentation_key_numbers.rds\n")