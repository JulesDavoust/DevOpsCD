package main

import (
        "encoding/json"
        "fmt"
        "log"
        "net/http"
)

type Student struct {
        FirstName string
        LastName string
}

type ClassInfo struct{
        Class string
        Students []Student
}

func main() {
        request1()
}

func whoAmI(response http.ResponseWriter, r *http.Request) {
	who := ClassInfo{
			Class : "SE1",
			Students: []Student{
					{FirstName: "Vadim", LastName: "BERNARD"},
					{FirstName: "Jules", LastName: "DAVOUST"},
					{FirstName: "Robin", LastName: "LUCAS"},
			},
	}

	response.Header().Set("Content-Type", "application/json")
	json.NewEncoder(response).Encode(who)

	fmt.Println("Endpoint Hit", who)
}

func homePage(response http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(response, "Welcome to the Web API!")
	fmt.Println("Endpoint Hit: homePage")
}

func aboutMe(response http.ResponseWriter, r *http.Request) {
	who := "EfreiParis"

	fmt.Fprintf(response, "A little bit about me...")
	fmt.Println("Endpoint Hit: ", who)
}

func request1() {
	http.HandleFunc("/", homePage)
	http.HandleFunc("/aboutme", aboutMe)
	http.HandleFunc("/whoami", whoAmI)

	log.Fatal(http.ListenAndServe(":9090", nil))
}