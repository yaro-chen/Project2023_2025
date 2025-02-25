
from selenium import webdriver
from selenium.webdriver.common.by import By
#from selenium.webdriver.common.action_chains import ActionChains

#import requests
from bs4 import BeautifulSoup
#from bs4.element import NavigableString

import time
import re
import openpyxl

driver = webdriver.Chrome()

driver.get("") #websitelink
driver.implicitly_wait(5)

def scroll():
    stay = 0

    while True:
        height = driver.execute_script("return document.body.scrollHeight")
        print(f"initial height: {height}")
        driver.execute_script("window.scrollBy(0, 300);")
        time.sleep(3)
        button = driver.find_element(By.XPATH, "/html/body/div[1]/div/div/div[2]/div[4]/div[2]/div/div[2]/button")
        if button:
            try:
                driver.execute_script("arguments[0].scrollIntoView();", button)
                button.click()
                print("button is clicked")
                time.sleep(3)
                del button
            except:
                print("button not in the view")
        
            
            ##ActionChains(driver).move_to_element(button).click(button).perform()
            
        new_height = driver.execute_script("return document.documentElement.scrollHeight")
        print(f"new height :{new_height}")
        print("-------------------")
        
        if height == new_height:
            stay = stay+1
            print(f"Hit the buttom:{stay}")
            if stay == 5 :
                print("Reached the bottom of the page.")
                break
        else:
            stay = 0
scroll()

def link_get():
    tag = driver.find_elements(By.CLASS_NAME,"news-card-title")

    hrefs = []
    for i in tag:   
        link = i.find_element(By.TAG_NAME,'a')
        print(link)
        hrefs.append(link.get_attribute("href"))
    return hrefs

linklists = link_get()

wb = openpyxl.Workbook()

worksheet=wb.active
worksheet.append(["Cancer","Drug","Response","Biomarker_Criteria","Clincal_setting","Note","Others"])

def text_parse(link):
    outputs = []
    driver.get(link)
    driver.implicitly_wait(3)

    cancer = driver.find_element(By.XPATH, "/html/body/div[3]/div[1]/div[1]/div[2]/h4").text #tuple1
    print(f"############## Current tag: {cancer} ###############")

    therapy = driver.find_element(By.XPATH, "/html/body/div[3]/div[1]/div[2]/div[2]/div[2]/div/div[1]/div[1]/h4/span")

    while True:
        try:
            therapy.click()
            print("<Biomarker-Diected Therapies> Clicked !")
            break
        except:
            driver.execute_script("arguments[0].scrollIntoView();", therapy)

    drugs = driver.find_elements(By.CLASS_NAME,"about-disease-therapy-header")

    drugs_all = []
    for i in drugs:
        drug_name = i.text.split('\n')[0]
        drugs_all.append(drug_name)
        try:
            i.click()
            print(f"Drug <{drug_name}> Clicked!")
        except:
            driver.execute_script("arguments[0].scrollIntoView();", i)
            i.click()
            print(f"Scrolling down. Drug <{drug_name}> Clicked!")
        time.sleep(1)
        
    invalid_chars = r'[<>:"/\\|?*]'
    cancer_out = re.sub(invalid_chars, '_', cancer)    

    with open(f"D:\\Others\\NCCN_guildline\\{cancer_out}_temp","w+") as html:
        html.write(driver.page_source)


    soup = BeautifulSoup(driver.page_source, "html.parser")
    drugs_list = soup.find_all(class_="about-disease-therapy-row")

    d = 0
    for item in drugs_list:
        drugtag = drugs_all[d] #tuple2
        print(drugtag)
        main_tag = item.find_all(class_="about-disease-therapy-sensitivity-row")
        for j in main_tag:
            prediction_check = j.find(class_="about-disease-therapy-sensitivity-header") 
            prediction = prediction_check.get_text().split(':')[0].split(' ')[-1] #tuple3
            print(prediction)

            criteria = j.find_all("div", class_= re.compile("biomarker-criteria"))
            
            for cri in criteria:
                
                texts = cri.findChildren(class_="therapy_criteria_header")
                text_structure = [] 
                for c in texts:
                    paracheck = c.find(style = re.compile("padding-left"))
                    if paracheck is not None:
                        text_structure.append((f"{c.get_text().split(':')[0]} :"))
                    else:
                        text_structure.append(f"\t{c.get_text()}")
                text_structure_out = '\n'.join(text_structure) #tuple 4
                if text_structure_out.count("Sample") == 1:
                    text_structure_out = text_structure_out.replace("\t","")
                print(text_structure_out)
                
                appendix = cri.find_next_sibling().find_all(class_="small-12 columns")
                for a in appendix:
                    label = a.get_text().split(':')[0]
                    if "Clinical" in label:
                       Clinical_setting = ''.join(a.get_text().split(':')[1:]).strip() #tuple 5
                       print(Clinical_setting)
                    elif "Note" in label:
                        Note = ''.join(a.get_text().split(':')[1:]).strip() #tuple 6
                        print(Note)
                    else:
                        others = a.get_text() #tuple 7
                        print(others)
                output_list = ["cancer", "drugtag", "prediction", "text_structure_out", "Clinical_setting", "Note", "others"]
                output = []
                for var in output_list:
                    try:
                        value = eval(var)
                        output.append(value)
                    except NameError:
                        output.append("N/A")
                outputs.append(tuple(output))
                
        d += 1
    for o in outputs:
        worksheet.append(o)
for link in linklists:
    text_parse(link)

wb.save("D:\\Others\\NCCN_guildline\\TargetedTherapies_MCG.xlsx")






