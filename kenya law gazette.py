from PyPDF2 import PdfReader
import requests
from bs4 import BeautifulSoup
import pandas as pd
from datetime import datetime
import os
import re
from sqlalchemy import create_engine, MetaData, Table, select
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from sqlalchemy import create_engine
from dotenv import load_dotenv
import base64

# Initialize the parser and read the config file
load_dotenv('config.env')

# Fetch the credentials using uppercase variable names
username = base64.b64decode(os.getenv("USER_NAME")).decode('utf-8')
password = base64.b64decode(os.getenv('PASSWORD')).decode('utf-8')
host = os.getenv("HOST")
port = os.getenv("PORT")

# Define the connection string to the MySQL database using SQLAlchemy
legal = f'mysql+pymysql://{username}:{password}@{host}:{port}/legal'

# Create an SQLAlchemy engine object for connecting to the database
engine = create_engine(legal)


def scrape_kenya_gazettes():
    """
    Scrapes all gazette information from the Kenya Law website for the latest date
    and processes each PDF content.
    
    Returns:
        tuple: Contains (date_string, df)
            - date_string (str): Publication date as string
            - df (pd.DataFrame): DataFrame containing all gazette information
    """
    # Specify url and get initial page
    base_url = "https://new.kenyalaw.org/gazettes/"
    try:
        page = requests.get(base_url)
        page.raise_for_status()
        soup = BeautifulSoup(page.text, 'html.parser')
        
        # Get current year and year page
        year = soup.find(lambda tag: tag.string and tag.string.startswith("20")).get_text()
        url_year = f"{base_url}{year}"
        
        page_year = requests.get(url_year)
        page_year.raise_for_status()
        soup = BeautifulSoup(page_year.text, 'html.parser')
        
        # Extract the latest date
        date_string = soup.find(
            lambda tag: tag.name == 'td' and 
            tag.get('class') == ['cell-date'] and 
            tag.string and 
            tag.string.strip()
        ).get_text()

        date = datetime.strptime(date_string, '%d %B %Y')
        
        # Find all rows and extract data for matching date
        rows = soup.find_all('tr')
        data = []
        
        for row in rows:
            date_cell = row.find('td', class_='cell-date')
            
            # Check if date matches and row has title
            if (date_cell and 
                date_cell.text.strip() == date_string and 
                row.find('td', class_='cell-title')):
                
                title_cell = row.find('td', class_='cell-title')
                cells = row.find_all('td')
                
                # Extract data for each gazette
                title = title_cell.find('a').text.strip()
                link = "https://new.kenyalaw.org" + title_cell.find('a')['href']
                category = cells[1].text.strip() or 'Weekly Issue'  # Default if empty
                index = cells[2].text.strip()
                download_link = link + "/source"
                
                data.append({
                    'Date': date,
                    'Issue': category,
                    'Title': title,
                    'Page Link': link,
                    'Download Link': download_link
                })
        
        # Create DataFrame
        df = pd.DataFrame(data)
        
        # Process each PDF and check for EPRA content
        for index, row in df.iterrows():
            try:
                # Download PDF
                response = requests.get(row['Download Link'], stream=True)
                response.raise_for_status()
                
                # Save PDF temporarily
                with open("downloads/download.pdf", 'wb') as file:
                    for chunk in response.iter_content(chunk_size=8192):
                        file.write(chunk)
                
                # Extract and check content
                doc = PdfReader("downloads/download.pdf")
                tbl_content = doc.pages[0].extract_text()
                
                # Check for EPRA or "The Energy Act" mention
                has_epra = bool(re.findall(
                    r"Energy and Petroleum Regulatory Authority",
                    tbl_content,
                    flags=re.IGNORECASE
                ))

                has_energy_act = bool(re.findall(
                    r"The Energy Act",
                    tbl_content,
                    flags=re.IGNORECASE
                ))

                # Determine the column value based on mentions
                if has_epra and has_energy_act:
                    df.at[index, 'EPRA/Energy Act'] = "EPRA & The Energy Act"
                elif has_epra:
                    df.at[index, 'EPRA/Energy Act'] = "EPRA"
                elif has_energy_act:
                    df.at[index, 'EPRA/Energy Act'] = "The Energy Act"
                else:
                    df.at[index, 'EPRA/Energy Act'] = ""
                
            except Exception as e:
                print(f"Error processing {row['Download Link']}: {str(e)}")
                df.at[index, 'EPRA/Energy Act'] = f"Error: {str(e)}"
            
            finally:
                # Clean up temporary file
                if os.path.exists("download.pdf"):
                    try:
                        os.remove("download.pdf")
                    except:
                        pass
        
        return date, df
        
    except Exception as e:
        print(f"Failed to scrape gazette data: {str(e)}")
        return None, None

