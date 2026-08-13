# Sean Neptali P. Perez
## INF233
## CTADMOBL Advance Programming

A flutter project that focuses on advance topics. Covering the web to mobile transactions. 

## Lab Activity Instance


## Laboratory List

- ##Lab 1 - Theme (Dark/Light Mode):
- Discussion: 
 SetState is a built in that manages a singe statefulwidget for the ephemeral or local state that rebuilds the widget whenver something changed in the widget itself.
 While App State where we use Provider it a package that helps manage states, it notifies all the listeners so they will rebuild the widgets or any descendant widget. This happens that if you change or provide a change on the state, this will change every widget related to it.

 ##Lab 2 - API
 - Discussion:
The model is a class that defines the structure of the data you expect from the API endpoint. The service contains the logic for network communication, it uses a package like http to make the actual API call. When the service receives a JSON response, it uses the model's fromjson method to convert the JSON into one or more model instances. Finally, screen is responsible for displaying the data. Instead, it uses a state management solution like Provider to request the data. The Provider, acting as a middleman, calls the service, gets the data, and notifies the screen that the data is ready. The screen then rebuilds and displays the data from the model objects, cleanly separating the UI from the business and data-fetching logic.
 
