#!/bin/bash
certbot certonly --webroot --email dougnd@gmail.com -w /var/www/letsencrypt -d dawsons.family -d www.dawsons.family -d research.dawsons.family -d recipes.dawsons.family -d ooa-staging.dawsons.family
