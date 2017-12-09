# Bluetooth-RC-car
iOS player end controller app for the RC car
Created with Swift 3

Please run/test this app on real iOS devices. Bluetooth feature isn't available on simulator 
[Pi] Install the supproting libraries on your raspberry pi according to the readme file provided in 'RaspberryPi' repo.
[Pi] On raspberry pi side please copy and run 'main.js' from the 'RaspberryPi' repo. 
This is the first version of the controller. Known bugs so far are: 
1. Due to force unwrapping the app crashes if the user
tries to select a already disconnected BLE device on the list. 
2. There isn't a 'refresh' button for user to refresh the bluetooth devies' list manually

Please connect your raspberry pi RC car with both camera module and mic in order to use pic streaming and speech control features

I am working on imporving the bugs and there will soon be version 2
