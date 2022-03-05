export PG_USER=mms
export PG_PASS=mms
export PG_IP_ADDR=postgres-docker
export ES_IP_ADDR=elasticsearch-docker



docker network create -d bridge mynet

# MMS
docker run --net=mynet --name mms-docker --mount source=mmsvol,target=/mnt/alf_data --publish=8080:8080 -e PG_HOST=${PG_IP_ADDR} -e PG_DB_NAME=mms -e PG_DB_USER=${PG_USER} -e PG_DB_PASS=${PG_PASS} -e ES_HOST=${ES_IP_ADDR} -d openmbee/mms:3.4.2

# PG
docker run --net=mynet -d --name postgres-docker --publish=5432:5432 -e POSTGRES_USER=${PG_USER} -e POSTGRES_PASSWORD=${PG_PASS} postgres:9.4-alpine
sleep "10"
docker exec -it postgres-docker psql -h 127.0.0.1 -U ${PG_USER} -c "ALTER ROLE ${PG_USER} CREATEDB"
docker exec -it postgres-docker createdb -h 127.0.0.1 -U ${PG_USER} alfresco
#docker exec -it postgres-docker createdb -h 127.0.0.1 -U ${PG_USER} mms
docker exec -it postgres-docker psql -h 127.0.0.1 -U ${PG_USER} -d mms -c "create table if not exists organizations (   id bigserial primary key,   orgId text not null,   orgName text not null,   constraint unique_organizations unique(orgId, orgName) ); create index orgId on organizations(orgId);  create table projects (   id bigserial primary key,   projectId text not null,   orgId integer references organizations(id),   name text not null,   location text not null,   constraint unique_projects unique(orgId, projectId) ); create index projectIdIndex on projects(projectid);"

# ES 
docker run --net=mynet -d --name elasticsearch-docker --publish=9200:9200 elasticsearch:5.5-alpine
sleep "10"
curl -XPUT http://localhost:9200/_template/template -d @mms-alfresco/mms-ent/repo-amp/src/main/resources/mapping_template.json

