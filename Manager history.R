#This program defines a function count_managers that takes the data frame, 
#FundID, and date as input and returns the number of managers employed at the 
#given FundID on the given date. The function works by first filtering the 
#data frame for the given FundID, then splitting the manager history into 
#separate rows, then filtering the managers who were employed on the given 
#date, and finally counting the number of rows.

# Load the required packages
library(readxl)
library(tidyverse)
library(lubridate)

# Read in the data
df = read_excel("Manager History-1.xlsx")
df = df[which(is.na(df$`Manager History`)==F),]

# Define a function to count the number of managers for a given date and FundID
count_managers = function(Data, Fund_id,date) {
  # Select a Fund
  fundid=Data %>% filter(FundId == Fund_id)
  # Split the manager history into a list of strings
  managerhist_li=strsplit(fundid$`Manager History`, ";")
  # Unlist manager history into a vector and
  # Convert the list of strings to separate rows
  managerhist_unli=data.frame(history=unlist(managerhist_li))
  # Split the manager history into separate columns
  new_df=managerhist_unli %>% separate(history,
                  into = c("start_date", "manager_name"),sep = "] ")
  new_df=separate(data = new_df,col = start_date,
                  into = c("start_date", "end_date"),sep = " -- ")
  # Convert the dates to the date type
  new_df1=new_df %>% 
    mutate(start_date = ymd(start_date), end_date = ymd(end_date))
  # Converting NA end date to still continuing to date
  new_df1[which(is.na(new_df1$end_date)==T),"end_date"]=Sys.Date()
  # Filter the managers who were employed on the given date
  new_df1 %>% 
    filter(start_date <= date, end_date >= date) %>% 
    # Count the number of rows, which is the number of managers
    nrow()
}


#Example
count_managers(df, "FS00008M0G", "2012-11-3")

results

###############################################################################
#You can use this function in a loop to compute the number of managers for 
#each FundID and date. Here's an example of how to do this:

# Define a vector of dates
dates = seq(ymd("2000-01-01"), ymd(Sys.Date()), by = "month")

# Define a vector of FundIDs
fund_ids = unique(df$FundId)[1:2000]

# Loop over all FundIDs and dates and compute the number of managers
a=Sys.time()
results1 = expand.grid(FundId = fund_ids, Date = dates) %>% 
  mutate(Managers = map2_dbl(FundId,Date,count_managers,Data=df))
b=Sys.time() 
difftime(b,a)

results1 = results1 %>% spread(Date,Managers)
  
results=rbind(results1,results2,results3,results4)

write.csv(results,file = "Managers History.csv")
