<template>
  <div>
    <h1>Liste des utilisateurs</h1>
    <ul>
      <li v-for="user in users" :key="user.id">{{ user.name }} - {{ user.email }}</li>
    </ul>
    <form @submit.prevent="addUser">
      <input v-model="newUser.name" placeholder="Nom" required />
      <input v-model="newUser.email" placeholder="Email" required />
      <button type="submit">Ajouter</button>
    </form>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  data() {
    return {
      users: [],
      newUser: {
        name: '',
        email: '',
      },
      API_URL: '', // Initialisé dynamiquement
    }
  },
  async mounted() {
    await this.loadConfig()
    this.fetchUsers()
  },
  methods: {
    async loadConfig() {
      try {
        const response = await axios.get('/env-config.js');
        eval(response.data); // Exécute et initialise window.env
        console.log(response.data);
        console.log("env-config.js loaded:", window.env);
        if (window.env && window.env.VUE_APP_API_URL) {
          this.API_URL = window.env.VUE_APP_API_URL;
          console.log("API_URL loaded:", this.API_URL);
        } else {
          console.error("VUE_APP_API_URL not found in env-config.js");
          this.API_URL = 'http://localhost:8080/'; // Fallback URL
        }
      } catch (error) {
        console.error("Error loading env-config.js:", error);
        this.API_URL = 'http://localhost:8080/'; // Fallback URL
      }
    },

    async fetchUsers() {
      const response = await axios.get(`${this.API_URL}users/all`)
      this.users = response.data
    },
    async addUser() {
      await axios.post(`${this.API_URL}users/add`, this.newUser)
      this.fetchUsers()
      this.newUser = { name: '', email: '' }
    },
  },
}
</script>
