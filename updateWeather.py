import requests
import pandas as pd
import datetime
import config
from bs4 import BeautifulSoup

cities_df = pd.read_csv('data/city_names.csv')

if cities_df is None:
    world_cities = requests.get('https://worldpopulationreview.com/world-cities/')

    cities = BeautifulSoup(world_cities.text,'lxml')

    city_names = []
    for i in range(42,450):
        if i%2 == 0:
            city_names.append(cities.findAll('a')[i].getText())

    city_populations = []
    for i in range(1220):
        if i%6 == 0:
            city_populations.append(cities.findAll('td')[i+3].getText())
    
    city_names_pop = pd.DataFrame(data={"city_names":city_names, "population":city_populations})
    city_names_pop.to_csv('data/city_names.csv',index=False)
else:
    city_names = cities_df['city_names'].values.tolist()
    city_populations = cities_df['population'].values.tolist()

def getCurrentWeather(params):
    weather = 'http://api.openweathermap.org/data/2.5/weather'
    params['APPID'] = config.appid
    params['units'] = 'metric'
    return requests.get(weather,params)

def get_correct_name(city_name):
    correct_name = city_name
    if city_name == 'St Petersburg':
        correct_name = 'St. Petersburg'
    elif city_name == 'Rome':
        correct_name = 'Rome,IT'
    elif city_name == 'Melbourne':
        correct_name = 'Melbourne,AU'
    return correct_name

d = datetime.date.today()
date_for = d.strftime('%d-%m-%Y')

print('Updating Weather Condtions...')

params = {}
world_temperatures = []
for i in range(204):
    params['q'] = get_correct_name(city_names[i])
    response = getCurrentWeather(params)
    if response.status_code != 200:
        continue
    city_information = response.json()
    country = city_information['sys']['country']
    latitude = city_information['coord']['lat']
    longitude = city_information['coord']['lon']
    date_unix = city_information['dt'] - 60*60*3 + city_information['timezone']
    date_weather = datetime.datetime.fromtimestamp(date_unix).strftime("%Y-%m-%d %H:%M")
    weather_condition = city_information['weather'][0]['main']
    weather_det = city_information['weather'][0]['description']
    feels_like = city_information['main']['feels_like']
    temp = city_information['main']['temp']
    max_temp = city_information['main']['temp_max']
    min_temp = city_information['main']['temp_min']
    wind_speed = city_information['wind']['speed']
    city_data = {'City': city_names[i],
                 'Country': country,
                 'Latitude': latitude,
                 'Longitude': longitude,
                 'Population': city_populations[i],
                 'DateTime': date_weather,
                 'Weather': weather_condition,
                 'Main_Weather': weather_det,
                 'Feels_like': feels_like,
                 'temp': temp,
                 'max_temp': max_temp,
                 'min_temp': min_temp,
                 'Wind_Speed': wind_speed}
    print('Updating ' + city_names[i])
    world_temperatures.append(city_data)

world_temps_df = pd.DataFrame(world_temperatures, columns = city_data.keys())

world_temps_df.to_csv('data/weather.csv',index=False)

print('Weather Update Complete')