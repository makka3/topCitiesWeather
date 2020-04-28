import dropbox
import config

access_token = config.drop_key

file_from = 'data/weather.csv'

file_to = '/weather_csv/weather.csv'

dbx = dropbox.Dropbox(access_token)

with open(file_from, 'rb') as f:
    dbx.files_upload(f.read(), file_to, mode=dropbox.files.WriteMode.overwrite)

print("Upload complete")