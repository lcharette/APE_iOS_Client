APE iOS Client
==============
The APE iOS Client is a client used to connect to the [APE Server](http://ape-project.org/) [See [APE Server on GitHub](https://github.com/APE-Project/APE_Server)]. 

The client consist for now in a demo iPad app. This demo app connect and can exchange messages with the _APE Chat Demo_ bundle with [APE JSF](https://github.com/APE-Project/APE_JSF). 

This code is still in beta stage. It does connect and interact with the chat demo, but hasn't been fully tested and implemented yet. See **Contribute** for more infos.

![iPad](http://i.imgur.com/NXBTWQI.png)
![Chrome](http://i.imgur.com/KAoJnfF.png)

# What is APE?
APE is a full-featured OpenSource solution designed for Ajax Push. It includes a comet server and a Javascript Framework. APE allows to implement any kind of real-time data streaming to a web browser, without having to install anything on the client-side.

## Why use APE in iOS?
APE Client for iOS is used to interact in realtime with the APE Server and browser based APE clients. 

iOS provide push notification service (APNS) to push events to apps in realtime. But APNS can sometimes be unreliable and costly in ressources. When you have multiple client receiving many events in a small time frame, sometimes APNS can't keep up to the task. Also, APNS can only send a certain amount of data in one request and no methods are available to push data **to** the server or other clients. An HTTP request, to a PHP script for example, must be then used.

That's where this APE Clients comes in. Instead of relaying on an external service, the client connect directly to your APE Server, which may or may not already power your service on your website. You don't have to code extra server side module or service to relay event to your iOS app. The app is directly interacting with the APE Server and all of it's server side modules, all in realtime. And it's the same protocol and feature as the javascript based client. And if you're already using APE on your website, you don't have to change anything to support an iOS app. The app is just another users like everyone else!


For example, let's look at a chat app. Event with something small scale, you can have a dozen or more users sending dozen of messages in just a couple of seconds. If each of the 12 users send something at the same time, it's 12 messages, each sending 12 notifications thought the Apple Push Notification Services. That's 144 request, each of them taking a couple of second to be sent to the users devices by your server. Not only this small delay can cause the messages not to be sent in true realtime, but they can all be received in a random order. And it consume a lot of your server ressources, since you may need to load extra data from the server using an async http request. 

And using Safari won't be much of an help since you have no control when the user leave the page (so you can close the connexion for example) or other native functions and flexibility. With a native iOS client, you can take full advantage of all native function of iOS and even continue interacting with the user when he leave the app (see **Going further**). All of this with a small footprint and low data consumption thanks to APE.


Other solution exist on the web for realtime interaction (APNS). But none if them include the power of [APE](http://ape-project.org/) !

## How does it works?
This client uses native iOS socket streams to open a connexion to the APE Server and act as a XHRStreaming client on the server to send and receive JSON encoded data in realtime.

## Requirements
This client requires a **patched version of APE Server 1.1.3-DEV**. See [Pull Request](https://github.com/lcharette/APE_Server/tree/fe98daf9db61410cb4358f248b74975cbd6072cb). 

This patch fix an issue that cause "BAD_JSON" event to be returned from APE Server when small request are sent to the server. Just download the source code, build it (see [APE Documentation](http://ape-project.org/wiki/index.php?page=Main+page)), locally run APE and edit the url and port in the app's viewcontroler and you're good to go!


# Contribute
Even if I know APE like the back of my hand, I'm still new to iOS development. So fell free to test this app, add comments and contribute! I still have a lot to learn in iOS development and I'll be happy to use your input as a source of improvement. 

I'm pretty sure you know more than me how this client can be improved, but here's a small todo list if you want to contribute:

## Todo list
* Use custom objects for users and channels instead of NSDictionnary
* "get_user" method (get only one user; By pubid/name)
* Handle APE sessions
* Use APE Sessions to restore when the App comes back from 
* Unify events handling and params/arguments
* Add other [APE related function](http://ape-project.org/static/jsdocs/client/symbols/APE.html)
* Document the whole thing
* Check for blocking code or optimise code
* Clean up the whole code
* Create iPhone Demo
* **Create awesome APE app !**
* _etc._

## Going further...
This client and demo app are a small example of what can be done using APE in iOS. Many many more feature can be added or improved using APE Server Side coding and APE awesomeness ! 

One example: The iOS app can't stay connected to the APE server when it's closed. A server side script could be written to to register clients closing the app (during _applicationDidEnterBackground_) and keep track of the messages sent to the chat while the app is in background. When the app is launched again (_applicationWillEnterForeground_), the server "bot" can then send back all missed messages to the client or event send Push Notifications to the device while the app is still inactive !
