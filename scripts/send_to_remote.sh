#!/bin/bash

IP_ADDR="$1"

scp -r ./backend default@"$IP_ADDR":~/project/backend
scp -r ./frontend default@"$IP_ADDR":~/project/frontend
scp -r ./models default@"$IP_ADDR":~/project/models
scp -r ./docker-compose.yaml default@"$IP_ADDR":~/project