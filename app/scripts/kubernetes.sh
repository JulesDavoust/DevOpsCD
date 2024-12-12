#!/bin/bash

kubectl create namespace dev
kubectl config set-context --current --namespace=dev

read -p "Do you want to create global gateway ? (y/n) " globalGatewayVar
if [ $globalGatewayVar == "y" ]
then
    kubectl apply -f ../kubernetes/gateway-global.yml
fi

read -p "Do you want to create database ? (y/n) " databaseVar
if [ $databaseVar == "y" ]
then
    kubectl apply -f ../kubernetes/backend/database/database.yaml
fi

read -p "Do you want to create api ? (y/n) " apiVar
if [ $apiVar == "y" ]
then
    kubectl apply -f ../kubernetes/backend/API/API.yml
fi

read -p "Do you want to create frontend ? (y/n) " frontendVar
if [ $frontendVar == "y" ]
then
    kubectl apply -f ../kubernetes/frontend/frontend.yml
fi