######################################################################################################################

def send_mail(FROM, TO, SUBJECT, SERVER, PASSWORD, date_obj=None, data = None):
    """
    Sends an email with the recent notice details (weekly and/or special).

    Args:
    FROM (str): Sender's email address.
    TO (list): List of recipient email addresses.
    SUBJECT (str): Email subject.
    date_obj (datetime, optional): The date of the recent weekly notice.
    data (data frame): The dataframe of the fgazette info 
    SERVER (str): SMTP server address.
    PASSWORD (str): The sender's email password or app-specific password.
    """

    # Convert URLs to clickable links with custom text (Page + Index for Page Link, Download + Index for Download Link)
    data['Page Link'] = data.apply(lambda row: f'<a href="{row["Page Link"]}">Page {row["Title"]}</a>', axis=1)
    data['Download Link'] = data.apply(lambda row: f'<a href="{row["Download Link"]}">Download {row["Title"]}</a>', axis=1)

    # Convert DataFrame to HTML table
    table_html = data.to_html(index=False, escape=False)

    try:
        # Create a multipart message
        message = MIMEMultipart()
        message['From'] = FROM
        message['To'] = ", ".join(TO)
        message['Subject'] = SUBJECT

        # Start building the body of the email with HTML
        body = """
        <html>
        <body>
            <h2>Recent Kenya Law Notices</h2>
        """

        # Add Notice if available
        if date_obj:
            body += f"""
            <h3>Date: <b>{date_obj.strftime('%d %B, %Y')}</b></h3>
            <p></p>
            <p>Please find below the latest gazette posts:</p>
            {table_html}
            """


        # End the HTML body
        body += """
        </body>
        </html>
        """

        # Attach the body as HTML content
        message.attach(MIMEText(body, 'html'))

        # Setup the SMTP server and login
        server = smtplib.SMTP(SERVER, 587)
        server.starttls()  # Secure the connection
        server.login(FROM, PASSWORD)

        # Send the email
        server.sendmail(FROM, TO, message.as_string())
        server.quit()
        print("Email sent successfully!")

    except Exception as e:
        print(f"Failed to send email: {e}")

######################################################################################################################

# Define a function to upload the recent notice to a MySQL database after sending an email on latest issues
def upload_notice(engine):
    """
    input: engine

    Send email and Uploads the most recent weekly notice from the Kenya Law website to a MySQL database.
    If the notice is not already in the database, it adds the new notice.
    """

    # Usage
    FROM = 'alex.dev868@gmail.com'
    TO = [
        'wawerualex5483@gmail.com', 
        # "KWamwangi@kengen.co.ke"
        ]  # List of recipients
    SUBJECT = 'Recent Kenya Law Weekly Notice'
    SERVER = 'smtp.gmail.com'  
    PASSWORD = 'qiww ocvh erfw rots'   # App-specific password if 2FA is enabled

    # Create a MetaData object (holds schema information for database reflection)
    metadata = MetaData()

    # Reflect the 'weekly issues' table from the database using the engine
    table = Table('gazett notice db', metadata, autoload_with=engine)

    # Re-extract the notice information
    Date, df = scrape_kenya_gazettes()

    # Check if the notice date is not None (meaning the notice exists)
    if Date is not None:
        # Create a connection to the database
        with engine.connect() as connection:
            # Define a select query to check if the notice date already exists in the database
            query = select(table.c.Date).where(table.c.Date == Date)

            result = connection.execute(query).fetchone()  # Execute the query and fetch one result


        # Check if either weekly or special notice data is missing in the database
        if not result:
            # Send the email with the available notice data (could be both or one)
            send_mail(
                FROM, TO, SUBJECT, 
                date_obj=Date if not result else None, data=df if not result else None, 
                SERVER=SERVER, PASSWORD=PASSWORD
            )

            # Upload the weekly notice data if it's new
            if not result:
                # Re-extract the notice information
                Date, df = scrape_kenya_gazettes()
                df.to_sql(name='gazett notice db', con=engine, if_exists='append', index=False)

            

######################################################################################################################       

# Extract the recent weekly notice and send via email then upload to bd
upload_notice(engine)