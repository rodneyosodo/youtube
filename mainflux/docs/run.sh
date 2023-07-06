ADMIN_TOKEN=""
THING_ID=""
THING_SECRET=""
CHANNEL_ID=""
MSG="[{\"bn\":\"demo\", \"bu\":\"V\",\"bver\":5, \"n\":\"voltage\",\"u\":\"V\",\"v\":120}]"

function start() {
	docker-compose -f docker/docker-compose.yml up -d
	docker-compose -f docker/addons/cassandra-reader/docker-compose.yml up -d
	docker-compose -f docker/addons/cassandra-writer/docker-compose.yml up -d
	docker-compose -f docker/addons/influxdb-reader/docker-compose.yml up -d
	docker-compose -f docker/addons/influxdb-writer/docker-compose.yml up -d
	docker-compose -f docker/addons/mongodb-reader/docker-compose.yml up -d
	docker-compose -f docker/addons/mongodb-writer/docker-compose.yml up -d
	docker-compose -f docker/addons/postgres-reader/docker-compose.yml up -d
	docker-compose -f docker/addons/postgres-writer/docker-compose.yml up -d
	docker-compose -f docker/addons/timescale-reader/docker-compose.yml up -d
	docker-compose -f docker/addons/timescale-writer/docker-compose.yml up -d
	bash docker/addons/cassandra-writer/init.sh
}

function stop() {
	docker-compose -f docker/addons/timescale-writer/docker-compose.yml down
	docker-compose -f docker/addons/timescale-reader/docker-compose.yml down
	docker-compose -f docker/addons/postgres-writer/docker-compose.yml down
	docker-compose -f docker/addons/postgres-reader/docker-compose.yml down
	docker-compose -f docker/addons/mongodb-writer/docker-compose.yml down
	docker-compose -f docker/addons/mongodb-reader/docker-compose.yml down
	docker-compose -f docker/addons/influxdb-writer/docker-compose.yml down
	docker-compose -f docker/addons/influxdb-reader/docker-compose.yml down
	docker-compose -f docker/addons/cassandra-writer/docker-compose.yml down
	docker-compose -f docker/addons/cassandra-reader/docker-compose.yml down
	docker-compose -f docker/docker-compose.yml down
}

function provision() {
	ADMIN_TOKEN=$(mainflux-cli users token admin@example.com 12345678 | jq -r .access_token)
	THING_RESP=$(mainflux-cli things create '{"name": "thing"}' $ADMIN_TOKEN)
	THING_ID=$(echo $THING_RESP | jq -r .id)
	THING_SECRET=$(echo $THING_RESP | jq -r .credentials.secret)
	CHANNEL_RESP=$(mainflux-cli channels create '{"name": "channel"}' $ADMIN_TOKEN)
	CHANNEL_ID=$(echo $CHANNEL_RESP | jq -r .id)
	mainflux-cli things connect $THING_ID $CHANNEL_ID $ADMIN_TOKEN

	echo "Set env vars:"
	echo "export THING_ID=$THING_ID"
	echo "export THING_SECRET=$THING_SECRET"
	echo "export CHANNEL_ID=$CHANNEL_ID"
	echo "export MSG='$MSG'"
	echo ""
	echo "Subscription commands:"
	echo "mosquitto_sub --id-prefix mainflux -u $THING_ID -P $THING_SECRET -t channels/$CHANNEL_ID/messages -h localhost"
	echo "coap-cli get channels/$CHANNEL_ID/messages -auth $THING_SECRET -o"
	echo ""
	echo "Publishing commands:"
	echo "coap-cli post channels/$CHANNEL_ID/messages -auth $THING_SECRET -d '$MSG'"
	echo "mosquitto_pub --id-prefix mainflux -u $THING_ID -P $THING_SECRET -t channels/$CHANNEL_ID/messages -h localhost -m '$MSG'"
	echo "curl -s -S -i -X POST -H \"Content-Type: application/senml+json\" -H \"Authorization: Thing $THING_SECRET\" http://localhost/http/channels/$CHANNEL_ID/messages -d '$MSG'"
	echo ""
	echo "Readers commands:"
	echo "Cassandra Database"
	echo "curl -s -S -i -H \"Authorization: Thing $THING_SECRET\" http://localhost:9003/channels/$CHANNEL_ID/messages?offset=0&limit=5"
	echo "Influx Database"
	echo "curl -s -S -i -H \"Authorization: Thing $THING_SECRET\" http://localhost:9005/channels/$CHANNEL_ID/messages?offset=0&limit=5"
	echo "Mongo Database"
	echo "curl -s -S -i -H \"Authorization: Thing $THING_SECRET\" http://localhost:9007/channels/$CHANNEL_ID/messages?offset=0&limit=5"
	echo "Postgres Database"
	echo "curl -s -S -i -H \"Authorization: Thing $THING_SECRET\" http://localhost:9009/channels/$CHANNEL_ID/messages?offset=0&limit=5"
	echo "Timescale Database"
	echo "curl -s -S -i -H \"Authorization: Thing $THING_SECRET\" http://localhost:9011/channels/$CHANNEL_ID/messages?offset=0&limit=5"
}

if [ "$1" == "start" ]; then
	start
elif [ "$1" == "stop" ]; then
	stop
elif [ "$1" == "provision" ]; then
	provision
else
	echo "Usage: $0 [start|stop|provision]"
fi
