#!/bin/bash

export CURR_DOCKER_MARIADB_ROOT_USERNAME="root";
export CURR_DOCKER_MARIADB_ROOT_PASS="123";
export CONTAINER_BENCH_PATH="/workspace/development/frappe-bench";

#set -x;

echo "";
echo "Bienvenue dans cette assistant de déploiement d'un environnement de développement Frappe (ERPNext)";
echo "Il est prévue pour un environnement Linux (tester sur Debian 13/Ubuntu 24.04/Ubuntu 26.06";
echo "Aucune garantie de résultat n'est incluses !";

echo "Ce script nécessite que vous ayez les pré-requis suivant :";
echo "	- [Install Docker](https://docs.docker.com/engine/install/ubuntu/)";
echo "	- [Post Install for development environement](https://docs.docker.com/engine/install/linux-postinstall/)";
echo "  - [Install docker-compose](https://docs.docker.com/compose/install/)";
echo "	- [Docker Compose Completion](https://docs.docker.com/compose/completion/)";
echo "";
echo "On suppose que vous avez un maximum de connaissance de votre poste de travail et de la stack technique de Frappe !";
echo "le script utilise 'sudo', vous devez donc être en connaissance du mot passe sudouers de votre poste";
echo "";

if [ ! -f "~/.gitconfig" ]; then
  echo "Il vous manque le fichier ~/.gitconfig. Allez on configure sont profil git sur son poste (git config --global user.name "John Doe"  et git config --global user.email johndoe@example.com)";
fi

if [ ! -f "~/.bash_history" ]; then
  echo "Il vous manque le fichier ~/.bash_history. Allez au moins une commande et ca devrait le faire";
fi

if [ ! -f ".ssh/known_hosts" ]; then
  echo "Il vous manque le fichier .ssh/known_hosts. Allez au moins une connexion ssh sur un serveur";
fi

