backup_dir = /tmp/df_backup
db_container = df_db
api_container = df_oe_api
backup_name = $(shell date '+%d-%m-%Y-%H_%M_%S')

backup:
	rm -rf $(backup_dir)
	mkdir -p $(backup_dir)
	docker exec $(db_container) sh -c 'exec mysqldump openeats -uroot -p"$$MYSQL_ROOT_PASSWORD"' > $(backup_dir)/db.sql
	tail $(backup_dir)/db.sql
	docker run --rm --volumes-from $(api_container) -v $(backup_dir):/backup alpine tar cvf /backup/img.tar /code/site-media
	cd $(backup_dir) && tar cvzf latest.tar.gz db.sql img.tar
	cp $(backup_dir)/latest.tar.gz backup/latest.tar.gz
	cp backup/latest.tar.gz backup/$(backup_name).tar.gz

.PHONY: backup


