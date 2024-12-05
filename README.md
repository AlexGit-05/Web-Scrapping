# Web Scraping

## 🌐 **Introduction to Web Scraping**

**Web Scraping** is the process of extracting information from websites by programmatically parsing the HTML content of web pages. It is commonly used for tasks like gathering data for analysis, monitoring website changes, and automating repetitive data collection processes. 

### 🔗 **Why Web Scraping?**
- **Efficiency**: Automates the collection of large amounts of data.  
- **Real-Time Updates**: Ensures access to the latest information from dynamic web pages.  
- **Customizability**: Extracts only the specific information you need.  

### 💻 **Web Scraping in Python**
Python is a popular choice for web scraping due to its ease of use and extensive library support:
- **`requests`**: Sends HTTP requests to fetch the webpage content.  
- **`BeautifulSoup`**: Parses and extracts HTML or XML data.  
- **`selenium`**: Automates browser interactions for scraping dynamic websites.  

### 🧑‍💻 **Web Scraping with R**
R is often used for data analysis and visualization but also supports web scraping via:
- **`rvest`**: Simplifies the extraction of web data.
- **`httr`**: Helps handle HTTP requests.
- **`xml2`**: Parses HTML or XML documents for data extraction.  
R is particularly suited for projects requiring statistical modeling or visualization of scraped data.

---

## Web Scraping Repository for KenyaLaw Gazette Notifications

## 📜 Overview

This repository contains a Python script designed to automate the process of scraping the **KenyaLaw** website for the latest **Gazette Notices**, uploading the notices to a database, and notifying recipients via email whenever a new Gazette has been uploaded. 

### 🔍 **Key Features**
- **Web Scraping**: Scrapes the latest Gazette Notices from the **KenyaLaw** website.
- **Database Upload**: Uploads the extracted data into a database (e.g., MySQL, SQLite).
- **Email Notification**: Sends an email notification to a predefined list of recipients when a new Gazette is uploaded.

## 💻 **How It Works**

1. **Web Scraping**:  
   The Python script uses the `requests` library to fetch the webpage containing the latest Gazette Notices. It then parses the HTML content using `BeautifulSoup` to extract the relevant information (e.g., Gazette title, publication date, etc.).

2. **Database Upload**:  
   After scraping, the latest Gazette details are uploaded to a database using the `SQLAlchemy` ORM. The data is stored in a structured table for future reference or querying.

3. **Email Notification**:  
   When a new Gazette Notice is uploaded to the database, the script automatically triggers an email notification to recipients using the `smtplib` library, ensuring that stakeholders are promptly informed about new uploads.

---

## ⚙️ **Technologies & Libraries Used**

- **Python**:
   - `requests`: For sending HTTP requests to scrape the webpage.
   - `BeautifulSoup`: For parsing HTML and extracting relevant information.
   - `SQLAlchemy`: For interacting with the database and storing scraped data.
   - `smtplib`: For sending email notifications.
   - `pandas`: For managing data and integrating with the database.
   
- **Database**:
   - Supports both **MySQL**.

---

## 🚀 **Installation**

### Python Dependencies:
To install the necessary Python packages, use the following command:
```bash
pip install requests beautifulsoup4 sqlalchemy pandas smtplib
