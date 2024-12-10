# 🏠 Web Scraping Repository

![Language](https://img.shields.io/badge/Language-R-blue)

## 🔍 Overview
This repository contains scripts for web scraping rental property data from **Realtor.com** and **For Rent by Owner**. The data includes property details like price, bedrooms, bathrooms, square footage, and location. The scripts are written in R using libraries like `tidyverse`, `rvest`, `purrr`, and `httr`.

---

## ✨ Features

- **Realtor.com Scraper**:
  - Collects apartment rental data from Realtor.com for California.
  - Scrapes details like price, bedrooms, bathrooms, square footage, and address.
  - Parses address into street, city, and state components.
  - Cleans and processes the scraped data for analysis.

- **For Rent by Owner Scraper**:
  - Collects apartment rental data from ForRentByOwner.com.
  - Scrapes details like price, rental type, bedrooms, bathrooms, square footage, and address.
  - Cleans and processes data for further use.

---

## 🛠️ Requirements

- **R Libraries**:
  - `tidyverse`
  - `rvest`
  - `purrr`
  - `httr`
  - `stringr`

---

## 🧹 Data Cleaning

### Realtor Data Cleaning
- **Dropped Columns**: 
  - `Broker`, `Address`, and any unnecessary metadata.
- **Row Expansion**:
  - Handles ranges in `Price`, `Bedrooms`, `Bathrooms`, and `Square Feet` by splitting into separate rows.
- **Numeric Conversion**:
  - Converts text fields to numeric for easier analysis.
- **Removed Studio Apartments**:
  - Excludes entries labeled as "Studio."

### For Rent Data Cleaning
- **Rental Type Check**:
  - Filters data to include only apartment rentals.
- **Dropped Columns**:
  - Removes the `RentalType` column after verification.
- **Removed Invalid Entries**:
  - Excludes entries with `0 sqft` in square footage.
- **Data Cleaning**:
  - Converts price, bedrooms, bathrooms, and square footage fields to numeric.

---

## 📊 Outputs

- **Dataframes**:
  - Cleaned data for both Realtor.com and For Rent by Owner is stored as R DataFrames.
- **Saved Files**:
  - Realtor data is saved as `Realtor.csv`.
  - For Rent data is saved as `Final Data.csv`.

---
