#!/bin/bash

IP_ADDR="$1"

ssh -o StrictHostKeyChecking=no default@"$IP_ADDR" "mkdir -p ~/project"
scp -r ./backend default@"$IP_ADDR":~/project/
scp -r ./frontend default@"$IP_ADDR":~/project/
scp -r ./models default@"$IP_ADDR":~/project/
scp -r ./docker-compose.yaml default@"$IP_ADDR":~/project