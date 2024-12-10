library(tidyverse)
library(rvest)
library(purrr)
library(httr)
library(stringr)


## Web Scrapping

### Realtors

# Base URL
base_url = "https://www.realtor.com/apartments/California/type-apartments/"

# Generate URLs for pages 1 to 206
page_urls = lapply(1:206, function(page) {
  if (page == 1) {
    return(base_url)
  } else {
    return(paste0(base_url, "pg-", page))
  }
})

# User Agents
User_Agent = c('User-Agent' = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36")

all_properties = list()

# Loop through each URL
for (url in page_urls) {
  res = GET(url, add_headers(.headers = User_Agent))
  
  if (status_code(res) != 200) next
  
  page = read_html(res)
  
  properties = page %>% 
    html_nodes("div.BasePropertyCard_propertyCardWrap__vNqYA")
  
  for (property in properties) {
    broker = property %>% 
      html_node("div.BrokerTitle_brokerTitle__8GOyr") %>% 
      html_text(trim = TRUE)
    price = property %>% 
      html_node("div[data-testid='card-price']") %>% 
      html_text(trim = TRUE)
    bedroom = property %>% 
      html_node("li[data-testid='property-meta-beds']") %>% 
      html_text(trim = TRUE)
    bathrooms = property %>% 
      html_node("li[data-testid='property-meta-baths']") %>% 
      html_text(trim = TRUE)
    square_ft = property %>% 
      html_node("li[data-testid='property-meta-sqft']") %>% 
      html_text(trim = TRUE)
    address = property %>% 
      html_node("div[data-testid='card-address-1']") %>% 
      html_text(trim = TRUE)
    
    street_city_state = property %>% 
      html_node("div[data-testid='card-address-2']") %>% 
      html_text(trim = TRUE) %>% 
      str_split(", ")
    
    street = NA
    city = NA
    state = NA
    
    # Check the length and assign accordingly
    if (length(street_city_state[[1]]) == 3) {
      street = street_city_state[[1]][1]
      city = street_city_state[[1]][2]
      state = street_city_state[[1]][3]
    } else if (length(street_city_state[[1]]) == 2) {
      city = street_city_state[[1]][1]
      state = street_city_state[[1]][2]
    } else if (length(street_city_state[[1]]) == 1) {
      state = street_city_state[[1]][1]
    }
    
    # Create a property data frame
    property_data = data.frame(Broker = broker, 
                               Price = price, 
                               Bedroom = bedroom, 
                               Bathrooms = bathrooms, 
                               SquareFt = square_ft, 
                               Address = address, 
                               Street = street, 
                               City = city, 
                               State = state, 
                               stringsAsFactors = FALSE)
    
    # Append each property's data to all_properties
    all_properties = append(all_properties, list(property_data))
  }
}

# Combine all property data into one DataFrame
final_data = do.call(rbind, all_properties)

# Remove rows where all values are NA
final_data = final_data[rowSums(is.na(final_data)) != ncol(final_data), ]

# View the final DataFrame
final_data

#Saving the file locally
write.csv(final_data, "Realtor.csv")


### For Rent by Owner

# Base URL
base_url = "https://www.forrentbyowner.com/?showpage=/classifieds/&f=Apartment,%20CA"

# Generate URLs for pages 1 to 1000
page_urls = lapply(1:1000, function(page) {
  if (page == 1) {
    return(base_url)
  } else {
    return(paste0(base_url, "&pg=", page)) # Adjusted for correct pagination
  }
})

# User Agent
User_Agent = c('User-Agent' = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36")

all_properties = list()

# Loop through each URL
for (url in page_urls) {
  res = GET(url, add_headers(.headers = User_Agent))
  
  if (status_code(res) != 200) next
  
  page = read_html(res)
  
  properties = page %>%
    html_nodes("div.uk-width-expand.uk-padding-remove-horizontal.mob-margin") 
  
  for (property in properties) {
    price = property %>%
      html_node("div.list-price b.list-price") %>%
      html_text(trim = TRUE) %>% na_if("") %>% replace_na(NA)
    
    rental_type = property %>%
      html_node("span.rent_type") %>%
      html_text(trim = TRUE) %>% na_if("") %>% replace_na(NA)
    
    bedrooms = property %>%
      html_node("ul.listing-details li:nth-child(1)") %>%
      html_text(trim = TRUE) %>% na_if("") %>% replace_na(NA)
    
    bathrooms = property %>%
      html_node("ul.listing-details li:nth-child(2)") %>%
      html_text(trim = TRUE) %>% na_if("") %>% replace_na(NA)
    
    square_feet = property %>%
      html_node("ul.listing-details li:nth-child(3)") %>%
      html_text(trim = TRUE) %>% na_if("") %>% replace_na(NA)
    
    address = property %>%
      html_node("p.uk-text-meta") %>%
      html_text(trim = TRUE) %>% na_if("") %>% replace_na(NA)
    
    # Split address into Street, City, and State
    address_parts = str_split(address, ", ") %>% unlist()
    street = ifelse(length(address_parts) >= 1, address_parts[1], NA)
    city = ifelse(length(address_parts) >= 2, address_parts[2], NA)
    state = ifelse(length(address_parts) >= 3, address_parts[3], NA)
    
    # Combine into a data frame
    property_data = data.frame(Price = price, RentalType = rental_type, Bedrooms = bedrooms, Bathrooms = bathrooms, SquareFeet = square_feet, Street = street, City = city, State = state)
    
    all_properties = append(all_properties, list(property_data))
  }
}

# Convert the list to a data frame
final_data_1 = do.call(rbind, all_properties)

# View the final DataFrame
final_data_1 %>% head()

#Saving the file locally
write.csv(final_data_1, "Final Data.csv")



### Cleaning real_data Realtor
## Dropping variables
realtor_data <- realtor_data[, !(names(realtor_data) %in% c("X","Broker", "Address"))]

# Split Rows with '-' in Price, Bedrooms, Bathrooms, and SquareFeet
split_and_expand_rows <- function(df) {
  rows_list <- list()
  for (i in 1:nrow(df)) {
    row <- df[i, ]
    prices <- strsplit(as.character(row$Price), " - ")[[1]]
    bedrooms <- strsplit(as.character(row$Bedroom), " - ")[[1]]
    bathrooms <- strsplit(as.character(row$Bathrooms), " - ")[[1]]
    squarefts <- strsplit(gsub("sqft.*", "", as.character(row$SquareFt)), " - ")[[1]]
    
    max_length <- max(length(prices), length(bedrooms), length(bathrooms), length(squarefts))
    prices <- rep(prices, length.out = max_length)
    bedrooms <- rep(bedrooms, length.out = max_length)
    bathrooms <- rep(bathrooms, length.out = max_length)
    squarefts <- rep(squarefts, length.out = max_length)
    
    for (j in 1:max_length) {
      row_expanded <- row
      row_expanded$Price <- prices[j]
      row_expanded$Bedroom <- bedrooms[j]
      row_expanded$Bathrooms <- bathrooms[j]
      row_expanded$SquareFt <- squarefts[j]
      rows_list[[length(rows_list) + 1]] <- row_expanded
    }
  }
  do.call("rbind", rows_list)
}

realtor_data <- split_and_expand_rows(realtor_data)

# Remove 'Studio' and Clean the Numeric Columns

realtor_data <- realtor_data %>%
  # Remove 'Studio'
  filter(!grepl("Studio", Bedroom)) %>%
  # Cleaning and converting to numeric
  mutate(
    Price = as.numeric(gsub("[$,]", "", Price)),
    Bedroom = as.numeric(gsub("bed", "", Bedroom)),
    Bathrooms = as.numeric(gsub("bath", "", Bathrooms)),
    SquareFt = as.numeric(gsub("[^0-9]", "", SquareFt))
  )

names(realtor_data)[c(2,4)] = c("Bedrooms","SquareFeet")

realtor_data %>% head()


## Cleaning real_data 


# Checking if all the houses are apartments 
For_rent$RentalType %>% unique()

## Dropping variables
For_rent <- For_rent[, !(names(For_rent) %in% c("RentalType"))]

# Remove rows where Square Feet is '0 sqft'
For_rent <- For_rent %>% 
  mutate(SquareFeet = ifelse(SquareFeet == "0 sqft", NA, SquareFeet))

# Remove unwanted characters from Price, Bedrooms, Bathrooms, and Square Feet
For_rent <- For_rent %>%
  mutate(
    Price = as.numeric(gsub("[^0-9]", "", Price)),
    Bedrooms = as.numeric(gsub(" bds?", "", Bedrooms)),
    Bathrooms = as.numeric(gsub(" ba", "", Bathrooms)),
    SquareFeet = as.numeric(gsub(" sqft", "", SquareFeet))
  )

For_rent %>% head()

names(For_rent)
