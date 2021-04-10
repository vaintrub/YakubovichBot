# 🚀 Yakubovich Bot
![](http://boobooka.com/wp-content/uploads/2019/02/zastavka-pole-chudes.jpg)
## ☝️ What is it?
This is a Game "Field Of Miracle (Поле чудес)" for Telegram.

## 📚 Technologies
This project is powered by Perl.

To store information about users and game sessions, a database was selected sqlite.

## ✌️ Who is this game for?
The YakubovichBot can be used in:
- A private chat
   * Single games supported
- A group chat
   * Multiplayer games supported
   * One chat can have several game sessions at the same time
   * User can play in different chats at the same time


## 👌 Available commands
### Syntax
`Якубович [command] [param]`
### States:
0. Available in all states:
   - ***help***             
   > Get help
   - ***рейтинг***          
   > Show rating in this chat
1. Preparing:
   - ***начинай***           
   > Show list of available sessions in this chat. And brief explanation of how to start game 
   - ***новая игра [n]***    
   > Create new session with n people
   - ***игра [id]***         
   > Join to session with id
2. Waiting:
   - ***отключиться***       
   > Disconnect from session. Note! All participants will be disbanded
3. Game:
   - ***буква [character]*** 
   > Give a character like an answer
   - ***слово [word]***      
   > Give a word like an answer


## 👨‍🎓 How to play this game
1. Add the bot to a conversation.
2. ***`Якубович начинай`***
```
...
...
Список доступных игр:
ID игры:                 Кол. человек:
1                        2/3
```

3. If you want to connect to an existing game: ***`Якубович игра 1`***
4. If you want to create a new game for 3 people: ***`Якубович новая игра 3`***
```
YourName, ваша игра: [ id - 2 ], [ Участников - 1/3 ]

Ожидание игроков...
```
5. Enjoy the game


## 📝 Deployment
### Docker
1. Clone this repository
2. If you have docker installed you can simply run:

```
cd YakubovichBot
docker build -t yakubot .
docker run --rm -d --name yakubot -e TOKEN=YOUR_TOKEN yakubot
```
To start the bot in debug mode, you also need to add a flag with enviroment variable `-e BOT_DEBUG=1` and remove `-d`

***Note:** If you want the database to be saved after restarting the application, you can add a flag: 

`-v /Your/local/path/YakubovichBot/storage:/usr/src/YakubovichBot/storage`*

## ☑️ TODO
- [ ] Create unit tests!!!
- [x] Handle cases where the user does not have a nickname or first name 
- [ ] Make the session class standalone
- [ ] Build logs

