build: build-network start-db prepare-db start-kong


build-network:
	@echo "Creating network..."
	@docker network create kong-net

start-db:
	@echo "sleeping..."
	@sleep 10
	@echo "done!"
	@echo "Starting DB..."
	@docker run -d --name kong-database \
		--network=kong-net \
		-p 5432:5432 \
		-e "POSTGRES_USER=kong" \
		-e "POSTGRES_DB=kong" \
		-e "POSTGRES_PASSWORD=kongpass" \
		postgres:9.6

prepare-db:
	@echo "sleeping..."
	@sleep 10
	@echo "done!"
	@echo "Running migrations..."
	@docker run --rm --network=kong-net \
		-e "KONG_DATABASE=postgres" \
		-e "KONG_PG_HOST=kong-database" \
		-e "KONG_PG_PASSWORD=kongpass" \
		kong:2.8.1-alpine kong migrations bootstrap

start-kong:
	@echo "sleeping..."
	@sleep 10
	@echo "done!"
	@echo "Starting kong-gateway..."
	@docker run -d --name kong-gateway \
		--network=kong-net \
		-e "KONG_DATABASE=postgres" \
		-e "KONG_PG_HOST=kong-database" \
		-e "KONG_PG_USER=kong" \
		-e "KONG_PG_PASSWORD=kongpass" \
		-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
		-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
		-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
		-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
		-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
		-p 8000:8000 \
		-p 8443:8443 \
		-p 127.0.0.1:8001:8001 \
		-p 127.0.0.1:8444:8444 \
		kong:2.8.1-alpine


setup: build

clean:
	@docker stop kong-database
	@docker container rm kong-database
	@docker network prune
	@docker stop kong-gateway
	@docker container rm kong-gateway
	@docker network rm kong-net
	@docker network prune