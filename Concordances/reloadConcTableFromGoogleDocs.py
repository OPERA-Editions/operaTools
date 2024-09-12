import csv
import requests

# dont forget to grant access to google doc

# steffani ME
# key of google spreadsheet
# https://docs.google.com/spreadsheets/d/1JoMVr3hkYxQaALnVQFtM8Yewkj5GwAITQ4-f0PrsJRQ/edit#gid=930928909
spreadsheet_key = '1JoMVr3hkYxQaALnVQFtM8Yewkj5GwAITQ4-f0PrsJRQ'
# ME lines conc
sheet_id = '930928909'
output_file = '../edition-74338566/resources/concordance/ME/concordance_bars_rawData.csv'

# vogelhändler 
# https://docs.google.com/spreadsheets/d/1MjsYAffh1HzJ-OnSjkYeBI6iThlA4L6qBmsIk5_GTDU/edit#gid=968622985
spreadsheet_key = '1MjsYAffh1HzJ-OnSjkYeBI6iThlA4L6qBmsIk5_GTDU'
sheet_id = '968622985'
output_file = '../edition-74338563/resources/concordance/concordance_bars_rawData.csv'

# lindpaintner
# https://docs.google.com/spreadsheets/d/1aVjM_bFcXIBGPsiyNfLkLut26xh13RRWjAh5xFf_L8E/edit#gid=959667295
spreadsheet_key = '1aVjM_bFcXIBGPsiyNfLkLut26xh13RRWjAh5xFf_L8E'
# conc by bars
sheet_id = '959667295'
output_file = '../edition-74338565/resources/concordance/concordance_bars_rawData.csv'
# conc by lines
# sheet_id = '334056104'
# output_file = '../edition-74338565/resources/concordance/concordance_lines_rawData.csv'

# function to read google doc csv file and safe to disc
def get_google_spreadsheet_as_csv (spreadsheet_key, output_file, sheet_id):
    response = requests.get('https://docs.google.com/spreadsheet/ccc?key=' + spreadsheet_key + '&gid=' + sheet_id + '&output=csv')
    # print(response.status_code)
    assert response.status_code == 200, 'Wrong status code'
    response.encoding = 'utf-8'
    spreadsheet_content = response.text

    csv_response = csv.reader(spreadsheet_content.splitlines(), delimiter=',')
    csv_list = list(csv_response)

    # TODO: delete after commit
    # for c in csv_list:
    #     c.append('')
    #     c.append('')

    # print(csv_list)

    with open(output_file, 'w') as csv_file:
        # creating a csv writer object  
        csv_writer = csv.writer(csv_file, delimiter=';')

        # writing the data rows  
        csv_writer.writerows(csv_list)

print('reloading csv from google...')
get_google_spreadsheet_as_csv(spreadsheet_key, output_file, sheet_id)
