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

 ##Lab 3 - API PART 2
 - Discussion:
The cart model defines the data structure for cart items as received from the API. All network operations are handled by the cart_service, which includes a getCartByUserId method to fetch a specific user's cart from the /carts/user/{userId} endpoint. The cart_screen then calls this service to retrieve the data and renders the user interface, displaying the items in the cart. 

##Lab 4 - API PART 3
- Discussion:
The created new user model defines the data of our users, while the user service will handle the API calls, this include the loginUser method which fetches the user data from the API endpoint. When a user logs in, the user data will be fetched from the dummyjson api, it will be saved in the shared preferences using user service, then if the user logs in again it will just retrieve the data from the shared preferences instead of fetching from the API. If the user logs out, the data will be cleared from the shared preferences. The profile screen uses this stored data to display the user information. 

##Lab 5 - Firebase 
- Discussion:
When signing up, we use firebase to store user data and dummyjson to create a new user, on dummyjson it just shows a fake success response. It can be seen in the sign up screen that the users can choose between Firebase and DummyJSON account. This will determine where the user data will be stored. If the user chooses Firebase, the user data will be stored in Firebase and if the user chooses DummyJSON, the user data will be stored in DummyJSON. The user service will act as a bridge between the firebase and the dummyjson. It will be responsible for the login and logout of the user. It will also be responsible for the reset password of the user, it also has methods like, updateProfile, updatePassword, etc. The firebase gives the application authentication, while the dummyjson gives the application fake data. 