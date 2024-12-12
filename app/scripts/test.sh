#! /bin/bash
#!bin/bash
clear

echo "Do you want to start the docker containers ? (y/n) "
read startContainerVar

if [ $startContainerVar == "y" ]
then
    echo "Starting services with Docker Compose..."
else
    echo "Exiting script."
    exit 1
fi
# count="str"

# if [ $count == "str" ]
# then
#     echo "The condition is true"
# fi