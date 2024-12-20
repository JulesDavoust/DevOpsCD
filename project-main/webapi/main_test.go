package main

import (
        "encoding/json"
        "net/http"
        "net/http/httptest"
        "reflect"
        "testing"
)

func TestWhoAmI(t *testing.T) {
	// Créer une requête HTTP GET simulée
	req, err := http.NewRequest("GET", "/whoami", nil)
	if err != nil {
			t.Fatalf("Impossible de créer une requête: %v", err)
	}

	// Créer un enregistreur de réponse simulé
	rr := httptest.NewRecorder()

	// Handler à tester
	handler := http.HandlerFunc(whoAmI)

	// Appeler le handler avec la requête et l'enregistreur
	handler.ServeHTTP(rr, req)

	// Vérifier le statut HTTP
	if status := rr.Code; status != http.StatusOK {
			t.Errorf("Statut HTTP incorrect: obtenu %v, attendu %v", status, http.StatusOK)
	}

	// Vérifier le contenu JSON de la réponse
	expected := ClassInfo{
			Class: "SE1",
			Students: []Student{
				{FirstName: "Vadim", LastName: "BERNARD"},
				{FirstName: "Jules", LastName: "DAVOUST"},
				{FirstName: "Robin", LastName: "LUCAS"},
		},
}

var actual ClassInfo
err = json.Unmarshal(rr.Body.Bytes(), &actual)
if err != nil {
		t.Fatalf("Erreur lors du parsing JSON: %v", err)
}

// Comparer les deux structures en utilisant reflect.DeepEqual
if !reflect.DeepEqual(expected, actual) {
		t.Errorf("Données incorrectes:\nobtenu: %+v\nattendu: %+v", actual, expected)
}
}