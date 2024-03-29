backup_dir = /tmp/df_backup
db_container = df_db
api_container = df_oe_api
backup_name = $(shell date '+%d-%m-%Y-%H_%M_%S')
tag_name = `git describe --tags --dirty`

compose = compose

backup:
	rm -rf $(backup_dir)
	mkdir -p $(backup_dir)
	docker exec $(db_container) sh -c 'exec mysqldump openeats -uroot -p"$$MYSQL_ROOT_PASSWORD"' > $(backup_dir)/db.sql
	tail $(backup_dir)/db.sql
	docker run --rm --volumes-from $(api_container) -v $(backup_dir):/backup alpine tar cvf /backup/img.tar /code/site-media
	cd $(backup_dir) && tar cvzf latest.tar.gz db.sql img.tar
	cp $(backup_dir)/latest.tar.gz backup/latest.tar.gz
	cp backup/latest.tar.gz backup/$(backup_name).tar.gz


fetch-latest-prod-backup:
	scp root@dawsons.family:dawsons-family/backup/latest.tar.gz backup

update-imgs:
	docker pull openeats/openeats-api:latest
	docker pull openeats/openeats-web:latest
	cd openeats-api && docker build -t dougnd/openeats-api .

update: update-imgs
	docker-compose -f docker-$(compose).yml up -d --build

rebuild: update-imgs
	rm -rf $(backup_dir)
	mkdir -p $(backup_dir)
	cp backup/latest.tar.gz $(backup_dir)/latest.tar.gz
	cd $(backup_dir) && tar xvf latest.tar.gz
	docker-compose -f docker-$(compose).yml down -v --remove-orphans
	docker-compose -f docker-$(compose).yml build 
	docker-compose -f docker-$(compose).yml up -d db 
	sleep 30
	docker exec -i $(db_container) sh -c 'exec mysql openeats -uroot -p"$$MYSQL_ROOT_PASSWORD"' < $(backup_dir)/db.sql
	docker-compose -f docker-$(compose).yml run --rm --entrypoint 'python manage.py migrate' api
	docker-compose -f docker-$(compose).yml up -d 
	sleep 20
	docker run --rm --volumes-from $(api_container) -v $(backup_dir):/backup alpine sh -c "cd /code/site-media && tar xvf /backup/img.tar --strip 1"

OpenEats:
	git clone https://github.com/dougnd/OpenEats.git

push-openeats: OpenEats
	cd OpenEats && git pull
	cd OpenEats && docker-compose build
	cd OpenEats && docker tag openeats_api dougnd/openeats-api:latest
	cd OpenEats && docker push dougnd/openeats-api:latest
	cd OpenEats && docker tag openeats_node dougnd/openeats-node:latest
	cd OpenEats && docker push dougnd/openeats-node:latest
	cd OpenEats && docker tag openeats_api dougnd/openeats-api:$(tag_name)
	cd OpenEats && docker push dougnd/openeats-api:$(tag_name)
	cd OpenEats && docker tag openeats_node dougnd/openeats-node:$(tag_name)
	cd OpenEats && docker push dougnd/openeats-node:$(tag_name)

.PHONY: backup rebuild update update-imgs push-openeats

