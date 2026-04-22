#!/bin/bash

export CURR_DOCKER_MARIADB_ROOT_USERNAME="root"
export CURR_DOCKER_MARIADB_ROOT_PASS="123"
export CONTAINER_BENCH_PATH="/workspace/development/frappe-bench"

echo ""
echo "Bienvenue dans cette assistant de deploiment d'un environement de developpment Frappe (ERPNext)"
echo "Il est prévue pour un environement Linux (tester sur Debain 13/ Unbuntu 24.04 ( et si jamais 26.04 mais elle n'est pas encore officilement disponible))"
echo "Aucune garantie de resultat n'est incluses !"

echo "Ce script necéssite que vous ayez les pré-requis suivant :"
echo "	- [Install Docker](https://docs.docker.com/engine/install/ubuntu/)"
echo "	- [Post Install for development environement](https://docs.docker.com/engine/install/linux-postinstall/)"
echo "  - [Install docker-compose](https://docs.docker.com/compose/install/)"
echo "	- [Docker Compose Completion](https://docs.docker.com/compose/completion/)"
echo ""
echo "On suppose que vous avez un maximum de connaissance de votre poste de travail et de la stack technique de Frappe !"
echo "le script utilise 'sudo', vous devez donc être en connaissance du mot passe sudouers de votre poste"
echo ""

read -p "Voulez-vous continuer ? (O/N) : " reponse
if [[ "$reponse" =~ ^[Oo]$ ]]; then
    	echo "Vous avez répondu Oui."
		echo "git submodule init;"
    	git submodule init;
		echo "git submodule update;"
		git submodule update;
	
	# Récupérer la liste version
	versions=()
	for version_dir in "frappe-docker-files/"*; do
	    versiondir_name=$(basename "$version_dir")
	    if [ -d "$version_dir" ]; then
		versions+=("$versiondir_name")
	    fi
	done
	
	select version in "${versions[@]}"
	do
	    if [ -z "$version" ]; then
		echo ""
		echo "Non non non, vous avez choisi un truc qui n'existe pas, à bientôt !"
		echo ""
		exit 2
	    fi
	    break
	done

	echo "Vous avez choisi la version $version"

	if [ ! -d "/opt/data/$version/mysql" ]; then
		echo "Create /opt/data/$version/mysql to store MarriaDb DB : sudo mkdir -p  /opt/data/$version/mysql"
		sudo mkdir -p "/opt/data/$version/mysql"
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$version/mysql --opt o=bind $version-mariadb-vol"
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$version"/mysql --opt o=bind "$version"-mariadb-vol
	fi
	
	if [ ! -d "/opt/data/$version/redis_cache" ]; then
		echo "Create /opt/data/$version/redis_cache to store Redis Cache : sudo mkdir -p  /opt/data/$version/redis_cache;"
	 	sudo mkdir -p  /opt/data/"$version"/redis_cache;
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$version/redis_cache --opt o=bind $version-redis-cache-data;"
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$version"/redis_cache --opt o=bind "$version"-redis-cache-data;
	fi
	 
	if [ ! -d "/opt/data/$version/redis_queue" ]; then
		echo "Create /opt/data/$version/redis_queue to store Redis Queue : sudo mkdir -p  /opt/data/$version/redis_queue"
	 	sudo mkdir -p  /opt/data/"$version"/redis_queue;
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$version/redis_queue --opt o=bind $version-redis-cache-queue;"
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$version"/redis_queue --opt o=bind "$version"-redis-cache-queue;
	fi
	 
	if [ ! -d "/opt/data/$version/redis_socketio" ]; then
		echo "Create /opt/data/$version/redis_socketio to store Redis Socket Io : sudo mkdir -p  /opt/data/$version/redis_socketio;"
	 	sudo mkdir -p  /opt/data/"$version"/redis_socketio;
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$version/redis_socketio --opt o=bind $version-redis-redis-socketio;"
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$version"/redis_socketio --opt o=bind "$version"-redis-cache-socketio;
	fi

	echo "Create Docker Frappe Netcork  : docker network create frappe-network"
	docker network create frappe-network

	echo "Clone  frappe_docker : git clone https://github.com/frappe/frappe_docker frappe_docker_$version"
	git clone https://github.com/frappe/frappe_docker frappe_docker_"$version";

	cd frappe-docker-files/"$version"
	docker compose build --build-arg CURRENT_UID=$(id -u);
	docker compose up -d
	#docker exec -e "TERM=xterm-256color" -w /workspace/development -it "$version"-frappe-1 bench init --skip-redis-config-generation --frappe-branch version-16 frappe-bench;


	
else
	echo "Ok, we will keep up next time"
   	# Actions à effectuer si la réponse est N
   	exit 1
fi












 
 


