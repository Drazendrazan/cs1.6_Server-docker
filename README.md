# cs1.6_Server-docker

## Installation

1- Install Docker  
2- Clone this repository  
3- Run `cd dockerimage && docker build -t cs1.6-server .`  
4- create `docker-compose.yml` file and add this code:  

```docker
version: '1'
services:
  cs1.6-server:
    image: cs1.6-server
    container_name: cs1.6-server
    environment:
    - ENV PORT 27015
    - ENV MAP big_city2
    - ENV MAXPLAYERS 32
    - ENV SV_LAN 0
    - ENV IP 0.0.0.0
    ports:
      - 27015:27015/udp
    volumes:
      - /home/agalar/games/cs-1.6/data/game.cfg:/hlds/cstrike/game.cfg
      - /home/agalar/games/cs-1.6/data/reunion.cfg:/hlds/cstrike/reunion.cfg
      - /home/agalar/games/cs-1.6/data/server.cfg:/hlds/cstrike/server.cfg
      - /home/agalar/games/cs-1.6/data/settings.scr:/hlds/cstrike/settings.scr
      - /home/agalar/games/cs-1.6/data/sys_error.log:/hlds/cstrike/sys_error.log
      - /home/agalar/games/cs-1.6/data/titles.txt:/hlds/cstrike/titles.txt

    restart: 'unless-stopped'
```

5- Run `docker-compose up -d`