read -p "Voulez-vous continuer ? (O/n) : " reponse
reponse=${reponse:-O}
if [[ "$reponse" =~ ^[Oo]$ ]]; then
    echo "Vous avez répondu Oui.";
		echo "git clone https://github.com/scopen-coop/frappe-docker-files";
		git clone https://github.com/scopen-coop/frappe-docker-files;
	
	# Récupérer la liste version
	versions=()
	for version_dir in "frappe-docker-files/"*; do
	    version_name=$(basename "$version_dir")
	    if [ -d "$version_dir" ]; then
		    versions+=("$version_name")
	    fi
	done

  if [ ${#versions[@]} -eq 0 ]; then
    echo "";
		echo "Oups, pas de version trouvée...";
		echo "";
		exit 2
  fi
	
	select docker_scopen_version in "${versions[@]}"
	do
	    if [ -z "$docker_scopen_version" ]; then
        echo "";
        echo "Non non non, vous avez choisi un truc qui n'existe pas, à bientôt !";
        echo "";
        exit 2
	    fi
	    break
	done

	echo "Vous avez choisi la version $docker_scopen_version";

	if [ ! -d "/opt/data/$docker_scopen_version/mysql" ]; then
		echo "Create /opt/data/$docker_scopen_version/mysql to store MarriaDb DB : sudo mkdir -p  /opt/data/$docker_scopen_version/mysql";
		sudo mkdir -p "/opt/data/$docker_scopen_version/mysql";
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$docker_scopen_version/mysql --opt o=bind $docker_scopen_version-mariadb-vol";
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$docker_scopen_version"/mysql --opt o=bind "$docker_scopen_version"-mariadb-vol;
	fi

	if [ ! -d "/opt/data/$docker_scopen_version/redis_cache" ]; then
		echo "Create /opt/data/$docker_scopen_version/redis_cache to store Redis Cache : sudo mkdir -p  /opt/data/$docker_scopen_version/redis_cache;";
	 	sudo mkdir -p  /opt/data/"$docker_scopen_version"/redis_cache;
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$docker_scopen_version/redis_cache --opt o=bind $docker_scopen_version-redis-cache-data;";
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$docker_scopen_version"/redis_cache --opt o=bind "$docker_scopen_version"-redis-cache-data;
	fi

	if [ ! -d "/opt/data/$docker_scopen_version/redis_queue" ]; then
		echo "Create /opt/data/$docker_scopen_version/redis_queue to store Redis Queue : sudo mkdir -p  /opt/data/$docker_scopen_version/redis_queue";
	 	sudo mkdir -p  /opt/data/"$docker_scopen_version"/redis_queue;
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$docker_scopen_version/redis_queue --opt o=bind $docker_scopen_version-redis-queue-data;";
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$docker_scopen_version"/redis_queue --opt o=bind "$docker_scopen_version"-redis-queue-data;
	fi

	if [ ! -d "/opt/data/$docker_scopen_version/redis_socketio" ]; then
		echo "Create /opt/data/$docker_scopen_version/redis_socketio to store Redis Socket Io : sudo mkdir -p  /opt/data/$docker_scopen_version/redis_socketio;";
	 	sudo mkdir -p  /opt/data/"$docker_scopen_version"/redis_socketio;
		echo "Create Docker Volume : docker volume create --driver local --opt type=none --opt device=/opt/data/$docker_scopen_version/redis_socketio --opt o=bind $docker_scopen_version-redis-socketio-data";
		docker volume create --driver local --opt type=none --opt device=/opt/data/"$docker_scopen_version"/redis_socketio --opt o=bind "$docker_scopen_version"-redis-socketio-data;
	fi

  read -p "Voulez-vous dockerreset ? (O/n) : " reponse_clean_docker
  reponse_clean_docker=${reponse_clean_docker:-O}
  if [[ "$reponse_clean_docker" =~ ^[Oo]$ ]]; then
    current_contairers_run=$(docker ps -q)
    if [ ${#current_contairers_run[@]} -gt 0 ]; then
      echo "docker container stop (docker ps -q)";
      docker container stop $(docker ps -q);
    fi

    echo "docker network prune -f";
	  docker network prune -f;
	  echo "container prune -f";
	  docker container prune -f;
	  echo "system prune -f";
	  docker system prune -f;
	fi

	echo "Create Docker Frappe Network  : docker network create frappe-network"
	docker network create frappe-network;

  docker_folder="$docker_scopen_version";
  docker_folder="frappe_docker_${docker_scopen_version#frappe}";

  if [ ! -d "./$docker_folder" ]; then
	  echo "Clone  frappe_docker : git clone https://github.com/frappe/frappe_docker $docker_folder";
	  git clone https://github.com/frappe/frappe_docker "$docker_folder";
	fi


  echo "";
  echo "Build the image and run the container";
  echo "";
  cd frappe-docker-files/"$docker_scopen_version";
  docker compose build --build-arg CURRENT_UID=$(id -u);
  docker compose up -d;

  app_version="$docker_scopen_version"
  if [[ "$app_version" == "frappedev" ]]; then
    app_version="develop";
  else
    app_version="version-${docker_scopen_version#frappe}";
  fi


  if [ ! -d "./$docker_folder/development/frappe-bench/" ]; then
    docker exec -e "TERM=xterm-256color" -w /workspace/development -it "$docker_scopen_version"-frappe-1 bench init --skip-redis-config-generation --frappe-branch "$app_version" frappe-bench;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench set-config -g db_host mariadb;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench set-config -g redis_cache redis://redis-cache:6379;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench set-config -g redis_queue redis://redis-queue:6379;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench set-config -g redis_socketio redis://redis-socketio:6379;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench set-config -g server_script_enabled 1;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench set-config -g shallow_clone false;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench setup requirements --dev;
    docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench set-config -g dns_multitenant on;
  fi

  if [ ! -d "./$docker_folder/development/frappe-bench/app/scopen_frappe_diff" ]; then
      docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench get-app https://github.com/scopen-coop/scopen-frappe-diff.git;
  fi

  if [ ! -d "./$docker_folder/development/frappe-bench/app/erpnext" ]; then
    read -p "Voulez-vous get-app erpnext ? (O/n) : " reponse_get_erpnext
    reponse_get_erpnext=${reponse_get_erpnext:-O}
    if [[ "$reponse_get_erpnext" =~ ^[Oo]$ ]]; then
      docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench get-app --branch "$app_version" erpnext https://github.com/frappe/erpnext.git;
    fi
  fi
  
  if [ ! -d "./$docker_folder/development/frappe-bench/app/erpnext_france" ]; then
  	read -p "Voulez-vous get-app erpnext_france ? (O/n) : " reponse_get_erpnext_france
    reponse_get_erpnext_france=${reponse_get_erpnext_france:-O}
    if [[ "$reponse_get_erpnext_france" =~ ^[Oo]$ ]]; then
      docker exec -e "TERM=xterm-256color" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bench get-app --branch "$app_version" erpnext_france git@github.com:scopen-coop/erpnext_france.git;
    fi
  fi

  echo "";
  echo "Voila voila ! ";
  echo "Maintenant a vous de jouez : ";
  echo "Allez dans le container :";
  echo "docker exec -e \"TERM=xterm-256color\" -w /workspace/development/frappe-bench -it "$docker_scopen_version"-frappe-1 bash";
  echo "";
  echo "exemple de commande pour créer un site :";
  echo "bench new-site erpnextdev.local --mariadb-root-username root --mariadb-root-password 123 --admin-password admin --mariadb-user-host-login-scope='%' --db-name erpnextdev;"
  echo "bench --site erpnextdev.local install-app erpnext;";
  echo "bench --site erpnextdev.local install-app erpnext_france;";
  echo "bench --site erpnextdev.local set-config developer_mode 1;";
  echo "bench --site erpnextdev.local clear-cache;";
  echo "";
  echo "bench start";
  echo "(ou mettre à jour le docker-compose pour le faire au démarrage)";
  echo "";
  echo "Pensez également a mettre erpnextdev.local dans le fichier /etc/hosts ";
  echo "";
  echo "Dans les autre commandes intéressantes :";
  echo "Supprimer toute les colonnes qui ne sont plus dans les DocType (json) ou dans les CustomField  : bench --site all trim-tables --no-backup";
  echo "Update (pull,migrate,build) (attention si vous avez du code non commité et non poussé il sera effacé)  : bench update --reset --no-backup;";

else
	echo "Ok, on se revois plus tard"
   	# Actions à effectuer si la réponse est N
   	exit 1
fi
