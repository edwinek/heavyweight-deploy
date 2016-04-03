# heavyweight-deploy
A hacky script for running a dockerised version of "heavyweight".

## Deploy
* `chmod +x deploy.sh`
* Run the `deploy.sh` script
    * this will deploy the service to container, listening on port `8888`

## Useage
* Service will deploy to `http://localhost:8888/heavyweight`
* Resource (GET): `/query?date=yyyy-mm-dd`
    * to query by date
* Resource (GET): `/update`
    * to update the database
