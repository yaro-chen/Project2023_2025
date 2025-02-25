#!/usr/bin/env python3

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By

# Set path Selenium
CHROMEDRIVER_PATH = '/usr/local/bin/chromedriver'
s = Service(CHROMEDRIVER_PATH)
WINDOW_SIZE = "1920,1080"

# Options
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--window-size=%s" % WINDOW_SIZE)
chrome_options.add_argument('--no-sandbox')
#chrome_options.add_experimental_option("prefs", {"download.default_directory": "/opt"})
driver = webdriver.Chrome(service=s, options=chrome_options)

driver.get("") #website of database
print("waiting for loading page......")
driver.implicitly_wait(30)

button = driver.find_element(By.CLASS_NAME, "fa.fa-download.wdk-Icon")
import time
time.sleep(5)
print(button)
button.click()
time.sleep(30)

driver.close()

#If the downloaded file has an extension with '.crdownload', increase the waiting time (sleep or wait) for web parsing
